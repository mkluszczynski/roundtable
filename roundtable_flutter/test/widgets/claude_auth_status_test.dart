import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/widgets/claude_token_dialog.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Machine machine, {
    bool compact = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ClaudeAuthStatus(machine: machine, compact: compact),
      ),
    ),
  );

  final machine = Machine(
    id: 1,
    name: 'vps',
    status: MachineStatus.online,
  );

  testWidgets('a machine without credentials asks for a token', (tester) async {
    await pump(
      tester,
      machine.copyWith(claudeAuthSource: ClaudeAuthSource.none),
    );

    expect(
      find.text('No Claude token — tasks on this machine will fail'),
      findsOneWidget,
    );
    expect(find.text('Set token'), findsOneWidget);
  });

  testWidgets('a token on its way says so', (tester) async {
    await pump(
      tester,
      machine.copyWith(
        claudeAuthSource: ClaudeAuthSource.none,
        claudeTokenRequestedAt: DateTime.now(),
      ),
    );

    expect(find.textContaining('New Claude token sent'), findsOneWidget);
  });

  testWidgets('on a card, a working machine shows nothing', (tester) async {
    await pump(
      tester,
      machine.copyWith(claudeAuthSource: ClaudeAuthSource.install),
      compact: true,
    );

    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('an outdated runner or an offline machine cannot get a token', (
    tester,
  ) async {
    await pump(tester, machine);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );

    await pump(
      tester,
      machine.copyWith(
        claudeAuthSource: ClaudeAuthSource.none,
        status: MachineStatus.offline,
      ),
    );
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
  });
}
