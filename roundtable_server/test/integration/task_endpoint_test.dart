import 'package:roundtable_server/src/endpoints/task_endpoint.dart';
import 'package:roundtable_server/src/future_calls/paused_task_resume_future_call.dart';
import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Task endpoint', (sessionBuilder, endpoints) {
    Future<Machine> createMachine() async {
      return Machine.db.insertRow(sessionBuilder.build(), Machine(name: 'VPS'));
    }

    Future<Project> createProject() async {
      return Project.db.insertRow(
        sessionBuilder.build(),
        Project(
          name: 'Roundtable',
          repoUrl: 'https://github.com/example/roundtable',
        ),
      );
    }

    Future<Agent> createAgent(Machine machine) async {
      return Agent.db.insertRow(
        sessionBuilder.build(),
        Agent(name: 'Ana', machineId: machine.id!),
      );
    }

    test(
      'when creating a task then it is persisted as queued with the given fields',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);

        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );

        expect(task.id, isNotNull);
        expect(task.projectId, project.id);
        expect(task.agentId, agent.id);
        expect(task.prompt, 'Do something');
        expect(task.skipPlanning, isFalse);
        expect(task.status, TaskStatus.queued);
      },
    );

    group('task title', () {
      Future<Task> createTask() async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        return endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something\nwith details',
          skipPlanning: false,
        );
      }

      test('a new task has no title', () async {
        final task = await createTask();
        expect(task.title, isNull);
      });

      test(
        'when the agent suggests a title for an untitled task then it is stored trimmed',
        () async {
          final task = await createTask();

          final updated = await endpoints.task.suggestTitle(
            sessionBuilder,
            task.id!,
            '  Add task titles  \nignored second line',
          );

          expect(updated.title, 'Add task titles');
          final stored = await Task.db.findById(
            sessionBuilder.build(),
            task.id!,
          );
          expect(stored!.title, 'Add task titles');
        },
      );

      test(
        'when the agent suggests a title for a titled task then it is kept',
        () async {
          final task = await createTask();
          await endpoints.task.setTitle(sessionBuilder, task.id!, 'Dev title');

          final updated = await endpoints.task.suggestTitle(
            sessionBuilder,
            task.id!,
            'Agent title',
          );

          expect(updated.title, 'Dev title');
        },
      );

      test('a too long title is cut to the maximum length', () async {
        final task = await createTask();

        final updated = await endpoints.task.suggestTitle(
          sessionBuilder,
          task.id!,
          'x' * 200,
        );

        expect(updated.title!.length, TaskEndpoint.maxTitleLength);
        expect(updated.title, endsWith('…'));
      });

      test(
        'when the dev sets a blank title then it is cleared and the agent may suggest one again',
        () async {
          final task = await createTask();
          await endpoints.task.setTitle(sessionBuilder, task.id!, 'Dev title');

          final cleared = await endpoints.task.setTitle(
            sessionBuilder,
            task.id!,
            '   ',
          );
          expect(cleared.title, isNull);

          final suggested = await endpoints.task.suggestTitle(
            sessionBuilder,
            task.id!,
            'Agent title',
          );
          expect(suggested.title, 'Agent title');
        },
      );

      test(
        'when the daemon updates the task with a stale snapshot then the title is kept',
        () async {
          final task = await createTask();
          await endpoints.task.suggestTitle(
            sessionBuilder,
            task.id!,
            'Agent title',
          );

          final updated = await endpoints.task.update(
            sessionBuilder,
            task.copyWith(status: TaskStatus.running),
          );

          expect(updated.title, 'Agent title');
        },
      );
    });

    group('task settings', () {
      late Agent agent;

      Future<Task> createTask() async {
        final machine = await createMachine();
        final project = await createProject();
        agent = await createAgent(machine);
        return endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
      }

      Future<Task> setStatus(Task task, TaskStatus status) => Task.db.updateRow(
        sessionBuilder.build(),
        task.copyWith(status: status),
      );

      test(
        'when the dev edits a queued task then the prompt and every option are stored',
        () async {
          final task = await createTask();

          final updated = await endpoints.task.updateTaskSettings(
            sessionBuilder,
            task.id!,
            '  Do something else  ',
            skipPlanning: true,
            autoReview: true,
            reviewerAgentId: agent.id,
            autoFixReview: true,
            maxReviewFixRounds: 3,
            autoMerge: true,
            autoFixFailingChecks: true,
            maxCheckFixAttempts: 5,
          );

          final stored = await Task.db.findById(
            sessionBuilder.build(),
            task.id!,
          );
          for (final t in [updated, stored!]) {
            expect(t.prompt, 'Do something else');
            expect(t.skipPlanning, isTrue);
            expect(t.autoReview, isTrue);
            expect(t.reviewerAgentId, agent.id);
            expect(t.autoFixReview, isTrue);
            expect(t.maxReviewFixRounds, 3);
            expect(t.autoMerge, isTrue);
            expect(t.autoFixFailingChecks, isTrue);
            expect(t.maxCheckFixAttempts, 5);
            expect(t.status, TaskStatus.queued);
          }
        },
      );

      test('a null reviewer clears it and the rounds are clamped', () async {
        final task = await createTask();
        await endpoints.task.updateTaskSettings(
          sessionBuilder,
          task.id!,
          task.prompt,
          reviewerAgentId: agent.id,
        );

        final updated = await endpoints.task.updateTaskSettings(
          sessionBuilder,
          task.id!,
          task.prompt,
          maxReviewFixRounds: 50,
          maxCheckFixAttempts: 0,
        );

        expect(updated.reviewerAgentId, isNull);
        expect(updated.maxReviewFixRounds, 10);
        expect(updated.maxCheckFixAttempts, 1);
      });

      for (final status in [TaskStatus.running, TaskStatus.awaitingReview]) {
        test(
          'when the task is ${status.name} then the prompt is rejected but the automation options change',
          () async {
            final task = await setStatus(await createTask(), status);

            await expectLater(
              endpoints.task.updateTaskSettings(
                sessionBuilder,
                task.id!,
                'New prompt',
              ),
              throwsA(isA<InvalidStateException>()),
            );
            await expectLater(
              endpoints.task.updateTaskSettings(
                sessionBuilder,
                task.id!,
                task.prompt,
                skipPlanning: true,
              ),
              throwsA(isA<InvalidStateException>()),
            );

            final updated = await endpoints.task.updateTaskSettings(
              sessionBuilder,
              task.id!,
              task.prompt,
              autoMerge: true,
            );
            expect(updated.autoMerge, isTrue);
            expect(updated.prompt, 'Do something');
            expect(updated.status, status);
          },
        );
      }

      test(
        'when a queued task resumes a paused run then the prompt is rejected but the automation options change',
        () async {
          final task = await Task.db.updateRow(
            sessionBuilder.build(),
            (await createTask()).copyWith(pausedPhase: LogPhase.execution),
          );

          await expectLater(
            endpoints.task.updateTaskSettings(
              sessionBuilder,
              task.id!,
              'New prompt',
            ),
            throwsA(isA<InvalidStateException>()),
          );
          await expectLater(
            endpoints.task.updateTaskSettings(
              sessionBuilder,
              task.id!,
              task.prompt,
              skipPlanning: true,
            ),
            throwsA(isA<InvalidStateException>()),
          );

          final updated = await endpoints.task.updateTaskSettings(
            sessionBuilder,
            task.id!,
            task.prompt,
            autoMerge: true,
          );
          expect(updated.autoMerge, isTrue);
          expect(updated.prompt, 'Do something');
          expect(updated.skipPlanning, isFalse);
          expect(updated.status, TaskStatus.queued);
        },
      );

      test('a failed task can get a new prompt before a retry', () async {
        final task = await setStatus(await createTask(), TaskStatus.failed);

        final updated = await endpoints.task.updateTaskSettings(
          sessionBuilder,
          task.id!,
          'Try differently',
        );

        expect(updated.prompt, 'Try differently');
      });

      test('a done task cannot be edited', () async {
        final task = await setStatus(await createTask(), TaskStatus.done);

        await expectLater(
          endpoints.task.updateTaskSettings(
            sessionBuilder,
            task.id!,
            task.prompt,
            autoMerge: true,
          ),
          throwsA(isA<InvalidStateException>()),
        );
      });

      test('a blank prompt is rejected', () async {
        final task = await createTask();

        await expectLater(
          endpoints.task.updateTaskSettings(sessionBuilder, task.id!, '   '),
          throwsA(isA<InvalidStateException>()),
        );
      });

      test('an unknown reviewer is rejected', () async {
        final task = await createTask();

        await expectLater(
          endpoints.task.updateTaskSettings(
            sessionBuilder,
            task.id!,
            task.prompt,
            reviewerAgentId: 999999,
          ),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    test(
      'when creating a task without an agent then it is persisted as a draft',
      () async {
        final project = await createProject();

        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          null,
          'Do something later',
          skipPlanning: false,
        );

        expect(task.agentId, isNull);
        expect(task.status, TaskStatus.draft);
      },
    );

    test(
      'when assigning an agent to a draft then it is queued for that agent',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final draft = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          null,
          'Do something later',
          skipPlanning: false,
        );

        final assigned = await endpoints.task.reassignAgent(
          sessionBuilder,
          draft.id!,
          agent.id!,
        );

        expect(assigned.agentId, agent.id);
        expect(assigned.status, TaskStatus.queued);
      },
    );

    test(
      'when deleting a draft then it is removed without cancelling first',
      () async {
        final project = await createProject();
        final draft = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          null,
          'Do something later',
          skipPlanning: false,
        );

        await endpoints.task.deleteTask(sessionBuilder, draft.id!);

        expect(
          await Task.db.findById(sessionBuilder.build(), draft.id!),
          isNull,
        );
      },
    );

    test(
      'when creating a task for an unknown agent then it throws',
      () async {
        final project = await createProject();

        await expectLater(
          endpoints.task.createTask(
            sessionBuilder,
            project.id!,
            999999,
            'Do something',
            skipPlanning: false,
          ),
          throwsException,
        );
      },
    );

    test(
      'when the daemon finishes a run without code then it may set done with '
      'the result, but not on a task that has a branch',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final answered = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Is this hardcoded?',
          skipPlanning: true,
        );
        final withBranch = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Change it',
          skipPlanning: true,
        );
        await endpoints.task.update(
          sessionBuilder,
          withBranch.copyWith(
            status: TaskStatus.running,
            branchName: 'task-${withBranch.id}',
          ),
        );

        final done = await endpoints.task.update(
          sessionBuilder,
          answered.copyWith(
            status: TaskStatus.done,
            resultSummary: 'Yes, it is.',
          ),
        );
        final refused = await endpoints.task.update(
          sessionBuilder,
          withBranch.copyWith(
            status: TaskStatus.done,
            branchName: 'task-${withBranch.id}',
          ),
        );

        expect(done.status, TaskStatus.done);
        expect(done.resultSummary, 'Yes, it is.');
        expect(refused.status, TaskStatus.running);
      },
    );

    test(
      'when the daemon appends a structured log entry then it is stored with '
      'its run and tool fields and a server timestamp',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );

        final stored = await endpoints.task.appendLogEntry(
          sessionBuilder,
          TaskLogEntry(
            id: 999,
            taskId: task.id!,
            content: 'Read(/a.dart)',
            kind: LogKind.toolCall,
            runId: 'task-1-1',
            phase: LogPhase.execution,
            toolName: 'Read',
            toolUseId: 'tu_1',
          ),
        );

        expect(stored.id, isNot(999));
        expect(stored.kind, LogKind.toolCall);
        expect(stored.runId, 'task-1-1');
        expect(stored.phase, LogPhase.execution);
        expect(stored.toolUseId, 'tu_1');
      },
    );

    test(
      'when a task finished without code is continued then it is reopened '
      'for the agent with the message as feedback; a task with a PR cannot be',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Analyze CI checks',
          skipPlanning: true,
        );
        await endpoints.task.update(
          sessionBuilder,
          task.copyWith(
            status: TaskStatus.done,
            claudeSessionId: 'sess-1',
            resultSummary: 'Here is the analysis.',
          ),
        );

        final feedback = await endpoints.task.continueTask(
          sessionBuilder,
          task.id!,
          ' Implement it. ',
        );
        final reopened = await Task.db.findById(
          sessionBuilder.build(),
          task.id!,
        );

        expect(feedback.message, 'Implement it.');
        expect(feedback.phase, TaskFeedbackPhase.review);
        expect(feedback.kind, TaskFeedbackKind.dev);
        final listed = await endpoints.task.listFeedback(
          sessionBuilder,
          task.id!,
        );
        expect(listed.map((f) => f.id), [feedback.id]);
        expect(reopened!.status, TaskStatus.awaitingReview);
        expect(
          () => endpoints.task.continueTask(sessionBuilder, task.id!, 'Again'),
          throwsA(isA<InvalidStateException>()),
        );
      },
    );

    test(
      'when the daemon pauses a task for a usage limit then it is resumed once '
      'pausedUntil passes, or right away with resumeTask',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        Future<Task> pausedTask(DateTime until) async {
          final task = await endpoints.task.createTask(
            sessionBuilder,
            project.id!,
            agent.id!,
            'Do something',
            skipPlanning: true,
          );
          return endpoints.task.update(
            sessionBuilder,
            task.copyWith(
              status: TaskStatus.paused,
              pausedUntil: until,
              pauseReason: 'You have hit your session limit',
              pausedPhase: LogPhase.execution,
              claudeSessionId: 'sess-1',
            ),
          );
        }

        final due = await pausedTask(
          DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
        );
        final later = await pausedTask(
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        );
        expect(due.status, TaskStatus.paused);
        expect(due.pausedPhase, LogPhase.execution);

        await PausedTaskResumeFutureCall().check(sessionBuilder.build());
        final resumed = await Task.db.findById(sessionBuilder.build(), due.id!);
        final stillPaused = await Task.db.findById(
          sessionBuilder.build(),
          later.id!,
        );
        expect(resumed!.status, TaskStatus.queued);
        expect(resumed.pausedUntil, isNull);
        expect(resumed.pausedPhase, LogPhase.execution);
        expect(stillPaused!.status, TaskStatus.paused);

        final now = await endpoints.task.resumeTask(sessionBuilder, later.id!);
        expect(now.status, TaskStatus.queued);
      },
    );

    test('when updating a task then the change is persisted', () async {
      final machine = await createMachine();
      final project = await createProject();
      final agent = await createAgent(machine);
      final created = await endpoints.task.createTask(
        sessionBuilder,
        project.id!,
        agent.id!,
        'Do something',
        skipPlanning: true,
      );

      final updated = await endpoints.task.update(
        sessionBuilder,
        created.copyWith(
          status: TaskStatus.running,
          startedAt: DateTime.now().toUtc(),
        ),
      );

      expect(updated.status, TaskStatus.running);
      expect(updated.startedAt, isNotNull);
    });

    test(
      'when appending a log line then it is persisted as a TaskLogEntry',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );

        final entry = await endpoints.task.appendLog(
          sessionBuilder,
          task.id!,
          '{"type":"system","subtype":"init"}',
          source: LogSource.agent,
        );

        expect(entry.id, isNotNull);
        expect(entry.taskId, task.id);
        expect(entry.content, '{"type":"system","subtype":"init"}');
        expect(entry.source, LogSource.agent);
      },
    );

    test(
      'when watching logs then an already-persisted log entry for that task is replayed',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );
        final existing = await endpoints.task.appendLog(
          sessionBuilder,
          task.id!,
          'already there',
          source: LogSource.agent,
        );

        final entries = await endpoints.task
            .watchLogs(sessionBuilder, task.id!)
            .take(1)
            .toList();

        expect(entries.map((e) => e.id), contains(existing.id));
      },
    );

    test(
      'when cancelling a queued task then it goes back to the backlog as an '
      'agent-less draft',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );

        final cancelled = await endpoints.task.cancelTask(
          sessionBuilder,
          task.id!,
        );

        expect(cancelled.status, TaskStatus.draft);
        expect(cancelled.agentId, isNull);
        expect(cancelled.finishedAt, isNull);
      },
    );

    test(
      'when cancelling a task in review then its run state is reset but the '
      'branch and PR are kept',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );
        await Task.db.updateRow(
          sessionBuilder.build(),
          task.copyWith(
            status: TaskStatus.awaitingReview,
            claudeSessionId: 'sess-1',
            resultSummary: 'Done.',
            branchName: 'task-${task.id}',
            prUrl: 'https://github.com/example/rt/pull/1',
            startedAt: DateTime.now().toUtc(),
            finishedAt: DateTime.now().toUtc(),
          ),
        );

        final cancelled = await endpoints.task.cancelTask(
          sessionBuilder,
          task.id!,
        );

        expect(cancelled.status, TaskStatus.draft);
        expect(cancelled.claudeSessionId, isNull);
        expect(cancelled.resultSummary, isNull);
        expect(cancelled.startedAt, isNull);
        expect(cancelled.branchName, 'task-${task.id}');
        expect(cancelled.prUrl, 'https://github.com/example/rt/pull/1');
      },
    );

    test('when cancelling a draft then it throws', () async {
      final project = await createProject();
      final task = await endpoints.task.createTask(
        sessionBuilder,
        project.id!,
        null,
        'Do something',
        skipPlanning: false,
      );

      await expectLater(
        endpoints.task.cancelTask(sessionBuilder, task.id!),
        throwsException,
      );
    });

    test(
      'when a cancelled run asks a question or reports a plan then it is '
      'rejected and the task stays a draft',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        await endpoints.task.cancelTask(sessionBuilder, task.id!);

        await expectLater(
          endpoints.task.createQuestion(sessionBuilder, task.id!, 'Q?', []),
          throwsException,
        );
        await expectLater(
          endpoints.task.setPlanReady(sessionBuilder, task.id!, 'Plan'),
          throwsException,
        );
        final current = await Task.db.findById(
          sessionBuilder.build(),
          task.id!,
        );
        expect(current!.status, TaskStatus.draft);
      },
    );

    test(
      'when cancelling a task already in a terminal state then it throws',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );
        // `update` can't set `done` (only acceptTask can) — seed it directly.
        await Task.db.updateRow(
          sessionBuilder.build(),
          task.copyWith(
            status: TaskStatus.done,
            finishedAt: DateTime.now().toUtc(),
          ),
        );

        await expectLater(
          endpoints.task.cancelTask(sessionBuilder, task.id!),
          throwsException,
        );
      },
    );

    test(
      'when cancelling an unknown task then it throws',
      () async {
        await expectLater(
          endpoints.task.cancelTask(sessionBuilder, 999999),
          throwsException,
        );
      },
    );

    test(
      'when retrying a failed task then it is reset to queued with the failure/session state cleared',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );
        await endpoints.task.update(
          sessionBuilder,
          task.copyWith(
            status: TaskStatus.failed,
            failureReason: 'claude: No such file or directory',
            claudeSessionId: 'session-123',
            currentPlan: 'Old plan',
            startedAt: DateTime.now().toUtc(),
            finishedAt: DateTime.now().toUtc(),
          ),
        );

        final retried = await endpoints.task.retryTask(
          sessionBuilder,
          task.id!,
        );

        expect(retried.status, TaskStatus.queued);
        expect(retried.failureReason, isNull);
        expect(retried.claudeSessionId, isNull);
        expect(retried.currentPlan, isNull);
        expect(retried.startedAt, isNull);
        expect(retried.finishedAt, isNull);
      },
    );

    test(
      'when retrying a cancelled task then it is reset to queued',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );
        // Cancelling now moves a task back to the backlog; `cancelled` is
        // only found on older rows.
        final cancelled = await Task.db.updateRow(
          sessionBuilder.build(),
          task.copyWith(
            status: TaskStatus.cancelled,
            finishedAt: DateTime.now().toUtc(),
          ),
        );

        final retried = await endpoints.task.retryTask(
          sessionBuilder,
          cancelled.id!,
        );

        expect(retried.status, TaskStatus.queued);
      },
    );

    test(
      'when retrying a task that is not failed/cancelled then it throws',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );

        await expectLater(
          endpoints.task.retryTask(sessionBuilder, task.id!),
          throwsException,
        );
      },
    );

    test(
      'when retrying an unknown task then it throws',
      () async {
        await expectLater(
          endpoints.task.retryTask(sessionBuilder, 999999),
          throwsException,
        );
      },
    );

    test(
      'when reassigning a queued task to a different agent then agentId is updated',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final otherAgent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );

        final reassigned = await endpoints.task.reassignAgent(
          sessionBuilder,
          task.id!,
          otherAgent.id!,
        );

        expect(reassigned.agentId, otherAgent.id);
      },
    );

    test(
      'when reassigning an agent-less task then it succeeds regardless of status',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final newAgent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        await Task.db.updateRow(
          sessionBuilder.build(),
          task.copyWith(status: TaskStatus.running, agentId: null),
        );

        final reassigned = await endpoints.task.reassignAgent(
          sessionBuilder,
          task.id!,
          newAgent.id!,
        );

        expect(reassigned.agentId, newAgent.id);
      },
    );

    test(
      'when reassigning a task actively running under its current agent then it throws',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final otherAgent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        await endpoints.task.update(
          sessionBuilder,
          task.copyWith(status: TaskStatus.running),
        );

        await expectLater(
          endpoints.task.reassignAgent(
            sessionBuilder,
            task.id!,
            otherAgent.id!,
          ),
          throwsException,
        );
      },
    );

    test(
      'when reassigning to an unknown agent then it throws',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );

        await expectLater(
          endpoints.task.reassignAgent(sessionBuilder, task.id!, 999999),
          throwsException,
        );
      },
    );

    test(
      'when reassigning an unknown task then it throws',
      () async {
        final machine = await createMachine();
        final agent = await createAgent(machine);

        await expectLater(
          endpoints.task.reassignAgent(sessionBuilder, 999999, agent.id!),
          throwsException,
        );
      },
    );

    test('when deleting a terminal task then it is removed', () async {
      final machine = await createMachine();
      final project = await createProject();
      final agent = await createAgent(machine);
      final task = await endpoints.task.createTask(
        sessionBuilder,
        project.id!,
        agent.id!,
        'Do something',
        skipPlanning: true,
      );
      // `update` can't set `done` (only acceptTask can) — seed it directly.
      await Task.db.updateRow(
        sessionBuilder.build(),
        task.copyWith(
          status: TaskStatus.done,
          finishedAt: DateTime.now().toUtc(),
        ),
      );

      await endpoints.task.deleteTask(sessionBuilder, task.id!);

      final deleted = await Task.db.findById(sessionBuilder.build(), task.id!);
      expect(deleted, isNull);
    });

    test(
      'when deleting a task that is not in a terminal state then it throws',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );

        await expectLater(
          endpoints.task.deleteTask(sessionBuilder, task.id!),
          throwsException,
        );
      },
    );

    test(
      'when deleting an unknown task then it throws',
      () async {
        await expectLater(
          endpoints.task.deleteTask(sessionBuilder, 999999),
          throwsException,
        );
      },
    );

    test(
      'when watching a task then its current row is replayed',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );

        final tasks = await endpoints.task
            .watchTask(sessionBuilder, task.id!)
            .take(1)
            .toList();

        expect(tasks.single.id, task.id);
      },
    );

    test(
      'when submitting feedback on an awaitingReview task then it is persisted as review-phase feedback',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );
        await endpoints.task.update(
          sessionBuilder,
          task.copyWith(
            status: TaskStatus.awaitingReview,
            claudeSessionId: 'sess-1',
            finishedAt: DateTime.now().toUtc(),
          ),
        );

        final feedback = await endpoints.task.submitFeedback(
          sessionBuilder,
          task.id!,
          'Please also update the README',
        );

        expect(feedback.id, isNotNull);
        expect(feedback.taskId, task.id);
        expect(feedback.message, 'Please also update the README');
        expect(feedback.phase, TaskFeedbackPhase.review);
      },
    );

    test(
      'when submitting feedback on a task that is not awaiting review then it throws',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );

        await expectLater(
          endpoints.task.submitFeedback(sessionBuilder, task.id!, 'Feedback'),
          throwsException,
        );
      },
    );

    test(
      'when submitting feedback on an unknown task then it throws',
      () async {
        await expectLater(
          endpoints.task.submitFeedback(sessionBuilder, 999999, 'Feedback'),
          throwsException,
        );
      },
    );

    test(
      'when fetching the latest feedback then the most recently submitted one is returned',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );
        await endpoints.task.update(
          sessionBuilder,
          task.copyWith(
            status: TaskStatus.awaitingReview,
            claudeSessionId: 'sess-1',
            finishedAt: DateTime.now().toUtc(),
          ),
        );
        await endpoints.task.submitFeedback(
          sessionBuilder,
          task.id!,
          'First round of feedback',
        );
        final latest = await endpoints.task.submitFeedback(
          sessionBuilder,
          task.id!,
          'Second round of feedback',
        );

        final fetched = await endpoints.task.latestFeedback(
          sessionBuilder,
          task.id!,
        );

        expect(fetched?.id, latest.id);
        expect(fetched?.message, 'Second round of feedback');
      },
    );

    test(
      'when fetching the latest feedback for a task with none then it returns null',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );

        final fetched = await endpoints.task.latestFeedback(
          sessionBuilder,
          task.id!,
        );

        expect(fetched, isNull);
      },
    );

    test(
      'when creating a question then it is persisted and the task is marked waitingForAnswer',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );

        final question = await endpoints.task.createQuestion(
          sessionBuilder,
          task.id!,
          'Which approach?',
          ['Option A', 'Option B'],
        );

        expect(question.id, isNotNull);
        expect(question.taskId, task.id);
        expect(question.question, 'Which approach?');
        expect(question.options, ['Option A', 'Option B']);
        expect(question.answer, isNull);

        final updated = await Task.db.findById(
          sessionBuilder.build(),
          task.id!,
        );
        expect(updated?.status, TaskStatus.waitingForAnswer);
      },
    );

    test(
      'when creating a question for an unknown task then it throws',
      () async {
        await expectLater(
          endpoints.task.createQuestion(sessionBuilder, 999999, 'Q?', []),
          throwsException,
        );
      },
    );

    test(
      'when fetching the latest question then the most recently asked one is returned',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        await endpoints.task.createQuestion(
          sessionBuilder,
          task.id!,
          'First question?',
          ['A', 'B'],
        );
        final latest = await endpoints.task.createQuestion(
          sessionBuilder,
          task.id!,
          'Second question?',
          ['C', 'D'],
        );

        final fetched = await endpoints.task.latestQuestion(
          sessionBuilder,
          task.id!,
        );

        expect(fetched?.id, latest.id);
        expect(fetched?.question, 'Second question?');
      },
    );

    test(
      'when fetching the latest question for a task with none then it returns null',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );

        final fetched = await endpoints.task.latestQuestion(
          sessionBuilder,
          task.id!,
        );

        expect(fetched, isNull);
      },
    );

    test(
      'when answering a question then the answer and answeredAt are persisted',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        final question = await endpoints.task.createQuestion(
          sessionBuilder,
          task.id!,
          'Which approach?',
          ['Option A', 'Option B'],
        );

        final answered = await endpoints.task.answerQuestion(
          sessionBuilder,
          question.id!,
          'Option A',
        );

        expect(answered.answer, 'Option A');
        expect(answered.answeredAt, isNotNull);
      },
    );

    test(
      'when answering a question then the task moves back to planning',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        final question = await endpoints.task.createQuestion(
          sessionBuilder,
          task.id!,
          'Which approach?',
          ['Option A', 'Option B'],
        );

        await endpoints.task.answerQuestion(
          sessionBuilder,
          question.id!,
          'Option A',
        );

        final fetched = await Task.db.findById(
          sessionBuilder.build(),
          task.id!,
        );
        expect(fetched!.status, TaskStatus.planning);
      },
    );

    test(
      'when answering an already-answered question then it throws',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        final question = await endpoints.task.createQuestion(
          sessionBuilder,
          task.id!,
          'Which approach?',
          ['Option A', 'Option B'],
        );
        await endpoints.task.answerQuestion(
          sessionBuilder,
          question.id!,
          'Option A',
        );

        await expectLater(
          endpoints.task.answerQuestion(
            sessionBuilder,
            question.id!,
            'Option B',
          ),
          throwsException,
        );
      },
    );

    test(
      'when answering an unknown question then it throws',
      () async {
        await expectLater(
          endpoints.task.answerQuestion(sessionBuilder, 999999, 'Answer'),
          throwsException,
        );
      },
    );

    test(
      'when watching the answer to an already-answered question then it is replayed',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        final question = await endpoints.task.createQuestion(
          sessionBuilder,
          task.id!,
          'Which approach?',
          ['Option A', 'Option B'],
        );
        await endpoints.task.answerQuestion(
          sessionBuilder,
          question.id!,
          'Option A',
        );

        final answers = await endpoints.task
            .watchAnswer(sessionBuilder, question.id!)
            .take(1)
            .toList();

        expect(answers.single.answer, 'Option A');
      },
    );

    test(
      'when stale task snapshots are written back via appendLog or update '
      'then planReady and currentPlan are preserved',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final dispatched = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        await endpoints.task.setPlanReady(
          sessionBuilder,
          dispatched.id!,
          'The plan',
        );

        await endpoints.task.appendLog(
          sessionBuilder,
          dispatched.id!,
          'line',
          source: LogSource.agent,
        );
        await endpoints.task.update(
          sessionBuilder,
          dispatched.copyWith(claudeSessionId: 'sess-1'),
        );

        final fetched = await Task.db.findById(
          sessionBuilder.build(),
          dispatched.id!,
        );
        expect(fetched!.currentPlan, 'The plan');
        expect(fetched.status, TaskStatus.planReady);
        expect(fetched.claudeSessionId, 'sess-1');
      },
    );

    test(
      'when setting a plan ready then currentPlan is stored and the task is marked planReady',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );

        final updated = await endpoints.task.setPlanReady(
          sessionBuilder,
          task.id!,
          '1. Do this\n2. Do that',
        );

        expect(updated.status, TaskStatus.planReady);
        expect(updated.currentPlan, '1. Do this\n2. Do that');
      },
    );

    test(
      'when setting a plan ready for an unknown task then it throws',
      () async {
        await expectLater(
          endpoints.task.setPlanReady(sessionBuilder, 999999, 'Plan'),
          throwsException,
        );
      },
    );

    test(
      'when approving a planReady task then it is marked running',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        await endpoints.task.setPlanReady(sessionBuilder, task.id!, 'Plan');

        final approved = await endpoints.task.approvePlan(
          sessionBuilder,
          task.id!,
        );

        expect(approved.status, TaskStatus.running);
      },
    );

    test(
      'when approving a task that is not planReady then it throws',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );

        await expectLater(
          endpoints.task.approvePlan(sessionBuilder, task.id!),
          throwsException,
        );
      },
    );

    test(
      'when submitting plan feedback on a planReady task then it is persisted as plan-phase feedback and the task returns to planning',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        await endpoints.task.setPlanReady(sessionBuilder, task.id!, 'Plan');

        final feedback = await endpoints.task.submitPlanFeedback(
          sessionBuilder,
          task.id!,
          'Please reconsider the approach',
        );

        expect(feedback.phase, TaskFeedbackPhase.plan);
        expect(feedback.message, 'Please reconsider the approach');

        final updated = await Task.db.findById(
          sessionBuilder.build(),
          task.id!,
        );
        expect(updated?.status, TaskStatus.planning);
      },
    );

    test(
      'when submitting plan feedback on a task that is not planReady then it throws',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );

        await expectLater(
          endpoints.task.submitPlanFeedback(
            sessionBuilder,
            task.id!,
            'Feedback',
          ),
          throwsException,
        );
      },
    );

    test(
      'when watching assigned tasks then an already-queued task for that machine is replayed',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final existing = await Task.db.insertRow(
          sessionBuilder.build(),
          Task(
            projectId: project.id!,
            agentId: agent.id,
            prompt: 'Already queued',
            status: TaskStatus.queued,
          ),
        );

        final tasks = await endpoints.task
            .watchAssignedTasks(sessionBuilder, machine.id!)
            .take(1)
            .toList();

        expect(tasks.map((t) => t.id), contains(existing.id));
      },
    );
  });

  // Concurrently holding an open watchAssignedTasks stream open on the same
  // sessionBuilder while calling createTask isn't supported inside a single
  // rolled-back transaction (see the serverpod-testing skill) — these two
  // tests get their own group with rollback disabled.
  withServerpod('Given Task endpoint streaming', (sessionBuilder, endpoints) {
    Future<Machine> createMachine() async {
      return Machine.db.insertRow(sessionBuilder.build(), Machine(name: 'VPS'));
    }

    Future<Project> createProject() async {
      return Project.db.insertRow(
        sessionBuilder.build(),
        Project(
          name: 'Roundtable',
          repoUrl: 'https://github.com/example/roundtable',
        ),
      );
    }

    Future<Agent> createAgent(Machine machine) async {
      return Agent.db.insertRow(
        sessionBuilder.build(),
        Agent(name: 'Ana', machineId: machine.id!),
      );
    }

    test(
      'when a task is created for an agent on the watched machine then it is emitted on the stream',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);

        final stream = endpoints.task.watchAssignedTasks(
          sessionBuilder,
          machine.id!,
        );
        // Listen before creating, otherwise the post can race the subscription.
        final firstId = stream.first.then((task) => task.id);
        await flushEventQueue();

        final created = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'New task',
          skipPlanning: false,
        );

        await expectLater(firstId, completion(created.id));
      },
    );

    test(
      'when a task is created for an agent on a different machine then it is not emitted',
      () async {
        final watchedMachine = await createMachine();
        final otherMachine = await createMachine();
        final project = await createProject();
        final otherAgent = await createAgent(otherMachine);

        final stream = endpoints.task.watchAssignedTasks(
          sessionBuilder,
          watchedMachine.id!,
        );
        final events = <Task>[];
        final subscription = stream.listen(events.add);
        await flushEventQueue();

        await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          otherAgent.id!,
          'For the other machine',
          skipPlanning: false,
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(events, isEmpty);
      },
    );

    test(
      'when a log line is appended for the watched task then it is emitted on the stream',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );

        final stream = endpoints.task.watchLogs(sessionBuilder, task.id!);
        final firstEvent = stream.first.then((entry) => entry.id);
        await flushEventQueue();

        final appended = await endpoints.task.appendLog(
          sessionBuilder,
          task.id!,
          'live line',
          source: LogSource.agent,
        );

        await expectLater(firstEvent, completion(appended.id));
      },
    );

    test(
      'when the watched task is cancelled then a cancelled signal (for older '
      'runners) and then its move back to draft are emitted on the stream',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );

        final stream = endpoints.task.watchTask(sessionBuilder, task.id!);
        // The replayed current row, then the two cancellation messages.
        final events = stream.take(3).map((t) => t.status).toList();
        await flushEventQueue();

        await endpoints.task.cancelTask(sessionBuilder, task.id!);

        await expectLater(
          events,
          completion([
            TaskStatus.queued,
            TaskStatus.cancelled,
            TaskStatus.draft,
          ]),
        );
        final stored = await Task.db.findById(
          sessionBuilder.build(),
          task.id!,
        );
        expect(stored!.status, TaskStatus.draft);
      },
    );

    test(
      'when a terminal task is deleted then it is emitted on watchTaskDeletions',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );
        // `update` can't set `done` (only acceptTask can) — seed it directly.
        await Task.db.updateRow(
          sessionBuilder.build(),
          task.copyWith(
            status: TaskStatus.done,
            finishedAt: DateTime.now().toUtc(),
          ),
        );

        final stream = endpoints.task.watchTaskDeletions(sessionBuilder);
        final firstEvent = stream.first.then((d) => d.taskId);
        await flushEventQueue();

        await endpoints.task.deleteTask(sessionBuilder, task.id!);

        await expectLater(firstEvent, completion(task.id));
      },
    );

    test(
      'when feedback is submitted on the watched machine\'s task then it is re-emitted on watchAssignedTasks',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );
        await endpoints.task.update(
          sessionBuilder,
          task.copyWith(
            status: TaskStatus.awaitingReview,
            claudeSessionId: 'sess-1',
            finishedAt: DateTime.now().toUtc(),
          ),
        );

        final stream = endpoints.task.watchAssignedTasks(
          sessionBuilder,
          machine.id!,
        );
        final events = <Task>[];
        final subscription = stream.listen(events.add);
        await flushEventQueue();

        await endpoints.task.submitFeedback(
          sessionBuilder,
          task.id!,
          'Please also update the README',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(events.map((t) => t.id), contains(task.id));
      },
    );

    test(
      'when a failed task is retried then it is re-emitted on watchAssignedTasks as queued',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: true,
        );
        await endpoints.task.update(
          sessionBuilder,
          task.copyWith(
            status: TaskStatus.failed,
            failureReason: 'boom',
            finishedAt: DateTime.now().toUtc(),
          ),
        );

        final stream = endpoints.task.watchAssignedTasks(
          sessionBuilder,
          machine.id!,
        );
        final events = <Task>[];
        final subscription = stream.listen(events.add);
        await flushEventQueue();

        await endpoints.task.retryTask(sessionBuilder, task.id!);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(
          events.where((t) => t.id == task.id).map((t) => t.status),
          contains(TaskStatus.queued),
        );
      },
    );

    test(
      'when a question is answered then the answer is emitted on watchAnswer',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        final question = await endpoints.task.createQuestion(
          sessionBuilder,
          task.id!,
          'Which approach?',
          ['Option A', 'Option B'],
        );

        final stream = endpoints.task.watchAnswer(sessionBuilder, question.id!);
        final firstEvent = stream.first.then((q) => q.answer);
        await flushEventQueue();

        await endpoints.task.answerQuestion(
          sessionBuilder,
          question.id!,
          'Option A',
        );

        await expectLater(firstEvent, completion('Option A'));
      },
    );

    test(
      'when a plan is approved then the decision is emitted on watchPlanDecision',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        await endpoints.task.setPlanReady(sessionBuilder, task.id!, 'Plan');

        final stream = endpoints.task.watchPlanDecision(
          sessionBuilder,
          task.id!,
        );
        final firstEvent = stream.first.then((t) => t.status);
        await flushEventQueue();

        await endpoints.task.approvePlan(sessionBuilder, task.id!);

        await expectLater(firstEvent, completion(TaskStatus.running));
      },
    );

    test(
      'when plan feedback is submitted then the decision is emitted on watchPlanDecision as planning',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        await endpoints.task.setPlanReady(sessionBuilder, task.id!, 'Plan');

        final stream = endpoints.task.watchPlanDecision(
          sessionBuilder,
          task.id!,
        );
        final firstEvent = stream.first.then((t) => t.status);
        await flushEventQueue();

        await endpoints.task.submitPlanFeedback(
          sessionBuilder,
          task.id!,
          'Reconsider',
        );

        await expectLater(firstEvent, completion(TaskStatus.planning));
      },
    );

    test(
      'when watching a plan decision for an already-planReady task then nothing is replayed until a new decision is made',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Do something',
          skipPlanning: false,
        );
        await endpoints.task.setPlanReady(sessionBuilder, task.id!, 'Plan');

        final stream = endpoints.task.watchPlanDecision(
          sessionBuilder,
          task.id!,
        );
        final events = <Task>[];
        final subscription = stream.listen(events.add);
        await flushEventQueue();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(events, isEmpty);
        await subscription.cancel();
      },
    );

    test(
      'when a log line is appended for a different task then it is not emitted',
      () async {
        final machine = await createMachine();
        final project = await createProject();
        final agent = await createAgent(machine);
        final watchedTask = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Watched',
          skipPlanning: true,
        );
        final otherTask = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'Other',
          skipPlanning: true,
        );

        final stream = endpoints.task.watchLogs(
          sessionBuilder,
          watchedTask.id!,
        );
        final entries = <TaskLogEntry>[];
        final subscription = stream.listen(entries.add);
        await flushEventQueue();

        await endpoints.task.appendLog(
          sessionBuilder,
          otherTask.id!,
          'for the other task',
          source: LogSource.agent,
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(entries, isEmpty);
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
}
