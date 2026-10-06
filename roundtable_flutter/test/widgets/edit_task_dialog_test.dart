import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/widgets/edit_task_dialog.dart';
import 'package:roundtable_flutter/widgets/task_options_form.dart';

void main() {
  Task task({TaskStatus status = TaskStatus.queued}) => Task(
    id: 7,
    projectId: 1,
    prompt: 'Fix the bug',
    status: status,
  );

  /// Opens the dialog; [onSave] defaults to recording what was saved.
  Future<void> open(
    WidgetTester tester,
    Task task, {
    required Future<void> Function(String, TaskOptions) onSave,
  }) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => EditTaskDialog(task: task, onSave: onSave),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Save'),
  );

  testWidgets('saves the edited prompt and options, then closes', (
    tester,
  ) async {
    String? savedPrompt;
    TaskOptions? savedOptions;
    await open(
      tester,
      task(),
      onSave: (prompt, options) async {
        savedPrompt = prompt;
        savedOptions = options;
      },
    );

    expect(saveButton(tester).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '  Fix the other bug ');
    await tester.tap(find.text('Auto merge'));
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(savedPrompt, 'Fix the other bug');
    expect(savedOptions!.autoMerge, isTrue);
    expect(find.byType(EditTaskDialog), findsNothing);
  });

  testWidgets('a running task keeps its prompt and skip planning locked', (
    tester,
  ) async {
    await open(
      tester,
      task(status: TaskStatus.running),
      onSave: (_, _) async {},
    );

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'Skip planning'),
          )
          .onChanged,
      isNull,
    );

    await tester.tap(find.text('Auto fix CI'));
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('shows the server error and stays open', (tester) async {
    await open(
      tester,
      task(),
      onSave: (_, _) async => throw Exception('Task 7 is running'),
    );

    await tester.tap(find.text('Auto merge'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Task 7 is running'), findsOneWidget);
    expect(find.byType(EditTaskDialog), findsOneWidget);
  });

  test('options equality ignores round counts of options that are off', () {
    const base = TaskOptions();
    expect(base.copyWith(maxReviewFixRounds: 5), base);
    expect(
      base.copyWith(autoFixReview: true, maxReviewFixRounds: 5),
      isNot(base.copyWith(autoFixReview: true)),
    );
    expect(base.withReviewer(3).withReviewer(null), base);
  });
}
