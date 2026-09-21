import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Basic CRUD for [Project]. No deletion guards apply here — see
/// [MachineEndpoint] and [AgentEndpoint] for the entities that have them.
class ProjectEndpoint extends Endpoint {
  Future<Project> create(
    Session session,
    String name,
    String repoUrl, {
    String? repoAccessToken,
    String? dockerImage,
  }) async {
    return Project.db.insertRow(
      session,
      Project(
        name: name,
        repoUrl: repoUrl,
        repoAccessToken: repoAccessToken,
        dockerImage: dockerImage,
      ),
    );
  }

  Future<Project?> get(Session session, int id) async {
    return Project.db.findById(session, id);
  }

  Future<List<Project>> list(Session session) async {
    return Project.db.find(session);
  }

  Future<Project> update(Session session, Project project) async {
    return Project.db.updateRow(session, project);
  }

  Future<void> delete(Session session, int id) async {
    await Project.db.deleteWhere(session, where: (t) => t.id.equals(id));
  }

  /// Returns a ready-to-clone HTTPS URL for [projectId], with
  /// `repoAccessToken` (`scope=serverOnly`, never returned as its own field)
  /// injected as the userinfo component when present. Called by the agent
  /// daemon only at the moment a task starts, never persisted to disk on the
  /// agent side (design doc §6.5).
  Future<String> getCloneUrl(Session session, int projectId) async {
    var project = await Project.db.findById(session, projectId);
    if (project == null) {
      throw Exception('Project $projectId not found');
    }

    var token = project.repoAccessToken;
    if (token == null || token.isEmpty) {
      return project.repoUrl;
    }

    var uri = Uri.tryParse(project.repoUrl);
    if (uri == null || uri.scheme != 'https') {
      return project.repoUrl;
    }

    return uri.replace(userInfo: 'x-access-token:$token').toString();
  }
}
