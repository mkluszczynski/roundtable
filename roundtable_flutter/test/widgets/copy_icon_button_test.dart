import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/copy_icon_button.dart';

void main() {
  testWidgets('copies the text and shows a check', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CopyIconButton(text: 'Fix the bug', tooltip: 'Copy prompt'),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.copy_outlined));
    await tester.pump();

    expect(copied, 'Fix the bug');
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
  });
}
