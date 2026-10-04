import 'package:roundtable_client/roundtable_client.dart';

class SettingsRepository {
  SettingsRepository(this._client);

  final Client _client;

  Future<WorkspaceSettings> getWorkspace() => _client.settings.getWorkspace();

  Future<WorkspaceSettings> updateWorkspace(WorkspaceSettings settings) =>
      _client.settings.updateWorkspace(settings);

  Future<Project> updateProjectTaskDefaults(
    int projectId, {
    bool? skipPlanning,
  }) => _client.settings.updateProjectTaskDefaults(
    projectId,
    skipPlanning: skipPlanning,
  );

  Future<TaskDefaults> taskDefaults(int projectId) =>
      _client.settings.taskDefaults(projectId);
}
