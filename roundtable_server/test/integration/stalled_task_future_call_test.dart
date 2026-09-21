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
  });
}
