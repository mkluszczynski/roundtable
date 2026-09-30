import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/claude_warning_banner.dart';

void main() {
  testWidgets('shows the summary but not the message until tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClaudeWarningBanner(message: 'Set CLAUDE_EXECUTABLE...'),
        ),
      ),
    );

    expect(
      find.text('claude CLI cannot run on this machine — tasks will fail'),
      findsOneWidget,
    );
    expect(find.text('Set CLAUDE_EXECUTABLE...'), findsNothing);
  });

  testWidgets('tapping the banner reveals the full message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClaudeWarningBanner(message: 'Set CLAUDE_EXECUTABLE...'),
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(find.text('Set CLAUDE_EXECUTABLE...'), findsOneWidget);
  });
}
