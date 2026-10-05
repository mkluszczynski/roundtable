import 'non_terminal_task_statuses.dart';
import 'task_attachment_endpoint.dart';
import '../generated/protocol.dart';
import '../github_repo_client.dart';
import '../pr_checks.dart';
import '../task_lifecycle.dart';
import '../task_review_support.dart';
import 'package:serverpod/serverpod.dart';

/// Task creation and the daemon's assignment feed (docs/FLOWS.md §4).
class TaskEndpoint extends Endpoint {
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
  /// dev (docs/ARCHITECTURE.md — `Task.agent` is optional precisely so a task
  /// survives its agent being deleted).
  static const _reassignableTaskStatuses = {
    TaskStatus.draft,
    TaskStatus.queued,
    TaskStatus.cloning,
    TaskStatus.awaitingReview,
  };

  GitHubRepoClient get _github => gitHubRepoClient;

  /// Creates a [Task] (docs/FLOWS.md §4). With an [agentId] it's
  /// `queued` and the agent's machine is notified via [watchAssignedTasks];
  /// without one it's a `draft` that nothing picks up until an agent is
  /// assigned via [reassignAgent].
  Future<Task> createTask(
    Session session,
    int projectId,
    int? agentId,
    String prompt, {
    bool skipPlanning = false,
    // Nullable rather than defaulted: the generated test tools would make a
    // defaulted named parameter required.
    bool? autoReview,
    int? reviewerAgentId,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    List<int>? attachmentIds,
  }) async {
    if (await Project.db.findById(session, projectId) == null) {
      throw NotFoundException(message: 'Project $projectId not found');
    }
    if (reviewerAgentId != null &&
        await Agent.db.findById(session, reviewerAgentId) == null) {
      throw NotFoundException(message: 'Agent $reviewerAgentId not found');
    }
    Agent? agent;
    if (agentId != null) {
      agent = await Agent.db.findById(session, agentId);
      if (agent == null) {
        throw NotFoundException(message: 'Agent $agentId not found');
      }
    }

    var task = await Task.db.insertRow(
      session,
      Task(
        projectId: projectId,
        agentId: agentId,
        prompt: prompt,
        skipPlanning: skipPlanning,
        autoReview: autoReview ?? false,
        reviewerAgentId: reviewerAgentId,
        autoFixReview: autoFixReview ?? false,
        maxReviewFixRounds: (maxReviewFixRounds ?? 2).clamp(1, 10),
        autoMerge: autoMerge ?? false,
        autoFixFailingChecks: autoFixFailingChecks ?? false,
        maxCheckFixAttempts: (maxCheckFixAttempts ?? 2).clamp(1, 10),
        status: agent == null ? TaskStatus.draft : TaskStatus.queued,
      ),
    );
    // Linked before the machine is notified, so the runner sees them.
    await TaskAttachmentEndpoint.link(
      session,
      task.id!,
      attachmentIds ?? const [],
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

  /// Statuses the agent daemon may move a task into via [update]. Every
  /// other transition goes through a dedicated, guarded method
  /// (`cancelTask`, `approvePlan`, `acceptTask`, ...).
  static const _runnerSettableStatuses = {
    TaskStatus.planning,
    TaskStatus.running,
    TaskStatus.awaitingReview,
    TaskStatus.failed,
    TaskStatus.cancelled,
    TaskStatus.paused,
  };

  /// Used by the agent daemon to report a run's progress and outcome —
  /// e.g. `queued` → `planning`/`running`, `running` →
  /// `awaitingReview`/`failed` — and to persist `claudeSessionId`, the branch
  /// and the PR URL. Only the columns the daemon owns are written, and only
  /// to a status in [_runnerSettableStatuses] — any other status in [task]
  /// is ignored and the current one kept. Bumps `lastProgressAt` (see
  /// [StalledTaskFutureCall]).
  ///
  /// A task that already reached a terminal state server-side (cancelled
  /// from the panel, failed by a future call, merged) is final: a late
  /// write from the daemon is ignored and the current row returned, rather
  /// than reviving it or throwing at a daemon that can't do anything about
  /// it.
  Future<Task> update(Session session, Task task) async {
    var previous = await _requireTask(session, task.id!);
    if (!nonTerminalTaskStatuses.contains(previous.status)) {
      session.log(
        'Ignoring update to task ${task.id}: already ${previous.status.name}',
        level: LogLevel.warning,
      );
      return previous;
    }
    // `done` is normally reached by merging the PR (acceptTask). The daemon
    // may only set it for a run that produced no code — nothing to review.
    final finishedWithoutCode =
        task.status == TaskStatus.done &&
        previous.branchName == null &&
        task.branchName == null &&
        task.prUrl == null;
    if (!_runnerSettableStatuses.contains(task.status) &&
        !finishedWithoutCode) {
      // A stale snapshot (e.g. the `queued` row the daemon got at dispatch)
      // or a status only a guarded method may set: keep the current status
      // and write just the other fields.
      task = task.copyWith(status: previous.status);
    }

    // The daemon sends back the Task it received at dispatch time, so only
    // write the fields it owns — otherwise it reverts server-side changes
    // made during the run (currentPlan, question/plan status transitions).
    var updated = await Task.db.updateRow(
      session,
      task.copyWith(lastProgressAt: DateTime.now().toUtc()),
      columns: (t) => [
        t.status,
        t.failureReason,
        t.resultSummary,
        t.pausedUntil,
        t.pauseReason,
        t.pausedPhase,
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
    // A finished fix run addressed the review comments it was sent, and
    // likely pushed a commit whose CI checks start now.
    if (previous.status == TaskStatus.running &&
        updated.status == TaskStatus.awaitingReview) {
      await resolveCommentsSentToFix(session, updated);
      final current = await Task.db.findById(session, updated.id!);
      if (current != null) await syncChecksQuietly(session, current);
    }
    if (previous.status != TaskStatus.awaitingReview &&
        updated.status == TaskStatus.awaitingReview) {
      // Re-read: the daemon's snapshot may predate (or, from an older
      // runner, lack) the review settings.
      final current = await Task.db.findById(session, updated.id!);
      if (current != null) await autoReviewIfEnabled(session, current);
    }
    return updated;
  }

  /// Squash-merges [taskId]'s PR and marks the task `done` — only once the
  /// GitHub Actions checks of the PR's current head commit passed (or the
  /// repo has no CI, or they can't be read), read fresh from GitHub rather
  /// than trusted from the last poll, no fix run is queued, and only that
  /// exact commit. With [force] the dev overrides the checks (e.g. a flaky
  /// or non-required job) — GitHub's branch protection still applies. If
  /// GitHub refuses the merge (conflicts, a newer commit, a required check,
  /// ...) the task stays in `awaitingReview` and the reason is thrown back
  /// to the panel. Also wakes the agent's daemon so it removes the task's
  /// worktree.
  Future<Task> acceptTask(
    Session session,
    int taskId, {
    bool force = false,
  }) async {
    var task = await _requireTask(session, taskId);
    if (task.status != TaskStatus.awaitingReview) {
      throw InvalidStateException(
        message: 'Task $taskId is not awaiting review (${task.status})',
      );
    }
    await requireNoActiveReview(session, taskId);

    final context = await repoContextFor(session, taskId);
    // The merge is pinned to the head commit the sync just read; a stale one
    // from an earlier poll would make GitHub refuse a forced merge.
    var synced = true;
    if (force) {
      try {
        await syncChecks(session, task, context: context);
      } catch (e) {
        synced = false;
        session.log(
          'Syncing CI checks before a forced merge of task $taskId failed: $e',
          level: LogLevel.warning,
        );
      }
    } else {
      task = await syncChecks(session, task, context: context);
      final blocked = mergeBlockedReason(
        task,
        await PrCheckRun.db.find(
          session,
          where: (r) => r.taskId.equals(taskId),
        ),
        fixRunQueued: await hasQueuedFixRun(session, task),
      );
      if (blocked != null) throw InvalidStateException(message: blocked);
    }
    // Re-read: the sync wrote only its own columns.
    task = await _requireTask(session, taskId);

    try {
      await _github.mergePullRequest(
        prUrl: context.prUrl,
        token: context.token,
        commitTitle: 'Roundtable task #$taskId',
        sha: synced ? task.prHeadSha : null,
      );
    } on GitHubException catch (e) {
      if (e.statusCode == 405 || e.statusCode == 409) {
        // Best effort: explain a conflict if GitHub can tell us, otherwise
        // surface GitHub's own refusal.
        final status = await _github
            .getMergeability(prUrl: context.prUrl, token: context.token)
            .then<({bool? hasConflicts, String baseRef})?>((s) => s)
            .catchError((Object _) => null);
        if (status?.hasConflicts ?? false) {
          throw InvalidStateException(
            message:
                'The PR has merge conflicts with ${status!.baseRef} — '
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
      throw InvalidStateException(
        message: 'Task $taskId is not awaiting review (${task.status})',
      );
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

  /// Returns [taskId]'s GitHub Actions checks as last synced (see
  /// [watchChecks]).
  Future<PrChecks> getChecks(Session session, int taskId) async {
    return loadChecks(session, await _requireTask(session, taskId));
  }

  /// Streams [taskId]'s GitHub Actions checks: the current snapshot on
  /// subscribe, then a new one whenever a sync (every 30 s while the task is
  /// in review, or [refreshChecks]) changes them.
  Stream<PrChecks> watchChecks(Session session, int taskId) async* {
    var updates = session.messages.createStream<PrChecks>(
      channelForTaskChecks(taskId),
    );
    yield await loadChecks(session, await _requireTask(session, taskId));
    await for (var checks in updates) {
      yield checks;
    }
  }

  /// Reads [taskId]'s checks from GitHub now, instead of waiting for the
  /// next poll.
  Future<PrChecks> refreshChecks(Session session, int taskId) async {
    var task = await syncChecks(session, await _requireTask(session, taskId));
    return loadChecks(session, task);
  }

  /// Sends the agent a fix run for [taskId]'s failing CI checks — all of
  /// them, or only [jobIds] — with each job's log in the prompt and the
  /// dev's optional [note]. Same `--resume` path as [resolveConflicts].
  Future<TaskFeedback> fixFailingChecks(
    Session session,
    int taskId, {
    List<int>? jobIds,
    String? note,
  }) async {
    return sendFailingChecksToFix(
      session,
      await _requireTask(session, taskId),
      jobIds: jobIds,
      note: note,
    );
  }

  /// Persists one line of a task's execution output as a [TaskLogEntry]
  /// (docs/FLOWS.md §4) and notifies any [watchLogs] subscribers for this
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

    await session.messages.postMessage(channelForTaskLogs(taskId), entry);

    return entry;
  }

  /// Continues a task that finished without code changes (its result is
  /// the agent's reply, e.g. an analysis or an answer) by resuming the same
  /// Claude Code session with [message] — "now implement it". The task goes
  /// back to `awaitingReview` so the daemon's resume path picks it up; it
  /// ends either with a PR (if the agent changes code) or `done` again with
  /// a new result.
  Future<TaskFeedback> continueTask(
    Session session,
    int taskId,
    String message,
  ) async {
    var task = await _requireTask(session, taskId);
    if (task.status != TaskStatus.done ||
        task.branchName != null ||
        task.prUrl != null) {
      throw InvalidStateException(
        message:
            'Only a task that finished without code changes can be '
            'continued (task $taskId is ${task.status.name})',
      );
    }
    if (task.claudeSessionId == null) {
      throw InvalidStateException(
        message: 'Task $taskId has no agent session to continue',
      );
    }
    if (message.trim().isEmpty) {
      throw InvalidStateException(message: 'Write what the agent should do');
    }

    var reopened = await Task.db.updateRow(
      session,
      task.copyWith(status: TaskStatus.awaitingReview),
      columns: (t) => [t.status],
    );
    await session.messages.postMessage(channelForTask(taskId), reopened);
    await session.messages.postMessage(channelForAllTasks(), reopened);
    return queueReviewFeedback(session, reopened, message.trim());
  }

  /// Resumes a task paused by a usage limit right away instead of waiting
  /// for `pausedUntil` — e.g. after the dev raised the plan's limit.
  Future<Task> resumeTask(Session session, int taskId) async {
    var task = await _requireTask(session, taskId);
    if (task.status != TaskStatus.paused) {
      throw InvalidStateException(
        message: 'Task $taskId is not paused (${task.status.name})',
      );
    }
    return resumePausedTask(session, task);
  }

  /// Persists a structured log entry (kind, run, tool…) from the daemon —
  /// see [TaskLogEntry]. Same side effects as [appendLog]; the server
  /// assigns the id and timestamp.
  Future<TaskLogEntry> appendLogEntry(
    Session session,
    TaskLogEntry entry,
  ) async {
    var stored = await TaskLogEntry.db.insertRow(
      session,
      entry.copyWith(id: null, createdAt: DateTime.now().toUtc()),
    );
    var task = await _requireTask(session, stored.taskId);
    await Task.db.updateRow(
      session,
      task.copyWith(lastProgressAt: DateTime.now().toUtc()),
      columns: (t) => [t.lastProgressAt],
    );
    await session.messages.postMessage(
      channelForTaskLogs(stored.taskId),
      stored,
    );
    return stored;
  }

  /// Cancels a task that hasn't reached a terminal state yet (docs/FLOWS.md §4
  /// "Cancelling mid-run"): marks it `cancelled` and notifies
  /// [watchTask] subscribers — the daemon running the task reacts by
  /// sending `SIGTERM` to the Claude Code subprocess and resetting the
  /// worktree.
  Future<Task> cancelTask(Session session, int taskId) async {
    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw NotFoundException(message: 'Task $taskId not found');
    }
    if (!nonTerminalTaskStatuses.contains(task.status)) {
      throw InvalidStateException(
        message: 'Task $taskId is not in a cancellable state (${task.status})',
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
      throw NotFoundException(message: 'Task $taskId not found');
    }
    if (task.status != TaskStatus.failed &&
        task.status != TaskStatus.cancelled) {
      throw InvalidStateException(
        message: 'Task $taskId is not retryable (status=${task.status})',
      );
    }
    var agentId = task.agentId;
    if (agentId == null) {
      throw InvalidStateException(
        message: 'Task $taskId has no assigned agent — reassign one first',
      );
    }
    var agent = await Agent.db.findById(session, agentId);
    if (agent == null) {
      throw NotFoundException(message: 'Agent $agentId not found');
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
        pausedUntil: null,
        pauseReason: null,
        pausedPhase: null,
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
      throw NotFoundException(message: 'Task $taskId not found');
    }
    if (task.agentId != null &&
        !_reassignableTaskStatuses.contains(task.status)) {
      throw InvalidStateException(
        message: 'Task $taskId cannot be reassigned while ${task.status.name}',
      );
    }
    var agent = await Agent.db.findById(session, agentId);
    if (agent == null) {
      throw NotFoundException(message: 'Agent $agentId not found');
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

  /// Records feedback on a completed run (docs/FLOWS.md §4) and
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

  /// Longest title kept; anything past it is cut off.
  static const maxTitleLength = 80;

  /// Sets [taskId]'s title from the agent's `set_task_title` tool
  /// (docs/FLOWS.md §4) — only while the task has none, so it never
  /// replaces a title the dev chose or one from an earlier run. A blank
  /// [title] is ignored. Returns the current task either way.
  Future<Task> suggestTitle(Session session, int taskId, String title) async {
    var task = await _requireTask(session, taskId);
    final normalized = _normalizeTitle(title);
    if (task.title != null || normalized == null) return task;
    return _writeTitle(session, task, normalized);
  }

  /// Renames [taskId] from the panel. A blank [title] clears it: the board
  /// falls back to the prompt and the agent may suggest one again on its
  /// next run.
  Future<Task> setTitle(Session session, int taskId, String? title) async {
    var task = await _requireTask(session, taskId);
    return _writeTitle(session, task, _normalizeTitle(title));
  }

  static String? _normalizeTitle(String? title) {
    final line = (title ?? '')
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    if (line.isEmpty) return null;
    return line.length > maxTitleLength
        ? '${line.substring(0, maxTitleLength - 1).trimRight()}…'
        : line;
  }

  Future<Task> _writeTitle(Session session, Task task, String? title) async {
    var updated = await Task.db.updateRow(
      session,
      task.copyWith(title: title),
      columns: (t) => [t.title],
    );
    await session.messages.postMessage(channelForTask(updated.id!), updated);
    await session.messages.postMessage(channelForAllTasks(), updated);
    return updated;
  }

  /// Records a plan-mode clarifying question (docs/FLOWS.md §4
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
    late TaskQuestion created;
    await session.db.transaction((transaction) async {
      created = await TaskQuestion.db.insertRow(
        session,
        TaskQuestion(taskId: taskId, question: question, options: options),
        transaction: transaction,
      );
      task = await Task.db.updateRow(
        session,
        task.copyWith(
          status: TaskStatus.waitingForAnswer,
          lastProgressAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
    });
    await session.messages.postMessage(channelForTask(taskId), task);
    await session.messages.postMessage(channelForAllTasks(), task);
    return created;
  }

  /// Answers a plan-mode clarifying question (docs/FLOWS.md §4), waking the
  /// permission-prompt-tool blocked on [watchAnswer], and moves the task back
  /// to `planning` since Claude Code resumes as soon as the tool returns.
  Future<TaskQuestion> answerQuestion(
    Session session,
    int questionId,
    String answer,
  ) async {
    var question = await TaskQuestion.db.findById(session, questionId);
    if (question == null) {
      throw NotFoundException(message: 'TaskQuestion $questionId not found');
    }
    if (question.answer != null) {
      throw InvalidStateException(
        message: 'TaskQuestion $questionId is already answered',
      );
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
  /// on while Claude Code waits on `AskUserQuestion` (docs/FLOWS.md §4). On
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

  /// Stores a ready plan (docs/FLOWS.md §4 `ExitPlanMode`) and flips
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

  /// Approves the current plan (docs/FLOWS.md §4), waking the
  /// permission-prompt-tool blocked on [watchPlanDecision] so it lets
  /// `ExitPlanMode` through and Claude Code proceeds to implement.
  Future<Task> approvePlan(Session session, int taskId) async {
    var task = await _requireTask(session, taskId);
    if (task.status != TaskStatus.planReady) {
      throw InvalidStateException(
        message: 'Task $taskId is not planReady (${task.status})',
      );
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

  /// Rejects the current plan with feedback (docs/FLOWS.md §4), waking the
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
      throw InvalidStateException(
        message: 'Task $taskId is not planReady (${task.status})',
      );
    }

    late TaskFeedback feedback;
    await session.db.transaction((transaction) async {
      feedback = await TaskFeedback.db.insertRow(
        session,
        TaskFeedback(
          taskId: taskId,
          message: message,
          phase: TaskFeedbackPhase.plan,
        ),
        transaction: transaction,
      );
      task = await Task.db.updateRow(
        session,
        task.copyWith(
          status: TaskStatus.planning,
          lastProgressAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
    });
    await session.messages.postMessage(_channelForPlanDecision(taskId), task);
    await session.messages.postMessage(channelForTask(taskId), task);
    await session.messages.postMessage(channelForAllTasks(), task);
    return feedback;
  }

  /// Streams the dev's decision on [taskId]'s current plan (docs/FLOWS.md §4),
  /// for the permission-prompt-tool to block on while `ExitPlanMode`
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
      throw InvalidStateException(
        message:
            'Task $taskId cannot be deleted while ${task.status.name} — cancel '
            'it first',
      );
    }

    // The rows cascade with the task; the stored files don't.
    await TaskAttachmentEndpoint.deleteStored(
      session,
      await TaskAttachment.db.find(
        session,
        where: (a) => a.taskId.equals(taskId),
      ),
    );
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

  /// Returns the tasks among [taskIds] that still exist. Used by the
  /// daemon's worktree cleanup to tell which on-disk worktrees belong to
  /// deleted or finished tasks.
  Future<List<Task>> findTasks(Session session, List<int> taskIds) async {
    if (taskIds.isEmpty) return [];
    return Task.db.find(session, where: (t) => t.id.inSet(taskIds.toSet()));
  }

  Future<Task> _requireTask(Session session, int taskId) async {
    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw NotFoundException(message: 'Task $taskId not found');
    }
    return task;
  }

  /// Returns the list of files changed in [taskId]'s pull request
  /// (docs/FLOWS.md §4), fetched from the GitHub API using the project's
  /// `repoAccessToken` — never returned to the panel.
  Future<List<DiffFile>> getChangedFiles(Session session, int taskId) async {
    final context = await repoContextFor(session, taskId);
    return _github.getChangedFiles(prUrl: context.prUrl, token: context.token);
  }

  /// Returns the raw content of the file at [contentsUrl] (as returned by
  /// [getChangedFiles]) for [taskId]'s repository (docs/FLOWS.md §4).
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

  /// Streams every task, for the panel's dashboard kanban (docs/ARCHITECTURE.md
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

  /// Streams tasks newly assigned to any agent hosted on [machineId] — by
  /// machine, not by agent, since one daemon serves every agent it hosts.
  /// On subscribe, first replays the machine's non-terminal tasks —
  /// otherwise a task created while the daemon was offline/restarting would
  /// never surface — then yields each task posted to the machine's channel
  /// (created, retried, reassigned, fed back, merged).
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
  /// (docs/FLOWS.md §4), for the panel to render live. On subscribe, first
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
      channelForTaskLogs(taskId),
    );
    await for (var entry in updates) {
      yield entry;
    }
  }

  /// Streams [taskId]'s status, for the daemon running it (to detect a
  /// cancellation mid-run, docs/FLOWS.md §4) and the panel alike. On
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
