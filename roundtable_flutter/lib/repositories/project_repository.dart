import 'package:roundtable_client/roundtable_client.dart';

class ProjectRepository {
  ProjectRepository(this._client);

  final Client _client;

  Future<List<Project>> listProjects() => _client.project.list();

  Future<Project?> getProject(int id) => _client.project.get(id);

  Future<Project> createProject({
    required String name,
    required String repoUrl,
    String? repoAccessToken,
    List<ProjectTool>? tools,
  }) => _client.project.create(
    name,
    repoUrl,
    repoAccessToken: repoAccessToken,
    tools: tools,
  );

  Future<Project> updateTools(int projectId, List<ProjectTool> tools) =>
      _client.project.updateTools(projectId, tools);

  /// Suggested toolchains from the repo's manifests — see
  /// `ProjectEndpoint.detectTools`.
  Future<List<ProjectTool>> detectTools(
    String repoUrl, {
    String? repoAccessToken,
    int? projectId,
  }) => _client.project.detectTools(
    repoUrl,
    repoAccessToken: repoAccessToken,
    projectId: projectId,
  );

  Future<Project> updateProject(Project project) =>
      _client.project.update(project);

  Future<void> deleteProject(int id) => _client.project.delete(id);

  Future<void> updateRepoAccessToken(int projectId, String token) =>
      _client.project.updateRepoAccessToken(projectId, token);
}
