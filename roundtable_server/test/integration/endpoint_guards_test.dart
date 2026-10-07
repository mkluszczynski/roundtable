import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'enroll_machine.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Guards on the generic `update` endpoints, typed exceptions, and the
/// daemon's startup report.
void main() {
  withServerpod('Given endpoint guards', (sessionBuilder, endpoints) {
    Future<Machine> createMachine() =>
        Machine.db.insertRow(sessionBuilder.build(), Machine(name: 'VPS'));

    Future<Project> createProject() => Project.db.insertRow(
      sessionBuilder.build(),
      Project(name: 'Roundtable', repoUrl: 'https://github.com/example/rt'),
    );

    Future<Agent> createAgent(Machine machine) => Agent.db.insertRow(
      sessionBuilder.build(),
      Agent(name: 'Ana', machineId: machine.id!),
    );

    Future<Task> createTask(Agent agent, Project project, TaskStatus status) =>
        Task.db.insertRow(
          sessionBuilder.build(),
          Task(
            projectId: project.id!,
            agentId: agent.id,
            prompt: 'Do something',
            status: status,
          ),
        );

    group('task update', () {
      test('when the daemon reports a run outcome then it is stored', () async {
        final task = await createTask(
          await createAgent(await createMachine()),
          await createProject(),
          TaskStatus.running,
        );

        final updated = await endpoints.task.update(
          sessionBuilder,
          task.copyWith(
            status: TaskStatus.awaitingReview,
            prUrl: 'https://github.com/example/rt/pull/1',
          ),
        );

        expect(updated.status, TaskStatus.awaitingReview);
        expect(updated.prUrl, 'https://github.com/example/rt/pull/1');
      });

      test('when it tries to set done on a task with code then the status '
          'is kept', () async {
        final task = await createTask(
          await createAgent(await createMachine()),
          await createProject(),
          TaskStatus.awaitingReview,
        );

        // A branch means there is code to review: only acceptTask may
        // finish it.
        final updated = await endpoints.task.update(
          sessionBuilder,
          task.copyWith(
            status: TaskStatus.done,
            branchName: 'roundtable/task-${task.id}',
          ),
        );

        expect(updated.status, TaskStatus.awaitingReview);
      });

      test(
        'when the task was already cancelled then a late daemon write is '
        'ignored',
        () async {
          final task = await createTask(
            await createAgent(await createMachine()),
            await createProject(),
            TaskStatus.cancelled,
          );

          final updated = await endpoints.task.update(
            sessionBuilder,
            task.copyWith(
              status: TaskStatus.awaitingReview,
              prUrl: 'https://github.com/example/rt/pull/1',
            ),
          );

          expect(updated.status, TaskStatus.cancelled);
          expect(updated.prUrl, isNull);
        },
      );

      test(
        'when the task was cancelled back to a draft then a late daemon '
        'write is ignored',
        () async {
          final task = await createTask(
            await createAgent(await createMachine()),
            await createProject(),
            TaskStatus.running,
          );
          await endpoints.task.cancelTask(sessionBuilder, task.id!);

          final updated = await endpoints.task.update(
            sessionBuilder,
            task.copyWith(status: TaskStatus.failed, failureReason: 'killed'),
          );

          expect(updated.status, TaskStatus.draft);
          expect(updated.failureReason, isNull);
        },
      );
    });

    group('generic updates', () {
      test('when updating an agent then its status is not touched', () async {
        final agent = await createAgent(await createMachine());
        await endpoints.agent.setStatus(
          sessionBuilder,
          agent.id!,
          AgentStatus.busy,
        );

        final updated = await endpoints.agent.update(
          sessionBuilder,
          agent.copyWith(name: 'Bea', status: AgentStatus.idle),
        );

        expect(updated.name, 'Bea');
        final fetched = await Agent.db.findById(
          sessionBuilder.build(),
          agent.id!,
        );
        expect(fetched!.name, 'Bea');
        expect(fetched.status, AgentStatus.busy);
      });

      test('when updating a machine then its token hash is kept', () async {
        final registration = await enrollMachine(
          sessionBuilder,
          endpoints,
          'VPS',
        );
        final machine = (await Machine.db.findById(
          sessionBuilder.build(),
          registration.machine.id!,
        ))!;

        await endpoints.machine.update(
          sessionBuilder,
          machine.copyWith(name: 'Laptop', tokenHash: 'forged'),
        );

        final fetched = await Machine.db.findById(
          sessionBuilder.build(),
          machine.id!,
        );
        expect(fetched!.name, 'Laptop');
        expect(fetched.tokenHash, machine.tokenHash);
      });

      test('when updating a project then its access token is kept', () async {
        final project = await endpoints.project.create(
          sessionBuilder,
          'Roundtable',
          'https://github.com/example/rt',
          repoAccessToken: 'secret',
        );

        await endpoints.project.update(
          sessionBuilder,
          project.copyWith(name: 'Renamed', repoAccessToken: 'forged'),
        );

        final fetched = await Project.db.findById(
          sessionBuilder.build(),
          project.id!,
        );
        expect(fetched!.name, 'Renamed');
        expect(fetched.repoAccessToken, 'secret');
      });
    });

    group('typed exceptions', () {
      test('when creating a task for an unknown project then it throws '
          'NotFoundException', () async {
        await expectLater(
          endpoints.task.createTask(
            sessionBuilder,
            999999,
            null,
            'x',
            skipPlanning: false,
          ),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('when creating an agent on an unknown machine then it throws '
          'NotFoundException', () async {
        await expectLater(
          endpoints.agent.create(
            sessionBuilder,
            'Ana',
            999999,
          ),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('when approving a plan in the wrong state then it throws '
          'InvalidStateException', () async {
        final task = await createTask(
          await createAgent(await createMachine()),
          await createProject(),
          TaskStatus.running,
        );
        await expectLater(
          endpoints.task.approvePlan(sessionBuilder, task.id!),
          throwsA(isA<InvalidStateException>()),
        );
      });
    });

    group('reportStartup', () {
      test(
        'when the daemon restarts then its in-flight tasks and reviews fail, '
        'queued ones stay, and its agents go idle',
        () async {
          final registration = await enrollMachine(
            sessionBuilder,
            endpoints,
            'VPS',
          );
          final agent = await Agent.db.insertRow(
            sessionBuilder.build(),
            Agent(
              name: 'Ana',
              machineId: registration.machine.id!,
              status: AgentStatus.waitingForResponse,
            ),
          );
          final project = await createProject();
          final waiting = await createTask(
            agent,
            project,
            TaskStatus.waitingForAnswer,
          );
          final queued = await createTask(agent, project, TaskStatus.queued);
          final reviewed = await createTask(
            agent,
            project,
            TaskStatus.awaitingReview,
          );
          final review = await CodeReview.db.insertRow(
            sessionBuilder.build(),
            CodeReview(
              taskId: reviewed.id!,
              reviewerAgentId: agent.id,
              status: CodeReviewStatus.running,
            ),
          );

          await endpoints.machine.reportStartup(
            sessionBuilder,
            registration.token,
          );

          final session = sessionBuilder.build();
          final fetchedWaiting = await Task.db.findById(session, waiting.id!);
          expect(fetchedWaiting!.status, TaskStatus.failed);
          expect(fetchedWaiting.failureReason, contains('restarted'));
          expect(
            (await Task.db.findById(session, queued.id!))!.status,
            TaskStatus.queued,
          );
          expect(
            (await Task.db.findById(session, reviewed.id!))!.status,
            TaskStatus.awaitingReview,
          );
          expect(
            (await CodeReview.db.findById(session, review.id!))!.status,
            CodeReviewStatus.failed,
          );
          expect(
            (await Agent.db.findById(session, agent.id!))!.status,
            AgentStatus.idle,
          );
        },
      );

      test('when the token is unknown then it throws', () async {
        await expectLater(
          endpoints.machine.reportStartup(sessionBuilder, 'nope'),
          throwsA(isA<InvalidTokenException>()),
        );
      });
    });
  });
}
