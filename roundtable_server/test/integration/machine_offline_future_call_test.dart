import 'package:roundtable_server/src/future_calls/machine_offline_future_call.dart';
import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given MachineOfflineFutureCall', (sessionBuilder, endpoints) {
    test(
      'when an online machine has a stale lastSeenAt and a non-terminal '
      'task then the machine goes offline and the task fails',
      () async {
        final session = sessionBuilder.build();
        final machine = await Machine.db.insertRow(
          session,
          Machine(
            name: 'VPS',
            status: MachineStatus.online,
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
          ),
        );

        await MachineOfflineFutureCall().check(session);

        final fetchedMachine = await Machine.db.findById(session, machine.id!);
        expect(fetchedMachine!.status, MachineStatus.offline);

        final fetchedTask = await Task.db.findById(session, task.id!);
        expect(fetchedTask!.status, TaskStatus.failed);
        expect(fetchedTask.failureReason, 'Machine went offline mid-task');
        expect(fetchedTask.finishedAt, isNotNull);
      },
    );

    test(
      'when an online machine has a recent lastSeenAt then nothing changes',
      () async {
        final session = sessionBuilder.build();
        final machine = await Machine.db.insertRow(
          session,
          Machine(
            name: 'VPS',
            status: MachineStatus.online,
            lastSeenAt: DateTime.now().toUtc(),
          ),
        );

        await MachineOfflineFutureCall().check(session);

        final fetchedMachine = await Machine.db.findById(session, machine.id!);
        expect(fetchedMachine!.status, MachineStatus.online);
      },
    );

    test(
      'when a stale machine has only terminal tasks then the machine goes '
      'offline but the task is left untouched',
      () async {
        final session = sessionBuilder.build();
        final machine = await Machine.db.insertRow(
          session,
          Machine(
            name: 'VPS',
            status: MachineStatus.online,
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
            status: TaskStatus.done,
          ),
        );

        await MachineOfflineFutureCall().check(session);

        final fetchedMachine = await Machine.db.findById(session, machine.id!);
        expect(fetchedMachine!.status, MachineStatus.offline);

        final fetchedTask = await Task.db.findById(session, task.id!);
        expect(fetchedTask!.status, TaskStatus.done);
        expect(fetchedTask.failureReason, isNull);
      },
    );

    test(
      'when a machine is already offline with a stale lastSeenAt then it is '
      'left alone',
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

        await MachineOfflineFutureCall().check(session);

        final fetchedMachine = await Machine.db.findById(session, machine.id!);
        expect(fetchedMachine!.status, MachineStatus.offline);
      },
    );
  });
}
