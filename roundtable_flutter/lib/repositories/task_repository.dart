import 'package:roundtable_client/roundtable_client.dart';

class TaskRepository {
  TaskRepository(this._client);

  final Client _client;

  Future<Task> createTask(
    int projectId,
    int agentId,
    String prompt, {
    required bool skipPlanning,
  }) => _client.task.createTask(
    projectId,
    agentId,
    prompt,
    skipPlanning: skipPlanning,
  );

  Future<List<DiffFile>> getChangedFiles(int taskId) =>
      _client.task.getChangedFiles(taskId);

  Future<String> getFileContent(int taskId, String contentsUrl) =>
      _client.task.getFileContent(taskId, contentsUrl);

  Stream<Task> watchTask(int taskId) => _client.task.watchTask(taskId);

  Future<TaskQuestion?> latestQuestion(int taskId) =>
      _client.task.latestQuestion(taskId);

  Future<TaskQuestion> answerQuestion(int questionId, String answer) =>
      _client.task.answerQuestion(questionId, answer);

  Future<Task> approvePlan(int taskId) => _client.task.approvePlan(taskId);

  Future<TaskFeedback> submitPlanFeedback(int taskId, String message) =>
      _client.task.submitPlanFeedback(taskId, message);
}
