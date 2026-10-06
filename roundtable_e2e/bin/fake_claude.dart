/// A scripted stand-in for the `claude` CLI in E2E tests (docs/DEVELOPMENT.md
/// "E2E tests"): speaks the same stream-json output and, in plan mode, the
/// same MCP calls to Roundtable's permission prompt tool, but its plans,
/// edits and reviews come from a scenario file instead of a model.
///
/// Environment:
/// - `FAKE_CLAUDE_SCENARIO`: JSON file, see [Scenario].
/// - `FAKE_CLAUDE_STATE`: directory for counters and the invocation log
///   (`invocations.jsonl`, one `{"args": [...], "cwd": ...}` per run).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  // The runner's health check of its claude executable.
  if (args.contains('--version')) {
    stdout.writeln('0.0.0 (fake claude)');
    return;
  }
  final state = Directory(Platform.environment['FAKE_CLAUDE_STATE']!);
  await state.create(recursive: true);
  await File('${state.path}/invocations.jsonl').writeAsString(
    '${jsonEncode({'args': args, 'cwd': Directory.current.path, 'pid': pid, 'start': _now()})}\n',
    mode: FileMode.append,
  );
  final scenario = Scenario(
    jsonDecode(
          await File(
            Platform.environment['FAKE_CLAUDE_SCENARIO']!,
          ).readAsString(),
        )
        as Map<String, dynamic>,
  );
  final prompt = _option(args, '-p') ?? '';
  final session = _option(args, '--resume') ?? 'fake-session-${_pid()}';
  _emit({'type': 'system', 'subtype': 'init', 'session_id': session});

  try {
    final String result;
    if (_option(args, '--allowedTools')?.startsWith('Read,Grep,Glob') ??
        false) {
      result = await _review(scenario, state, prompt);
    } else if (_option(args, '--permission-mode') == 'plan') {
      result = await _planThenExecute(scenario, state, args);
    } else {
      result = await _execute(scenario, state);
    }
    _say(result);
    _emit({
      'type': 'result',
      'subtype': 'success',
      'session_id': session,
      'result': result,
    });
    await _logEnd(state);
    exit(0);
  } on _Denied catch (e) {
    _emit({
      'type': 'result',
      'subtype': 'error_during_execution',
      'is_error': true,
      'session_id': session,
      'result': e.message,
    });
    await _logEnd(state);
    exit(1);
  }
}

/// What the fake agent does, in order:
/// - `plan` (String): the plan proposed in plan mode.
/// - `title` (String?): set through `set_task_title` when offered.
/// - `runs` (List): one per planning/execution/feedback run — `files`
///   (path → content written in the worktree), `result` (final message)
///   and `sleepMs` (how long the run takes).
/// - `reviews` (List): one per review run — `verdict`, `summary`,
///   `comments` (as the reviewer JSON) and `fixPrevious` (mark every earlier
///   comment listed in the prompt as fixed).
class Scenario {
  Scenario(this.json);

  final Map<String, dynamic> json;

  String get plan => json['plan'] as String? ?? '1. Make the change.';
  String? get title => json['title'] as String?;
  List<dynamic> get runs => json['runs'] as List? ?? const [];
  List<dynamic> get reviews => json['reviews'] as List? ?? const [];
}

class _Denied implements Exception {
  _Denied(this.message);
  final String message;
}

Future<String> _planThenExecute(
  Scenario scenario,
  Directory state,
  List<String> args,
) async {
  final config =
      jsonDecode(await File(_option(args, '--mcp-config')!).readAsString())
          as Map<String, dynamic>;
  final server =
      (config['mcpServers'] as Map).values.first as Map<String, dynamic>;
  final mcp = await _Mcp.start(
    server['command'] as String,
    (server['args'] as List).cast<String>(),
    (server['env'] as Map?)?.cast<String, String>() ?? const {},
  );
  try {
    final tools = await mcp.call('tools/list', {});
    final names = [
      for (final t in (tools['tools'] as List)) (t as Map)['name'] as String,
    ];
    final title = scenario.title;
    if (title != null && names.contains('set_task_title')) {
      await mcp.call('tools/call', {
        'name': 'set_task_title',
        'arguments': {'title': title},
      });
    }
    var plan = scenario.plan;
    for (var attempt = 0; attempt < 5; attempt++) {
      _say('Proposing the plan.');
      final response = await mcp.call('tools/call', {
        'name': 'approval_prompt',
        'arguments': {
          'tool_name': 'ExitPlanMode',
          'input': {'plan': plan},
        },
      });
      final text =
          ((response['content'] as List).first as Map)['text'] as String;
      final decision = jsonDecode(text) as Map<String, dynamic>;
      if (decision['behavior'] == 'allow') {
        return await _execute(scenario, state);
      }
      plan = '$plan\n\nRevised after feedback: ${decision['message']}';
    }
    throw _Denied('The plan was rejected too many times.');
  } finally {
    mcp.close();
  }
}

/// Writes the next run's files into the worktree (the current directory).
Future<String> _execute(Scenario scenario, Directory state) async {
  final index = await _next(state, 'runs');
  if (index >= scenario.runs.length) {
    return 'Nothing left to change.';
  }
  final run = scenario.runs[index] as Map<String, dynamic>;
  final sleep = run['sleepMs'] as int?;
  if (sleep != null) await Future<void>.delayed(Duration(milliseconds: sleep));
  final files = (run['files'] as Map?)?.cast<String, String>() ?? const {};
  for (final MapEntry(key: path, value: content) in files.entries) {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    _emit({
      'type': 'assistant',
      'message': {
        'content': [
          {
            'type': 'tool_use',
            'id': 'tool-$path',
            'name': 'Write',
            'input': {'file_path': path},
          },
        ],
      },
    });
  }
  return run['result'] as String? ?? 'Done.';
}

Future<String> _review(
  Scenario scenario,
  Directory state,
  String prompt,
) async {
  final index = await _next(state, 'reviews');
  final review = index < scenario.reviews.length
      ? scenario.reviews[index] as Map<String, dynamic>
      : <String, dynamic>{'verdict': 'approve', 'summary': 'Looks good.'};
  final previous = [
    if (review['fixPrevious'] == true)
      for (final match in RegExp(
        r'^- id (\d+) ·',
        multiLine: true,
      ).allMatches(prompt))
        {'id': int.parse(match.group(1)!), 'fixed': true, 'note': null},
  ];
  final verdict = {
    'verdict': review['verdict'] ?? 'approve',
    'summary': review['summary'] ?? 'Reviewed.',
    'comments': review['comments'] ?? const [],
    'previous': previous,
  };
  return 'Review done.\n\n```json\n${jsonEncode(verdict)}\n```';
}

/// Returns and bumps the counter [name] in [state].
Future<int> _next(Directory state, String name) async {
  final file = File('${state.path}/$name.count');
  final current = await file.exists()
      ? int.parse((await file.readAsString()).trim())
      : 0;
  await file.writeAsString('${current + 1}');
  return current;
}

void _say(String text) => _emit({
  'type': 'assistant',
  'message': {
    'content': [
      {'type': 'text', 'text': text},
    ],
  },
});

void _emit(Map<String, Object?> event) => stdout.writeln(jsonEncode(event));

String? _option(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

int _pid() => pid;

int _now() => DateTime.now().millisecondsSinceEpoch;

Future<void> _logEnd(Directory state) =>
    File('${state.path}/ends.jsonl').writeAsString(
      '${jsonEncode({'pid': pid, 'end': _now()})}\n',
      mode: FileMode.append,
    );

/// A minimal MCP client over the server's stdio (JSON-RPC, one per line).
class _Mcp {
  _Mcp._(this._process) {
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.trim().isEmpty) return;
          final message = jsonDecode(line) as Map<String, dynamic>;
          final id = message['id'];
          final pending = _pending.remove(id);
          if (pending == null) return;
          if (message['error'] != null) {
            pending.completeError(StateError('${message['error']}'));
          } else {
            pending.complete(
              (message['result'] as Map?)?.cast<String, dynamic>() ?? {},
            );
          }
        });
    _process.stderr.listen(stderr.add);
  }

  final Process _process;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  var _nextId = 1;

  static Future<_Mcp> start(
    String command,
    List<String> args,
    Map<String, String> env,
  ) async {
    final mcp = _Mcp._(await Process.start(command, args, environment: env));
    await mcp.call('initialize', {
      'protocolVersion': '2025-06-18',
      'capabilities': {},
      'clientInfo': {'name': 'fake-claude', 'version': '0'},
    });
    mcp._process.stdin.writeln(
      jsonEncode({'jsonrpc': '2.0', 'method': 'notifications/initialized'}),
    );
    return mcp;
  }

  Future<Map<String, dynamic>> call(
    String method,
    Map<String, Object?> params,
  ) {
    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _process.stdin.writeln(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      }),
    );
    return completer.future;
  }

  void close() => _process.kill();
}
