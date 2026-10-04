import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roundtable_server/src/endpoints/task_endpoint.dart';
import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:roundtable_server/src/github_repo_client.dart';
import 'package:test/test.dart';

import 'github_ci_fixtures.dart';
import 'test_tools/serverpod_test_tools.dart';

const _prUrl = 'https://github.com/example/roundtable/pull/5';

void main() {
  withServerpod('Given a task whose PR conflicts with main', (
    sessionBuilder,
    endpoints,
  ) {
    late bool mergeable;

    setUp(() {
      mergeable = false;
      gitHubRepoClient = GitHubRepoClient(
        httpClient: MockClient((request) async {
          if (request.method == 'PUT') {
            return http.Response(
              jsonEncode({'message': 'Pull Request is not mergeable'}),
              405,
            );
          }
          if (request.url.path.contains('/actions/')) {
            return fakeCiResponse(request)!;
          }
          return http.Response(
            jsonEncode({
              'state': 'open',
              'head': {'sha': 'abc1234def'},
              'mergeable': mergeable,
              'mergeable_state': mergeable ? 'clean' : 'dirty',
              'base': {'ref': 'main'},
            }),
            200,
          );
        }),
      );
    });

    tearDown(() => gitHubRepoClient = GitHubRepoClient());

    Future<Task> seed({TaskStatus status = TaskStatus.awaitingReview}) async {
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
          status: status,
          claudeSessionId: 'session-1',
          branchName: 'task-1',
          prUrl: _prUrl,
          finishedAt: DateTime.now().toUtc(),
        ),
      );
    }

    test(
      'when fetching the merge status then conflicts are reported',
      () async {
        final task = await seed();
        final status = await endpoints.task.getMergeStatus(
          sessionBuilder,
          task.id!,
        );
        expect(status.hasConflicts, isTrue);
        expect(status.baseBranch, 'main');

        mergeable = true;
        final clean = await endpoints.task.getMergeStatus(
          sessionBuilder,
          task.id!,
        );
        expect(clean.hasConflicts, isFalse);
      },
    );

    test(
      'when resolving conflicts then a review feedback with the merge '
      'prompt is queued',
      () async {
        final task = await seed();
        final feedback = await endpoints.task.resolveConflicts(
          sessionBuilder,
          task.id!,
        );
        expect(feedback.phase, TaskFeedbackPhase.review);
        expect(feedback.message, TaskEndpoint.conflictResolutionPrompt('main'));
      },
    );

    test(
      'when the task is not awaiting review then resolving throws',
      () async {
        final task = await seed(status: TaskStatus.running);
        await expectLater(
          endpoints.task.resolveConflicts(sessionBuilder, task.id!),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'when accepting then a readable conflict error is thrown and the task '
      'stays in review',
      () async {
        final task = await seed();
        await expectLater(
          endpoints.task.acceptTask(sessionBuilder, task.id!),
          throwsA(
            predicate(
              (e) => e.toString().contains('merge conflicts with main'),
            ),
          ),
        );
        final reloaded = await Task.db.findById(
          sessionBuilder.build(),
          task.id!,
        );
        expect(reloaded!.status, TaskStatus.awaitingReview);
      },
    );
  });
}
