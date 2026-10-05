import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../utils/error_message.dart';
import '../repositories/task_repository.dart';
import '../utils/closeable_streams.dart';

/// The kanban's columns, grouped from
/// [TaskStatus].
enum KanbanColumn { backlog, inProgress, review, done }

KanbanColumn kanbanColumnFor(TaskStatus status) => switch (status) {
  TaskStatus.draft ||
  TaskStatus.queued ||
  TaskStatus.cloning => KanbanColumn.backlog,
  TaskStatus.planning ||
  TaskStatus.waitingForAnswer ||
  TaskStatus.planReady ||
  TaskStatus.running ||
  TaskStatus.paused => KanbanColumn.inProgress,
  TaskStatus.awaitingReview => KanbanColumn.review,
  TaskStatus.done ||
  TaskStatus.failed ||
  TaskStatus.cancelled => KanbanColumn.done,
};

/// Statuses where the task is blocked on the dev — highlighted on cards and
/// listed in the dashboard's "Needs you" strip.
const needsAttentionStatuses = {
  TaskStatus.waitingForAnswer,
  TaskStatus.planReady,
  TaskStatus.awaitingReview,
  TaskStatus.failed,
};

/// Statuses where a task occupies its agent (queued for it up to running).
const agentOccupyingStatuses = {
  TaskStatus.queued,
  TaskStatus.cloning,
  TaskStatus.planning,
  TaskStatus.waitingForAnswer,
  TaskStatus.planReady,
  TaskStatus.running,
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

  Map<KanbanColumn, List<Task>> get columns => columnsFor();

  /// The task agent [agentId] is working on (or queued for), newest first.
  Task? currentTaskFor(int agentId) {
    Task? current;
    for (final task in tasks.values) {
      if (task.agentId != agentId ||
          !agentOccupyingStatuses.contains(task.status)) {
        continue;
      }
      if (current == null || task.createdAt.isAfter(current.createdAt)) {
        current = task;
      }
    }
    return current;
  }

  /// [tasks] grouped into columns, newest first — only [projectId]'s when
  /// given.
  Map<KanbanColumn, List<Task>> columnsFor({int? projectId}) {
    final byColumn = <KanbanColumn, List<Task>>{
      for (final column in KanbanColumn.values) column: [],
    };
    for (final task in tasks.values) {
      if (projectId != null && task.projectId != projectId) continue;
      byColumn[kanbanColumnFor(task.status)]!.add(task);
    }
    for (final tasks in byColumn.values) {
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return byColumn;
  }
}

/// Wraps [TaskRepository.watchAllTasks]/[TaskRepository.watchTaskDeletions]
/// — one changed/created/deleted task per event, merged into an in-memory
/// map by id and regrouped into [KanbanColumn]s on every update. A Cubit,
/// not a Bloc: both streams feed the same single `Map<int, Task>` state
/// rather than driving separate concerns.
///
/// One instance is provided by `PanelShell` and shared by every screen that
/// shows tasks, so the panel holds a single `watchAllTasks` subscription.
class DashboardCubit extends Cubit<DashboardState>
    with CloseableStreams<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardLoading());

  final TaskRepository _repository;
  final Map<int, Task> _tasks = {};

  Future<void> subscribe() async {
    emit(const DashboardLoading());
    // `watchAllTasks` only yields when a task already exists or changes —
    // with zero tasks in the database it never emits at all, so without
    // this the cubit would sit in `DashboardLoading` forever instead of
    // showing an empty board.
    emit(DashboardLoaded(Map.of(_tasks)));
    unawaited(_watchTasks());
    unawaited(_watchDeletions());
  }

  Future<void> _watchTasks() async {
    try {
      await for (final task in untilClosed(_repository.watchAllTasks())) {
        _tasks[task.id!] = task;
        emit(DashboardLoaded(Map.of(_tasks)));
      }
    } catch (e) {
      emit(DashboardError(errorMessage(e)));
    }
  }

  Future<void> _watchDeletions() async {
    try {
      await for (final deletion in untilClosed(
        _repository.watchTaskDeletions(),
      )) {
        _tasks.remove(deletion.taskId);
        emit(DashboardLoaded(Map.of(_tasks)));
      }
    } catch (e) {
      emit(DashboardError(errorMessage(e)));
    }
  }
}
