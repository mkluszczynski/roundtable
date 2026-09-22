import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/app_card.dart';

void main() {
  testWidgets('renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppCard(child: Text('content'))),
    );

    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AppCard(
          onTap: () => tapped = true,
          child: const Text('content'),
        ),
      ),
    );

    await tester.tap(find.byType(AppCard));
    expect(tapped, isTrue);
  });

  testWidgets('is not tappable without onTap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppCard(child: Text('content'))),
    );

    expect(find.byType(InkWell), findsNothing);
  });
}
