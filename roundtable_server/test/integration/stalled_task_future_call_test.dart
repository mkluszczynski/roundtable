import 'package:roundtable_server/src/future_calls/stalled_task_future_call.dart';
import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given StalledTaskFutureCall', (sessionBuilder, endpoints) {
    test(
      'when a non-terminal task has a stale lastProgressAt then it fails',
      () async {
        final session = sessionBuilder.build();
        final project = await Project.db.insertRow(
          session,
          Project(
            name: 'Roundtable',
            repoUrl: 'https://github.com/example/roundtable',
          ),
        );
        final task = await Task.db.insertRow(
          session,
          Task(
            projectId: project.id!,
            prompt: 'Do something',
            status: TaskStatus.running,
            lastProgressAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 20),
            ),
          ),
        );

        await StalledTaskFutureCall().check(session);

        final fetchedTask = await Task.db.findById(session, task.id!);
        expect(fetchedTask!.status, TaskStatus.failed);
        expect(
          fetchedTask.failureReason,
          'Task made no progress for over 15 minutes',
        );
        expect(fetchedTask.finishedAt, isNotNull);
      },
    );

    group('when a queued task waits for its turn', () {
      final stale = DateTime.now().toUtc().subtract(
        const Duration(minutes: 20),
      );

      Future<({Task waiting, Machine machine, Agent agent, int projectId})>
      seedQueued() async {
        final session = sessionBuilder.build();
        final project = await Project.db.insertRow(
          session,
          Project(name: 'R', repoUrl: 'https://github.com/example/r'),
        );
        final machine = await Machine.db.insertRow(
          session,
          Machine(name: 'VPS'),
        );
        final agent = await Agent.db.insertRow(
          session,
          Agent(name: 'Ana', machineId: machine.id!),
        );
        final waiting = await Task.db.insertRow(
          session,
          Task(
            projectId: project.id!,
            agentId: agent.id!,
            prompt: 'Next',
            status: TaskStatus.queued,
            lastProgressAt: stale,
          ),
        );
        return (
          waiting: waiting,
          machine: machine,
          agent: agent,
          projectId: project.id!,
        );
      }

      Future<TaskStatus> statusAfterCheck(Task task) async {
        final session = sessionBuilder.build();
        await StalledTaskFutureCall().check(session);
        return (await Task.db.findById(session, task.id!))!.status;
      }

      test('behind another task of its agent then it is kept', () async {
        final seeded = await seedQueued();
        await Task.db.insertRow(
          sessionBuilder.build(),
          Task(
            projectId: seeded.projectId,
            agentId: seeded.agent.id!,
            prompt: 'Long one',
            status: TaskStatus.running,
            lastProgressAt: DateTime.now().toUtc(),
          ),
        );
        expect(await statusAfterCheck(seeded.waiting), TaskStatus.queued);
      });

      test('while its machine is usage limited then it is kept', () async {
        final seeded = await seedQueued();
        await Machine.db.updateRow(
          sessionBuilder.build(),
          seeded.machine.copyWith(
            usageLimitedUntil: DateTime.now().toUtc().add(
              const Duration(hours: 2),
            ),
          ),
        );
        expect(await statusAfterCheck(seeded.waiting), TaskStatus.queued);
      });

      test('with nothing to wait for then it fails', () async {
        final seeded = await seedQueued();
        expect(await statusAfterCheck(seeded.waiting), TaskStatus.failed);
      });
    });

    test(
      'when a non-terminal task has a recent lastProgressAt then nothing '
      'changes',
      () async {
        final session = sessionBuilder.build();
        final project = await Project.db.insertRow(
          session,
          Project(
            name: 'Roundtable',
            repoUrl: 'https://github.com/example/roundtable',
          ),
        );
        final task = await Task.db.insertRow(
          session,
          Task(
            projectId: project.id!,
            prompt: 'Do something',
            status: TaskStatus.running,
            lastProgressAt: DateTime.now().toUtc(),
          ),
        );

        await StalledTaskFutureCall().check(session);

        final fetchedTask = await Task.db.findById(session, task.id!);
        expect(fetchedTask!.status, TaskStatus.running);
        expect(fetchedTask.failureReason, isNull);
      },
    );

    test(
      'when a terminal task has a stale lastProgressAt then it is left '
      'untouched',
      () async {
        final session = sessionBuilder.build();
        final project = await Project.db.insertRow(
          session,
          Project(
            name: 'Roundtable',
            repoUrl: 'https://github.com/example/roundtable',
          ),
        );
        final task = await Task.db.insertRow(
          session,
          Task(
            projectId: project.id!,
            prompt: 'Do something',
            status: TaskStatus.done,
            lastProgressAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 20),
            ),
          ),
        );

        await StalledTaskFutureCall().check(session);

        final fetchedTask = await Task.db.findById(session, task.id!);
        expect(fetchedTask!.status, TaskStatus.done);
        expect(fetchedTask.failureReason, isNull);
      },
    );

    test(
      'when a task belongs to an already-offline machine and has a stale '
      'lastProgressAt then it still fails, safely alongside '
      'MachineOfflineFutureCall',
      () async {
        final session = sessionBuilder.build();
        final machine = await Machine.db.insertRow(
          session,
          Machine(
            name: 'VPS',
            status: MachineStatus.offline,
            lastSeenAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 2),
            ),
          ),
        );
        final agent = await Agent.db.insertRow(
          session,
          Agent(name: 'Ana', machineId: machine.id!),
        );
        final project = await Project.db.insertRow(
          session,
          Project(
            name: 'Roundtable',
            repoUrl: 'https://github.com/example/roundtable',
          ),
        );
        final task = await Task.db.insertRow(
          session,
          Task(
            projectId: project.id!,
            agentId: agent.id,
            prompt: 'Do something',
            status: TaskStatus.running,
            lastProgressAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 20),
            ),
          ),
        );

        await StalledTaskFutureCall().check(session);

        final fetchedTask = await Task.db.findById(session, task.id!);
        expect(fetchedTask!.status, TaskStatus.failed);
        expect(
          fetchedTask.failureReason,
          'Task made no progress for over 15 minutes',
        );
      },
    );

    for (final status in [
      TaskStatus.waitingForAnswer,
      TaskStatus.planReady,
      TaskStatus.awaitingReview,
    ]) {
      test(
        'when a ${status.name} task has a stale lastProgressAt then it is '
        'left alone',
        () async {
          final session = sessionBuilder.build();
          final project = await Project.db.insertRow(
            session,
            Project(
              name: 'Roundtable',
              repoUrl: 'https://github.com/example/roundtable',
            ),
          );
          final task = await Task.db.insertRow(
            session,
            Task(
              projectId: project.id!,
              prompt: 'Do something',
              status: status,
              lastProgressAt: DateTime.now().toUtc().subtract(
                const Duration(hours: 2),
              ),
            ),
          );

          await StalledTaskFutureCall().check(session);

          final fetchedTask = await Task.db.findById(session, task.id!);
          expect(fetchedTask!.status, status);
        },
      );
    }
  });
}
