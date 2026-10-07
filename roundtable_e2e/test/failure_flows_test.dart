@Timeout(Duration(minutes: 8))
library;

import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_e2e/roundtable_e2e.dart';
import 'package:test/test.dart';

/// Things going wrong outside the code: the Claude usage limit and failing
/// CI (docs/DEVELOPMENT.md "E2E tests").
void main() {
  E2EHarness? e2e;

  Future<E2EHarness> start(Map<String, Object?> scenario) async =>
      e2e = await E2EHarness.start(scenario: scenario);

  tearDown(() async {
    await e2e?.stop();
    e2e = null;
  });

  test('a run stopped by the usage limit pauses the task, flags the machine '
      'and resumes the same session after the reset', () async {
    final e2e = await start({
      'runs': [
        {'usageLimit': true},
        {
          'files': {'greeting.txt': 'Hello\n'},
          'result': 'Added a greeting.',
        },
      ],
    });
    final seeded = await e2e.seed();
    final task = await e2e.client.task.createTask(
      seeded.project.id!,
      seeded.developer.id!,
      'Add a greeting',
      skipPlanning: true,
    );

    final paused = await e2e.waitForStatus(task.id!, TaskStatus.paused);
    expect(paused.pausedUntil!.isAfter(DateTime.now()), isTrue);
    expect(paused.pauseReason, contains('session limit'));
    final machine = await e2e.waitFor(
      'the machine to show the limit',
      () async => (await e2e.client.machine.list())
          .where((m) => m.usageLimitedUntil != null)
          .firstOrNull,
    );
    expect(machine.usageLimitedUntil!.isAfter(DateTime.now()), isTrue);

    // Resets within ~2 minutes (minute precision plus a minute of slack).
    await e2e.waitForStatus(
      task.id!,
      TaskStatus.awaitingReview,
      timeout: const Duration(minutes: 4),
    );
    final resumed = e2e.claudeRuns.last;
    expect(resumed.args, contains('--resume'));
    expect(
      await e2e.github.fileOn(
        'acme',
        'demo',
        'task-${task.id}',
        'greeting.txt',
      ),
      'Hello\n',
    );
  });

  test('failing CI is sent to the agent, its fix turns CI green and auto '
      'merge lands it', () async {
    final e2e = await start({
      'runs': [
        {
          'files': {'divide.txt': 'divide(a, b) = a / b\n'},
          'result': 'Added divide.',
        },
        {
          'files': {'divide.txt': 'divide(a, b) = b == 0 ? null : a / b\n'},
          'result': 'Fixed the division by zero.',
        },
      ],
    });
    // CI fails while divide() has no zero guard.
    e2e.github.ciFailure = (owner, repo, sha) async {
      final code = await e2e.github.fileOn(owner, repo, sha, 'divide.txt');
      return code != null && !code.contains('b == 0')
          ? 'test/divide_test: divide(1, 0) threw IntegerDivisionByZero'
          : null;
    };
    final seeded = await e2e.seed();
    final task = await e2e.client.task.createTask(
      seeded.project.id!,
      seeded.developer.id!,
      'Add a divide function',
      skipPlanning: true,
      autoFixFailingChecks: true,
      autoMerge: true,
    );

    final done = await e2e.waitForStatus(
      task.id!,
      TaskStatus.done,
      timeout: const Duration(minutes: 5),
    );
    expect(done.checkState, PrCheckState.success);

    final fixRun = e2e.claudeRuns.last;
    expect(
      fixRun.args[fixRun.args.indexOf('-p') + 1],
      contains('IntegerDivisionByZero'),
      reason: 'the agent got the failing job log',
    );
    expect(
      await e2e.github.fileOn('acme', 'demo', 'main', 'divide.txt'),
      'divide(a, b) = b == 0 ? null : a / b\n',
    );
  });
}
