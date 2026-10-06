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
      roleId: 7,
      role: AgentRoleDefinition(
        id: 7,
        name: 'backend',
        prompt: 'You are {name}, the backend specialist.',
      ),
      status: AgentStatus.idle,
    );

    TaskDispatcher dispatcherFor(
      String claudeScript, {
      required List<Task> taskUpdates,
      List<String>? messages,
      List<TaskLogEntry>? logEntries,
      ToolchainInstaller? installer,
      List<ProjectTool> tools = const [],
      Agent? agent,
      ContainerSandbox Function(ContainerRequest request)? sandboxFor,
      String? dockerImage,
    }) => TaskDispatcher(
      worktreeManager: WorktreeManager(
        workspaceRoot: '${tempDir.path}/workspace',
      ),
      executorFactory: () => ClaudeCodeExecutor(executable: claudeScript),
      oauthToken: null,
      getCloneUrl: (projectId) async => fixtureRepo.path,
      fetchAgent: (agentId) async => agent ?? buildAgent(),
      updateTask: (task) async => taskUpdates.add(task),
      updateAgent: (agent) async {},
      appendLog: (entry) async => logEntries?.add(entry),
      fetchLatestFeedback: (_) async => null,
      openPullRequest:
          ({
            required cloneUrl,
            required branchName,
            required title,
            body,
          }) async => 'https://github.com/example/repo/pull/1',
      watchTask: (_) => const Stream<Task>.empty(),
      log: messages?.add ?? (_) {},
      serverUrl: 'https://server.example',
      permissionPromptToolCommand: const ['echo'],
      fetchProject: (_) async => Project(
        name: 'p',
        repoUrl: 'https://github.com/a/b',
        tools: tools,
        dockerImage: dockerImage,
      ),
      sandboxFor: sandboxFor,
      environmentPrompt: ({container = false}) =>
          container ? 'ENV(container)' : 'ENV(native)',
      toolchainInstaller: installer,
    );

    /// A fake `mise` under a fresh home: `ls --missing` reports [missing]
    /// until `install` runs, `env` puts a toolchain dir first on PATH.
    ToolchainInstaller fakeMise({String missing = '{}', bool fail = false}) {
      final home = '${tempDir.path}/home';
      Directory('$home/.local/bin').createSync(recursive: true);
      final mise = File('$home/.local/bin/mise');
      mise.writeAsStringSync('''#!/bin/sh
case "\$1" in
  ls) if [ -f installed ]; then echo '{}'; else echo '$missing'; fi ;;
  install) ${fail ? 'echo "download failed" >&2; exit 1' : 'touch installed'} ;;
  env) echo '{"PATH": "/opt/fake-flutter/bin:/usr/bin:/bin"}' ;;
esac
''');
      Process.runSync('chmod', ['+x', mise.path]);
      return ToolchainInstaller(home: home);
    }

    group('task title', () {
      Future<String> argsFor(Task task) async {
        final outFile = '${tempDir.path}/out.txt';
        final claudeScript = writeFakeClaude('''
echo "\$@" > $outFile
echo "x" > x.txt
echo '{"type":"result","subtype":"success","session_id":"s"}'
''');
        await dispatcherFor(claudeScript, taskUpdates: []).handle(task);
        return File(outFile).readAsStringSync();
      }

      test('an untitled task asks the agent to name it', () async {
        final out = await argsFor(buildTask());
        expect(out, contains('# Task title'));
        expect(out, contains('mcp__roundtable-permission__set_task_title'));
      });

      test('a titled task does not', () async {
        final out = await argsFor(buildTask().copyWith(title: 'Named'));
        expect(out, isNot(contains('# Task title')));
      });
    });

    group('a docker-mode agent', () {
      Agent dockerAgent() =>
          buildAgent().copyWith(executionMode: AgentExecutionMode.docker);

      test(
        'runs claude through podman in its container, with the server '
        'URL rewritten for the MCP tool and a container system prompt',
        () async {
          final podmanArgs = '${tempDir.path}/podman-args.txt';
          final claudeArgs = '${tempDir.path}/claude-args.txt';
          final claudeScript = writeFakeClaude('''
echo "\$@" > $claudeArgs
for a in "\$@"; do case "\$a" in *mcp-config.json) cat "\$a" >> $claudeArgs ;; esac; done
echo "x" > x.txt
echo '{"type":"result","subtype":"success","session_id":"s"}'
''');
          // A fake podman: records its arguments, then runs what follows the
          // image (claude and its args) directly.
          final podman = File('${tempDir.path}/podman')
            ..writeAsStringSync('''#!/bin/sh
echo "\$@" >> $podmanArgs
[ "\$3" = "rm" ] && exit 0
while [ "\$1" != "my/image:1" ]; do shift; done
shift
exec "\$@"
''');
          Process.runSync('chmod', ['+x', podman.path]);
          ContainerRequest? request;
          final taskUpdates = <Task>[];

          await dispatcherFor(
            claudeScript,
            taskUpdates: taskUpdates,
            agent: dockerAgent(),
            dockerImage: 'my/image:1',
            sandboxFor: (r) {
              request = r;
              return ContainerSandbox(
                image: r.image!,
                name: 'roundtable-task-${r.taskId}',
                workingDirectory: r.worktreePath,
                mounts: [(path: r.worktreePath, readOnly: false)],
                home: '${tempDir.path}/chome',
                claudePath: claudeScript,
                podman: podman.path,
              );
            },
          ).handle(buildTask());

          expect(request!.projectId, 1);
          expect(request!.readOnlyDirectories, hasLength(1));
          final podmanCall = File(podmanArgs).readAsStringSync();
          expect(podmanCall, contains('--userns=keep-id'));
          expect(podmanCall, contains('my/image:1 $claudeScript'));
          expect(
            podmanCall,
            contains('rm --force --ignore roundtable-task-1'),
            reason: 'a leftover container is removed after the run',
          );
          final claudeCall = File(claudeArgs).readAsStringSync();
          expect(claudeCall, contains('ENV(container)'));
          expect(claudeCall, contains('https://server.example'));
          expect(taskUpdates.last.status, TaskStatus.awaitingReview);
        },
      );

      test(
        'fails with an explanation when the machine has no runtime',
        () async {
          final claudeScript = writeFakeClaude('exit 0');
          final taskUpdates = <Task>[];

          await dispatcherFor(
            claudeScript,
            taskUpdates: taskUpdates,
            agent: dockerAgent(),
          ).handle(buildTask());

          expect(taskUpdates.last.status, TaskStatus.failed);
          expect(taskUpdates.last.failureReason, contains('container runtime'));
        },
      );
    });

    group('with project tools', () {
      final flutter = [ProjectTool(name: 'flutter', version: '3.24.0')];

      test('installs missing ones first, shows it on the timeline and runs '
          'claude with their PATH and a note in the system prompt', () async {
        final outFile = '${tempDir.path}/out.txt';
        final claudeScript = writeFakeClaude('''
echo "PATH=\$PATH" > $outFile
echo "\$@" >> $outFile
echo "x" > x.txt
echo '{"type":"result","subtype":"success","session_id":"s"}'
''');
        final entries = <TaskLogEntry>[];

        await dispatcherFor(
          claudeScript,
          taskUpdates: [],
          logEntries: entries,
          tools: flutter,
          installer: fakeMise(missing: '{"flutter": [{"version": "3.24.0"}]}'),
        ).handle(buildTask());

        final out = File(outFile).readAsStringSync();
        expect(out, contains('PATH=/opt/fake-flutter/bin:'));
        expect(out, contains('Installed for this project'));
        expect(out, contains('flutter 3.24.0'));
        final events = [
          for (final e in entries)
            if (e.kind == LogKind.event && !e.content.startsWith('Committed'))
              e.content,
        ];
        expect(events, [
          contains('Installing flutter 3.24.0'),
          'Tools ready: flutter 3.24.0',
        ]);
        expect(
          File(
            '${tempDir.path}/home/.config/roundtable/toolchains/'
            'project-1.toml',
          ).readAsStringSync(),
          contains('"flutter" = "3.24.0"'),
        );
      });

      test('cached tools add nothing to the timeline', () async {
        final claudeScript = writeFakeClaude('''
echo "x" > x.txt
echo '{"type":"result","subtype":"success","session_id":"s"}'
''');
        final entries = <TaskLogEntry>[];

        await dispatcherFor(
          claudeScript,
          taskUpdates: [],
          logEntries: entries,
          tools: flutter,
          installer: fakeMise(),
        ).handle(buildTask());

        expect(
          entries.where(
            (e) =>
                e.kind == LogKind.event && !e.content.startsWith('Committed'),
          ),
          isEmpty,
        );
      });

      test('a failed install is reported but the task still runs', () async {
        final claudeScript = writeFakeClaude('''
echo "x" > x.txt
echo '{"type":"result","subtype":"success","session_id":"s"}'
''');
        final entries = <TaskLogEntry>[];
        final taskUpdates = <Task>[];

        await dispatcherFor(
          claudeScript,
          taskUpdates: taskUpdates,
          logEntries: entries,
          tools: flutter,
          installer: fakeMise(
            missing: '{"flutter": [{"version": "3.24.0"}]}',
            fail: true,
          ),
        ).handle(buildTask());

        final error = entries.singleWhere((e) => e.isError ?? false);
        expect(error.kind, LogKind.event);
        expect(error.content, contains("Couldn't install"));
        expect(error.content, contains('download failed'));
        expect(taskUpdates.last.status, TaskStatus.awaitingReview);
      });
    });

    test('a run stopped by the usage limit pauses the task with the reset '
        'time, its phase and session', () async {
      final claudeScript = writeFakeClaude('''
echo '{"type":"result","subtype":"error_during_execution","is_error":true,"session_id":"sess-9","result":"You have hit your session limit · resets 3am (Europe/Warsaw)"}'
exit 1
''');
      final taskUpdates = <Task>[];

      await dispatcherFor(
        claudeScript,
        taskUpdates: taskUpdates,
      ).handle(buildTask());

      final paused = taskUpdates.last;
      expect(paused.status, TaskStatus.paused);
      expect(paused.pausedPhase, LogPhase.execution);
      expect(paused.claudeSessionId, 'sess-9');
      expect(paused.pauseReason, contains('session limit'));
      expect(paused.pausedUntil!.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test(
      'a paused task requeued after the reset resumes its session',
      () async {
        final argsFile = '${tempDir.path}/args.txt';
        final claudeScript = writeFakeClaude('''
echo "\$@" > $argsFile
echo "more" > more.txt
echo '{"type":"result","subtype":"success","session_id":"sess-9"}'
exit 0
''');
        final taskUpdates = <Task>[];

        await dispatcherFor(claudeScript, taskUpdates: taskUpdates).handle(
          buildTask().copyWith(
            claudeSessionId: 'sess-9',
            pausedPhase: LogPhase.execution,
          ),
        );

        final args = File(argsFile).readAsStringSync();
        expect(args, contains('--resume sess-9'));
        expect(args, contains('usage limit'));
        expect(taskUpdates.first.pausedPhase, isNull);
        expect(taskUpdates.last.status, TaskStatus.awaitingReview);
      },
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
        appendLog: (entry) async => logLines.add(entry.content),
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

      expect(logLines, [
        'Ana started working',
        'Done',
        startsWith('Committed and pushed task-1, opened pull request '),
      ]);
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

    test('a task that produces no changes is done without a PR, keeping '
        "the agent's reply as its result", () async {
      final claudeScript = writeFakeClaude('''
echo '{"type":"result","subtype":"success","session_id":"sess-1","result":"It is hardcoded; no change needed."}'
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
        appendLog: (_) async {},
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

      expect(taskUpdates.last.status, TaskStatus.done);
      expect(taskUpdates.last.failureReason, isNull);
      expect(
        taskUpdates.last.resultSummary,
        'It is hardcoded; no change needed.',
      );
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
          appendLog: (_) async {},
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
        appendLog: (_) async {},
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

    test('an unlaunchable claude executable marks the task failed with a '
        'friendly, actionable reason instead of the raw exception', () async {
      final taskUpdates = <Task>[];
      final agentUpdates = <Agent>[];

      final dispatcher = TaskDispatcher(
        worktreeManager: WorktreeManager(
          workspaceRoot: '${tempDir.path}/workspace',
        ),
        executorFactory: () =>
            ClaudeCodeExecutor(executable: '${tempDir.path}/no-such-claude'),
        oauthToken: null,
        getCloneUrl: (projectId) async => fixtureRepo.path,
        fetchAgent: (agentId) async => buildAgent(),
        updateTask: (task) async => taskUpdates.add(task),
        updateAgent: (agent) async => agentUpdates.add(agent),
        appendLog: (_) async {},
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
      expect(taskUpdates.last.failureReason, contains('CLAUDE_EXECUTABLE'));
      expect(taskUpdates.last.failureReason, contains('no-such-claude'));
      expect(agentUpdates.last.status, AgentStatus.idle);
    });

    // `draft`: the server moved the task back to the backlog; `cancelled`:
    // an older server.
    for (final cancelledStatus in [TaskStatus.draft, TaskStatus.cancelled]) {
      test(
        'a task cancelled mid-run (${cancelledStatus.name}) is SIGTERM-ed, '
        'has its worktree reset, and reports no outcome nor opens a PR',
        () async {
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
            appendLog: (_) async {},
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
            buildTask().copyWith(status: cancelledStatus),
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
          // Only the run's start was reported — the server owns the outcome.
          expect(taskUpdates.map((t) => t.status), [TaskStatus.running]);
          expect(taskUpdates.last.branchName, isNull);
          expect(taskUpdates.last.prUrl, isNull);
          expect(agentUpdates.last.status, AgentStatus.idle);
        },
      );
    }

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
          appendLog: (_) async {},
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
        appendLog: (_) async {},
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
        appendLog: (_) async {},
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
          appendLog: (_) async {},
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
          appendLog: (_) async {},
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
