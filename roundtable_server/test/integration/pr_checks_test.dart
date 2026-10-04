import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roundtable_server/src/future_calls/pr_checks_future_call.dart';
import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:roundtable_server/src/github_repo_client.dart';
import 'package:test/test.dart';

import 'github_ci_fixtures.dart';
import 'test_tools/serverpod_test_tools.dart';

const _prUrl = 'https://github.com/example/roundtable/pull/5';

void main() {
  withServerpod('Given a task in review with GitHub Actions on its PR', (
    sessionBuilder,
    endpoints,
  ) {
    late List<http.Request> githubRequests;
    late String headSha;
    late String? conclusion;
    late bool noWorkflows;

    setUp(() {
      githubRequests = [];
      headSha = 'abc1234def';
      conclusion = 'success';
      noWorkflows = false;
      gitHubRepoClient = GitHubRepoClient(
        httpClient: MockClient((request) async {
          githubRequests.add(request);
          if (request.method == 'PUT') {
            return http.Response(jsonEncode({'merged': true}), 200);
          }
          return fakeCiResponse(
                request,
                headSha: headSha,
                conclusion: conclusion,
                noWorkflows: noWorkflows,
              ) ??
              http.Response('{}', 404);
        }),
      );
    });

    tearDown(() => gitHubRepoClient = GitHubRepoClient());

    Future<Task> seed({
      bool autoFix = false,
      int maxAttempts = 2,
      TaskStatus status = TaskStatus.awaitingReview,
    }) async {
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
          autoFixFailingChecks: autoFix,
          maxCheckFixAttempts: maxAttempts,
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

    Future<Task> reload(Task task) async =>
        (await Task.db.findById(sessionBuilder.build(), task.id!))!;

    Future<List<TaskFeedback>> feedbackOf(Task task) => TaskFeedback.db.find(
      sessionBuilder.build(),
      where: (f) => f.taskId.equals(task.id!),
    );

    test('when the poll runs then the jobs and the state are stored', () async {
      final task = await seed();
      conclusion = 'failure';

      await PrChecksFutureCall().check(sessionBuilder.build());

      final stored = await reload(task);
      expect(stored.prHeadSha, 'abc1234def');
      expect(stored.checkState, PrCheckState.failure);
      final checks = await endpoints.task.getChecks(sessionBuilder, task.id!);
      expect(checks.state, PrCheckState.failure);
      expect(checks.runs, hasLength(1));
      expect(checks.runs.single.jobName, 'test');
      expect(checks.runs.single.failedStep, 'Run tests');

      final events = await TaskLogEntry.db.find(
        sessionBuilder.build(),
        where: (e) => e.taskId.equals(task.id!),
      );
      expect(events.map((e) => e.content), contains('CI failed: CI / test'));
    });

    test('when nothing changed then finished runs are not fetched again', () async {
      final task = await seed();
      await endpoints.task.refreshChecks(sessionBuilder, task.id!);
      githubRequests.clear();

      await endpoints.task.refreshChecks(sessionBuilder, task.id!);

      expect(
        githubRequests.where((r) => r.url.path.endsWith('/jobs')),
        isEmpty,
      );
    });

    test(
      'when the PR gets a new commit then the old checks are replaced and '
      'the state is pending again',
      () async {
        final task = await seed();
        conclusion = 'failure';
        await endpoints.task.refreshChecks(sessionBuilder, task.id!);

        headSha = 'fff9999aaa';
        conclusion = null;
        final checks = await endpoints.task.refreshChecks(
          sessionBuilder,
          task.id!,
        );

        expect(checks.headSha, 'fff9999aaa');
        expect(checks.state, PrCheckState.pending);
        expect(checks.runs.map((r) => r.headSha), everyElement('fff9999aaa'));
        final events = await TaskLogEntry.db.find(
          sessionBuilder.build(),
          where: (e) => e.taskId.equals(task.id!),
        );
        expect(
          events.map((e) => e.content),
          contains('New commit fff9999 — CI checks restarted'),
        );
      },
    );

    test(
      'when failing checks are sent to fix then the feedback carries the '
      'job log and the checks go pending',
      () async {
        final task = await seed();
        conclusion = 'failure';
        await endpoints.task.refreshChecks(sessionBuilder, task.id!);

        final feedback = await endpoints.task.fixFailingChecks(
          sessionBuilder,
          task.id!,
          note: 'Keep the API unchanged',
        );

        expect(feedback.phase, TaskFeedbackPhase.review);
        expect(feedback.message, contains('CI / test'));
        expect(feedback.message, contains('Expected: 2, Actual: 3'));
        expect(feedback.message, contains('Keep the API unchanged'));
        final stored = await reload(task);
        expect(stored.checkState, PrCheckState.pending);
        expect(stored.checkFixAttempts, 1);
        expect(stored.checkFixSentForSha, 'abc1234def');
      },
    );

    test('when no check failed then sending them to fix throws', () async {
      final task = await seed();
      await endpoints.task.refreshChecks(sessionBuilder, task.id!);
      await expectLater(
        endpoints.task.fixFailingChecks(sessionBuilder, task.id!),
        throwsA(isA<InvalidStateException>()),
      );
    });

    test('when the task is not in review then sending to fix throws', () async {
      final task = await seed(status: TaskStatus.running);
      await expectLater(
        endpoints.task.fixFailingChecks(sessionBuilder, task.id!),
        throwsA(isA<InvalidStateException>()),
      );
    });

    test(
      'when auto-fix is on then a failure is sent once per commit, up to the '
      'attempt cap',
      () async {
        final task = await seed(autoFix: true, maxAttempts: 1);
        conclusion = 'failure';

        await PrChecksFutureCall().check(sessionBuilder.build());
        await PrChecksFutureCall().check(sessionBuilder.build());
        expect(await feedbackOf(task), hasLength(1));

        // The fix run pushed a commit that still fails: the cap is reached.
        headSha = 'fff9999aaa';
        await PrChecksFutureCall().check(sessionBuilder.build());
        expect(await feedbackOf(task), hasLength(1));
      },
    );

    test('when auto-fix is off then a failure is not sent', () async {
      final task = await seed();
      conclusion = 'failure';
      await PrChecksFutureCall().check(sessionBuilder.build());
      expect(await feedbackOf(task), isEmpty);
    });

    test('when the checks pass then the fix attempts are reset', () async {
      final task = await seed();
      await Task.db.updateRow(
        sessionBuilder.build(),
        task.copyWith(checkFixAttempts: 2),
      );
      await endpoints.task.refreshChecks(sessionBuilder, task.id!);
      expect((await reload(task)).checkFixAttempts, 0);
    });

    test('when the checks are failing then accepting is refused', () async {
      final task = await seed();
      conclusion = 'failure';
      await expectLater(
        endpoints.task.acceptTask(sessionBuilder, task.id!),
        throwsA(
          isA<InvalidStateException>().having(
            (e) => e.message,
            'message',
            contains('failing'),
          ),
        ),
      );
      expect(githubRequests.where((r) => r.method == 'PUT'), isEmpty);
      expect((await reload(task)).status, TaskStatus.awaitingReview);
    });

    test('when the checks are still running then accepting is refused', () async {
      final task = await seed();
      conclusion = null;
      await expectLater(
        endpoints.task.acceptTask(sessionBuilder, task.id!),
        throwsA(isA<InvalidStateException>()),
      );
      expect(githubRequests.where((r) => r.method == 'PUT'), isEmpty);
    });

    test(
      'when a new commit has no workflow yet then accepting waits for the '
      'grace period',
      () async {
        final task = await seed();
        noWorkflows = true;
        await expectLater(
          endpoints.task.acceptTask(sessionBuilder, task.id!),
          throwsA(isA<InvalidStateException>()),
        );

        // Two minutes later still no workflow: the repo has no CI.
        await Task.db.updateRow(
          sessionBuilder.build(),
          (await reload(task)).copyWith(
            prHeadSeenAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 3),
            ),
          ),
        );
        final accepted = await endpoints.task.acceptTask(
          sessionBuilder,
          task.id!,
        );
        expect(accepted.status, TaskStatus.done);
      },
    );

    test(
      'when the agent finishes a fix run then the checks are synced right '
      'away',
      () async {
        final task = await seed(status: TaskStatus.running);
        conclusion = null;

        await endpoints.task.update(
          sessionBuilder,
          task.copyWith(status: TaskStatus.awaitingReview),
        );

        final stored = await reload(task);
        expect(stored.prHeadSha, 'abc1234def');
        expect(stored.checkState, PrCheckState.pending);
      },
    );
  });
}
