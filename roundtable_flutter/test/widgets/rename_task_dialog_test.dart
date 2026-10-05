import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/widgets/rename_task_dialog.dart';

void main() {
  /// Opens the dialog and returns a getter for what it popped.
  Future<String? Function()> open(WidgetTester tester, {String? title}) async {
    String? result = 'not popped';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDialog<String>(
              context: context,
              builder: (_) => RenameTaskDialog(taskId: 3, title: title),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('pops the edited, trimmed title on save', (tester) async {
    final result = await open(tester, title: 'Old title');

    expect(find.text('Old title'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  New title ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result(), 'New title');
  });

  testWidgets('cancel pops null', (tester) async {
    final result = await open(tester, title: 'Old title');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result(), isNull);
  });
}
