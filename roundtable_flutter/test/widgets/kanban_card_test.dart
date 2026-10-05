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

  testWidgets('shows the title instead of the prompt once it has one', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KanbanCard(
            task: task().copyWith(title: 'Login fix'),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Login fix'), findsOneWidget);
    expect(find.text('Fix the login bug'), findsNothing);
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

  testWidgets('shows the CI result of a PR in review', (tester) async {
    Future<void> pump(Task t) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KanbanCard(task: t, onTap: () {}),
        ),
      ),
    );

    final inReview = task().copyWith(
      branchName: 'task-1',
      prUrl: 'https://github.com/x/y/pull/1',
      checkState: PrCheckState.failure,
    );
    await pump(inReview);
    expect(find.text('CI failed'), findsOneWidget);

    // A merged task's CI no longer matters.
    await pump(inReview.copyWith(status: TaskStatus.done));
    expect(find.text('CI failed'), findsNothing);
  });
}
