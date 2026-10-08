import '../utils/status_rules.dart';
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../repositories/task_repository.dart';
import '../utils/closeable_streams.dart';

/// The kanban's columns, grouped from
/// [TaskStatus].
enum KanbanColumn { backlog, inProgress, review, done }

KanbanColumn kanbanColumnFor(TaskStatus status) => switch (status) {
  TaskStatus.draft ||
  TaskStatus.queued ||
  TaskStatus.cloning ||
  TaskStatus.failed => KanbanColumn.backlog,
  TaskStatus.planning ||
  TaskStatus.waitingForAnswer ||
  TaskStatus.planReady ||
  TaskStatus.running ||
  TaskStatus.paused => KanbanColumn.inProgress,
  TaskStatus.awaitingReview => KanbanColumn.review,
  TaskStatus.done || TaskStatus.cancelled => KanbanColumn.done,
};

/// Statuses where the task is blocked on the dev — highlighted on cards and
/// listed in the dashboard's "Needs you" strip.
const needsAttentionStatuses = {
  TaskStatus.waitingForAnswer,
  TaskStatus.planReady,
  TaskStatus.awaitingReview,
  TaskStatus.failed,
};

/// Blocked on the dev right now: needs attention, minus failures (those
/// are only highlighted).
bool waitsOnDev(TaskStatus status) =>
    needsAttentionStatuses.contains(status) && status != TaskStatus.failed;

/// Statuses where the agent is working on the task.
const workingStatuses = {
  TaskStatus.cloning,
  TaskStatus.planning,
  TaskStatus.running,
};

/// The dashboard's stat tiles, computed from what the cubits hold.
class DashboardStats {
  const DashboardStats({
    required this.running,
    required this.waiting,
    required this.busyAgents,
    required this.agents,
    required this.onlineMachines,
    required this.machines,
  });

  factory DashboardStats.from({
    required Iterable<Task> tasks,
    required List<Agent> agents,
    required List<Machine> machines,
  }) => DashboardStats(
    running: tasks.where((t) => workingStatuses.contains(t.status)).length,
    waiting: tasks.where((t) => waitsOnDev(t.status)).length,
    busyAgents: agents.where((a) => a.status != AgentStatus.idle).length,
    agents: agents.length,
    onlineMachines: machines.where((m) => m.isOnline).length,
    machines: machines.length,
  );

  final int running;
  final int waiting;
  final int busyAgents;
  final int agents;
  final int onlineMachines;
  final int machines;
}

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
  const DashboardLoaded(this.tasks, {this.reconnecting = false});

  final Map<int, Task> tasks;

  /// The live connection dropped: [tasks] is the last known state until
  /// it's back.
  final bool reconnecting;

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
    _emit();
    unawaited(_watchTasks());
    unawaited(_watchDeletions());
  }

  var _reconnecting = false;

  void _emit() =>
      emit(DashboardLoaded(Map.of(_tasks), reconnecting: _reconnecting));

  void _dropped() {
    if (_reconnecting) return;
    _reconnecting = true;
    _emit();
  }

  /// Back after a drop: `watchAllTasks` replays every task, but deletions
  /// made meanwhile were missed — drop the tasks that are gone. Throws
  /// while the server is still unreachable.
  Future<void> _resync() async {
    if (_tasks.isNotEmpty) {
      final existing = {
        for (final task in await _repository.findTasks(_tasks.keys.toList()))
          task.id!,
      };
      _tasks.removeWhere((id, _) => !existing.contains(id));
    }
    _reconnecting = false;
    _emit();
  }

  Future<void> _watchTasks() async {
    await for (final task in keepAlive(
      _repository.watchAllTasks,
      onDrop: _dropped,
      onReopen: _resync,
    )) {
      _tasks[task.id!] = task;
      _emit();
    }
  }

  Future<void> _watchDeletions() async {
    await for (final deletion in keepAlive(
      _repository.watchTaskDeletions,
      onDrop: _dropped,
    )) {
      _tasks.remove(deletion.taskId);
      _emit();
    }
  }
}
