import 'package:roundtable_client/roundtable_client.dart';

/// Reads a [TaskLogEntry]'s kind and display text the same way for
/// structured entries (`kind` set by newer runners) and older ones, whose
/// kind is only encoded as a prefix on `content` (🔧 ✓ ✗ ✅ ❌ 🤔 ▶).
extension TaskLogEntryKind on TaskLogEntry {
  static const _prefixes = <(String, LogKind, bool)>[
    ('🔧 ', LogKind.toolCall, false),
    ('✓ ', LogKind.toolResult, false),
    ('✗ ', LogKind.toolResult, true),
    ('✅', LogKind.runFinished, false),
    ('❌', LogKind.runFinished, true),
    ('🤔 ', LogKind.thinking, false),
    ('▶ ', LogKind.runStarted, false),
    ('• ', LogKind.event, false),
  ];

  (String, LogKind, bool)? get _legacyPrefix {
    if (kind != null) return null;
    for (final prefix in _prefixes) {
      if (content.startsWith(prefix.$1)) return prefix;
    }
    return null;
  }

  /// The entry's kind; a legacy line without a prefix is the agent talking.
  LogKind get effectiveKind => kind ?? _legacyPrefix?.$2 ?? LogKind.message;

  bool get failed => isError ?? _legacyPrefix?.$3 ?? false;

  /// [content] without a legacy prefix.
  String get text {
    final prefix = _legacyPrefix;
    if (prefix == null) return content;
    return content.substring(prefix.$1.length).trimLeft();
  }

  bool get isToolActivity =>
      effectiveKind == LogKind.toolCall || effectiveKind == LogKind.toolResult;
}
