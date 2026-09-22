import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../repositories/task_repository.dart';

/// The kanban's columns (design doc §4 "Should" kanban), grouped from
/// [TaskStatus].
enum KanbanColumn { backlog, inProgress, review, done }

KanbanColumn kanbanColumnFor(TaskStatus status) => switch (status) {
  TaskStatus.queued || TaskStatus.cloning => KanbanColumn.backlog,
  TaskStatus.planning ||
  TaskStatus.waitingForAnswer ||
  TaskStatus.planReady ||
  TaskStatus.running => KanbanColumn.inProgress,
  TaskStatus.awaitingReview => KanbanColumn.review,
  TaskStatus.done ||
  TaskStatus.failed ||
  TaskStatus.cancelled => KanbanColumn.done,
};

sealed class DashboardState {
  const DashboardState();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.tasks);

  final Map<int, Task> tasks;

  Map<KanbanColumn, List<Task>> get columns {
    final byColumn = <KanbanColumn, List<Task>>{
      for (final column in KanbanColumn.values) column: [],
    };
    for (final task in tasks.values) {
      byColumn[kanbanColumnFor(task.status)]!.add(task);
    }
    for (final tasks in byColumn.values) {
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return byColumn;
  }
}

/// Wraps [TaskRepository.watchAllTasks] — one changed/created task per
/// event, merged into an in-memory map by id and regrouped into
/// [KanbanColumn]s on every update. A Cubit, not a Bloc: a single stream
/// source (design doc §3.3).
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardLoading());

  final TaskRepository _repository;
  final Map<int, Task> _tasks = {};

  Future<void> subscribe() async {
    emit(const DashboardLoading());
    try {
      // `watchAllTasks` only yields when a task already exists or changes —
      // with zero tasks in the database it never emits at all, so without
      // this the cubit would sit in `DashboardLoading` forever instead of
      // showing an empty board.
      emit(DashboardLoaded(Map.of(_tasks)));
      await for (final task in _repository.watchAllTasks()) {
        _tasks[task.id!] = task;
        emit(DashboardLoaded(Map.of(_tasks)));
      }
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
