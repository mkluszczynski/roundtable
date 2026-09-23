import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Machine endpoint', (sessionBuilder, endpoints) {
    test(
      'when registering a machine then it is persisted as offline',
      () async {
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'VPS',
        );

        expect(registration.machine.id, isNotNull);
        expect(registration.machine.name, 'VPS');
        expect(registration.machine.status, MachineStatus.offline);
      },
    );

    test(
      'when registering a machine then a token is returned and the stored '
      'hash matches it',
      () async {
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'VPS',
        );

        expect(registration.token, isNotEmpty);
        expect(
          sha256.convert(utf8.encode(registration.token)).toString(),
          registration.machine.tokenHash,
        );
      },
    );

    test(
      'when registering a machine then the raw token itself is never '
      'persisted as tokenHash',
      () async {
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'VPS',
        );

        expect(registration.machine.tokenHash, isNot(registration.token));
      },
    );

    test(
      'when registering two machines then they get different tokens and '
      'hashes',
      () async {
        final first = await endpoints.machine.register(sessionBuilder, 'VPS');
        final second = await endpoints.machine.register(
          sessionBuilder,
          'Laptop',
        );

        expect(first.token, isNot(second.token));
        expect(first.machine.tokenHash, isNot(second.machine.tokenHash));
      },
    );

    test('when getting a machine by id then it is returned', () async {
      final created = await endpoints.machine.register(sessionBuilder, 'VPS');

      final fetched = await endpoints.machine.get(
        sessionBuilder,
        created.machine.id!,
      );

      expect(fetched, isNotNull);
      expect(fetched!.id, created.machine.id);
    });

    test(
      'when listing machines then all created machines are included',
      () async {
        final first = await endpoints.machine.register(sessionBuilder, 'VPS');
        final second = await endpoints.machine.register(
          sessionBuilder,
          'Laptop',
        );

        final machines = await endpoints.machine.list(sessionBuilder);

        expect(
          machines.map((m) => m.id),
          containsAll([first.machine.id, second.machine.id]),
        );
      },
    );

    test('when updating a machine then the change is persisted', () async {
      final created = await endpoints.machine.register(sessionBuilder, 'VPS');

      await endpoints.machine.update(
        sessionBuilder,
        created.machine.copyWith(name: 'Renamed'),
      );

      final fetched = await endpoints.machine.get(
        sessionBuilder,
        created.machine.id!,
      );
      expect(fetched!.name, 'Renamed');
    });

    test(
      'when deleting an offline machine with no tasks then it is removed',
      () async {
        final created = await endpoints.machine.register(sessionBuilder, 'VPS');

        await endpoints.machine.delete(sessionBuilder, created.machine.id!);

        final fetched = await endpoints.machine.get(
          sessionBuilder,
          created.machine.id!,
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
          throwsA(
            isA<DeletionBlockedException>().having(
              (e) => e.reason,
              'reason',
              DeletionBlockReason.machineOnline,
            ),
          ),
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
          throwsA(
            isA<DeletionBlockedException>().having(
              (e) => e.reason,
              'reason',
              DeletionBlockReason.nonTerminalTasks,
            ),
          ),
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

    test(
      'when sending a heartbeat with a valid token then the machine is '
      'marked online and lastSeenAt is refreshed',
      () async {
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'VPS',
        );

        await endpoints.machine.heartbeat(sessionBuilder, registration.token);

        final fetched = await endpoints.machine.get(
          sessionBuilder,
          registration.machine.id!,
        );
        expect(fetched!.status, MachineStatus.online);
        expect(fetched.lastSeenAt, isNotNull);
      },
    );

    test(
      'when sending a heartbeat with an unknown token then it throws '
      'InvalidTokenException',
      () async {
        await expectLater(
          endpoints.machine.heartbeat(sessionBuilder, 'not-a-real-token'),
          throwsA(isA<InvalidTokenException>()),
        );
      },
    );

    test(
      'when deregistering with a valid token then the machine is marked '
      'offline and the token is revoked',
      () async {
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'VPS',
        );
        await endpoints.machine.heartbeat(sessionBuilder, registration.token);

        await endpoints.machine.deregister(
          sessionBuilder,
          registration.token,
        );

        final fetched = await endpoints.machine.get(
          sessionBuilder,
          registration.machine.id!,
        );
        expect(fetched!.status, MachineStatus.offline);
        await expectLater(
          endpoints.machine.heartbeat(sessionBuilder, registration.token),
          throwsA(isA<InvalidTokenException>()),
        );
      },
    );

    test(
      'when deregistering with an unknown token then it throws '
      'InvalidTokenException',
      () async {
        await expectLater(
          endpoints.machine.deregister(sessionBuilder, 'not-a-real-token'),
          throwsA(isA<InvalidTokenException>()),
        );
      },
    );

    test(
      'when reporting a failing claude status with a valid token then it is '
      'persisted on the machine',
      () async {
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'VPS',
        );

        await endpoints.machine.reportClaudeStatus(
          sessionBuilder,
          registration.token,
          false,
          'Permission denied launching the claude CLI',
        );

        final fetched = await endpoints.machine.get(
          sessionBuilder,
          registration.machine.id!,
        );
        expect(fetched!.claudeExecutableOk, isFalse);
        expect(
          fetched.claudeExecutableError,
          'Permission denied launching the claude CLI',
        );
      },
    );

    test(
      'when reporting a successful claude status then a previous error is '
      'cleared',
      () async {
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'VPS',
        );
        await endpoints.machine.reportClaudeStatus(
          sessionBuilder,
          registration.token,
          false,
          'some earlier error',
        );

        await endpoints.machine.reportClaudeStatus(
          sessionBuilder,
          registration.token,
          true,
          null,
        );

        final fetched = await endpoints.machine.get(
          sessionBuilder,
          registration.machine.id!,
        );
        expect(fetched!.claudeExecutableOk, isTrue);
        expect(fetched.claudeExecutableError, isNull);
      },
    );

    test(
      'when reporting a claude status with an unknown token then it throws '
      'InvalidTokenException',
      () async {
        await expectLater(
          endpoints.machine.reportClaudeStatus(
            sessionBuilder,
            'not-a-real-token',
            false,
            'irrelevant',
          ),
          throwsA(isA<InvalidTokenException>()),
        );
      },
    );
  });
}
