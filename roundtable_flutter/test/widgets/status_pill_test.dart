import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/theme/colors.dart';
import 'package:roundtable_flutter/widgets/status_pill.dart';

void main() {
  testWidgets('renders the label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StatusPill(color: AppColors.live, label: 'Online'),
      ),
    );

    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('a static pill does not animate', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StatusPill(color: AppColors.text2, label: 'Idle'),
      ),
    );

    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('a pulsing pill animates its dot opacity', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StatusPill(color: AppColors.live, label: 'Busy', pulsing: true),
      ),
    );

    expect(find.byType(Opacity), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    final opacity1 = tester.widget<Opacity>(find.byType(Opacity)).opacity;
    await tester.pump(const Duration(milliseconds: 400));
    final opacity2 = tester.widget<Opacity>(find.byType(Opacity)).opacity;

    expect(opacity1, isNot(equals(opacity2)));
  });
}
