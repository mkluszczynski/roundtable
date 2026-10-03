import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/load_failed_view.dart';

void main() {
  testWidgets('shows the message and retries', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoadFailedView(
            title: "Couldn't load this project",
            message: 'Connection refused',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text("Couldn't load this project"), findsOneWidget);
    expect(find.text('Connection refused'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('without onRetry only offers going back', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadFailedView(title: 'Project not found', message: 'Gone.'),
        ),
      ),
    );

    expect(find.text('Retry'), findsNothing);
    expect(find.text('Back'), findsOneWidget);
  });
}
