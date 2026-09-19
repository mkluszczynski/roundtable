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
  }, rollbackDatabase: RollbackDatabase.disabled);
}
