import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:roundtable_server/src/github_repo_client.dart';
import 'package:test/test.dart';

import 'github_ci_fixtures.dart';
import 'test_tools/serverpod_test_tools.dart';

const _prUrl = 'https://github.com/example/roundtable/pull/5';

void main() {
  withServerpod('Given a task in review with green checks', (
    sessionBuilder,
    endpoints,
  ) {
    late int merges;

    /// Runs while GitHub "merges", e.g. to write the task meanwhile.
    late Future<void> Function() duringMerge;

    setUp(() {
      merges = 0;
      duringMerge = () async {};
      gitHubRepoClient = GitHubRepoClient(
        httpClient: MockClient((request) async {
          if (request.method == 'PUT') {
            merges++;
            await duringMerge();
            // GitHub refuses to merge a PR twice.
            return merges == 1
                ? http.Response(jsonEncode({'merged': true}), 200)
                : http.Response(
                    jsonEncode({'message': 'Pull Request is not mergeable'}),
                    405,
                  );
          }
          return fakeCiResponse(request) ??
              http.Response(
                jsonEncode({
                  'state': 'open',
                  'head': {'sha': 'abc1234def'},
                  'mergeable': true,
                  'mergeable_state': 'clean',
                  'base': {'ref': 'main'},
                }),
                200,
              );
        }),
      );
    });

    tearDown(() => gitHubRepoClient = GitHubRepoClient());

    Future<Task> seed() async {
      final session = sessionBuilder.build();
      final machine = await Machine.db.insertRow(
        session,
        Machine(name: 'VPS'),
      );
      final project = await Project.db.insertRow(
        session,
        Project(
          name: 'Roundtable',
          repoUrl: 'https://github.com/example/roundtable',
          repoAccessToken: 'token',
        ),
      );
      final agent = await Agent.db.insertRow(
        session,
        Agent(name: 'Ana', machineId: machine.id!),
      );
      return Task.db.insertRow(
        session,
        Task(
          projectId: project.id!,
          agentId: agent.id!,
          prompt: 'Add login',
          status: TaskStatus.awaitingReview,
          branchName: 'task-1',
          prUrl: _prUrl,
          finishedAt: DateTime.now().toUtc(),
        ),
      );
    }

    test(
      'two merges at once merge once; the second is told it is done',
      () async {
        final task = await seed();
        duringMerge = () => Future<void>.delayed(
          const Duration(milliseconds: 100),
        );

        final first = endpoints.task.acceptTask(
          sessionBuilder,
          task.id!,
          force: false,
        );
        final second = endpoints.task.acceptTask(
          sessionBuilder,
          task.id!,
          force: false,
        );

        expect((await first).status, TaskStatus.done);
        await expectLater(second, throwsA(isA<InvalidStateException>()));
        expect(merges, 1);
      },
    );

    test("fields written while GitHub merges aren't lost", () async {
      final task = await seed();
      duringMerge = () async {
        final session = sessionBuilder.build();
        final current = (await Task.db.findById(session, task.id!))!;
        await Task.db.updateRow(
          session,
          current.copyWith(title: 'Login form'),
          columns: (t) => [t.title],
        );
      };

      await endpoints.task.acceptTask(sessionBuilder, task.id!, force: false);

      final stored = await Task.db.findById(
        sessionBuilder.build(),
        task.id!,
      );
      expect(stored!.status, TaskStatus.done);
      expect(stored.title, 'Login form');
    });
  });
}
