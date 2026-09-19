import 'dart:io';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:test/test.dart';

void main() {
  group('TaskDispatcher', () {
    late Directory tempDir;
    late Directory fixtureRepo;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('task_dispatcher_test_');
      fixtureRepo = Directory('${tempDir.path}/fixture_origin');
      await fixtureRepo.create();
      await _git(fixtureRepo.path, ['init', '-b', 'main']);
      await _git(fixtureRepo.path, [
        'config',
        'user.email',
        'test@example.com',
      ]);
      await _git(fixtureRepo.path, ['config', 'user.name', 'Test']);
      File('${fixtureRepo.path}/README.md').writeAsStringSync('hello\n');
      await _git(fixtureRepo.path, ['add', '.']);
      await _git(fixtureRepo.path, ['commit', '-m', 'initial']);
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    String writeFakeClaude(String body) {
      final script = File('${tempDir.path}/fake_claude.sh');
      script.writeAsStringSync('#!/bin/sh\n$body\n');
      Process.runSync('chmod', ['+x', script.path]);
      return script.path;
    }

    Task buildTask({bool skipPlanning = true}) => Task(
      id: 1,
      projectId: 1,
      agentId: 1,
      prompt: 'Do something',
      skipPlanning: skipPlanning,
      status: TaskStatus.queued,
    );

    Agent buildAgent() => Agent(
      id: 1,
      machineId: 1,
      name: 'Ana',
      role: AgentRole.backend,
      status: AgentStatus.idle,
    );

    test(
      'a skipPlanning task runs to completion and reports success',
      () async {
        final claudeScript = writeFakeClaude('''
echo '{"type":"result","subtype":"success","session_id":"sess-1"}'
exit 0
''');
        final logLines = <String>[];
        final taskUpdates = <Task>[];
        final agentUpdates = <Agent>[];
        final messages = <String>[];

        final dispatcher = TaskDispatcher(
          worktreeManager: WorktreeManager(
            workspaceRoot: '${tempDir.path}/workspace',
          ),
          executorFactory: () => ClaudeCodeExecutor(executable: claudeScript),
          oauthToken: null,
          getCloneUrl: (projectId) async => fixtureRepo.path,
          fetchAgent: (agentId) async => buildAgent(),
          updateTask: (task) async => taskUpdates.add(task),
          updateAgent: (agent) async => agentUpdates.add(agent),
          appendLog: (taskId, content) async => logLines.add(content),
          log: messages.add,
        );

        await dispatcher.handle(buildTask());

        expect(logLines, contains(contains('"session_id":"sess-1"')));
        expect(agentUpdates.map((a) => a.status), [
          AgentStatus.busy,
          AgentStatus.idle,
        ]);
        expect(taskUpdates.map((t) => t.status), [
          TaskStatus.running,
          TaskStatus.awaitingReview,
        ]);
        expect(taskUpdates.last.claudeSessionId, 'sess-1');
      },
    );

    test('a failing execution marks the task failed with a reason', () async {
      final claudeScript = writeFakeClaude('exit 1');
      final taskUpdates = <Task>[];
      final agentUpdates = <Agent>[];

      final dispatcher = TaskDispatcher(
        worktreeManager: WorktreeManager(
          workspaceRoot: '${tempDir.path}/workspace',
        ),
        executorFactory: () => ClaudeCodeExecutor(executable: claudeScript),
        oauthToken: null,
        getCloneUrl: (projectId) async => fixtureRepo.path,
        fetchAgent: (agentId) async => buildAgent(),
        updateTask: (task) async => taskUpdates.add(task),
        updateAgent: (agent) async => agentUpdates.add(agent),
        appendLog: (taskId, content) async {},
        log: (_) {},
      );

      await dispatcher.handle(buildTask());

      expect(taskUpdates.last.status, TaskStatus.failed);
      expect(taskUpdates.last.failureReason, isNotNull);
      expect(agentUpdates.last.status, AgentStatus.idle);
    });

    test('a task that has not skipped planning is left untouched', () async {
      final taskUpdates = <Task>[];
      final messages = <String>[];

      final dispatcher = TaskDispatcher(
        worktreeManager: WorktreeManager(
          workspaceRoot: '${tempDir.path}/workspace',
        ),
        executorFactory: ClaudeCodeExecutor.new,
        oauthToken: null,
        getCloneUrl: (projectId) async =>
            throw StateError('should not be called'),
        fetchAgent: (agentId) async => throw StateError('should not be called'),
        updateTask: (task) async => taskUpdates.add(task),
        updateAgent: (agent) async {},
        appendLog: (taskId, content) async {},
        log: messages.add,
      );

      await dispatcher.handle(buildTask(skipPlanning: false));

      expect(taskUpdates, isEmpty);
      expect(messages, contains(contains('planning phase not implemented')));
    });
  });
}

Future<void> _git(String cwd, List<String> args) async {
  final result = await Process.run('git', args, workingDirectory: cwd);
  if (result.exitCode != 0) {
    throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
  }
}
