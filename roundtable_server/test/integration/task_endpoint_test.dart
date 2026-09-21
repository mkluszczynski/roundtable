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

    test('when cancelling a queued task then it is marked cancelled', () async {
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

      expect(cancelled.status, TaskStatus.cancelled);
      expect(cancelled.finishedAt, isNotNull);
    });

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
        await endpoints.task.update(
          sessionBuilder,
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
        await flushEventQueue();

        final created = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          agent.id!,
          'New task',
          skipPlanning: false,
        );

        await expectLater(
          stream.first.then((task) => task.id),
          completion(created.id),
        );
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
        await flushEventQueue();

        final appended = await endpoints.task.appendLog(
          sessionBuilder,
          task.id!,
          'live line',
          source: LogSource.agent,
        );

        await expectLater(
          stream.first.then((entry) => entry.id),
          completion(appended.id),
        );
      },
    );

    test(
      'when the watched task is cancelled then the cancellation is emitted on the stream',
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
        await flushEventQueue();

        await endpoints.task.cancelTask(sessionBuilder, task.id!);

        await expectLater(
          stream
              .firstWhere((t) => t.status == TaskStatus.cancelled)
              .then((t) => t.id),
          completion(task.id),
        );
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
        await flushEventQueue();

        await endpoints.task.answerQuestion(
          sessionBuilder,
          question.id!,
          'Option A',
        );

        await expectLater(
          stream.first.then((q) => q.answer),
          completion('Option A'),
        );
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
        await flushEventQueue();

        await endpoints.task.approvePlan(sessionBuilder, task.id!);

        await expectLater(
          stream.first.then((t) => t.status),
          completion(TaskStatus.running),
        );
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
        await flushEventQueue();

        await endpoints.task.submitPlanFeedback(
          sessionBuilder,
          task.id!,
          'Reconsider',
        );

        await expectLater(
          stream.first.then((t) => t.status),
          completion(TaskStatus.planning),
        );
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
