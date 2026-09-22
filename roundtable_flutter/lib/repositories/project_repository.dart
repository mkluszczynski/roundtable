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
  }) => _client.project.create(
    name,
    repoUrl,
    repoAccessToken: repoAccessToken,
  );

  Future<Project> updateProject(Project project) =>
      _client.project.update(project);

  Future<void> deleteProject(int id) => _client.project.delete(id);

  Future<void> updateRepoAccessToken(int projectId, String token) =>
      _client.project.updateRepoAccessToken(projectId, token);
}
