import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/widgets/active_tasks_nav.dart';

Task _task(int id, TaskStatus status, {int minutesAgo = 0}) => Task(
  id: id,
  projectId: 1,
  agentId: 1,
  prompt: 'Task $id',
  status: status,
  lastProgressAt: DateTime.now().subtract(Duration(minutes: minutesAgo)),
);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 232, height: 600, child: child)),
);

void main() {
  test('keeps the In progress and Review tasks, waiting on the dev first, '
      'then the most recently active', () {
    final tasks = activeTasks([
      _task(1, TaskStatus.draft),
      _task(2, TaskStatus.running, minutesAgo: 5),
      _task(3, TaskStatus.planReady, minutesAgo: 30),
      _task(4, TaskStatus.done),
      _task(5, TaskStatus.running, minutesAgo: 1),
      _task(6, TaskStatus.failed),
      _task(7, TaskStatus.awaitingReview, minutesAgo: 2),
      _task(8, TaskStatus.queued),
      _task(9, TaskStatus.paused, minutesAgo: 60),
    ]);

    expect(tasks.map((t) => t.id), [7, 3, 5, 2, 9]);
  });

  testWidgets('lists the tasks with their agent and opens one on tap', (
    tester,
  ) async {
    final opened = <int>[];
    await tester.pumpWidget(
      _wrap(
        ActiveTasksNav(
          tasks: [
            _task(1, TaskStatus.planReady).copyWith(title: 'Login fix'),
            _task(2, TaskStatus.running),
          ],
          agentNames: const {1: 'Ana'},
          openTaskId: 2,
          onOpen: (t) => opened.add(t.id!),
          onShowAll: () {},
        ),
      ),
    );

    expect(find.text('ACTIVE TASKS'), findsOneWidget);
    expect(find.text('Login fix'), findsOneWidget);
    expect(find.text('Ana · Plan ready'), findsOneWidget);
    await tester.tap(find.text('Task 2'));
    expect(opened, [2]);
  });

  testWidgets('shows the first ones and how many more there are', (
    tester,
  ) async {
    var showAll = 0;
    await tester.pumpWidget(
      _wrap(
        ActiveTasksNav(
          tasks: [for (var i = 1; i <= 4; i++) _task(i, TaskStatus.running)],
          limit: 3,
          onOpen: (_) {},
          onShowAll: () => showAll++,
        ),
      ),
    );

    expect(find.text('Task 4'), findsNothing);
    await tester.tap(find.text('+1 more'));
    expect(showAll, 1);
  });

  testWidgets('shows nothing without active tasks', (tester) async {
    await tester.pumpWidget(
      _wrap(ActiveTasksNav(tasks: const [], onOpen: (_) {}, onShowAll: () {})),
    );

    expect(find.text('ACTIVE TASKS'), findsNothing);
  });
}
