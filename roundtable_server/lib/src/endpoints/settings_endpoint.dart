import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Workspace settings and the task defaults resolved from them.
///
/// Defaults cascade workspace → project → task: a project's nullable
/// override wins over the workspace value, and the result only pre-fills the
/// new-task form — the task stores its own copy, so later settings changes
/// never affect tasks that already exist.
class SettingsEndpoint extends Endpoint {
  Future<WorkspaceSettings> getWorkspace(Session session) =>
      workspaceSettings(session);

  Future<WorkspaceSettings> updateWorkspace(
    Session session,
    WorkspaceSettings settings,
  ) async {
    final current = await workspaceSettings(session);
    return WorkspaceSettings.db.updateRow(
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
    return Project.db.updateRow(
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
  }

  /// The options a new task in [projectId] starts with.
  Future<TaskDefaults> taskDefaults(Session session, int projectId) async {
    final project = await Project.db.findById(session, projectId);
    if (project == null) {
      throw NotFoundException(message: 'Project $projectId not found');
    }
    final workspace = await workspaceSettings(session);
    return TaskDefaults(
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
