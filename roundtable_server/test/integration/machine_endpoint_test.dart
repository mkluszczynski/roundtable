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

    test('when the daemon reports a usage limit then it is stored', () async {
      final registration = await endpoints.machine.register(
        sessionBuilder,
        'VPS',
      );
      final until = DateTime.utc(2026, 10, 7, 15, 30);

      await endpoints.machine.reportUsageLimit(
        sessionBuilder,
        registration.token,
        until,
      );

      final machine = await Machine.db.findById(
        sessionBuilder.build(),
        registration.machine.id!,
      );
      expect(machine!.usageLimitedUntil, until);
    });

    test(
      'when checking in then the machine is marked online and its runner '
      'version is recorded',
      () async {
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'VPS',
        );

        final updateRequested = await endpoints.machine.checkIn(
          sessionBuilder,
          registration.token,
          'v1',
        );

        expect(updateRequested, isFalse);
        final fetched = await endpoints.machine.get(
          sessionBuilder,
          registration.machine.id!,
        );
        expect(fetched!.status, MachineStatus.online);
        expect(fetched.runnerVersion, 'v1');
      },
    );

    test(
      'when an update is requested then check-ins report it until the '
      'daemon comes back with a new version',
      () async {
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'VPS',
        );
        final id = registration.machine.id!;
        await endpoints.machine.checkIn(
          sessionBuilder,
          registration.token,
          'v1',
        );

        await endpoints.machine.requestRunnerUpdate(sessionBuilder, id);

        expect(
          await endpoints.machine.checkIn(
            sessionBuilder,
            registration.token,
            'v1',
          ),
          isTrue,
        );
        expect(
          await endpoints.machine.checkIn(
            sessionBuilder,
            registration.token,
            'v2',
          ),
          isFalse,
        );
        final fetched = await endpoints.machine.get(sessionBuilder, id);
        expect(fetched!.runnerVersion, 'v2');
        expect(fetched.updateRequestedAt, isNull);
      },
    );

    test(
      'when checking in with an unknown token then it throws '
      'InvalidTokenException',
      () async {
        await expectLater(
          endpoints.machine.checkIn(sessionBuilder, 'not-a-real-token', 'v1'),
          throwsA(isA<InvalidTokenException>()),
        );
      },
    );

    test(
      'when deregistering an online machine with a valid token then the '
      'machine is deleted and the token no longer works',
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
        expect(fetched, isNull);
        await expectLater(
          endpoints.machine.heartbeat(sessionBuilder, registration.token),
          throwsA(isA<InvalidTokenException>()),
        );
      },
    );

    test(
      'when deregistering a machine whose agent has an in-flight task then '
      'the task fails, keeps its history, and the machine is deleted',
      () async {
        final session = sessionBuilder.build();
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'VPS',
        );
        await endpoints.machine.heartbeat(sessionBuilder, registration.token);
        final agent = await Agent.db.insertRow(
          session,
          Agent(name: 'Ana', machineId: registration.machine.id!),
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

        await endpoints.machine.deregister(
          sessionBuilder,
          registration.token,
        );

        expect(
          await endpoints.machine.get(sessionBuilder, registration.machine.id!),
          isNull,
        );
        expect(await Agent.db.findById(session, agent.id!), isNull);
        final fetchedTask = await Task.db.findById(session, task.id!);
        expect(fetchedTask!.status, TaskStatus.failed);
        expect(fetchedTask.failureReason, contains('uninstalled'));
        expect(fetchedTask.agentId, isNull);
      },
    );

    test(
      'when deregistering a machine whose agent has a queued task then the '
      'machine is kept offline with its token revoked, and deleting it is '
      'blocked only by that task',
      () async {
        final session = sessionBuilder.build();
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'VPS',
        );
        await endpoints.machine.heartbeat(sessionBuilder, registration.token);
        final agent = await Agent.db.insertRow(
          session,
          Agent(name: 'Ana', machineId: registration.machine.id!),
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
            status: TaskStatus.queued,
          ),
        );

        await endpoints.machine.deregister(
          sessionBuilder,
          registration.token,
        );

        final fetched = await endpoints.machine.get(
          sessionBuilder,
          registration.machine.id!,
        );
        expect(fetched!.status, MachineStatus.offline);
        expect(fetched.tokenHash, isNull);
        expect(
          (await Task.db.findById(session, task.id!))!.status,
          TaskStatus.queued,
        );
        await expectLater(
          endpoints.machine.heartbeat(sessionBuilder, registration.token),
          throwsA(isA<InvalidTokenException>()),
        );
        await expectLater(
          endpoints.machine.delete(sessionBuilder, registration.machine.id!),
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
      'when deregistering a machine whose agent has a queued code review then '
      'the review fails instead of blocking its task forever, and the machine '
      'is deleted',
      () async {
        final session = sessionBuilder.build();
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'Reviewer VPS',
        );
        final reviewer = await Agent.db.insertRow(
          session,
          Agent(name: 'Rex', machineId: registration.machine.id!),
        );
        // The reviewed task belongs to an agent on another machine, so it
        // doesn't block deleting the reviewer's machine.
        final otherMachine = await Machine.db.insertRow(
          session,
          Machine(name: 'Laptop', status: MachineStatus.offline),
        );
        final author = await Agent.db.insertRow(
          session,
          Agent(name: 'Ana', machineId: otherMachine.id!),
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
            agentId: author.id,
            prompt: 'Do something',
            status: TaskStatus.awaitingReview,
          ),
        );
        final review = await CodeReview.db.insertRow(
          session,
          CodeReview(
            taskId: task.id!,
            reviewerAgentId: reviewer.id,
            status: CodeReviewStatus.queued,
          ),
        );

        await endpoints.machine.deregister(
          sessionBuilder,
          registration.token,
        );

        expect(
          await endpoints.machine.get(sessionBuilder, registration.machine.id!),
          isNull,
        );
        final fetchedReview = await CodeReview.db.findById(
          session,
          review.id!,
        );
        expect(fetchedReview!.status, CodeReviewStatus.failed);
        expect(fetchedReview.failureReason, contains('uninstalled'));
        expect(fetchedReview.reviewerAgentId, isNull);
        expect(
          (await Task.db.findById(session, task.id!))!.status,
          TaskStatus.awaitingReview,
        );
      },
    );

    test(
      'when deleting an offline machine whose agent has a queued code review '
      'then the review fails instead of being left without a reviewer',
      () async {
        final session = sessionBuilder.build();
        final machine = await Machine.db.insertRow(
          session,
          Machine(name: 'Reviewer VPS', status: MachineStatus.offline),
        );
        final reviewer = await Agent.db.insertRow(
          session,
          Agent(name: 'Rex', machineId: machine.id!),
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
            prompt: 'Do something',
            status: TaskStatus.awaitingReview,
          ),
        );
        final review = await CodeReview.db.insertRow(
          session,
          CodeReview(
            taskId: task.id!,
            reviewerAgentId: reviewer.id,
            status: CodeReviewStatus.queued,
          ),
        );

        await endpoints.machine.delete(sessionBuilder, machine.id!);

        expect(
          await endpoints.machine.get(sessionBuilder, machine.id!),
          isNull,
        );
        final fetchedReview = await CodeReview.db.findById(
          session,
          review.id!,
        );
        expect(fetchedReview!.status, CodeReviewStatus.failed);
        expect(fetchedReview.reviewerAgentId, isNull);
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

    test(
      'when reporting the OS version with a valid token then it is persisted '
      'on the machine',
      () async {
        final registration = await endpoints.machine.register(
          sessionBuilder,
          'VPS',
        );

        await endpoints.machine.reportOsVersion(
          sessionBuilder,
          registration.token,
          'Ubuntu 24.04',
        );

        final fetched = await endpoints.machine.get(
          sessionBuilder,
          registration.machine.id!,
        );
        expect(fetched!.osVersion, 'Ubuntu 24.04');
      },
    );

    test(
      'when reporting the OS version with an unknown token then it throws '
      'InvalidTokenException',
      () async {
        await expectLater(
          endpoints.machine.reportOsVersion(
            sessionBuilder,
            'not-a-real-token',
            'Ubuntu 24.04',
          ),
          throwsA(isA<InvalidTokenException>()),
        );
      },
    );
  });
}
