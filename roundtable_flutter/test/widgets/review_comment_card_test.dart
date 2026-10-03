import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/widgets/review_comment_card.dart';

ReviewComment _comment({
  ReviewCommentState state = ReviewCommentState.open,
  int? line = 12,
}) => ReviewComment(
  id: 1,
  reviewId: 1,
  path: 'lib/main.dart',
  line: line,
  body: 'Null check is missing',
  severity: ReviewCommentSeverity.blocker,
  state: state,
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders severity, location and body', (tester) async {
    await tester.pumpWidget(_wrap(ReviewCommentCard(comment: _comment())));

    expect(find.text('blocker'), findsOneWidget);
    expect(find.text('lib/main.dart:12'), findsOneWidget);
    expect(find.text('Null check is missing'), findsOneWidget);
  });

  testWidgets('hides the location when inline', (tester) async {
    await tester.pumpWidget(
      _wrap(ReviewCommentCard(comment: _comment(), showLocation: false)),
    );

    expect(find.text('lib/main.dart:12'), findsNothing);
  });

  testWidgets('read-only without callbacks', (tester) async {
    await tester.pumpWidget(_wrap(ReviewCommentCard(comment: _comment())));

    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('an open comment can be selected, dismissed and resolved', (
    tester,
  ) async {
    var toggled = 0;
    final states = <ReviewCommentState>[];
    await tester.pumpWidget(
      _wrap(
        ReviewCommentCard(
          comment: _comment(),
          onToggleSelected: () => toggled++,
          onStateChanged: states.add,
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.byTooltip('Dismiss'));
    await tester.tap(find.byTooltip('Mark resolved'));

    expect(toggled, 1);
    expect(states, [ReviewCommentState.dismissed, ReviewCommentState.resolved]);
  });

  testWidgets('a dismissed comment shows its state and can be reopened', (
    tester,
  ) async {
    final states = <ReviewCommentState>[];
    await tester.pumpWidget(
      _wrap(
        ReviewCommentCard(
          comment: _comment(state: ReviewCommentState.dismissed),
          onToggleSelected: () {},
          onStateChanged: states.add,
        ),
      ),
    );

    expect(find.text('Dismissed'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    await tester.tap(find.byTooltip('Reopen'));
    expect(states, [ReviewCommentState.open]);
  });

  testWidgets('a comment sent to the agent has no controls', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ReviewCommentCard(
          comment: _comment(state: ReviewCommentState.sentToFix),
          onToggleSelected: () {},
          onStateChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Sent to agent'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });
}
