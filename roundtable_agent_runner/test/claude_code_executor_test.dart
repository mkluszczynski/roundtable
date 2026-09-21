import 'dart:io';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  group('ClaudeCodeExecutor', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'claude_code_executor_test_',
      );
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    String writeFakeClaude(String body) {
      final script = File('${tempDir.path}/fake_claude.sh');
      script.writeAsStringSync('#!/bin/sh\n$body\n');
      Process.runSync('chmod', ['+x', script.path]);
      return script.path;
    }

    test(
      'forwards every NDJSON line and reports success with the session id',
      () async {
        final script = writeFakeClaude('''
echo '{"type":"system","subtype":"init"}'
echo '{"type":"assistant","message":{"content":[{"type":"text","text":"hi"}]}}'
echo '{"type":"result","subtype":"success","session_id":"abc123"}'
exit 0
''');
        final executor = ClaudeCodeExecutor(executable: script);
        final lines = <String>[];

        final result = await executor.run(
          prompt: 'do the thing',
          workingDirectory: tempDir.path,
          onLine: lines.add,
        );

        expect(lines, hasLength(3));
        expect(lines.last, contains('"session_id":"abc123"'));
        expect(result.success, isTrue);
        expect(result.exitCode, 0);
        expect(result.sessionId, 'abc123');
        expect(result.errorSummary, isNull);
      },
    );

    test(
      'reports failure and an error summary when the result subtype is not success',
      () async {
        final script = writeFakeClaude('''
echo '{"type":"result","subtype":"error_max_turns","session_id":"abc123"}'
echo 'something went wrong' >&2
exit 0
''');
        final executor = ClaudeCodeExecutor(executable: script);

        final result = await executor.run(
          prompt: 'do the thing',
          workingDirectory: tempDir.path,
          onLine: (_) {},
        );

        expect(result.success, isFalse);
        expect(result.sessionId, 'abc123');
        expect(result.errorSummary, contains('something went wrong'));
      },
    );

    test(
      'reports failure with a fallback summary when the process exits non-zero with no stderr',
      () async {
        final script = writeFakeClaude('exit 1');
        final executor = ClaudeCodeExecutor(executable: script);

        final result = await executor.run(
          prompt: 'do the thing',
          workingDirectory: tempDir.path,
          onLine: (_) {},
        );

        expect(result.success, isFalse);
        expect(result.exitCode, 1);
        expect(result.errorSummary, contains('exited with code 1'));
      },
    );

    test(
      'passes an empty prompt and --resume when resuming a session',
      () async {
        final script = writeFakeClaude(r'''
echo "{\"args\":\"$*\"}"
exit 0
''');
        final executor = ClaudeCodeExecutor(executable: script);
        final lines = <String>[];

        await executor.run(
          prompt: 'ignored when resuming',
          workingDirectory: tempDir.path,
          resumeSessionId: 'session-1',
          onLine: lines.add,
        );

        expect(lines.single, contains('--resume session-1'));
        expect(lines.single, isNot(contains('ignored when resuming')));
      },
    );

    test('calls onProcessStarted once with the live process', () async {
      final script = writeFakeClaude('exit 0');
      final executor = ClaudeCodeExecutor(executable: script);
      final started = <Process>[];

      await executor.run(
        prompt: 'do the thing',
        workingDirectory: tempDir.path,
        onLine: (_) {},
        onProcessStarted: started.add,
      );

      expect(started, hasLength(1));
      expect(started.single.pid, greaterThan(0));
    });
  });
}
