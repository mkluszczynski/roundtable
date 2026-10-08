import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/plan_content.dart';

void main() {
  testWidgets('renders markdown as formatted text, not raw syntax', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlanContent(
          markdown:
              '# Add login flow\n\n'
              'This introduces **OAuth** support.\n\n'
              '- Add the client\n'
              '- Wire up the callback',
        ),
      ),
    );

    expect(find.text('Add login flow'), findsOneWidget);
    expect(find.text('Add the client'), findsOneWidget);
    expect(find.text('Wire up the callback'), findsOneWidget);

    expect(find.textContaining('# Add login flow'), findsNothing);
    expect(find.textContaining('**OAuth**'), findsNothing);
    expect(find.textContaining('- Add the client'), findsNothing);
  });

  testWidgets("an image in the plan isn't fetched, only its alt text shown", (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlanContent(markdown: 'Plan ![diagram](https://evil.test/x.png)'),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('[diagram]'), findsOneWidget);
  });
}
