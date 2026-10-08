import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  // Real transactions: the test's own rollback transaction would serialize
  // the two calls (and Serverpod refuses concurrent ones inside it). The
  // rows are removed afterwards instead.
  withServerpod(
    'Given a queued code review',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      late Machine machine;
      late Project project;

      tearDown(() async {
        final session = sessionBuilder.build();
        await CodeReview.db.deleteWhere(
          session,
          where: (r) => r.id.notEquals(null),
        );
        await Task.db.deleteWhere(
          session,
          where: (t) => t.projectId.equals(project.id!),
        );
        await Agent.db.deleteWhere(
          session,
          where: (a) => a.machineId.equals(machine.id!),
        );
        await Project.db.deleteRow(session, project);
        await Machine.db.deleteRow(session, machine);
      });

      test('starting it twice at once runs it once', () async {
        final session = sessionBuilder.build();
        machine = await Machine.db.insertRow(session, Machine(name: 'VPS'));
        project = await Project.db.insertRow(
          session,
          Project(
            name: 'Roundtable',
            repoUrl: 'https://github.com/example/roundtable',
          ),
        );
        final author = await Agent.db.insertRow(
          session,
          Agent(name: 'Ana', machineId: machine.id!),
        );
        final reviewer = await Agent.db.insertRow(
          session,
          Agent(name: 'Rex', machineId: machine.id!),
        );
        final task = await Task.db.insertRow(
          session,
          Task(
            projectId: project.id!,
            agentId: author.id!,
            prompt: 'Add login',
            status: TaskStatus.awaitingReview,
            branchName: 'task-1',
            prUrl: 'https://github.com/example/roundtable/pull/5',
          ),
        );
        final review = await endpoints.codeReview.requestReview(
          sessionBuilder,
          task.id!,
          reviewer.id!,
        );

        final results = await Future.wait([
          for (var i = 0; i < 2; i++)
            endpoints.codeReview
                .startReview(sessionBuilder, review.id!)
                .then<Object>((t) => t, onError: (Object e) => e),
        ]);

        expect(results.whereType<Task>(), hasLength(1));
        expect(results.whereType<InvalidStateException>(), hasLength(1));
      });
    },
  );
}
