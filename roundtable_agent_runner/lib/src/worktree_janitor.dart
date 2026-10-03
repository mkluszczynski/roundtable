import 'package:roundtable_client/roundtable_client.dart';

import 'worktree_manager.dart';

/// Removes task worktrees that are no longer needed. The dispatcher removes
/// a worktree itself when a task is merged, but a task that's deleted, or
/// that failed/was cancelled while this daemon wasn't told (e.g. the machine
/// was offline), would otherwise leave its worktree on disk forever.
///
/// A worktree is removed when its task no longer exists, is `done`, or
/// ended `failed`/`cancelled` without ever pushing a branch. A failed task
/// that did push keeps its worktree: a retry reuses it to push onto the
/// existing PR branch.
class WorktreeJanitor {
  WorktreeJanitor({
    required this.worktreeManager,
    required this.findTasks,
    required this.isActive,
    required this.log,
  });

  final WorktreeManager worktreeManager;

  /// Bound to `client.task.findTasks`: the tasks among the ids that still
  /// exist.
  final Future<List<Task>> Function(List<int> taskIds) findTasks;

  /// Whether this daemon is currently running [taskId] — never touched.
  final bool Function(int taskId) isActive;

  final void Function(String message) log;

  Future<void> sweep() async {
    final worktrees = [
      for (final w in worktreeManager.listTaskWorktrees())
        if (int.tryParse(w.taskId) case final id? when !isActive(id))
          (projectId: w.projectId, taskId: id),
    ];
    if (worktrees.isEmpty) return;

    final tasks = {
      for (final task in await findTasks([for (final w in worktrees) w.taskId]))
        task.id!: task,
    };

    for (final w in worktrees) {
      final task = tasks[w.taskId];
      if (task != null && !_isDisposable(task)) continue;
      try {
        await worktreeManager.removeWorktree(
          projectId: w.projectId,
          taskId: '${w.taskId}',
        );
        log(
          'task ${w.taskId}: removed leftover worktree '
          '(${task?.status.name ?? 'deleted'})',
        );
      } catch (e) {
        log('task ${w.taskId}: could not remove leftover worktree: $e');
      }
    }
  }

  static bool _isDisposable(Task task) => switch (task.status) {
    TaskStatus.done => true,
    TaskStatus.failed || TaskStatus.cancelled => task.branchName == null,
    _ => false,
  };
}
