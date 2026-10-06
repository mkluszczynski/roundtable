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
  test('commentableLines lists added and context lines of the new file', () {
    const patch =
        '@@ -1,3 +1,4 @@\n'
        ' a\n'
        '-b\n'
        '+B\n'
        '+c\n'
        ' d\n'
        '@@ -20,2 +21,2 @@\n'
        ' x\n'
        '\\ No newline at end of file';
    expect(commentableLines(patch), {1, 2, 3, 4, 21});
    expect(commentableLines(null), isEmpty);
  });

  withServerpod('Given CodeReview endpoint', (sessionBuilder, endpoints) {
    late List<http.Request> githubRequests;
    late http.Response Function(http.Request) githubHandler;

    setUp(() {
      githubRequests = [];
      githubHandler = (_) => http.Response('{}', 200);
      gitHubRepoClient = GitHubRepoClient(
        httpClient: MockClient((request) async {
          githubRequests.add(request);
          return githubHandler(request);
        }),
      );
    });

    tearDown(() => gitHubRepoClient = GitHubRepoClient());

    Future<({Task task, Agent author, Agent reviewer})> seed({
      String? token,
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
          repoAccessToken: token,
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
          claudeSessionId: 'session-1',
          branchName: 'task-1',
          prUrl: _prUrl,
          finishedAt: DateTime.now().toUtc(),
        ),
      );
      return (task: task, author: author, reviewer: reviewer);
    }

    Future<CodeReview> completedReview(Task task, Agent reviewer) async {
      final review = await endpoints.codeReview.requestReview(
        sessionBuilder,
        task.id!,
        reviewer.id!,
      );
      await endpoints.codeReview.startReview(sessionBuilder, review.id!);
      return endpoints.codeReview.completeReview(
        sessionBuilder,
        review.id!,
        'Two problems.',
        [
          ReviewCommentDraft(
            path: 'lib/a.dart',
            line: 3,
            body: 'Crash on null',
            severity: ReviewCommentSeverity.blocker,
          ),
          ReviewCommentDraft(
            path: 'lib/b.dart',
            body: 'Missing test',
            severity: ReviewCommentSeverity.issue,
          ),
        ],
      );
    }

    group('auto fix', () {
      Future<CodeReview> reviewWith(
        Task task,
        Agent reviewer,
        List<ReviewCommentDraft> drafts,
      ) async {
        final review = await endpoints.codeReview.requestReview(
          sessionBuilder,
          task.id!,
          reviewer.id!,
        );
        await endpoints.codeReview.startReview(sessionBuilder, review.id!);
        return endpoints.codeReview.completeReview(
          sessionBuilder,
          review.id!,
          'Findings.',
          drafts,
        );
      }

      Future<List<TaskFeedback>> feedbackOf(Task task) => TaskFeedback.db.find(
        sessionBuilder.build(),
        where: (f) => f.taskId.equals(task.id!),
      );

      Future<Task> withAutoFix(
        Task task, {
        int maxRounds = 2,
        int rounds = 0,
      }) => Task.db.updateRow(
        sessionBuilder.build(),
        task.copyWith(
          autoFixReview: true,
          maxReviewFixRounds: maxRounds,
          reviewFixRounds: rounds,
        ),
      );

      final mixed = [
        ReviewCommentDraft(
          path: 'lib/a.dart',
          line: 3,
          body: 'Crash on null',
          severity: ReviewCommentSeverity.blocker,
        ),
        ReviewCommentDraft(
          path: 'lib/b.dart',
          body: 'Rename this',
          severity: ReviewCommentSeverity.nit,
        ),
      ];

      test('when a review completes then its blockers and issues go to the '
          'agent and nits stay open', () async {
        final seeded = await seed();
        final task = await withAutoFix(seeded.task);

        await reviewWith(task, seeded.reviewer, mixed);

        final feedback = await feedbackOf(task);
        expect(feedback, hasLength(1));
        expect(feedback.single.message, contains('Crash on null'));
        expect(feedback.single.message, isNot(contains('Rename this')));
        final comments = await ReviewComment.db.find(
          sessionBuilder.build(),
          orderBy: (c) => c.id,
        );
        expect(comments.map((c) => c.state), [
          ReviewCommentState.sentToFix,
          ReviewCommentState.open,
        ]);
        final updated = await Task.db.findById(
          sessionBuilder.build(),
          task.id!,
        );
        expect(updated!.reviewFixRounds, 1);
      });

      test('when auto fix is off then nothing is sent', () async {
        final seeded = await seed();

        await reviewWith(seeded.task, seeded.reviewer, mixed);

        expect(await feedbackOf(seeded.task), isEmpty);
      });

      test('when the round limit is reached then nothing is sent', () async {
        final seeded = await seed();
        final task = await withAutoFix(seeded.task, maxRounds: 2, rounds: 2);

        await reviewWith(task, seeded.reviewer, mixed);

        expect(await feedbackOf(task), isEmpty);
        final events = await TaskLogEntry.db.find(
          sessionBuilder.build(),
          where: (e) => e.taskId.equals(task.id!),
        );
        expect(
          events.map((e) => e.content),
          contains(contains('Auto fix stopped after 2 rounds')),
        );
      });
    });

    group('auto review', () {
      Future<Task> finishRun(Task task) async {
        final session = sessionBuilder.build();
        final running = await Task.db.updateRow(
          session,
          task.copyWith(status: TaskStatus.running),
        );
        return endpoints.task.update(
          sessionBuilder,
          running.copyWith(status: TaskStatus.awaitingReview),
        );
      }

      Future<List<CodeReview>> reviewsOf(Task task) => CodeReview.db.find(
        sessionBuilder.build(),
        where: (r) => r.taskId.equals(task.id!),
      );

      test(
        'when a run ends awaiting review then the reviewer is queued',
        () async {
          final seeded = await seed();
          final task = await Task.db.updateRow(
            sessionBuilder.build(),
            seeded.task.copyWith(
              autoReview: true,
              reviewerAgentId: seeded.reviewer.id,
            ),
          );

          await finishRun(task);

          final reviews = await reviewsOf(task);
          expect(reviews, hasLength(1));
          expect(reviews.single.reviewerAgentId, seeded.reviewer.id);
          expect(reviews.single.status, CodeReviewStatus.queued);
        },
      );

      test('when auto review is off then no review is queued', () async {
        final seeded = await seed();
        final task = await Task.db.updateRow(
          sessionBuilder.build(),
          seeded.task.copyWith(reviewerAgentId: seeded.reviewer.id),
        );

        await finishRun(task);

        expect(await reviewsOf(task), isEmpty);
      });

      test('when no reviewer is set then the run still finishes and the '
          'skip is logged', () async {
        final seeded = await seed();
        final task = await Task.db.updateRow(
          sessionBuilder.build(),
          seeded.task.copyWith(autoReview: true),
        );

        final updated = await finishRun(task);

        expect(updated.status, TaskStatus.awaitingReview);
        expect(await reviewsOf(task), isEmpty);
        final events = await TaskLogEntry.db.find(
          sessionBuilder.build(),
          where: (e) => e.taskId.equals(task.id!),
        );
        expect(
          events.map((e) => e.content),
          contains(contains('Auto review skipped')),
        );
      });
    });

    test(
      'when the task is not awaiting review then requesting one throws',
      () async {
        final seeded = await seed();
        await Task.db.updateRow(
          sessionBuilder.build(),
          seeded.task.copyWith(status: TaskStatus.running),
        );

        await expectLater(
          endpoints.codeReview.requestReview(
            sessionBuilder,
            seeded.task.id!,
            seeded.reviewer.id!,
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'when a review runs then the reviewer is busy until it completes',
      () async {
        final seeded = await seed();
        final review = await endpoints.codeReview.requestReview(
          sessionBuilder,
          seeded.task.id!,
          seeded.reviewer.id!,
        );
        expect(review.status, CodeReviewStatus.queued);

        final task = await endpoints.codeReview.startReview(
          sessionBuilder,
          review.id!,
        );
        expect(task.branchName, 'task-1');
        var reviewer = await Agent.db.findById(
          sessionBuilder.build(),
          seeded.reviewer.id!,
        );
        expect(reviewer!.status, AgentStatus.busy);

        await expectLater(
          endpoints.codeReview.requestReview(
            sessionBuilder,
            seeded.task.id!,
            seeded.author.id!,
          ),
          throwsA(isA<Exception>()),
        );

        final completed = await endpoints.codeReview.completeReview(
          sessionBuilder,
          review.id!,
          'LGTM',
          [],
          verdict: CodeReviewVerdict.approve,
        );
        expect(completed.status, CodeReviewStatus.completed);
        expect(completed.verdict, CodeReviewVerdict.approve);
        expect(completed.summary, 'LGTM');
        reviewer = await Agent.db.findById(
          sessionBuilder.build(),
          seeded.reviewer.id!,
        );
        expect(reviewer!.status, AgentStatus.idle);
      },
    );

    group('when a later review checks earlier comments', () {
      test('then fixed ones are resolved and the rest carried over', () async {
        final seeded = await seed();
        final first = await completedReview(seeded.task, seeded.reviewer);
        final session = sessionBuilder.build();
        var earlier = await ReviewComment.db.find(
          session,
          where: (c) => c.reviewId.equals(first.id!),
          orderBy: (c) => c.id,
        );
        final blocker = earlier[0];
        final issue = earlier[1];

        final second = await endpoints.codeReview.requestReview(
          sessionBuilder,
          seeded.task.id!,
          seeded.reviewer.id!,
        );
        await endpoints.codeReview.startReview(sessionBuilder, second.id!);
        final previous = await endpoints.codeReview.previousComments(
          sessionBuilder,
          second.id!,
        );
        expect(previous.map((c) => c.id), [blocker.id, issue.id]);

        await endpoints.codeReview.completeReview(
          sessionBuilder,
          second.id!,
          'One left.',
          [
            ReviewCommentDraft(
              path: 'lib/c.dart',
              body: 'New problem',
              severity: ReviewCommentSeverity.nit,
            ),
          ],
          checks: [
            ReviewCommentCheck(commentId: blocker.id!, fixed: true),
            ReviewCommentCheck(
              commentId: issue.id!,
              fixed: false,
              note: 'Still no test for b',
            ),
            ReviewCommentCheck(commentId: 999999, fixed: true),
          ],
        );

        earlier = await ReviewComment.db.find(
          session,
          where: (c) => c.reviewId.equals(first.id!),
          orderBy: (c) => c.id,
        );
        expect(earlier.map((c) => c.state), [
          ReviewCommentState.resolved,
          ReviewCommentState.superseded,
        ]);
        final latest = await ReviewComment.db.find(
          session,
          where: (c) => c.reviewId.equals(second.id!),
          orderBy: (c) => c.id,
        );
        expect(latest, hasLength(2));
        expect(latest[0].carriedOverFromId, issue.id);
        expect(latest[0].body, 'Still no test for b');
        expect(latest[0].severity, ReviewCommentSeverity.issue);
        expect(latest[0].state, ReviewCommentState.open);
        expect(latest[1].body, 'New problem');

        final third = await endpoints.codeReview.requestReview(
          sessionBuilder,
          seeded.task.id!,
          seeded.reviewer.id!,
        );
        final next = await endpoints.codeReview.previousComments(
          sessionBuilder,
          third.id!,
        );
        expect(
          next.map((c) => c.id),
          isNot(contains(issue.id)),
          reason: 'a superseded comment is represented by its copy',
        );
      });

      test('then a dismissed comment is never reopened', () async {
        final seeded = await seed();
        final first = await completedReview(seeded.task, seeded.reviewer);
        final session = sessionBuilder.build();
        final dismissed = (await ReviewComment.db.find(
          session,
          where: (c) => c.reviewId.equals(first.id!),
          orderBy: (c) => c.id,
        )).first;
        await endpoints.codeReview.setCommentState(
          sessionBuilder,
          dismissed.id!,
          ReviewCommentState.dismissed,
        );

        final second = await endpoints.codeReview.requestReview(
          sessionBuilder,
          seeded.task.id!,
          seeded.reviewer.id!,
        );
        await endpoints.codeReview.startReview(sessionBuilder, second.id!);
        await endpoints.codeReview.completeReview(
          sessionBuilder,
          second.id!,
          'LGTM',
          [],
          checks: [ReviewCommentCheck(commentId: dismissed.id!, fixed: false)],
        );

        final after = await ReviewComment.db.findById(session, dismissed.id!);
        expect(after!.state, ReviewCommentState.dismissed);
        expect(
          await ReviewComment.db.count(
            session,
            where: (c) => c.reviewId.equals(second.id!),
          ),
          0,
        );
      });
    });

    group('when the reviewer also works on its own task', () {
      Future<(Agent reviewer, CodeReview review)> reviewWhile(
        TaskStatus ownTaskStatus,
      ) async {
        final seeded = await seed();
        final session = sessionBuilder.build();
        final review = await endpoints.codeReview.requestReview(
          sessionBuilder,
          seeded.task.id!,
          seeded.reviewer.id!,
        );
        await endpoints.codeReview.startReview(sessionBuilder, review.id!);
        await Task.db.insertRow(
          session,
          Task(
            projectId: seeded.task.projectId,
            agentId: seeded.reviewer.id!,
            prompt: 'Own work',
            status: ownTaskStatus,
          ),
        );
        return (seeded.reviewer, review);
      }

      Future<AgentStatus> statusOf(Agent agent) async =>
          (await Agent.db.findById(sessionBuilder.build(), agent.id!))!.status;

      test('then finishing the review keeps it busy', () async {
        final (reviewer, review) = await reviewWhile(TaskStatus.running);
        await endpoints.codeReview.completeReview(
          sessionBuilder,
          review.id!,
          'LGTM',
          [],
        );
        expect(await statusOf(reviewer), AgentStatus.busy);
      });

      test('then a failed review keeps it waiting for an answer', () async {
        final (reviewer, review) = await reviewWhile(
          TaskStatus.waitingForAnswer,
        );
        await endpoints.codeReview.failReview(
          sessionBuilder,
          review.id!,
          'no JSON',
        );
        expect(await statusOf(reviewer), AgentStatus.waitingForResponse);
      });

      test(
        'then its task finishing keeps it busy until the review ends',
        () async {
          final (reviewer, review) = await reviewWhile(
            TaskStatus.awaitingReview,
          );
          await endpoints.agent.setStatus(
            sessionBuilder,
            reviewer.id!,
            AgentStatus.idle,
          );
          expect(await statusOf(reviewer), AgentStatus.busy);

          await endpoints.codeReview.completeReview(
            sessionBuilder,
            review.id!,
            'LGTM',
            [],
          );
          expect(await statusOf(reviewer), AgentStatus.idle);
        },
      );
    });

    test(
      'when the project has no token then comments are kept locally only',
      () async {
        final seeded = await seed();
        final review = await completedReview(seeded.task, seeded.reviewer);

        expect(review.comments, hasLength(2));
        expect(review.githubReviewId, isNull);
        expect(githubRequests, isEmpty);
      },
    );

    test(
      'when completing then comments on diff lines are mirrored inline',
      () async {
        final seeded = await seed(token: 'secret');
        githubHandler = (request) {
          final path = request.url.path;
          if (path.endsWith('/files')) {
            return http.Response(
              jsonEncode([
                {
                  'filename': 'lib/a.dart',
                  'status': 'modified',
                  'additions': 1,
                  'deletions': 0,
                  'patch': '@@ -1,2 +1,3 @@\n a\n b\n+c',
                  'contents_url':
                      'https://api.github.com/repos/example/roundtable/contents/lib/a.dart',
                },
              ]),
              200,
            );
          }
          if (path.endsWith('/reviews') && request.method == 'POST') {
            return http.Response(jsonEncode({'id': 99}), 200);
          }
          if (path.endsWith('/reviews/99/comments')) {
            return http.Response(
              jsonEncode([
                {'id': 501},
              ]),
              200,
            );
          }
          // PR head lookups made while waiting for GitHub to catch up.
          return http.Response('{}', 404);
        };

        final review = await completedReview(seeded.task, seeded.reviewer);

        expect(review.githubReviewId, 99);
        final post = githubRequests.firstWhere(
          (r) => r.method == 'POST' && r.url.path.endsWith('/reviews'),
        );
        final body = jsonDecode(post.body) as Map<String, dynamic>;
        expect(body['comments'], hasLength(1));
        expect(body['body'], contains('lib/b.dart'));
        final a = review.comments!.firstWhere((c) => c.path == 'lib/a.dart');
        final b = review.comments!.firstWhere((c) => c.path == 'lib/b.dart');
        expect(a.githubCommentId, 501);
        expect(b.githubCommentId, isNull);
      },
    );

    test(
      'when comments are sent to fix and the run finishes then they are resolved',
      () async {
        final seeded = await seed();
        final review = await completedReview(seeded.task, seeded.reviewer);
        final blocker = review.comments!.firstWhere(
          (c) => c.severity == ReviewCommentSeverity.blocker,
        );

        final feedback = await endpoints.codeReview.sendCommentsToFix(
          sessionBuilder,
          seeded.task.id!,
          [blocker.id!],
          'Please fix this first.',
        );
        expect(feedback.phase, TaskFeedbackPhase.review);
        expect(feedback.message, startsWith('Please fix this first.'));
        expect(feedback.message, contains('lib/a.dart:3 [blocker] Crash'));
        expect(feedback.message, isNot(contains('lib/b.dart')));

        var stored = await ReviewComment.db.findById(
          sessionBuilder.build(),
          blocker.id!,
        );
        expect(stored!.state, ReviewCommentState.sentToFix);

        // The daemon picks the feedback up and finishes the fix run.
        var task = (await Task.db.findById(
          sessionBuilder.build(),
          seeded.task.id!,
        ))!;
        task = await endpoints.task.update(
          sessionBuilder,
          task.copyWith(status: TaskStatus.running),
        );
        await endpoints.task.update(
          sessionBuilder,
          task.copyWith(status: TaskStatus.awaitingReview),
        );

        stored = await ReviewComment.db.findById(
          sessionBuilder.build(),
          blocker.id!,
        );
        expect(stored!.state, ReviewCommentState.resolved);
        final other = await ReviewComment.db.findFirstRow(
          sessionBuilder.build(),
          where: (c) => c.path.equals('lib/b.dart'),
        );
        expect(other!.state, ReviewCommentState.open);
      },
    );

    test('when a comment is dismissed then it can be reopened', () async {
      final seeded = await seed();
      final review = await completedReview(seeded.task, seeded.reviewer);
      final comment = review.comments!.first;

      var updated = await endpoints.codeReview.setCommentState(
        sessionBuilder,
        comment.id!,
        ReviewCommentState.dismissed,
      );
      expect(updated.state, ReviewCommentState.dismissed);
      updated = await endpoints.codeReview.setCommentState(
        sessionBuilder,
        comment.id!,
        ReviewCommentState.open,
      );
      expect(updated.state, ReviewCommentState.open);
    });

    test('when accepting then the PR is merged and the task is done', () async {
      final seeded = await seed(token: 'secret');
      githubHandler = (request) =>
          fakeCiResponse(request) ??
          http.Response(jsonEncode({'merged': true}), 200);

      final task = await endpoints.task.acceptTask(
        sessionBuilder,
        seeded.task.id!,
        force: false,
      );

      expect(task.status, TaskStatus.done);
      final merge = githubRequests.where((r) => r.method == 'PUT').single;
      expect(merge.url.path, '/repos/example/roundtable/pulls/5/merge');
      // Only the commit whose checks passed may be merged.
      expect(jsonDecode(merge.body)['sha'], 'abc1234def');
    });

    test(
      'when GitHub refuses the merge then the task stays in review',
      () async {
        final seeded = await seed(token: 'secret');
        githubHandler = (request) => request.method == 'PUT'
            ? http.Response(
                jsonEncode({'message': 'Pull Request is not mergeable'}),
                405,
              )
            : fakeCiResponse(request) ?? http.Response('{}', 200);

        await expectLater(
          endpoints.task.acceptTask(
            sessionBuilder,
            seeded.task.id!,
            force: false,
          ),
          throwsA(
            predicate((e) => e.toString().contains('not mergeable')),
          ),
        );
        final task = await Task.db.findById(
          sessionBuilder.build(),
          seeded.task.id!,
        );
        expect(task!.status, TaskStatus.awaitingReview);
      },
    );

    test('when a review is in progress then accepting throws', () async {
      final seeded = await seed(token: 'secret');
      await endpoints.codeReview.requestReview(
        sessionBuilder,
        seeded.task.id!,
        seeded.reviewer.id!,
      );

      await expectLater(
        () => endpoints.task.acceptTask(
          sessionBuilder,
          seeded.task.id!,
          force: false,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
