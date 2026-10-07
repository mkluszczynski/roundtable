import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'task_endpoint.dart';

/// Workspace settings and the task defaults resolved from them.
///
/// Defaults cascade workspace → project → task: a project's nullable
/// override wins over the workspace value, and the result pre-fills the
/// new-task form. The task stores its own copy; one created with the
/// defaults untouched (`Task.followsDefaults`) gets it rewritten whenever
/// the settings change, until the dev edits its options or it's `done`.
class SettingsEndpoint extends Endpoint {
  Future<WorkspaceSettings> getWorkspace(Session session) =>
      workspaceSettings(session);

  Future<WorkspaceSettings> updateWorkspace(
    Session session,
    WorkspaceSettings settings,
  ) async {
    final current = await workspaceSettings(session);
    final updated = await WorkspaceSettings.db.updateRow(
      session,
      current.copyWith(
        skipPlanning: settings.skipPlanning,
        autoReview: settings.autoReview,
        reviewerAgentId: settings.reviewerAgentId,
        autoFixReview: settings.autoFixReview,
        maxReviewFixRounds: settings.maxReviewFixRounds.clamp(1, 10),
        autoMerge: settings.autoMerge,
        autoFixFailingChecks: settings.autoFixFailingChecks,
        maxCheckFixAttempts: settings.maxCheckFixAttempts.clamp(1, 10),
        updatedAt: DateTime.now(),
      ),
    );
    await applyDefaultsToFollowingTasks(session);
    return updated;
  }

  /// Saves [project]'s task-default overrides (a null field inherits the
  /// workspace value); its other fields are ignored.
  Future<Project> updateProjectTaskDefaults(
    Session session,
    Project project,
  ) async {
    if (await Project.db.findById(session, project.id!) == null) {
      throw NotFoundException(message: 'Project ${project.id} not found');
    }
    final updated = await Project.db.updateRow(
      session,
      project,
      columns: (t) => [
        t.skipPlanning,
        t.autoReview,
        t.reviewerAgentId,
        t.autoFixReview,
        t.maxReviewFixRounds,
        t.autoMerge,
        t.autoFixFailingChecks,
        t.maxCheckFixAttempts,
      ],
    );
    await applyDefaultsToFollowingTasks(session, projectId: updated.id);
    return updated;
  }

  /// The options a new task in [projectId] starts with.
  Future<TaskDefaults> taskDefaults(Session session, int projectId) =>
      resolveTaskDefaults(session, projectId);
}

/// The options a new task in [projectId] starts with: the project's
/// overrides on top of the workspace defaults.
Future<TaskDefaults> resolveTaskDefaults(
  Session session,
  int projectId,
) async {
  final project = await Project.db.findById(session, projectId);
  if (project == null) {
    throw NotFoundException(message: 'Project $projectId not found');
  }
  return _taskDefaults(project, await workspaceSettings(session));
}

TaskDefaults _taskDefaults(Project project, WorkspaceSettings workspace) =>
    TaskDefaults(
      skipPlanning: project.skipPlanning ?? workspace.skipPlanning,
      autoReview: project.autoReview ?? workspace.autoReview,
      reviewerAgentId: project.reviewerAgentId ?? workspace.reviewerAgentId,
      autoFixReview: project.autoFixReview ?? workspace.autoFixReview,
      maxReviewFixRounds:
          project.maxReviewFixRounds ?? workspace.maxReviewFixRounds,
      autoMerge: project.autoMerge ?? workspace.autoMerge,
      autoFixFailingChecks:
          project.autoFixFailingChecks ?? workspace.autoFixFailingChecks,
      maxCheckFixAttempts:
          project.maxCheckFixAttempts ?? workspace.maxCheckFixAttempts,
    );

/// Rewrites the options of every task that still follows the defaults
/// (`Task.followsDefaults`) and isn't `done` with what its project resolves
/// to now — for [projectId] only, or every project after a workspace change.
/// `skipPlanning` only changes while the prompt could (see
/// [TaskEndpoint.promptEditableStatuses]): a run under way keeps the mode it
/// started in.
Future<void> applyDefaultsToFollowingTasks(
  Session session, {
  int? projectId,
}) async {
  final tasks = await Task.db.find(
    session,
    where: (t) {
      final following =
          t.followsDefaults.equals(true) & t.status.notEquals(TaskStatus.done);
      return projectId == null
          ? following
          : following & t.projectId.equals(projectId);
    },
  );
  if (tasks.isEmpty) return;
  final workspace = await workspaceSettings(session);
  final projects = {
    for (final p in await Project.db.find(
      session,
      where: (t) => t.id.inSet(tasks.map((task) => task.projectId).toSet()),
    ))
      p.id!: p,
  };
  for (final task in tasks) {
    final project = projects[task.projectId];
    if (project == null) continue;
    final d = _taskDefaults(project, workspace);
    final canChangeSkipPlanning =
        TaskEndpoint.promptEditableStatuses.contains(task.status) &&
        task.pausedPhase == null;
    final next = task.copyWith(
      skipPlanning: canChangeSkipPlanning ? d.skipPlanning : null,
      autoReview: d.autoReview,
      reviewerAgentId: d.reviewerAgentId,
      autoFixReview: d.autoFixReview,
      maxReviewFixRounds: d.maxReviewFixRounds,
      autoMerge: d.autoMerge,
      autoFixFailingChecks: d.autoFixFailingChecks,
      maxCheckFixAttempts: d.maxCheckFixAttempts,
    );
    if (next.skipPlanning == task.skipPlanning &&
        next.autoReview == task.autoReview &&
        next.reviewerAgentId == task.reviewerAgentId &&
        next.autoFixReview == task.autoFixReview &&
        next.maxReviewFixRounds == task.maxReviewFixRounds &&
        next.autoMerge == task.autoMerge &&
        next.autoFixFailingChecks == task.autoFixFailingChecks &&
        next.maxCheckFixAttempts == task.maxCheckFixAttempts) {
      continue;
    }
    // Only these columns, so a concurrent daemon `update` isn't reverted.
    final updated = await Task.db.updateRow(
      session,
      next,
      columns: (t) => [
        t.skipPlanning,
        t.autoReview,
        t.reviewerAgentId,
        t.autoFixReview,
        t.maxReviewFixRounds,
        t.autoMerge,
        t.autoFixFailingChecks,
        t.maxCheckFixAttempts,
      ],
    );
    await session.messages.postMessage(
      TaskEndpoint.channelForTask(updated.id!),
      updated,
    );
    await session.messages.postMessage(
      TaskEndpoint.channelForAllTasks(),
      updated,
    );
  }
}

/// The single settings row, created with defaults on first access.
Future<WorkspaceSettings> workspaceSettings(Session session) async {
  final existing = await WorkspaceSettings.db.findFirstRow(
    session,
    orderBy: (t) => t.id,
  );
  return existing ??
      await WorkspaceSettings.db.insertRow(session, WorkspaceSettings());
}
