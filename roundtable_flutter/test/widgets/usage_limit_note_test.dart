import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/usage_limit_note.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  final now = DateTime(2026, 10, 7, 12);

  testWidgets('shows the reset time while the limit is active', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(UsageLimitNote(until: DateTime(2026, 10, 7, 15, 5), now: now)),
    );
    expect(find.text('Usage limit until 15:05'), findsOneWidget);
  });

  testWidgets('renders nothing once the limit has reset or without one', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(UsageLimitNote(until: DateTime(2026, 10, 7, 11), now: now)),
    );
    expect(find.textContaining('Usage limit'), findsNothing);

    await tester.pumpWidget(_wrap(UsageLimitNote(until: null, now: now)));
    expect(find.textContaining('Usage limit'), findsNothing);
  });
}
