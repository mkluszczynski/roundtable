import 'dart:convert';

import 'package:roundtable_client/roundtable_client.dart';

/// Turns the raw `claude --output-format stream-json --include-partial-messages`
/// NDJSON stdout (docs/FLOWS.md §4) into human-readable lines, so
/// `TaskDispatcher` can persist readable `TaskLogEntry.content` instead of raw
/// protocol JSON (docs/FLOWS.md §4).
///
/// One instance is used per `claude` process invocation — planning and
/// execution share a single continuous invocation (see
/// `ClaudeCodeExecutor.runPlanning`'s doc comment), so a fresh
/// [StreamJsonFormatter] per `TaskDispatcher.handle()` call is enough.
///
/// The model's own output (`assistant` turns) streams in as `stream_event`
/// deltas, which this class buffers per content-block index and flattens
/// into one line per completed block. Tool results, by contrast, are never
/// streamed (they come from the tool runner, not the model), so they only
/// ever arrive as a complete `user`-type message — those are read directly.
/// The complete, non-streamed `assistant`-type message that also appears in
/// the output is skipped: since `--include-partial-messages` is always
/// passed, every one of its content blocks already went through the
/// `stream_event` path above, so re-emitting it here would just duplicate
/// every line.
class StreamJsonFormatter {
  final _blocks = <int, _BlockBuffer>{};

  /// Feeds one raw NDJSON line, returning zero or more human-readable lines
  /// — the legacy, prefix-based form of [feedEntries]. Never throws.
  List<String> feed(String rawLine) => [
    for (final item in feedEntries(rawLine)) item.line,
  ];

  /// Feeds one raw NDJSON line, returning zero or more structured log items
  /// to persist. Never throws — a malformed or unrecognized line simply
  /// yields no output.
  List<LogItem> feedEntries(String rawLine) {
    final Map<String, dynamic> event;
    try {
      event = jsonDecode(rawLine) as Map<String, dynamic>;
    } catch (_) {
      return const [];
    }

    switch (event['type']) {
      case 'stream_event':
        return _handleStreamEvent(event['event'] as Map<String, dynamic>?);
      case 'user':
        return _handleToolResults(event['message'] as Map<String, dynamic>?);
      case 'result':
        return [_summarizeResult(event)];
      default:
        // 'system' (init) and the complete, non-streamed 'assistant'
        // message are deliberately not surfaced — see class doc comment.
        return const [];
    }
  }

  List<LogItem> _handleStreamEvent(Map<String, dynamic>? inner) {
    if (inner == null) return const [];
    switch (inner['type']) {
      case 'message_start':
        _blocks.clear();
        return const [];
      case 'content_block_start':
        final index = inner['index'] as int?;
        final block = inner['content_block'] as Map<String, dynamic>?;
        if (index == null || block == null) return const [];
        _blocks[index] = _BlockBuffer(
          type: block['type'] as String? ?? '',
          toolName: block['name'] as String?,
          toolUseId: block['id'] as String?,
        );
        return const [];
      case 'content_block_delta':
        final index = inner['index'] as int?;
        final delta = inner['delta'] as Map<String, dynamic>?;
        final buffer = index == null ? null : _blocks[index];
        if (buffer == null || delta == null) return const [];
        switch (delta['type']) {
          case 'text_delta':
            buffer.text.write(delta['text'] as String? ?? '');
          case 'thinking_delta':
            buffer.text.write(delta['thinking'] as String? ?? '');
          case 'input_json_delta':
            buffer.text.write(delta['partial_json'] as String? ?? '');
        }
        return const [];
      case 'content_block_stop':
        final index = inner['index'] as int?;
        final buffer = index == null ? null : _blocks.remove(index);
        if (buffer == null) return const [];
        final item = _finalizeBlock(buffer);
        return item == null ? const [] : [item];
      default:
        return const [];
    }
  }

  LogItem? _finalizeBlock(_BlockBuffer buffer) {
    switch (buffer.type) {
      case 'text':
        final text = buffer.text.toString().trim();
        return text.isEmpty
            ? null
            : LogItem(kind: LogKind.message, content: text);
      case 'thinking':
        final text = buffer.text.toString().trim();
        return text.isEmpty
            ? null
            : LogItem(kind: LogKind.thinking, content: text);
      case 'tool_use':
        final name = buffer.toolName ?? 'Tool';
        final raw = buffer.text.toString();
        return LogItem(
          kind: LogKind.toolCall,
          content: _summarizeToolUse(name, raw),
          toolName: name,
          toolUseId: buffer.toolUseId,
          detail: _truncate(_prettyJson(raw), _maxDetail),
        );
      default:
        return null;
    }
  }

  String _summarizeToolUse(String name, String rawInputJson) {
    Map<String, dynamic>? input;
    try {
      input = jsonDecode(rawInputJson) as Map<String, dynamic>?;
    } catch (_) {
      input = null;
    }

    String? field(String key) => input?[key] as String?;

    switch (name) {
      case 'Read':
      case 'Write':
        return '$name(${field('file_path') ?? '?'})';
      case 'Edit':
        return 'Edit(${field('file_path') ?? '?'})';
      case 'Bash':
        return 'Bash: ${_truncate(field('command') ?? '?', 120)}';
      case 'Grep':
        return "Grep '${field('pattern') ?? '?'}' in ${field('path') ?? '.'}";
      case 'Glob':
        return "Glob '${field('pattern') ?? '?'}'";
      case 'Task':
      case 'Agent':
        return '${field('subagent_type') ?? name}: '
            '${_truncate(field('description') ?? field('prompt') ?? '', 120)}';
      default:
        return input == null
            ? '$name(${_truncate(rawInputJson, 120)})'
            : '$name(${_truncate(jsonEncode(input), 120)})';
    }
  }

  List<LogItem> _handleToolResults(Map<String, dynamic>? message) {
    final content = message?['content'];
    if (content is! List) return const [];

    final items = <LogItem>[];
    for (final block in content) {
      if (block is! Map<String, dynamic> || block['type'] != 'tool_result') {
        continue;
      }
      final isError = block['is_error'] == true;
      final text = _stripNoise(_toolResultText(block['content']));
      items.add(
        LogItem(
          kind: LogKind.toolResult,
          content: _truncate(_collapseWhitespace(text), 200),
          toolUseId: block['tool_use_id'] as String?,
          detail: _truncate(text.trim(), _maxDetail),
          isError: isError,
        ),
      );
    }
    return items;
  }

  /// Raw tool result text (newlines kept, for [LogItem.detail]).
  String _toolResultText(Object? content) {
    if (content is String) return content;
    if (content is List) {
      return content
          .whereType<Map<String, dynamic>>()
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'] as String? ?? '')
          .join('\n');
    }
    return '';
  }

  LogItem _summarizeResult(Map<String, dynamic> event) {
    final subtype = event['subtype'] as String?;
    final isError = event['is_error'] == true || subtype != 'success';
    final durationMs = event['duration_ms'] as int?;
    final durationSuffix = durationMs == null
        ? ''
        : ' in ${(durationMs / 1000).toStringAsFixed(1)}s';

    if (!isError) {
      return LogItem(kind: LogKind.runFinished, content: 'Done$durationSuffix');
    }
    final errorText = event['result'] as String? ?? subtype ?? 'unknown error';
    return LogItem(
      kind: LogKind.runFinished,
      content: 'Failed$durationSuffix: ${_truncate(errorText, 200)}',
      isError: true,
    );
  }

  static const _maxDetail = 4000;

  String _prettyJson(String raw) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
    } catch (_) {
      return raw;
    }
  }

  String _collapseWhitespace(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  String _truncate(String text, int maxLength) =>
      text.length > maxLength ? '${text.substring(0, maxLength)}…' : text;
}

/// Claude Code's notes addressed to the model, not the developer (e.g. the
/// background-subagent receipt) — dropped from what's shown.
String _stripNoise(String text) {
  if (text.trimLeft().startsWith('Async agent launched successfully')) {
    return 'Subagent started in the background.';
  }
  return text
      .replaceAll(
        RegExp(r'\(This tool result is internal metadata[^)]*\)\s*'),
        '',
      )
      .replaceAll(RegExp(r'\[Subagent hand-back\][^\n]*\n?'), '');
}

/// One structured log item: what the dispatchers persist through
/// `TaskEndpoint.appendLogEntry`.
class LogItem {
  const LogItem({
    required this.kind,
    required this.content,
    this.toolName,
    this.toolUseId,
    this.detail,
    this.isError = false,
  });

  final LogKind kind;

  /// The short, display form.
  final String content;
  final String? toolName;
  final String? toolUseId;

  /// The longer form (full tool input/output), truncated.
  final String? detail;
  final bool isError;

  LogItem copyWith({String? content}) => LogItem(
    kind: kind,
    content: content ?? this.content,
    toolName: toolName,
    toolUseId: toolUseId,
    detail: detail,
    isError: isError,
  );

  /// The legacy one-line form, with the prefixes older panels parse.
  String get line => switch (kind) {
    LogKind.message => content,
    LogKind.thinking => '🤔 $content',
    LogKind.toolCall => '🔧 $content',
    LogKind.toolResult => '${isError ? '✗' : '✓'} $content',
    LogKind.runStarted => '▶ $content',
    LogKind.runFinished => '${isError ? '❌' : '✅'} $content',
  };
}

class _BlockBuffer {
  _BlockBuffer({required this.type, this.toolName, this.toolUseId});

  final String type;
  final String? toolName;
  final String? toolUseId;
  final StringBuffer text = StringBuffer();
}
