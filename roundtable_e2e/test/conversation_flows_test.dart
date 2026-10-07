@Timeout(Duration(minutes: 6))
library;

import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_e2e/roundtable_e2e.dart';
import 'package:test/test.dart';

/// The developer talking to an agent mid-task: rejecting a plan, giving
/// feedback on a PR, answering a question (docs/DEVELOPMENT.md "E2E tests").
void main() {
  E2EHarness? e2e;

  Future<E2EHarness> start(Map<String, Object?> scenario) async =>
      e2e = await E2EHarness.start(scenario: scenario);

  tearDown(() async {
    await e2e?.stop();
    e2e = null;
  });

  Future<Task> createTask(
    E2EHarness e2e,
    String prompt, {
    bool plan = true,
  }) async {
    final seeded = await e2e.seed();
    return e2e.client.task.createTask(
      seeded.project.id!,
      seeded.developer.id!,
      prompt,
      skipPlanning: !plan,
    );
  }

  test('a rejected plan comes back revised with the feedback', () async {
    final e2e = await start({
      'plan': '1. Write the greeting in English.',
      'runs': [
        {
          'files': {'greeting.txt': 'Cześć!\n'},
          'result': 'Greeting in Polish.',
        },
      ],
    });
    final task = await createTask(e2e, 'Add a greeting');

    final first = await e2e.waitForStatus(task.id!, TaskStatus.planReady);
    expect(first.currentPlan, contains('English'));

    await e2e.client.task.submitPlanFeedback(task.id!, 'Use Polish instead.');
    final revised = await e2e.waitFor('the revised plan', () async {
      final current = await e2e.task(task.id!);
      return current.status == TaskStatus.planReady &&
              (current.currentPlan ?? '').contains('Use Polish instead.')
          ? current
          : null;
    });
    expect(revised.currentPlan, contains('Revised after feedback'));

    await e2e.client.task.approvePlan(task.id!);
    await e2e.waitForStatus(task.id!, TaskStatus.awaitingReview);
    expect(
      await e2e.github.fileOn(
        'acme',
        'demo',
        'task-${task.id}',
        'greeting.txt',
      ),
      'Cześć!\n',
    );
    // Rejecting a plan stays in the same claude run.
    expect(e2e.claudeRuns, hasLength(1));
  });

  test(
    'feedback on a PR resumes the session and updates the same PR',
    () async {
      final e2e = await start({
        'runs': [
          {
            'files': {'greeting.txt': 'Hello\n'},
            'result': 'Added a greeting.',
          },
          {
            'files': {'greeting.txt': 'Hello, world!\n'},
            'result': 'Made it friendlier.',
          },
        ],
      });
      final task = await createTask(e2e, 'Add a greeting', plan: false);
      await e2e.waitForStatus(task.id!, TaskStatus.awaitingReview);

      await e2e.client.task.submitFeedback(task.id!, 'Greet the whole world.');
      await e2e.waitFor('the feedback run to finish', () async {
        final current = await e2e.task(task.id!);
        return e2e.claudeRuns.length == 2 &&
                e2e.claudeRuns.last.end != null &&
                current.status == TaskStatus.awaitingReview
            ? current
            : null;
      });

      final feedbackRun = e2e.claudeRuns.last;
      expect(feedbackRun.args, contains('--resume'));
      expect(
        feedbackRun.args[feedbackRun.args.indexOf('-p') + 1],
        contains('Greet the whole world.'),
      );
      expect(e2e.github.pullRequests, hasLength(1), reason: 'same PR');
      expect(
        await e2e.github.fileOn(
          'acme',
          'demo',
          'task-${task.id}',
          'greeting.txt',
        ),
        'Hello, world!\n',
      );
    },
  );

  test('a question from the agent waits for the answer, which shapes the '
      'plan', () async {
    final e2e = await start({
      'question': {
        'question': 'Which language should the greeting be in?',
        'options': ['English', 'Polish'],
      },
      'plan': '1. Write the greeting.',
      'runs': [
        {
          'files': {'greeting.txt': 'Cześć!\n'},
          'result': 'Greeting in Polish.',
        },
      ],
    });
    final task = await createTask(e2e, 'Add a greeting');

    await e2e.waitForStatus(task.id!, TaskStatus.waitingForAnswer);
    final question = (await e2e.client.task.latestQuestion(task.id!))!;
    expect(question.question, 'Which language should the greeting be in?');
    expect(question.options, ['English', 'Polish']);

    await e2e.client.task.answerQuestion(question.id!, 'Polish');
    final planned = await e2e.waitForStatus(task.id!, TaskStatus.planReady);
    expect(planned.currentPlan, contains('The developer chose: Polish'));

    await e2e.client.task.approvePlan(task.id!);
    await e2e.waitForStatus(task.id!, TaskStatus.awaitingReview);
  });
}
