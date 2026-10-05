import 'package:roundtable_client/roundtable_client.dart';

class TaskRepository {
  TaskRepository(this._client);

  final Client _client;

  Future<Task> createTask(
    int projectId,
    int? agentId,
    String prompt, {
    required bool skipPlanning,
    bool autoReview = false,
    int? reviewerAgentId,
    bool autoFixReview = false,
    int? maxReviewFixRounds,
    bool autoMerge = false,
    bool autoFixFailingChecks = false,
    int? maxCheckFixAttempts,
    List<int> attachmentIds = const [],
  }) => _client.task.createTask(
    projectId,
    agentId,
    prompt,
    skipPlanning: skipPlanning,
    autoReview: autoReview,
    reviewerAgentId: reviewerAgentId,
    autoFixReview: autoFixReview,
    maxReviewFixRounds: maxReviewFixRounds,
    autoMerge: autoMerge,
    autoFixFailingChecks: autoFixFailingChecks,
    maxCheckFixAttempts: maxCheckFixAttempts,
    attachmentIds: attachmentIds,
  );

  Future<List<DiffFile>> getChangedFiles(int taskId) =>
      _client.task.getChangedFiles(taskId);

  Future<String> getFileContent(int taskId, String contentsUrl) =>
      _client.task.getFileContent(taskId, contentsUrl);

  /// Renames [taskId]; a blank [title] clears it.
  Future<Task> setTitle(int taskId, String? title) =>
      _client.task.setTitle(taskId, title);

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

  /// Resumes a task paused by a usage limit now instead of at the reset.
  Future<Task> resumeTask(int taskId) => _client.task.resumeTask(taskId);

  /// Resumes a task that finished without code changes with [message].
  Future<TaskFeedback> continueTask(int taskId, String message) =>
      _client.task.continueTask(taskId, message);

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

  /// Squash-merges [taskId]'s PR and marks it `done`. The server refuses
  /// while the CI checks are pending or failing, unless [force].
  Future<Task> acceptTask(int taskId, {bool force = false}) =>
      _client.task.acceptTask(taskId, force: force);

  /// Whether [taskId]'s PR conflicts with its base branch.
  Future<PrMergeStatus> getMergeStatus(int taskId) =>
      _client.task.getMergeStatus(taskId);

  /// Sends the agent a fix run that merges the base branch in and resolves
  /// the conflicts.
  Future<TaskFeedback> resolveConflicts(int taskId) =>
      _client.task.resolveConflicts(taskId);

  /// Streams [taskId]'s GitHub Actions checks — each event is the whole
  /// current snapshot.
  Stream<PrChecks> watchChecks(int taskId) => _client.task.watchChecks(taskId);

  /// Reads [taskId]'s checks from GitHub now, instead of waiting for the
  /// server's next poll.
  Future<PrChecks> refreshChecks(int taskId) =>
      _client.task.refreshChecks(taskId);

  /// Sends [taskId]'s failing checks (all, or just [jobIds]) with their logs
  /// and an optional [note] to the agent as one fix run.
  Future<TaskFeedback> fixFailingChecks(
    int taskId, {
    List<int>? jobIds,
    String? note,
  }) => _client.task.fixFailingChecks(taskId, jobIds: jobIds, note: note);

  /// Streams [taskId]'s AI code reviews, each with its comments. Each event
  /// is a single review — merge it into your list by id.
  Stream<CodeReview> watchReviews(int taskId) =>
      _client.codeReview.watchReviews(taskId);

  Future<CodeReview> requestReview(int taskId, int agentId) =>
      _client.codeReview.requestReview(taskId, agentId);

  Future<ReviewComment> setCommentState(
    int commentId,
    ReviewCommentState state,
  ) => _client.codeReview.setCommentState(commentId, state);

  /// Sends [commentIds] (and an optional [note]) to the task's agent as one
  /// feedback iteration.
  Future<TaskFeedback> sendCommentsToFix(
    int taskId,
    List<int> commentIds,
    String? note,
  ) => _client.codeReview.sendCommentsToFix(taskId, commentIds, note);
}
