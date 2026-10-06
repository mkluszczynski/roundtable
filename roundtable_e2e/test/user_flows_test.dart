@Timeout(Duration(minutes: 8))
library;

import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_e2e/roundtable_e2e.dart';
import 'package:test/test.dart';

/// Whole user flows through the real server and runner (docs/DEVELOPMENT.md
/// "E2E tests"). Each test starts its own stack with its own fake agents.
void main() {
  E2EHarness? e2e;

  Future<E2EHarness> start(Map<String, Object?> scenario) async =>
      e2e = await E2EHarness.start(scenario: scenario);

  tearDown(() async {
    await e2e?.stop();
    e2e = null;
  });

  test('plan, approve, execute, review the PR and merge it', () async {
    final e2e = await start({
      'title': 'Add a greeting',
      'plan': '1. Create greeting.txt with a friendly hello.',
      'runs': [
        {
          'files': {'greeting.txt': 'Hello, world!\n'},
          'result': 'Created greeting.txt.',
        },
      ],
    });
    final seeded = await e2e.seed();

    final created = await e2e.client.task.createTask(
      seeded.project.id!,
      seeded.developer.id!,
      'Add a greeting file',
      skipPlanning: false,
    );

    // The agent plans first and waits for the developer's approval.
    final planned = await e2e.waitForStatus(created.id!, TaskStatus.planReady);
    expect(planned.currentPlan, contains('greeting.txt'));
    expect(planned.title, 'Add a greeting');
    expect(e2e.github.pullRequests, isEmpty);

    await e2e.client.task.approvePlan(created.id!);
    final ready = await e2e.waitForStatus(
      created.id!,
      TaskStatus.awaitingReview,
    );
    expect(ready.prUrl, isNotNull);
    expect(
      e2e.claudeRuns.single.args,
      containsAllInOrder(['--permission-mode', 'plan']),
    );

    final merged = await e2e.client.task.acceptTask(created.id!, force: false);
    expect(merged.status, TaskStatus.done);
    expect(e2e.github.pullRequests.single.merged, isTrue);
    expect(
      await e2e.github.fileOn('acme', 'demo', 'main', 'greeting.txt'),
      'Hello, world!\n',
    );
  });

  test('auto review finds a blocker, auto fix repairs it, the re-review '
      'confirms the fix and auto merge lands it', () async {
    final e2e = await start({
      'runs': [
        {
          'files': {'divide.txt': 'divide(a, b) = a / b\n'},
          'result': 'Added divide.',
        },
        {
          'files': {'divide.txt': 'divide(a, b) = b == 0 ? null : a / b\n'},
          'result': 'Guarded against division by zero.',
        },
      ],
      'reviews': [
        {
          'verdict': 'changes_requested',
          'summary': 'Division by zero crashes.',
          'comments': [
            {
              'path': 'divide.txt',
              'line': 1,
              'severity': 'blocker',
              'body': 'Guard against b == 0.',
            },
          ],
        },
        {
          'verdict': 'approve',
          'summary': 'The guard is in place.',
          'fixPrevious': true,
        },
      ],
    });
    final seeded = await e2e.seed();

    final created = await e2e.client.task.createTask(
      seeded.project.id!,
      seeded.developer.id!,
      'Add a divide function',
      skipPlanning: true,
      autoReview: true,
      reviewerAgentId: seeded.reviewer.id!,
      autoFixReview: true,
      autoMerge: true,
    );

    final done = await e2e.waitForStatus(
      created.id!,
      TaskStatus.done,
      timeout: const Duration(minutes: 4),
    );
    expect(done.reviewFixRounds, 1);

    final reviews = await e2e.reviews(created.id!);
    expect(reviews.map((r) => r.verdict), [
      CodeReviewVerdict.changesRequested,
      CodeReviewVerdict.approve,
    ]);
    final blocker = reviews.first.comments!.single;
    expect(blocker.severity, ReviewCommentSeverity.blocker);
    expect(
      blocker.state,
      ReviewCommentState.resolved,
      reason: 'the re-review confirmed the fix',
    );
    expect(
      await e2e.github.fileOn('acme', 'demo', 'main', 'divide.txt'),
      'divide(a, b) = b == 0 ? null : a / b\n',
    );
    // The developer ran twice (task + fix), the reviewer twice.
    expect(e2e.claudeRuns, hasLength(4));
  });

  test('an agent works on one task at a time, and a waiting task can be '
      'cancelled', () async {
    final e2e = await start({
      'runs': [
        {
          'files': {'one.txt': '1\n'},
          'result': 'One.',
          'sleepMs': 3000,
        },
        {
          'files': {'two.txt': '2\n'},
          'result': 'Two.',
        },
      ],
    });
    final seeded = await e2e.seed();
    Future<Task> create(String prompt) => e2e.client.task.createTask(
      seeded.project.id!,
      seeded.developer.id!,
      prompt,
      skipPlanning: true,
    );

    final first = await create('First');
    final second = await create('Second');
    final third = await create('Third');

    // The second waits for the first; cancel the third while it waits.
    await e2e.waitFor(
      'the first run to start',
      () async => e2e.claudeRuns.isEmpty ? null : true,
    );
    await e2e.client.task.cancelTask(third.id!);

    await e2e.waitForStatus(first.id!, TaskStatus.awaitingReview);
    await e2e.waitForStatus(second.id!, TaskStatus.awaitingReview);

    final runs = e2e.claudeRuns;
    expect(runs, hasLength(2), reason: 'the cancelled task never ran');
    expect(
      runs[1].start,
      greaterThanOrEqualTo(runs[0].end!),
      reason: 'the second run started after the first ended',
    );
    expect((await e2e.task(third.id!)).status, TaskStatus.draft);
    expect(e2e.github.pullRequests, hasLength(2));
  });
}
