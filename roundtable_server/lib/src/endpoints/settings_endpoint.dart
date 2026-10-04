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
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Sets a project's overrides; a null field inherits the workspace value.
  Future<Project> updateProjectTaskDefaults(
    Session session,
    int projectId, {
    bool? skipPlanning,
  }) async {
    final project = await Project.db.findById(session, projectId);
    if (project == null) {
      throw NotFoundException(message: 'Project $projectId not found');
    }
    return Project.db.updateRow(
      session,
      project.copyWith(skipPlanning: skipPlanning),
      columns: (t) => [t.skipPlanning],
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
