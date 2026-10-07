import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/cubits/dashboard_cubit.dart';

void main() {
  Task task(int id, int projectId, TaskStatus status) => Task(
    id: id,
    projectId: projectId,
    prompt: 'Task $id',
    status: status,
    createdAt: DateTime.utc(2026, 1, id),
  );

  final state = DashboardLoaded({
    1: task(1, 1, TaskStatus.queued),
    2: task(2, 1, TaskStatus.waitingForAnswer),
    3: task(3, 2, TaskStatus.awaitingReview),
    4: task(4, 2, TaskStatus.failed),
    5: task(5, 1, TaskStatus.draft),
    6: task(6, 2, TaskStatus.done),
  });

  test('groups every task into its column, newest first', () {
    final columns = state.columnsFor();
    expect(columns[KanbanColumn.backlog]!.map((t) => t.id), [5, 4, 1]);
    expect(columns[KanbanColumn.inProgress]!.map((t) => t.id), [2]);
    expect(columns[KanbanColumn.review]!.map((t) => t.id), [3]);
    expect(columns[KanbanColumn.done]!.map((t) => t.id), [6]);
  });

  test('filters to one project', () {
    final columns = state.columnsFor(projectId: 2);
    expect(columns[KanbanColumn.backlog]!.map((t) => t.id), [4]);
    expect(columns[KanbanColumn.review]!.map((t) => t.id), [3]);
    expect(columns[KanbanColumn.done]!.map((t) => t.id), [6]);
  });
}
