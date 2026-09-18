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
}
