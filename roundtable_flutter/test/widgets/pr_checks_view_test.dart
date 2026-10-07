import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/theme/colors.dart';
import 'package:roundtable_flutter/widgets/pr_checks_view.dart';

PrCheckRun _job(
  int jobId,
  String name, {
  String status = 'completed',
  String? conclusion = 'success',
  String? failedStep,
  int workflowRunId = 7,
  String workflowName = 'CI',
}) => PrCheckRun(
  id: jobId,
  taskId: 1,
  headSha: 'abc1234def',
  workflowRunId: workflowRunId,
  runAttempt: 1,
  workflowName: workflowName,
  jobId: jobId,
  jobName: name,
  status: status,
  conclusion: conclusion,
  failedStep: failedStep,
  htmlUrl: 'https://github.com/x/y/actions/runs/$workflowRunId/job/$jobId',
);

PrChecks _checks(PrCheckState state, List<PrCheckRun> runs) =>
    PrChecks(taskId: 1, headSha: 'abc1234def', state: state, runs: runs);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 800, height: 600, child: child)),
);

void main() {
  testWidgets('lists jobs grouped by workflow with the failed step', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PrChecksView(
          checks: _checks(PrCheckState.failure, [
            _job(1, 'unit', conclusion: 'failure', failedStep: 'Run tests'),
            _job(2, 'lint'),
            _job(3, 'e2e', workflowRunId: 8, workflowName: 'E2E'),
          ]),
        ),
      ),
    );

    expect(find.text('CI failed'), findsOneWidget);
    expect(find.text('abc1234'), findsOneWidget);
    expect(find.text('CI'), findsOneWidget);
    expect(find.text('e2e', findRichText: true), findsOneWidget);
    expect(find.text('unit', findRichText: true), findsOneWidget);
    expect(find.text('Failed at "Run tests"'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Passed'), findsNWidgets(2));
  });

  testWidgets('a workflow with one job named like it shows no header', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PrChecksView(
          checks: _checks(PrCheckState.success, [
            _job(1, 'analyze', workflowName: 'Analyze'),
          ]),
        ),
      ),
    );

    expect(find.text('ANALYZE'), findsNothing);
    expect(find.text('analyze', findRichText: true), findsOneWidget);
  });

  testWidgets('read-only without canSendToAgent', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrChecksView(
          checks: _checks(PrCheckState.failure, [
            _job(1, 'unit', conclusion: 'failure'),
          ]),
        ),
      ),
    );

    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('failing jobs can be ticked and sent with a note', (
    tester,
  ) async {
    final toggled = <int>[];
    final sent = <String>[];
    await tester.pumpWidget(
      _wrap(
        PrChecksView(
          checks: _checks(PrCheckState.failure, [
            _job(1, 'unit', conclusion: 'failure'),
            _job(2, 'lint'),
          ]),
          canSendToAgent: true,
          onToggleJob: toggled.add,
          onSendToAgent: sent.add,
        ),
      ),
    );

    // Only the failing job is selectable.
    expect(find.byType(Checkbox), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    expect(toggled, [1]);

    expect(find.text('Send 1 to agent'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Keep the API  ');
    await tester.tap(find.text('Send 1 to agent'));
    expect(sent, ['Keep the API']);
  });

  testWidgets('without failures there is nothing to send', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrChecksView(
          checks: _checks(PrCheckState.success, [_job(1, 'unit')]),
          canSendToAgent: true,
        ),
      ),
    );

    expect(find.text('CI passed'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('a new commit without workflows yet says so', (tester) async {
    await tester.pumpWidget(
      _wrap(PrChecksView(checks: _checks(PrCheckState.pending, const []))),
    );

    expect(
      find.text('Waiting for the workflows to start on the latest commit…'),
      findsOneWidget,
    );
  });

  testWidgets('warns that a running agent will restart the checks', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PrChecksView(
          checks: _checks(PrCheckState.pending, const []),
          agentWorking: true,
        ),
      ),
    );

    expect(find.textContaining('The agent is working'), findsOneWidget);
  });

  testWidgets('explains when the checks cannot be read', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrChecksView(
          checks: PrChecks(
            taskId: 1,
            headSha: 'abc1234def',
            state: PrCheckState.none,
            error: 'Forbidden — make sure the token has "Actions: read"',
            runs: const [],
          ),
        ),
      ),
    );

    expect(find.textContaining("can't be read"), findsOneWidget);
    expect(find.textContaining('Actions: Read'), findsWidgets);
  });

  test('check appearances follow the status colors', () {
    expect(
      checkStateAppearance(PrCheckState.failure).color,
      AppColors.red,
    );
    expect(checkStateAppearance(PrCheckState.success).color, AppColors.live);
    expect(checkStateAppearance(PrCheckState.pending).pulsing, isTrue);
    expect(
      checkRunAppearance(
        _job(1, 'x', status: 'in_progress', conclusion: null),
      ).color,
      AppColors.warning,
    );
    expect(checkRunAppearance(_job(1, 'x')).color, AppColors.live);
    expect(
      checkRunAppearance(_job(1, 'x', conclusion: 'timed_out')).color,
      AppColors.red,
    );
  });
}
