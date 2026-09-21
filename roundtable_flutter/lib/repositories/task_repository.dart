import 'package:roundtable_client/roundtable_client.dart';

class TaskRepository {
  TaskRepository(this._client);

  final Client _client;

  Future<List<DiffFile>> getChangedFiles(int taskId) =>
      _client.task.getChangedFiles(taskId);

  Future<String> getFileContent(int taskId, String contentsUrl) =>
      _client.task.getFileContent(taskId, contentsUrl);
}
