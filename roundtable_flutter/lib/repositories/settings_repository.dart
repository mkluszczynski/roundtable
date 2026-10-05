import 'package:roundtable_client/roundtable_client.dart';

class SettingsRepository {
  SettingsRepository(this._client);

  final Client _client;

  Future<WorkspaceSettings> getWorkspace() => _client.settings.getWorkspace();

  Future<WorkspaceSettings> updateWorkspace(WorkspaceSettings settings) =>
      _client.settings.updateWorkspace(settings);

  /// Saves [project]'s task-default overrides; other fields are ignored.
  Future<Project> updateProjectTaskDefaults(Project project) =>
      _client.settings.updateProjectTaskDefaults(project);

  Future<TaskDefaults> taskDefaults(int projectId) =>
      _client.settings.taskDefaults(projectId);
}
