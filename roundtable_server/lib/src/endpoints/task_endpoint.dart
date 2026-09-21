import 'non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import '../github_repo_client.dart';
import 'package:serverpod/serverpod.dart';

/// Task creation and the daemon's assignment feed (design doc §6.1).
class TaskEndpoint extends Endpoint {
  static String _channelForMachine(int machineId) => 'machine-$machineId-tasks';
  static String _channelForTaskLogs(int taskId) => 'task-$taskId-logs';
  static String _channelForTask(int taskId) => 'task-$taskId';
  static String _channelForQuestion(int questionId) =>
      'task-question-$questionId';
  static String _channelForPlanDecision(int taskId) =>
      'task-$taskId-plan-decision';

  final _github = GitHubRepoClient();

  /// Creates a [Task] already assigned to [agentId] (design doc §6.1 step 1 —
  /// queueing without an agent is a Should-scope feature, not implemented
  /// here even though the schema allows `Task.agent` to be null).
  ///
  /// Notifies the assigned agent's machine via [watchAssignedTasks].
  Future<Task> createTask(
    Session session,
    int projectId,
    int agentId,
    String prompt, {
    bool skipPlanning = false,
  }) async {
    var agent = await Agent.db.findById(session, agentId);
    if (agent == null) {
      throw Exception('Agent $agentId not found');
    }

    var task = await Task.db.insertRow(
      session,
      Task(
        projectId: projectId,
        agentId: agentId,
        prompt: prompt,
        skipPlanning: skipPlanning,
        status: TaskStatus.queued,
      ),
    );

    await session.messages.postMessage(
      _channelForMachine(agent.machineId),
      task,
    );

    return task;
  }

  /// Streams tasks newly assigned to any agent hosted on [machineId] (design
  /// doc §6.1 step 2 — by machine, not by agent, since one daemon serves
  /// every agent it hosts). On subscribe, first replays any already-queued,
  /// non-terminal tasks for that machine — otherwise a task created while the
  /// daemon was offline/restarting would never surface — then yields each
  /// task as it's created via [createTask].
  /// Generic CRUD update, mirroring [ProjectEndpoint.update] /
  /// [AgentEndpoint.update] / [MachineEndpoint.update]. Used by the agent
  /// daemon to move a task through its lifecycle (design doc §6.1) —
  /// e.g. `running` → `awaitingReview`/`failed` — and to persist
  /// `claudeSessionId` once Claude Code reports one.
  Future<Task> update(Session session, Task task) async {
    return Task.db.updateRow(session, task);
  }

  /// Persists one line of a task's execution output as a [TaskLogEntry]
  /// (design doc §6.3) and notifies any [watchLogs] subscribers for this
  /// task.
  Future<TaskLogEntry> appendLog(
    Session session,
    int taskId,
    String content, {
    LogSource source = LogSource.agent,
  }) async {
    var entry = await TaskLogEntry.db.insertRow(
      session,
      TaskLogEntry(taskId: taskId, content: content, source: source),
    );

    await session.messages.postMessage(_channelForTaskLogs(taskId), entry);

    return entry;
  }

  /// Cancels a task that hasn't reached a terminal state yet (design doc
  /// §6.1 "Cancelling mid-run"): marks it `cancelled` and notifies
  /// [watchTask] subscribers — the daemon running the task reacts by
  /// sending `SIGTERM` to the Claude Code subprocess and resetting the
  /// worktree.
  Future<Task> cancelTask(Session session, int taskId) async {
    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw Exception('Task $taskId not found');
    }
    if (!nonTerminalTaskStatuses.contains(task.status)) {
      throw Exception(
        'Task $taskId is not in a cancellable state (${task.status})',
      );
    }

    task = await Task.db.updateRow(
      session,
      task.copyWith(
        status: TaskStatus.cancelled,
        finishedAt: DateTime.now().toUtc(),
      ),
    );
    await session.messages.postMessage(_channelForTask(taskId), task);

    return task;
  }

  /// Records feedback on a completed run (design doc §6.1 step 9, §6.4) and
  /// wakes the daemon via the same channel [createTask] uses — the daemon
  /// picks it up through its existing [watchAssignedTasks] subscription and
  /// resumes the same Claude Code session (`TaskDispatcher.handle`).
  Future<TaskFeedback> submitFeedback(
    Session session,
    int taskId,
    String message,
  ) async {
    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw Exception('Task $taskId not found');
    }
    if (task.status != TaskStatus.awaitingReview) {
      throw Exception('Task $taskId is not awaiting review (${task.status})');
    }
    var agentId = task.agentId;
    if (agentId == null) {
      throw Exception('Task $taskId has no assigned agent');
    }
    var agent = await Agent.db.findById(session, agentId);
    if (agent == null) {
      throw Exception('Agent $agentId not found');
    }

    var feedback = await TaskFeedback.db.insertRow(
      session,
      TaskFeedback(
        taskId: taskId,
        message: message,
        phase: TaskFeedbackPhase.review,
      ),
    );

    // Status is deliberately left as `awaitingReview` here — the dispatcher
    // itself flips it to `running` once it actually picks the resume up,
    // mirroring how it already does that transition for a fresh `queued`
    // task.
    await session.messages.postMessage(
      _channelForMachine(agent.machineId),
      task,
    );

    return feedback;
  }

  /// Returns the most recently submitted [TaskFeedback] for [taskId], or
  /// `null` if none exists. Used by the daemon to fetch the message text of
  /// a review-phase feedback that woke it via [submitFeedback], and to tell
  /// a stale replay (e.g. after a daemon restart) apart from a real pending
  /// one — see `TaskDispatcher.handle`'s use of `Task.finishedAt`.
  Future<TaskFeedback?> latestFeedback(Session session, int taskId) async {
    var results = await TaskFeedback.db.find(
      session,
      where: (t) => t.taskId.equals(taskId),
      orderBy: (t) => t.createdAt.desc(),
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  /// Records a plan-mode clarifying question (design doc §6.4
  /// `AskUserQuestion`), asked by the permission-prompt-tool intercepting
  /// Claude Code's tool call. Flips `Task.status = waitingForAnswer` so the
  /// panel can render it.
  Future<TaskQuestion> createQuestion(
    Session session,
    int taskId,
    String question,
    List<String> options,
  ) async {
    var task = await _requireTask(session, taskId);
    var created = await TaskQuestion.db.insertRow(
      session,
      TaskQuestion(taskId: taskId, question: question, options: options),
    );
    task = await Task.db.updateRow(
      session,
      task.copyWith(status: TaskStatus.waitingForAnswer),
    );
    await session.messages.postMessage(_channelForTask(taskId), task);
    return created;
  }

  /// Answers a plan-mode clarifying question (design doc §6.4), waking the
  /// permission-prompt-tool blocked on [watchAnswer].
  Future<TaskQuestion> answerQuestion(
    Session session,
    int questionId,
    String answer,
  ) async {
    var question = await TaskQuestion.db.findById(session, questionId);
    if (question == null) {
      throw Exception('TaskQuestion $questionId not found');
    }
    if (question.answer != null) {
      throw Exception('TaskQuestion $questionId is already answered');
    }

    question = await TaskQuestion.db.updateRow(
      session,
      question.copyWith(answer: answer, answeredAt: DateTime.now().toUtc()),
    );
    await session.messages.postMessage(
      _channelForQuestion(questionId),
      question,
    );
    return question;
  }

  /// Streams [questionId]'s answer, for the permission-prompt-tool to block
  /// on while Claude Code waits on `AskUserQuestion` (design doc §6.4). On
  /// subscribe, replays the question immediately if it was already answered
  /// before the subscriber attached.
  Stream<TaskQuestion> watchAnswer(Session session, int questionId) async* {
    var question = await TaskQuestion.db.findById(session, questionId);
    if (question != null && question.answer != null) {
      yield question;
    }

    var updates = session.messages.createStream<TaskQuestion>(
      _channelForQuestion(questionId),
    );
    await for (var q in updates) {
      yield q;
    }
  }

  /// Returns the most recently asked [TaskQuestion] for [taskId], or `null`
  /// if none exists — mirrors [latestFeedback]. The panel checks
  /// `Task.status == waitingForAnswer` to decide whether this is still
  /// pending, since this method doesn't distinguish an answered question
  /// from an unanswered one.
  Future<TaskQuestion?> latestQuestion(Session session, int taskId) async {
    var results = await TaskQuestion.db.find(
      session,
      where: (t) => t.taskId.equals(taskId),
      orderBy: (t) => t.createdAt.desc(),
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  /// Stores a ready plan (design doc §6.4 `ExitPlanMode`) and flips
  /// `Task.status = planReady`, so the dev can approve it or give feedback.
  Future<Task> setPlanReady(Session session, int taskId, String plan) async {
    var task = await _requireTask(session, taskId);
    task = await Task.db.updateRow(
      session,
      task.copyWith(status: TaskStatus.planReady, currentPlan: plan),
    );
    await session.messages.postMessage(_channelForTask(taskId), task);
    return task;
  }

  /// Approves the current plan (design doc §6.4), waking the
  /// permission-prompt-tool blocked on [watchPlanDecision] so it lets
  /// `ExitPlanMode` through and Claude Code proceeds to implement.
  Future<Task> approvePlan(Session session, int taskId) async {
    var task = await _requireTask(session, taskId);
    if (task.status != TaskStatus.planReady) {
      throw Exception('Task $taskId is not planReady (${task.status})');
    }

    task = await Task.db.updateRow(
      session,
      task.copyWith(status: TaskStatus.running),
    );
    await session.messages.postMessage(_channelForPlanDecision(taskId), task);
    return task;
  }

  /// Rejects the current plan with feedback (design doc §6.4), waking the
  /// permission-prompt-tool so it denies `ExitPlanMode` and returns the
  /// feedback message as the reason — Claude Code plans again in the same
  /// process.
  Future<TaskFeedback> submitPlanFeedback(
    Session session,
    int taskId,
    String message,
  ) async {
    var task = await _requireTask(session, taskId);
    if (task.status != TaskStatus.planReady) {
      throw Exception('Task $taskId is not planReady (${task.status})');
    }

    var feedback = await TaskFeedback.db.insertRow(
      session,
      TaskFeedback(
        taskId: taskId,
        message: message,
        phase: TaskFeedbackPhase.plan,
      ),
    );
    task = await Task.db.updateRow(
      session,
      task.copyWith(status: TaskStatus.planning),
    );
    await session.messages.postMessage(_channelForPlanDecision(taskId), task);
    return feedback;
  }

  /// Streams the dev's decision on [taskId]'s current plan (design doc
  /// §6.4), for the permission-prompt-tool to block on while `ExitPlanMode`
  /// is pending. Deliberately doesn't replay on subscribe — the tool always
  /// subscribes right after setting `planReady` itself via [setPlanReady],
  /// so a decision is always a future event, never one already made.
  Stream<Task> watchPlanDecision(Session session, int taskId) async* {
    var updates = session.messages.createStream<Task>(
      _channelForPlanDecision(taskId),
    );
    await for (var t in updates) {
      yield t;
    }
  }

  Future<Task> _requireTask(Session session, int taskId) async {
    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw Exception('Task $taskId not found');
    }
    return task;
  }

  /// Returns the list of files changed in [taskId]'s pull request (design
  /// doc §6.7), fetched from the GitHub API using the project's
  /// `repoAccessToken` — never returned to the panel.
  Future<List<DiffFile>> getChangedFiles(Session session, int taskId) async {
    final context = await _repoContextFor(session, taskId);
    return _github.getChangedFiles(prUrl: context.prUrl, token: context.token);
  }

  /// Returns the raw content of the file at [contentsUrl] (as returned by
  /// [getChangedFiles]) for [taskId]'s repository (design doc §6.7).
  Future<String> getFileContent(
    Session session,
    int taskId,
    String contentsUrl,
  ) async {
    final context = await _repoContextFor(session, taskId);
    final pr = _github.parsePrUrl(context.prUrl);
    return _github.getFileContent(
      contentsUrl: contentsUrl,
      token: context.token,
      owner: pr.owner,
      repo: pr.repo,
    );
  }

  /// Loads [taskId]'s `prUrl` and its project's `repoAccessToken`, throwing
  /// if the task, its PR, its project, or the project's token is missing.
  Future<({String prUrl, String token})> _repoContextFor(
    Session session,
    int taskId,
  ) async {
    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw Exception('Task $taskId not found');
    }
    var prUrl = task.prUrl;
    if (prUrl == null) {
      throw Exception('Task $taskId has no PR yet');
    }
    var project = await Project.db.findById(session, task.projectId);
    if (project == null) {
      throw Exception('Project ${task.projectId} not found');
    }
    var token = project.repoAccessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Project ${task.projectId} has no repo access token');
    }

    return (prUrl: prUrl, token: token);
  }

  Stream<Task> watchAssignedTasks(Session session, int machineId) async* {
    var agentIds = (await Agent.db.find(
      session,
      where: (t) => t.machineId.equals(machineId),
    )).map((agent) => agent.id!).toSet();

    var pending = await Task.db.find(
      session,
      where: (t) =>
          t.agentId.inSet(agentIds) & t.status.inSet(nonTerminalTaskStatuses),
      orderBy: (t) => t.createdAt,
    );
    for (var task in pending) {
      yield task;
    }

    var updates = session.messages.createStream<Task>(
      _channelForMachine(machineId),
    );
    await for (var task in updates) {
      yield task;
    }
  }

  /// Streams a task's execution output as it's persisted via [appendLog]
  /// (design doc §6.3), for the panel to render live. On subscribe, first
  /// replays every already-persisted [TaskLogEntry] for [taskId] in order,
  /// then yields each new entry as it's appended.
  Stream<TaskLogEntry> watchLogs(Session session, int taskId) async* {
    var existing = await TaskLogEntry.db.find(
      session,
      where: (t) => t.taskId.equals(taskId),
      orderBy: (t) => t.createdAt,
    );
    for (var entry in existing) {
      yield entry;
    }

    var updates = session.messages.createStream<TaskLogEntry>(
      _channelForTaskLogs(taskId),
    );
    await for (var entry in updates) {
      yield entry;
    }
  }

  /// Streams [taskId]'s status, for the daemon running it (to detect a
  /// cancellation mid-run, design doc §6.1) and the panel alike. On
  /// subscribe, first replays the task's current row, then yields it again
  /// each time [cancelTask] cancels it.
  Stream<Task> watchTask(Session session, int taskId) async* {
    var task = await Task.db.findById(session, taskId);
    if (task != null) {
      yield task;
    }

    var updates = session.messages.createStream<Task>(_channelForTask(taskId));
    await for (var t in updates) {
      yield t;
    }
  }
}
