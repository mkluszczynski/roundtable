import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/widgets/task_log_timeline.dart';

TaskLogEntry _e(String content, LogKind kind, {String run = 'r1'}) =>
    TaskLogEntry(
      taskId: 1,
      content: content,
      kind: kind,
      runId: run,
      phase: LogPhase.execution,
      toolName: kind == LogKind.toolCall ? 'Read' : null,
    );

Future<void> _pump(WidgetTester tester, List<TaskLogEntry> entries) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: TaskLogTimeline(entries: entries)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final entries = [
    _e('Ada started working', LogKind.runStarted, run: 'r1'),
    _e('First try.', LogKind.message, run: 'r1'),
    _e('Done in 1.0s', LogKind.runFinished, run: 'r1'),
    _e('Ada resumed with your feedback', LogKind.runStarted, run: 'r2'),
    _e('Read(/a.dart)', LogKind.toolCall, run: 'r2'),
    _e('Fixed it.', LogKind.message, run: 'r2'),
  ];

  testWidgets('shows runs with only the latest one expanded', (tester) async {
    await _pump(tester, entries);

    expect(find.text('Ada started working'), findsOneWidget);
    expect(find.text('Ada resumed with your feedback'), findsOneWidget);
    expect(find.text('First try.'), findsNothing);
    expect(find.text('Fixed it.'), findsOneWidget);
    expect(find.text('1 step'), findsOneWidget);

    await tester.tap(find.text('Ada started working'));
    await tester.pumpAndSettle();
    expect(find.text('First try.'), findsOneWidget);
  });

  testWidgets('the raw toggle shows the plain log', (tester) async {
    await _pump(tester, entries);

    await tester.tap(find.byTooltip('Show raw log'));
    await tester.pumpAndSettle();

    expect(find.text('1 step'), findsNothing);
    expect(find.byTooltip('Show timeline'), findsOneWidget);
  });

  testWidgets('expand all opens every run', (tester) async {
    await _pump(tester, entries);

    await tester.tap(find.text('Expand all'));
    await tester.pumpAndSettle();

    expect(find.text('First try.'), findsOneWidget);
    expect(find.text('Collapse all'), findsOneWidget);
  });
}
