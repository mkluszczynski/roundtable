import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Machine endpoint', (sessionBuilder, endpoints) {
    test(
      'when creating a machine then it is persisted as offline',
      () async {
        final machine = await endpoints.machine.create(sessionBuilder, 'VPS');

        expect(machine.id, isNotNull);
        expect(machine.name, 'VPS');
        expect(machine.status, MachineStatus.offline);
      },
    );

    test('when getting a machine by id then it is returned', () async {
      final created = await endpoints.machine.create(sessionBuilder, 'VPS');

      final fetched = await endpoints.machine.get(sessionBuilder, created.id!);

      expect(fetched, isNotNull);
      expect(fetched!.id, created.id);
    });

    test(
      'when listing machines then all created machines are included',
      () async {
        final first = await endpoints.machine.create(sessionBuilder, 'VPS');
        final second = await endpoints.machine.create(sessionBuilder, 'Laptop');

        final machines = await endpoints.machine.list(sessionBuilder);

        expect(machines.map((m) => m.id), containsAll([first.id, second.id]));
      },
    );

    test('when updating a machine then the change is persisted', () async {
      final created = await endpoints.machine.create(sessionBuilder, 'VPS');

      await endpoints.machine.update(
        sessionBuilder,
        created.copyWith(name: 'Renamed'),
      );

      final fetched = await endpoints.machine.get(sessionBuilder, created.id!);
      expect(fetched!.name, 'Renamed');
    });

    test(
      'when deleting an offline machine with no tasks then it is removed',
      () async {
        final created = await endpoints.machine.create(sessionBuilder, 'VPS');

        await endpoints.machine.delete(sessionBuilder, created.id!);

        final fetched = await endpoints.machine.get(
          sessionBuilder,
          created.id!,
        );
        expect(fetched, isNull);
      },
    );

    test(
      'when deleting a machine whose status is online then it throws DeletionBlockedException',
      () async {
        final session = sessionBuilder.build();
        final created = await Machine.db.insertRow(
          session,
          Machine(name: 'VPS', status: MachineStatus.online),
        );

        await expectLater(
          endpoints.machine.delete(sessionBuilder, created.id!),
          throwsA(isA<DeletionBlockedException>()),
        );
      },
    );

    test(
      'when deleting an offline machine with an agent that has a non-terminal task then it throws DeletionBlockedException',
      () async {
        final session = sessionBuilder.build();
        final machine = await Machine.db.insertRow(
          session,
          Machine(name: 'VPS', status: MachineStatus.offline),
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
        await Task.db.insertRow(
          session,
          Task(
            projectId: project.id!,
            agentId: agent.id,
            prompt: 'Do something',
            status: TaskStatus.running,
          ),
        );

        await expectLater(
          endpoints.machine.delete(sessionBuilder, machine.id!),
          throwsA(isA<DeletionBlockedException>()),
        );
      },
    );

    test(
      'when deleting an offline machine whose agent only has terminal tasks '
      'then, once that agent is removed, the machine can be deleted too',
      () async {
        final session = sessionBuilder.build();
        final machine = await Machine.db.insertRow(
          session,
          Machine(name: 'VPS', status: MachineStatus.offline),
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
        await Task.db.insertRow(
          session,
          Task(
            projectId: project.id!,
            agentId: agent.id,
            prompt: 'Do something',
            status: TaskStatus.done,
          ),
        );

        // The agent's tasks are all terminal, so its own guard doesn't
        // block deletion; the machine's foreign key is what requires
        // agents to be removed before the machine itself can go.
        await endpoints.agent.delete(sessionBuilder, agent.id!);
        await endpoints.machine.delete(sessionBuilder, machine.id!);

        final fetched = await endpoints.machine.get(
          sessionBuilder,
          machine.id!,
        );
        expect(fetched, isNull);
      },
    );
  });
}
