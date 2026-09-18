import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Agent endpoint', (sessionBuilder, endpoints) {
    Future<Machine> createMachine() async {
      return Machine.db.insertRow(sessionBuilder.build(), Machine(name: 'VPS'));
    }

    test(
      'when creating an agent then it is persisted with the given fields',
      () async {
        final machine = await createMachine();

        final agent = await endpoints.agent.create(
          sessionBuilder,
          'Ana',
          machine.id!,
          role: AgentRole.generalist,
        );

        expect(agent.id, isNotNull);
        expect(agent.name, 'Ana');
        expect(agent.machineId, machine.id);
        expect(agent.role, AgentRole.generalist);
      },
    );

    test('when getting an agent by id then it is returned', () async {
      final machine = await createMachine();
      final created = await endpoints.agent.create(
        sessionBuilder,
        'Ana',
        machine.id!,
        role: AgentRole.generalist,
      );

      final fetched = await endpoints.agent.get(sessionBuilder, created.id!);

      expect(fetched, isNotNull);
      expect(fetched!.id, created.id);
    });

    test('when listing agents then all created agents are included', () async {
      final machine = await createMachine();
      final first = await endpoints.agent.create(
        sessionBuilder,
        'Ana',
        machine.id!,
        role: AgentRole.generalist,
      );
      final second = await endpoints.agent.create(
        sessionBuilder,
        'Adam',
        machine.id!,
        role: AgentRole.generalist,
      );

      final agents = await endpoints.agent.list(sessionBuilder);

      expect(agents.map((a) => a.id), containsAll([first.id, second.id]));
    });

    test('when updating an agent then the change is persisted', () async {
      final machine = await createMachine();
      final created = await endpoints.agent.create(
        sessionBuilder,
        'Ana',
        machine.id!,
        role: AgentRole.generalist,
      );

      await endpoints.agent.update(
        sessionBuilder,
        created.copyWith(name: 'Renamed'),
      );

      final fetched = await endpoints.agent.get(sessionBuilder, created.id!);
      expect(fetched!.name, 'Renamed');
    });

    test('when deleting an agent with no tasks then it is removed', () async {
      final machine = await createMachine();
      final created = await endpoints.agent.create(
        sessionBuilder,
        'Ana',
        machine.id!,
        role: AgentRole.generalist,
      );

      await endpoints.agent.delete(sessionBuilder, created.id!);

      final fetched = await endpoints.agent.get(sessionBuilder, created.id!);
      expect(fetched, isNull);
    });

    test(
      'when deleting an agent with a non-terminal task then it throws DeletionBlockedException',
      () async {
        final session = sessionBuilder.build();
        final machine = await createMachine();
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
            status: TaskStatus.planning,
          ),
        );

        await expectLater(
          endpoints.agent.delete(sessionBuilder, agent.id!),
          throwsA(isA<DeletionBlockedException>()),
        );
      },
    );

    test(
      'when deleting an agent whose tasks are all terminal then it is removed',
      () async {
        final session = sessionBuilder.build();
        final machine = await createMachine();
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
            status: TaskStatus.cancelled,
          ),
        );

        await endpoints.agent.delete(sessionBuilder, agent.id!);

        final fetched = await endpoints.agent.get(sessionBuilder, agent.id!);
        expect(fetched, isNull);
      },
    );
  });
}
