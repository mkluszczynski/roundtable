import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/toolchain_chips.dart';

void main() {
  test('labels keep the tool name and its version number', () {
    expect(
      ToolchainChips.label('dart: Dart SDK version: 3.13.3 (stable)'),
      'dart 3.13.3',
    );
    expect(ToolchainChips.label('node: v22.1.0'), 'node 22.1.0');
    expect(ToolchainChips.label('docker: unknown version'), 'docker');
  });

  testWidgets('explains a daemon that has not reported yet', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ToolchainChips(toolchain: null))),
    );
    expect(find.textContaining('update the runner'), findsOneWidget);
  });
}
