import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/theme/colors.dart';
import 'package:roundtable_flutter/widgets/task_log_line.dart';

TaskLogEntry _entry(String content) =>
    TaskLogEntry(taskId: 1, content: content);

/// Finds the single rendered log line and returns its plain text and color,
/// so tests can assert on both without caring how many [TextSpan]s the
/// marker/text split produced.
({String text, Color color, FontStyle style}) _line(WidgetTester tester) {
  final richText = tester
      .widgetList<RichText>(find.byType(RichText))
      .map((w) => w.text)
      .whereType<TextSpan>()
      .firstWhere((span) => span.toPlainText().trim().isNotEmpty);
  return (
    text: richText.toPlainText(),
    color: richText.style!.color!,
    style: richText.style!.fontStyle ?? FontStyle.normal,
  );
}

void main() {
  testWidgets('renders plain narration with no marker in text0', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TaskLogView(
          entries: [_entry("I'll add the confirmation step.")],
        ),
      ),
    );

    final line = _line(tester);
    expect(line.text, "I'll add the confirmation step.");
    expect(line.color, AppColors.text0);
    expect(line.style, FontStyle.normal);
  });

  testWidgets('colors a tool-call line in accentSoft and strips the emoji', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TaskLogView(
          entries: [_entry('🔧 Read(src/components/TodoItem.tsx)')],
        ),
      ),
    );

    final line = _line(tester);
    expect(line.text, contains('Read(src/components/TodoItem.tsx)'));
    expect(line.text, isNot(contains('🔧')));
    expect(line.color, AppColors.accentSoft);
  });

  testWidgets('colors a success tool-result line in live green', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TaskLogView(entries: [_entry('✓ 12 passed, 0 failed')]),
      ),
    );

    final line = _line(tester);
    expect(line.text, contains('12 passed, 0 failed'));
    expect(line.color, AppColors.live);
  });

  testWidgets('colors the final success summary in live green', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: TaskLogView(entries: [_entry('✅ Done in 4.2s')])),
    );

    final line = _line(tester);
    expect(line.text, contains('Done in 4.2s'));
    expect(line.text, isNot(contains('✅')));
    expect(line.color, AppColors.live);
  });

  testWidgets('colors an error tool-result line in red', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TaskLogView(entries: [_entry('✗ command not found')])),
    );

    final line = _line(tester);
    expect(line.text, contains('command not found'));
    expect(line.color, AppColors.red);
  });

  testWidgets('colors the final failure summary in red and strips the emoji', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TaskLogView(entries: [_entry('❌ Failed in 1.0s: boom')]),
      ),
    );

    final line = _line(tester);
    expect(line.text, contains('Failed in 1.0s: boom'));
    expect(line.text, isNot(contains('❌')));
    expect(line.color, AppColors.red);
  });

  testWidgets('renders thinking lines dim and italic, emoji stripped', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TaskLogView(entries: [_entry('🤔 considering options')]),
      ),
    );

    final line = _line(tester);
    expect(line.text, contains('considering options'));
    expect(line.text, isNot(contains('🤔')));
    expect(line.color, AppColors.text2);
    expect(line.style, FontStyle.italic);
  });
}
