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

        final role = await AgentRoleDefinition.db.insertRow(
          sessionBuilder.build(),
          AgentRoleDefinition(name: 'backend', prompt: 'You are {name}.'),
        );

        final agent = await endpoints.agent.create(
          sessionBuilder,
          'Ana',
          machine.id!,
          roleId: role.id,
        );

        expect(agent.id, isNotNull);
        expect(agent.name, 'Ana');
        expect(agent.machineId, machine.id);
        expect(agent.roleId, role.id);
        final fetched = await endpoints.agent.get(sessionBuilder, agent.id!);
        expect(fetched!.role?.name, 'backend');
      },
    );

    test('when getting an agent by id then it is returned', () async {
      final machine = await createMachine();
      final created = await endpoints.agent.create(
        sessionBuilder,
        'Ana',
        machine.id!,
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
      );
      final second = await endpoints.agent.create(
        sessionBuilder,
        'Adam',
        machine.id!,
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

    test('when creating a docker-mode agent then the mode is saved', () async {
      final machine = await createMachine();

      final agent = await endpoints.agent.create(
        sessionBuilder,
        'Dex',
        machine.id!,
        executionMode: AgentExecutionMode.docker,
      );

      expect(agent.executionMode, AgentExecutionMode.docker);
    });

    test('when switching the execution mode of an idle agent then it is '
        'saved', () async {
      final machine = await createMachine();
      final agent = await endpoints.agent.create(
        sessionBuilder,
        'Dex',
        machine.id!,
      );

      final updated = await endpoints.agent.update(
        sessionBuilder,
        agent.copyWith(executionMode: AgentExecutionMode.docker),
      );

      expect(updated.executionMode, AgentExecutionMode.docker);
    });

    test('when switching the execution mode with an open task then it is '
        'rejected', () async {
      final machine = await createMachine();
      final agent = await endpoints.agent.create(
        sessionBuilder,
        'Dex',
        machine.id!,
      );
      final project = await Project.db.insertRow(
        sessionBuilder.build(),
        Project(name: 'p', repoUrl: 'https://github.com/a/b'),
      );
      await Task.db.insertRow(
        sessionBuilder.build(),
        Task(
          projectId: project.id!,
          agentId: agent.id,
          prompt: 'x',
          skipPlanning: true,
          status: TaskStatus.running,
        ),
      );

      await expectLater(
        endpoints.agent.update(
          sessionBuilder,
          agent.copyWith(executionMode: AgentExecutionMode.docker),
        ),
        throwsA(isA<InvalidStateException>()),
      );
    });

    test(
      'when an agent starts working then watchAgents emits its new status',
      () async {
        final machine = await createMachine();
        final role = await AgentRoleDefinition.db.insertRow(
          sessionBuilder.build(),
          AgentRoleDefinition(name: 'backend', prompt: 'You are {name}.'),
        );
        final agent = await endpoints.agent.create(
          sessionBuilder,
          'Ana',
          machine.id!,
          roleId: role.id,
        );

        final stream = endpoints.agent.watchAgents(sessionBuilder);
        // The replayed current row, then the status change.
        final events = stream.take(2).toList();
        await flushEventQueue();

        await endpoints.agent.setStatus(
          sessionBuilder,
          agent.id!,
          AgentStatus.busy,
        );

        final emitted = await events;
        expect(emitted.map((a) => a.status), [
          AgentStatus.idle,
          AgentStatus.busy,
        ]);
        expect(emitted.last.id, agent.id);
        expect(emitted.last.role?.name, 'backend');
      },
    );

    test(
      'when a status changes right after subscribing to watchAgents '
      'then the change is delivered',
      () async {
        final machine = await createMachine();
        final agent = await endpoints.agent.create(
          sessionBuilder,
          'Ana',
          machine.id!,
        );

        final stream = endpoints.agent.watchAgents(sessionBuilder);
        // No flushEventQueue: setStatus races the replay query. Whichever
        // row the replay reads, the posted change must follow it — before,
        // a post landing between the query and the channel subscription
        // was lost and only the replayed row arrived.
        final events = stream.take(2).toList();
        await endpoints.agent.setStatus(
          sessionBuilder,
          agent.id!,
          AgentStatus.busy,
        );

        final emitted = await events.timeout(const Duration(seconds: 10));
        expect(emitted.last.id, agent.id);
        expect(emitted.last.status, AgentStatus.busy);
      },
    );
  });
}
