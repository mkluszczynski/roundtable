import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/code_block.dart';

void main() {
  testWidgets('renders the code text by default', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CodeBlock(code: 'echo hello')),
    );

    expect(find.text('echo hello'), findsOneWidget);
  });

  testWidgets('renders a custom child instead of the raw code', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CodeBlock(code: 'echo hello', child: Text('custom')),
      ),
    );

    expect(find.text('custom'), findsOneWidget);
    expect(find.text('echo hello'), findsNothing);
  });

  testWidgets('copy button copies the code to the clipboard', (tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      const MaterialApp(home: CodeBlock(code: 'the-token')),
    );

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    final setDataCall = calls.singleWhere(
      (call) => call.method == 'Clipboard.setData',
    );
    expect(setDataCall.arguments['text'], 'the-token');
    expect(find.byIcon(Icons.check), findsOneWidget);

    // Let the "reset to copy icon" timer fire so no timer is left pending.
    await tester.pump(const Duration(seconds: 2));
  });
}
