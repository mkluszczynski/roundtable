import 'non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import '../github_repo_client.dart';
import '../task_review_support.dart';
import 'package:serverpod/serverpod.dart';

/// Task creation and the daemon's assignment feed (design doc §6.1).
class TaskEndpoint extends Endpoint {
  static String _channelForTaskLogs(int taskId) => 'task-$taskId-logs';
  static String channelForTask(int taskId) => 'task-$taskId';
  static String _channelForQuestion(int questionId) =>
      'task-question-$questionId';
  static String _channelForPlanDecision(int taskId) =>
      'task-$taskId-plan-decision';
  static String channelForAllTasks() => 'all-tasks';
  static String _channelForTaskDeletions() => 'task-deletions';

  /// Statuses [reassignAgent] allows changing `Task.agent` in — the task
  /// isn't actively executing under its current agent, so swapping it is
  /// safe: still sitting in the backlog, or parked in review waiting on the
  /// dev (design doc §5 — `Task.agent` is optional precisely so a task
  /// survives its agent being deleted).
  static const _reassignableTaskStatuses = {
    TaskStatus.draft,
    TaskStatus.queued,
    TaskStatus.cloning,
    TaskStatus.awaitingReview,
  };

  GitHubRepoClient get _github => gitHubRepoClient;

  /// Creates a [Task] (design doc §6.1 step 1). With an [agentId] it's
  /// `queued` and the agent's machine is notified via [watchAssignedTasks];
  /// without one it's a `draft` that nothing picks up until an agent is
  /// assigned via [reassignAgent].
  Future<Task> createTask(
    Session session,
    int projectId,
    int? agentId,
    String prompt, {
    bool skipPlanning = false,
  }) async {
    Agent? agent;
    if (agentId != null) {
      agent = await Agent.db.findById(session, agentId);
      if (agent == null) {
        throw Exception('Agent $agentId not found');
      }
    }

    var task = await Task.db.insertRow(
      session,
      Task(
        projectId: projectId,
        agentId: agentId,
        prompt: prompt,
        skipPlanning: skipPlanning,
        status: agent == null ? TaskStatus.draft : TaskStatus.queued,
      ),
    );

    if (agent != null) {
      await session.messages.postMessage(
        taskChannelForMachine(agent.machineId),
        task,
      );
    }
    await session.messages.postMessage(channelForAllTasks(), task);

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
  /// `claudeSessionId` once Claude Code reports one. Bumps
  /// `lastProgressAt`, since this is the daemon's primary path for
  /// reporting task activity — see [StalledTaskFutureCall].
  Future<Task> update(Session session, Task task) async {
    var previous = await Task.db.findById(session, task.id!);
    // The daemon sends back the Task it received at dispatch time, so only
    // write the fields it owns — otherwise it reverts server-side changes
    // made during the run (currentPlan, question/plan status transitions).
    var updated = await Task.db.updateRow(
      session,
      task.copyWith(lastProgressAt: DateTime.now().toUtc()),
      columns: (t) => [
        t.status,
        t.failureReason,
        t.claudeSessionId,
        t.branchName,
        t.prUrl,
        t.startedAt,
        t.finishedAt,
        t.lastProgressAt,
      ],
    );
    await session.messages.postMessage(channelForTask(updated.id!), updated);
    await session.messages.postMessage(channelForAllTasks(), updated);
    // A finished fix run addressed the review comments it was sent.
    if (previous?.status == TaskStatus.running &&
        updated.status == TaskStatus.awaitingReview) {
      await resolveCommentsSentToFix(session, updated);
    }
    return updated;
  }

  /// Squash-merges [taskId]'s PR and marks the task `done`. If GitHub
  /// refuses the merge (conflicts, failing checks, ...) the task stays in
  /// `awaitingReview` and the reason is thrown back to the panel. Also wakes
  /// the agent's daemon so it removes the task's worktree.
  Future<Task> acceptTask(Session session, int taskId) async {
    var task = await _requireTask(session, taskId);
    if (task.status != TaskStatus.awaitingReview) {
      throw Exception('Task $taskId is not awaiting review (${task.status})');
    }
    await requireNoActiveReview(session, taskId);

    final context = await repoContextFor(session, taskId);
    try {
      await _github.mergePullRequest(
        prUrl: context.prUrl,
        token: context.token,
        commitTitle: 'Roundtable task #$taskId',
      );
    } on GitHubApiException catch (e) {
      if (e.statusCode == 405 || e.statusCode == 409) {
        final status = await _github.getMergeability(
          prUrl: context.prUrl,
          token: context.token,
        );
        if (status.hasConflicts ?? false) {
          throw Exception(
            'The PR has merge conflicts with ${status.baseRef} — '
            'resolve them before merging.',
          );
        }
      }
      rethrow;
    }

    task = await Task.db.updateRow(
      session,
      task.copyWith(
        status: TaskStatus.done,
        finishedAt: DateTime.now().toUtc(),
        lastProgressAt: DateTime.now().toUtc(),
      ),
    );
    var agentId = task.agentId;
    var agent = agentId == null
        ? null
        : await Agent.db.findById(session, agentId);
    if (agent != null) {
      await session.messages.postMessage(
        taskChannelForMachine(agent.machineId),
        task,
      );
    }
    await session.messages.postMessage(channelForTask(taskId), task);
    await session.messages.postMessage(channelForAllTasks(), task);
    return task;
  }

  /// Whether [taskId]'s PR conflicts with its base branch, so the panel can
  /// offer "Resolve conflicts" instead of "Accept & merge".
  Future<PrMergeStatus> getMergeStatus(Session session, int taskId) async {
    final context = await repoContextFor(session, taskId);
    final status = await _github.getMergeability(
      prUrl: context.prUrl,
      token: context.token,
    );
    return PrMergeStatus(
      hasConflicts: status.hasConflicts,
      baseBranch: status.baseRef,
    );
  }

  /// Sends the agent a fix run that merges the base branch into the task's
  /// branch, resolves the conflicts and pushes — the same `--resume` path as
  /// [submitFeedback].
  Future<TaskFeedback> resolveConflicts(Session session, int taskId) async {
    var task = await _requireTask(session, taskId);
    if (task.status != TaskStatus.awaitingReview) {
      throw Exception('Task $taskId is not awaiting review (${task.status})');
    }
    await requireNoActiveReview(session, taskId);
    final status = await getMergeStatus(session, taskId);
    final base = status.baseBranch;
    return queueReviewFeedback(
      session,
      task,
      conflictResolutionPrompt(base),
    );
  }

  /// The fix-run prompt [resolveConflicts] sends for base branch [base].
  static String conflictResolutionPrompt(String base) =>
      'This PR has merge conflicts with `$base`. Run '
      '`git fetch origin && git merge origin/$base`, resolve every conflict '
      'preserving the intent of both sides, make sure the project still '
      'builds and its tests pass, then commit the merge and push the branch.';

  /// Persists one line of a task's execution output as a [TaskLogEntry]
  /// (design doc §6.3) and notifies any [watchLogs] subscribers for this
  /// task. Also bumps `Task.lastProgressAt`, since a log line is a sign of
  /// activity — see [StalledTaskFutureCall].
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

    var task = await _requireTask(session, taskId);
    // Only this column: log lines arrive concurrently with status changes
    // (e.g. setPlanReady), and writing the whole row back would revert them.
    await Task.db.updateRow(
      session,
      task.copyWith(lastProgressAt: DateTime.now().toUtc()),
      columns: (t) => [t.lastProgressAt],
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
        lastProgressAt: DateTime.now().toUtc(),
      ),
    );
    await session.messages.postMessage(channelForTask(taskId), task);
    await session.messages.postMessage(channelForAllTasks(), task);

    return task;
  }

  /// Re-queues a `failed` or `cancelled` task for another attempt, without
  /// the dev having to recreate it from scratch. Resets it to look exactly
  /// like a brand new `queued` task — clearing `claudeSessionId` in
  /// particular, so `TaskDispatcher.handle` starts a fresh Claude Code
  /// invocation rather than trying to `--resume` a session that already
  /// ended in failure/cancellation. Wakes the daemon via the same channel
  /// [createTask] uses.
  Future<Task> retryTask(Session session, int taskId) async {
    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw Exception('Task $taskId not found');
    }
    if (task.status != TaskStatus.failed &&
        task.status != TaskStatus.cancelled) {
      throw Exception(
        'Task $taskId is not retryable (status=${task.status})',
      );
    }
    var agentId = task.agentId;
    if (agentId == null) {
      throw Exception(
        'Task $taskId has no assigned agent — reassign one first',
      );
    }
    var agent = await Agent.db.findById(session, agentId);
    if (agent == null) {
      throw Exception('Agent $agentId not found');
    }

    task = await Task.db.updateRow(
      session,
      task.copyWith(
        status: TaskStatus.queued,
        currentPlan: null,
        failureReason: null,
        claudeSessionId: null,
        startedAt: null,
        finishedAt: null,
        lastProgressAt: DateTime.now().toUtc(),
      ),
    );

    await session.messages.postMessage(
      taskChannelForMachine(agent.machineId),
      task,
    );
    await session.messages.postMessage(channelForTask(taskId), task);
    await session.messages.postMessage(channelForAllTasks(), task);

    return task;
  }

  /// Assigns [agentId] to [taskId] — either giving an agent-less task one
  /// (its previous agent was deleted, see `Agent.machine`'s
  /// `onDelete=Cascade`) or moving a backlog/review task to a different
  /// agent. Blocked while the task is actively executing under its current
  /// agent (`planning`/`running`/etc.) to avoid pulling an agent out from
  /// under a live Claude Code run; not blocked when there's no current agent
  /// at all, since in that case nothing is actually running.
  Future<Task> reassignAgent(Session session, int taskId, int agentId) async {
    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw Exception('Task $taskId not found');
    }
    if (task.agentId != null &&
        !_reassignableTaskStatuses.contains(task.status)) {
      throw Exception(
        'Task $taskId cannot be reassigned while ${task.status.name}',
      );
    }
    var agent = await Agent.db.findById(session, agentId);
    if (agent == null) {
      throw Exception('Agent $agentId not found');
    }

    // Assigning an agent to a draft is what starts it.
    task = await Task.db.updateRow(
      session,
      task.status == TaskStatus.draft
          ? task.copyWith(
              agentId: agentId,
              status: TaskStatus.queued,
              lastProgressAt: DateTime.now().toUtc(),
            )
          : task.copyWith(agentId: agentId),
    );

    // Wakes the new agent's machine in case the task is sitting in the
    // backlog waiting to be picked up — the same channel [createTask] posts
    // to, since `watchAssignedTasks` only replays already-pending tasks once
    // at subscribe time.
    await session.messages.postMessage(
      taskChannelForMachine(agent.machineId),
      task,
    );
    await session.messages.postMessage(channelForTask(taskId), task);
    await session.messages.postMessage(channelForAllTasks(), task);

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
    return queueReviewFeedback(
      session,
      await _requireTask(session, taskId),
      message,
    );
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
      task.copyWith(
        status: TaskStatus.waitingForAnswer,
        lastProgressAt: DateTime.now().toUtc(),
      ),
    );
    await session.messages.postMessage(channelForTask(taskId), task);
    await session.messages.postMessage(channelForAllTasks(), task);
    return created;
  }

  /// Answers a plan-mode clarifying question (design doc §6.4), waking the
  /// permission-prompt-tool blocked on [watchAnswer], and moves the task back
  /// to `planning` since Claude Code resumes as soon as the tool returns.
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

    var task = await Task.db.findById(session, question.taskId);
    if (task != null && task.status == TaskStatus.waitingForAnswer) {
      task = await Task.db.updateRow(
        session,
        task.copyWith(
          status: TaskStatus.planning,
          lastProgressAt: DateTime.now().toUtc(),
        ),
      );
      await session.messages.postMessage(channelForTask(task.id!), task);
      await session.messages.postMessage(channelForAllTasks(), task);
    }
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
      task.copyWith(
        status: TaskStatus.planReady,
        currentPlan: plan,
        lastProgressAt: DateTime.now().toUtc(),
      ),
    );
    await session.messages.postMessage(channelForTask(taskId), task);
    await session.messages.postMessage(channelForAllTasks(), task);
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
      task.copyWith(
        status: TaskStatus.running,
        lastProgressAt: DateTime.now().toUtc(),
      ),
    );
    await session.messages.postMessage(_channelForPlanDecision(taskId), task);
    await session.messages.postMessage(channelForTask(taskId), task);
    await session.messages.postMessage(channelForAllTasks(), task);
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
      task.copyWith(
        status: TaskStatus.planning,
        lastProgressAt: DateTime.now().toUtc(),
      ),
    );
    await session.messages.postMessage(_channelForPlanDecision(taskId), task);
    await session.messages.postMessage(channelForTask(taskId), task);
    await session.messages.postMessage(channelForAllTasks(), task);
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

  /// Deletes a task once it's reached a terminal state — a non-terminal one
  /// has to be cancelled first (mirrors [cancelTask]'s own guard, just
  /// inverted). Its logs/questions/feedback cascade-delete with it (see
  /// `Task`'s relations). Broadcasts a [TaskDeleted] on the same channel
  /// [watchAllTasks] uses, since deleting the row leaves no `Task` to post as
  /// an update.
  Future<void> deleteTask(Session session, int taskId) async {
    var task = await _requireTask(session, taskId);
    // A draft never ran, so it can be deleted without cancelling first.
    if (task.status != TaskStatus.draft &&
        nonTerminalTaskStatuses.contains(task.status)) {
      throw Exception(
        'Task $taskId cannot be deleted while ${task.status.name} — cancel '
        'it first',
      );
    }

    await Task.db.deleteRow(session, task);
    await session.messages.postMessage(
      _channelForTaskDeletions(),
      TaskDeleted(taskId: taskId),
    );
  }

  /// Streams [TaskDeleted] broadcasts from [deleteTask], for the dashboard
  /// kanban to drop a deleted task from its local list. Uses its own channel:
  /// sharing [channelForAllTasks] would feed `Task` messages into a
  /// `TaskDeleted`-typed stream (and vice versa for [watchAllTasks]).
  /// Deliberately doesn't replay anything on subscribe, same reasoning as
  /// [watchPlanDecision]: a deletion is always a future event relative to
  /// subscribing.
  Stream<TaskDeleted> watchTaskDeletions(Session session) async* {
    var updates = session.messages.createStream<TaskDeleted>(
      _channelForTaskDeletions(),
    );
    await for (var deletion in updates) {
      yield deletion;
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
    final context = await repoContextFor(session, taskId);
    return _github.getChangedFiles(prUrl: context.prUrl, token: context.token);
  }

  /// Returns the raw content of the file at [contentsUrl] (as returned by
  /// [getChangedFiles]) for [taskId]'s repository (design doc §6.7).
  Future<String> getFileContent(
    Session session,
    int taskId,
    String contentsUrl,
  ) async {
    final context = await repoContextFor(session, taskId);
    final pr = _github.parsePrUrl(context.prUrl);
    return _github.getFileContent(
      contentsUrl: contentsUrl,
      token: context.token,
      owner: pr.owner,
      repo: pr.repo,
    );
  }

  /// Streams every task, for the panel's dashboard kanban (design doc §4
  /// "Should"), not the daemon, which uses [watchAssignedTasks] instead. On
  /// subscribe, replays every task currently in the database, then yields
  /// each task again whenever any of the status-changing methods above
  /// (create/update/cancel/plan transitions) touches it — the panel merges
  /// each update into its in-memory task list by id.
  Stream<Task> watchAllTasks(Session session) async* {
    var tasks = await Task.db.find(session, orderBy: (t) => t.createdAt);
    for (var task in tasks) {
      yield task;
    }

    var updates = session.messages.createStream<Task>(channelForAllTasks());
    await for (var task in updates) {
      yield task;
    }
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
      taskChannelForMachine(machineId),
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

    var updates = session.messages.createStream<Task>(channelForTask(taskId));
    await for (var t in updates) {
      yield t;
    }
  }
}
