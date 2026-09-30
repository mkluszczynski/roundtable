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

  /// Streams every task as it's created/changed, for the dashboard kanban.
  /// Each event is a single task — merge it into your task list by id.
  Stream<Task> watchAllTasks() => _client.task.watchAllTasks();

  Stream<TaskLogEntry> watchLogs(int taskId) => _client.task.watchLogs(taskId);

  Future<TaskQuestion?> latestQuestion(int taskId) =>
      _client.task.latestQuestion(taskId);

  Future<TaskQuestion> answerQuestion(int questionId, String answer) =>
      _client.task.answerQuestion(questionId, answer);

  Future<Task> approvePlan(int taskId) => _client.task.approvePlan(taskId);

  Future<TaskFeedback> submitPlanFeedback(int taskId, String message) =>
      _client.task.submitPlanFeedback(taskId, message);

  Future<TaskFeedback> submitFeedback(int taskId, String message) =>
      _client.task.submitFeedback(taskId, message);

  Future<Task> cancelTask(int taskId) => _client.task.cancelTask(taskId);

  /// Re-queues a `failed`/`cancelled` task for another attempt, so testing a
  /// fix doesn't require recreating the task from scratch.
  Future<Task> retryTask(int taskId) => _client.task.retryTask(taskId);

  /// Assigns or reassigns [taskId] to [agentId] — used to give an
  /// agent-less task (its previous agent was deleted) a new one, or to move
  /// a backlog/review task to a different agent.
  Future<Task> reassignAgent(int taskId, int agentId) =>
      _client.task.reassignAgent(taskId, agentId);

  /// Deletes a terminal (`done`/`failed`/`cancelled`) task — a non-terminal
  /// one has to be cancelled first.
  Future<void> deleteTask(int taskId) => _client.task.deleteTask(taskId);

  /// Streams every task deletion, for the dashboard kanban to drop a
  /// deleted task from its local list — the counterpart of [watchAllTasks].
  Stream<TaskDeleted> watchTaskDeletions() => _client.task.watchTaskDeletions();
}
