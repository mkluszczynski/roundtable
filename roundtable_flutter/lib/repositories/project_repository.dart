import 'package:roundtable_client/roundtable_client.dart';

class ProjectRepository {
  ProjectRepository(this._client);

  final Client _client;

  Future<List<Project>> listProjects() => _client.project.list();
}
