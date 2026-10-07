import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/utils/task_timeline.dart';
import 'package:roundtable_flutter/widgets/task_timeline_view.dart';

void main() {
  testWidgets('shows each step with its detail and duration, and opens a '
      'linked one', (tester) async {
    final start = DateTime.now().subtract(const Duration(minutes: 10));
    final opened = <TimelineLink>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTimelineView(
            steps: [
              TimelineStep(
                label: 'Created',
                at: start,
                state: TimelineStepState.neutral,
              ),
              TimelineStep(
                label: 'AI review #1',
                detail: 'Changes requested',
                at: start,
                endedAt: start.add(const Duration(minutes: 2, seconds: 5)),
                state: TimelineStepState.warning,
                link: TimelineLink.review,
              ),
            ],
            onOpen: opened.add,
          ),
        ),
      ),
    );

    expect(find.text('Created'), findsOneWidget);
    expect(find.text('Changes requested · 2m 5s'), findsOneWidget);
    await tester.tap(find.text('Created'));
    await tester.tap(find.text('AI review #1'));
    expect(opened, [TimelineLink.review]);
  });
}
