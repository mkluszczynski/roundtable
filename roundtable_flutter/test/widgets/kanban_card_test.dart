import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/widgets/kanban_card.dart';

void main() {
  Task task({TaskStatus status = TaskStatus.awaitingReview}) =>
      Task(id: 1, projectId: 1, prompt: 'Fix the login bug', status: status);

  testWidgets('shows the prompt, a readable status and the assignment', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KanbanCard(
            task: task(),
            onTap: () {},
            agentName: 'Ana',
            machineName: 'vps-1',
          ),
        ),
      ),
    );

    expect(find.text('Fix the login bug'), findsOneWidget);
    expect(find.text('awaitingReview'), findsNothing);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('vps-1'), findsOneWidget);
  });

  testWidgets('tapping it calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KanbanCard(task: task(), onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.text('Fix the login bug'));
    expect(tapped, isTrue);
  });

  testWidgets('shows project, branch and an unassigned hint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KanbanCard(
            task: Task(
              id: 7,
              projectId: 1,
              prompt: 'Add dark mode',
              status: TaskStatus.draft,
              branchName: 'task-7',
            ),
            onTap: () {},
            projectName: 'roundtable',
          ),
        ),
      ),
    );

    expect(find.text('roundtable'), findsOneWidget);
    expect(find.text('#7'), findsOneWidget);
    expect(find.text('task-7'), findsOneWidget);
    expect(find.text('Unassigned'), findsOneWidget);
  });
}
