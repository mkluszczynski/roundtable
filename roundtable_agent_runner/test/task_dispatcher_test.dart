import 'dart:async';
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

    test('a skipPlanning task that produces changes commits, pushes, opens a '
        'PR, and reports success', () async {
      final claudeScript = writeFakeClaude('''
echo "changed" > changed.txt
echo '{"type":"result","subtype":"success","session_id":"sess-1"}'
exit 0
''');
      final logLines = <String>[];
      final taskUpdates = <Task>[];
      final agentUpdates = <Agent>[];
      final messages = <String>[];
      final prRequests = <Map<String, String?>>[];

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
        fetchLatestFeedback: (_) async => null,
        openPullRequest:
            ({
              required cloneUrl,
              required branchName,
              required title,
              body,
            }) async {
              prRequests.add({
                'cloneUrl': cloneUrl,
                'branchName': branchName,
                'title': title,
                'body': body,
              });
              return 'https://github.com/acme/widgets/pull/1';
            },
        watchTask: (_) => const Stream<Task>.empty(),
        log: messages.add,
        serverUrl: 'https://server.example',
        permissionPromptToolCommand: const ['echo'],
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
      expect(taskUpdates.last.branchName, 'task-1');
      expect(taskUpdates.last.prUrl, 'https://github.com/acme/widgets/pull/1');
      expect(prRequests, hasLength(1));
      expect(prRequests.single['branchName'], 'task-1');
    });

    test('a skipPlanning task that produces no changes reaches awaitingReview '
        'without opening a PR', () async {
      final claudeScript = writeFakeClaude('''
echo '{"type":"result","subtype":"success","session_id":"sess-1"}'
exit 0
''');
      final taskUpdates = <Task>[];
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
        updateAgent: (agent) async {},
        appendLog: (taskId, content) async {},
        fetchLatestFeedback: (_) async => null,
        openPullRequest:
            ({
              required cloneUrl,
              required branchName,
              required title,
              body,
            }) async => throw StateError('should not be called'),
        watchTask: (_) => const Stream<Task>.empty(),
        log: messages.add,
        serverUrl: 'https://server.example',
        permissionPromptToolCommand: const ['echo'],
      );

      await dispatcher.handle(buildTask());

      expect(taskUpdates.last.status, TaskStatus.awaitingReview);
      expect(taskUpdates.last.branchName, isNull);
      expect(taskUpdates.last.prUrl, isNull);
      expect(messages, contains(contains('no changes to commit')));
    });

    test(
      'a PR-opening failure after a successful run marks the task failed',
      () async {
        final claudeScript = writeFakeClaude('''
echo "changed" > changed.txt
echo '{"type":"result","subtype":"success","session_id":"sess-1"}'
exit 0
''');
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
          fetchLatestFeedback: (_) async => null,
          openPullRequest:
              ({
                required cloneUrl,
                required branchName,
                required title,
                body,
              }) async => throw StateError('GitHub API unreachable'),
          watchTask: (_) => const Stream<Task>.empty(),
          log: (_) {},
          serverUrl: 'https://server.example',
          permissionPromptToolCommand: const ['echo'],
        );

        await dispatcher.handle(buildTask());

        expect(taskUpdates.last.status, TaskStatus.failed);
        expect(
          taskUpdates.last.failureReason,
          contains('GitHub API unreachable'),
        );
        expect(agentUpdates.last.status, AgentStatus.idle);
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
        fetchLatestFeedback: (_) async => null,
        openPullRequest:
            ({
              required cloneUrl,
              required branchName,
              required title,
              body,
            }) async => throw StateError('should not be called'),
        watchTask: (_) => const Stream<Task>.empty(),
        log: (_) {},
        serverUrl: 'https://server.example',
        permissionPromptToolCommand: const ['echo'],
      );

      await dispatcher.handle(buildTask());

      expect(taskUpdates.last.status, TaskStatus.failed);
      expect(taskUpdates.last.failureReason, isNotNull);
      expect(agentUpdates.last.status, AgentStatus.idle);
    });

    test('a task cancelled mid-run is SIGTERM-ed, has its worktree reset, and '
        'is marked cancelled without opening a PR', () async {
      final startedFile = File('${tempDir.path}/started');
      final terminatedFile = File('${tempDir.path}/terminated');
      final claudeScript = writeFakeClaude('''
trap 'touch "${terminatedFile.path}"; exit 143' TERM
echo "partial change" > changed.txt
touch "${startedFile.path}"
while true; do sleep 0.05; done
''');
      final taskUpdates = <Task>[];
      final agentUpdates = <Agent>[];
      final watchTaskController = StreamController<Task>();

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
        fetchLatestFeedback: (_) async => null,
        openPullRequest:
            ({
              required cloneUrl,
              required branchName,
              required title,
              body,
            }) async => throw StateError('should not be called'),
        watchTask: (_) => watchTaskController.stream,
        log: (_) {},
        serverUrl: 'https://server.example',
        permissionPromptToolCommand: const ['echo'],
      );

      final handleFuture = dispatcher.handle(buildTask());

      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!startedFile.existsSync()) {
        if (DateTime.now().isAfter(deadline)) {
          fail('fake claude script never started');
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      watchTaskController.add(
        buildTask().copyWith(status: TaskStatus.cancelled),
      );

      await handleFuture;
      await watchTaskController.close();

      expect(
        terminatedFile.existsSync(),
        isTrue,
        reason: 'SIGTERM should have reached the subprocess',
      );
      expect(
        File(
          '${tempDir.path}/workspace/1/worktrees/1/changed.txt',
        ).existsSync(),
        isFalse,
        reason: 'the worktree should have been reset',
      );
      expect(taskUpdates.last.status, TaskStatus.cancelled);
      expect(taskUpdates.last.finishedAt, isNotNull);
      expect(taskUpdates.last.branchName, isNull);
      expect(taskUpdates.last.prUrl, isNull);
      expect(agentUpdates.last.status, AgentStatus.idle);
    });

    test(
      'a fresh non-skipPlanning task runs the planning-phase invocation with '
      '--permission-mode plan and --mcp-config wired to the permission-prompt-tool',
      () async {
        final argsFile = File('${tempDir.path}/claude_args');
        final claudeScript = writeFakeClaude('''
echo "\$@" > "${argsFile.path}"
echo "changed" > changed.txt
echo '{"type":"result","subtype":"success","session_id":"sess-plan-1"}'
exit 0
''');
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
          fetchLatestFeedback: (_) async => null,
          openPullRequest:
              ({
                required cloneUrl,
                required branchName,
                required title,
                body,
              }) async => 'https://github.com/acme/widgets/pull/1',
          watchTask: (_) => const Stream<Task>.empty(),
          log: (_) {},
          serverUrl: 'https://server.example',
          permissionPromptToolCommand: const ['echo'],
        );

        await dispatcher.handle(buildTask(skipPlanning: false));

        final claudeArgs = argsFile.readAsStringSync();
        expect(claudeArgs, contains('--permission-mode plan'));
        expect(claudeArgs, contains('--mcp-config'));
        expect(claudeArgs, contains('--strict-mcp-config'));
        expect(
          claudeArgs,
          contains(
            '--permission-prompt-tool mcp__roundtable-permission__approval_prompt',
          ),
        );
        expect(taskUpdates.map((t) => t.status), [
          TaskStatus.planning,
          TaskStatus.awaitingReview,
        ]);
        expect(taskUpdates.last.claudeSessionId, 'sess-plan-1');
        expect(agentUpdates.map((a) => a.status), [
          AgentStatus.busy,
          AgentStatus.idle,
        ]);
      },
    );

    test('a planning-phase task moving through waitingForAnswer and back to '
        'planning mirrors those transitions onto Agent.status', () async {
      final startedFile = File('${tempDir.path}/started');
      final claudeScript = writeFakeClaude('''
touch "${startedFile.path}"
while [ ! -f "${tempDir.path}/release" ]; do sleep 0.05; done
echo '{"type":"result","subtype":"success","session_id":"sess-plan-2"}'
exit 0
''');
      final agentUpdates = <Agent>[];
      final watchTaskController = StreamController<Task>();

      final dispatcher = TaskDispatcher(
        worktreeManager: WorktreeManager(
          workspaceRoot: '${tempDir.path}/workspace',
        ),
        executorFactory: () => ClaudeCodeExecutor(executable: claudeScript),
        oauthToken: null,
        getCloneUrl: (projectId) async => fixtureRepo.path,
        fetchAgent: (agentId) async => buildAgent(),
        updateTask: (task) async {},
        updateAgent: (agent) async => agentUpdates.add(agent),
        appendLog: (taskId, content) async {},
        fetchLatestFeedback: (_) async => null,
        openPullRequest:
            ({
              required cloneUrl,
              required branchName,
              required title,
              body,
            }) async => throw StateError('should not be called'),
        watchTask: (_) => watchTaskController.stream,
        log: (_) {},
        serverUrl: 'https://server.example',
        permissionPromptToolCommand: const ['echo'],
      );

      final handleFuture = dispatcher.handle(buildTask(skipPlanning: false));

      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!startedFile.existsSync()) {
        if (DateTime.now().isAfter(deadline)) {
          fail('fake claude script never started');
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      watchTaskController.add(
        buildTask(
          skipPlanning: false,
        ).copyWith(status: TaskStatus.waitingForAnswer),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      watchTaskController.add(
        buildTask(skipPlanning: false).copyWith(status: TaskStatus.planning),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      File('${tempDir.path}/release').writeAsStringSync('');
      await handleFuture;
      await watchTaskController.close();

      expect(agentUpdates.map((a) => a.status), [
        AgentStatus.busy,
        AgentStatus.waitingForResponse,
        AgentStatus.busy,
        AgentStatus.idle,
      ]);
    });

    test('a failing planning-phase invocation marks the task failed without '
        'attempting to commit or open a PR', () async {
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
        fetchLatestFeedback: (_) async => null,
        openPullRequest:
            ({
              required cloneUrl,
              required branchName,
              required title,
              body,
            }) async => throw StateError('should not be called'),
        watchTask: (_) => const Stream<Task>.empty(),
        log: (_) {},
        serverUrl: 'https://server.example',
        permissionPromptToolCommand: const ['echo'],
      );

      await dispatcher.handle(buildTask(skipPlanning: false));

      expect(taskUpdates.map((t) => t.status), [
        TaskStatus.planning,
        TaskStatus.failed,
      ]);
      expect(taskUpdates.last.failureReason, isNotNull);
      expect(agentUpdates.last.status, AgentStatus.idle);
    });

    test(
      'an awaitingReview task with fresh review feedback resumes via '
      '--resume with the feedback message as the prompt, reuses the '
      'worktree, and pushes to the existing PR without opening a new one',
      () async {
        final claudeScript = writeFakeClaude('''
echo "\$@" > "${tempDir.path}/claude_args"
echo "more changes" > changed2.txt
echo '{"type":"result","subtype":"success","session_id":"sess-1"}'
exit 0
''');
        final taskUpdates = <Task>[];
        final prRequests = <Map<String, String?>>[];
        final messages = <String>[];

        final resumingTask = buildTask().copyWith(
          status: TaskStatus.awaitingReview,
          claudeSessionId: 'sess-1',
          branchName: 'task-1',
          prUrl: 'https://github.com/acme/widgets/pull/1',
          startedAt: DateTime.utc(2026),
          finishedAt: DateTime.utc(2026, 1, 2),
        );
        final feedback = TaskFeedback(
          taskId: 1,
          message: 'Please also update the README',
          phase: TaskFeedbackPhase.review,
          createdAt: DateTime.utc(2026, 1, 3),
        );

        final dispatcher = TaskDispatcher(
          worktreeManager: WorktreeManager(
            workspaceRoot: '${tempDir.path}/workspace',
          ),
          executorFactory: () => ClaudeCodeExecutor(executable: claudeScript),
          oauthToken: null,
          getCloneUrl: (projectId) async => fixtureRepo.path,
          fetchAgent: (agentId) async => buildAgent(),
          updateTask: (task) async => taskUpdates.add(task),
          updateAgent: (agent) async {},
          appendLog: (taskId, content) async {},
          fetchLatestFeedback: (_) async => feedback,
          openPullRequest:
              ({
                required cloneUrl,
                required branchName,
                required title,
                body,
              }) async {
                prRequests.add({'branchName': branchName});
                return 'https://github.com/acme/widgets/pull/999';
              },
          watchTask: (_) => const Stream<Task>.empty(),
          log: messages.add,
          serverUrl: 'https://server.example',
          permissionPromptToolCommand: const ['echo'],
        );

        // The worktree from the original run must already exist for the
        // resumed run to reuse (createWorktree is idempotent, but the
        // bare clone/branch need to already exist to model a real resume).
        final seedWorktreeManager = WorktreeManager(
          workspaceRoot: '${tempDir.path}/workspace',
        );
        await seedWorktreeManager.ensureProjectCloned(
          projectId: '1',
          cloneUrl: fixtureRepo.path,
        );
        await seedWorktreeManager.createWorktree(projectId: '1', taskId: '1');

        await dispatcher.handle(resumingTask);

        final claudeArgs = File(
          '${tempDir.path}/claude_args',
        ).readAsStringSync();
        expect(claudeArgs, contains('Please also update the README'));
        expect(claudeArgs, contains('--resume'));
        expect(claudeArgs, contains('sess-1'));
        expect(taskUpdates.last.status, TaskStatus.awaitingReview);
        expect(taskUpdates.last.startedAt, resumingTask.startedAt);
        expect(
          taskUpdates.last.prUrl,
          'https://github.com/acme/widgets/pull/1',
        );
        expect(prRequests, isEmpty);
        expect(messages, contains(contains('pushed additional commits')));
      },
    );

    test(
      'an awaitingReview task with no new review feedback is left untouched',
      () async {
        final taskUpdates = <Task>[];
        final messages = <String>[];

        final task = buildTask().copyWith(
          status: TaskStatus.awaitingReview,
          claudeSessionId: 'sess-1',
          finishedAt: DateTime.utc(2026, 1, 2),
        );

        final dispatcher = TaskDispatcher(
          worktreeManager: WorktreeManager(
            workspaceRoot: '${tempDir.path}/workspace',
          ),
          executorFactory: ClaudeCodeExecutor.new,
          oauthToken: null,
          getCloneUrl: (projectId) async =>
              throw StateError('should not be called'),
          fetchAgent: (agentId) async =>
              throw StateError('should not be called'),
          updateTask: (task) async => taskUpdates.add(task),
          updateAgent: (agent) async {},
          appendLog: (taskId, content) async {},
          fetchLatestFeedback: (_) async => TaskFeedback(
            taskId: 1,
            message: 'stale, already consumed',
            phase: TaskFeedbackPhase.review,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          openPullRequest:
              ({
                required cloneUrl,
                required branchName,
                required title,
                body,
              }) async => throw StateError('should not be called'),
          watchTask: (_) => const Stream<Task>.empty(),
          log: messages.add,
          serverUrl: 'https://server.example',
          permissionPromptToolCommand: const ['echo'],
        );

        await dispatcher.handle(task);

        expect(taskUpdates, isEmpty);
        expect(messages, contains(contains('no new review feedback pending')));
      },
    );
  });
}

Future<void> _git(String cwd, List<String> args) async {
  final result = await Process.run('git', args, workingDirectory: cwd);
  if (result.exitCode != 0) {
    throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
  }
}
