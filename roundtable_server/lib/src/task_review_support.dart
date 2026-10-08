import 'package:serverpod/serverpod.dart';

import 'generated/protocol.dart';
import 'github_repo_client.dart';
import 'task_events.dart';

/// Server-side pieces shared by `TaskEndpoint` and `CodeReviewEndpoint` —
/// kept out of the endpoint classes so they aren't exposed as RPC methods.

/// Channel a machine's daemon receives its assigned tasks on
/// (`TaskEndpoint.watchAssignedTasks`).
String taskChannelForMachine(int machineId) => 'machine-$machineId-tasks';

/// Channel the panel's `TaskEndpoint.watchLogs` listens on.
String channelForTaskLogs(int taskId) => 'task-$taskId-logs';

/// Records review-phase feedback on [task] (docs/FLOWS.md §4)
/// and wakes its agent's daemon via the same channel `createTask` uses —
/// the daemon picks it up through its `watchAssignedTasks` subscription and
/// resumes the same Claude Code session (`TaskDispatcher.handle`).
Future<TaskFeedback> queueReviewFeedback(
  Session session,
  Task task,
  String message, {
  required TaskFeedbackKind kind,
  Future<void> Function(Transaction transaction)? alsoWrite,
  TransactionSettings? transactionSettings,
}) async {
  if (task.status != TaskStatus.awaitingReview) {
    throw InvalidStateException(
      message: 'Task ${task.id} is not awaiting review (${task.status.name})',
    );
  }
  var agentId = task.agentId;
  if (agentId == null) {
    throw InvalidStateException(
      message: 'Task ${task.id} has no assigned agent',
    );
  }
  var agent = await Agent.db.findById(session, agentId);
  if (agent == null) {
    throw NotFoundException(message: 'Agent $agentId not found');
  }

  // The feedback row and any caller-side writes (e.g. marking review
  // comments `sentToFix`) land together, and the daemon is only woken once
  // they're committed — it reads the feedback back via `latestFeedback`.
  var feedback = await session.db.transaction((transaction) async {
    var inserted = await TaskFeedback.db.insertRow(
      session,
      TaskFeedback(
        taskId: task.id!,
        message: message,
        phase: TaskFeedbackPhase.review,
        kind: kind,
      ),
      transaction: transaction,
    );
    await alsoWrite?.call(transaction);
    return inserted;
  }, settings: transactionSettings);

  // The fix run is about to push a new commit, so the current CI results go
  // stale — merging stays blocked until the new commit's checks report.
  if (task.prUrl != null && task.checkState != PrCheckState.pending) {
    var updated = await Task.db.updateRow(
      session,
      task.copyWith(checkState: PrCheckState.pending),
      columns: (t) => [t.checkState],
    );
    await publishTask(session, updated);
  }

  // Status is deliberately left as `awaitingReview` here — the dispatcher
  // itself flips it to `running` once it actually picks the resume up,
  // mirroring how it already does that transition for a fresh `queued` task.
  await session.messages.postMessage(
    taskChannelForMachine(agent.machineId),
    task,
  );

  return feedback;
}

/// Loads [taskId]'s `prUrl` and its project's `repoAccessToken`, throwing if
/// the task, its PR, its project, or the project's token is missing.
Future<({String prUrl, String token})> repoContextFor(
  Session session,
  int taskId,
) async {
  var task = await Task.db.findById(session, taskId);
  if (task == null) {
    throw NotFoundException(message: 'Task $taskId not found');
  }
  var prUrl = task.prUrl;
  if (prUrl == null) {
    throw InvalidStateException(message: 'Task $taskId has no PR yet');
  }
  var project = await Project.db.findById(session, task.projectId);
  if (project == null) {
    throw NotFoundException(message: 'Project ${task.projectId} not found');
  }
  var token = project.repoAccessToken;
  if (token == null || token.isEmpty) {
    throw InvalidStateException(
      message: 'Project ${task.projectId} has no repo access token',
    );
  }

  return (prUrl: prUrl, token: token);
}

/// Statuses in which a [CodeReview] is still in flight.
const activeCodeReviewStatuses = {
  CodeReviewStatus.queued,
  CodeReviewStatus.running,
};

/// Throws if [taskId] has a review that hasn't finished yet.
Future<void> requireNoActiveReview(Session session, int taskId) async {
  var active = await CodeReview.db.count(
    session,
    where: (r) =>
        r.taskId.equals(taskId) & r.status.inSet(activeCodeReviewStatuses),
  );
  if (active > 0) {
    throw InvalidStateException(
      message: 'Task $taskId has a code review in progress',
    );
  }
}

/// Marks every `sentToFix` comment on [task]'s reviews `resolved` — called
/// once the fix run they were sent to finishes — and resolves their mirrored
/// GitHub threads, best effort.
Future<void> resolveCommentsSentToFix(Session session, Task task) async {
  var reviewIds = (await CodeReview.db.find(
    session,
    where: (r) => r.taskId.equals(task.id!),
  )).map((r) => r.id!).toSet();
  if (reviewIds.isEmpty) return;

  var comments = await ReviewComment.db.find(
    session,
    where: (c) =>
        c.reviewId.inSet(reviewIds) &
        c.state.equals(ReviewCommentState.sentToFix),
  );
  if (comments.isEmpty) return;

  await ReviewComment.db.update(
    session,
    [for (var c in comments) c.copyWith(state: ReviewCommentState.resolved)],
    columns: (c) => [c.state],
  );
  await resolveGitHubThreads(session, task, comments);
  for (var reviewId in comments.map((c) => c.reviewId).toSet()) {
    await postReviewChanged(session, reviewId);
  }
}

/// Resolves the GitHub threads mirrored from [comments], logging (not
/// throwing) failures — Roundtable stays the source of truth.
Future<void> resolveGitHubThreads(
  Session session,
  Task task,
  List<ReviewComment> comments,
) async {
  var mirrored = comments.where((c) => c.githubCommentId != null).toList();
  if (mirrored.isEmpty) return;
  ({String prUrl, String token}) context;
  try {
    context = await repoContextFor(session, task.id!);
  } catch (e) {
    session.log('Not resolving GitHub threads: $e', level: LogLevel.warning);
    return;
  }
  for (var comment in mirrored) {
    try {
      await gitHubRepoClient.resolveThread(
        prUrl: context.prUrl,
        token: context.token,
        githubCommentId: comment.githubCommentId!,
      );
    } catch (e) {
      session.log(
        'Resolving GitHub thread for comment ${comment.id} failed: $e',
        level: LogLevel.warning,
      );
    }
  }
}

/// Channel the panel's `CodeReviewEndpoint.watchReviews` listens on.
String channelForTaskReviews(int taskId) => 'task-$taskId-reviews';

/// Loads [reviewId] with its comments (oldest first) and sends it to the
/// task's [channelForTaskReviews] watchers, which merge it in by id.
Future<CodeReview> postReviewChanged(Session session, int reviewId) async {
  var review = await CodeReview.db.findById(
    session,
    reviewId,
    include: CodeReview.include(
      comments: ReviewComment.includeList(orderBy: (c) => c.id),
    ),
  );
  if (review == null) {
    throw NotFoundException(message: 'Code review $reviewId not found');
  }
  await session.messages.postMessage(
    channelForTaskReviews(review.taskId),
    review,
  );
  await refreshOpenReviewComments(session, review.taskId);
  await refreshReviewPause(session, review.taskId);
  return review;
}

/// Mirrors a `queued` code review waiting for the Claude usage limit onto
/// its `awaitingReview` task (`pausedUntil`, `pauseReason`, `pausedPhase`
/// `review`), so the kanban shows the pause like a paused run's — and
/// clears it once no review of the task waits anymore. The task keeps its
/// status: the review, not the agent's run, resumes.
Future<void> refreshReviewPause(Session session, int taskId) async {
  final task = await Task.db.findById(session, taskId);
  if (task == null || task.status == TaskStatus.paused) return;
  final waiting = task.status == TaskStatus.awaitingReview
      ? await CodeReview.db.findFirstRow(
          session,
          where: (r) =>
              r.taskId.equals(taskId) &
              r.status.equals(CodeReviewStatus.queued) &
              r.pausedUntil.notEquals(null),
          orderBy: (r) => r.pausedUntil.desc(),
        )
      : null;
  final Task next;
  if (waiting != null) {
    next = task.copyWith(
      pausedUntil: waiting.pausedUntil,
      pauseReason: waiting.pauseReason,
      pausedPhase: LogPhase.review,
    );
  } else if (task.pausedPhase == LogPhase.review) {
    next = task.copyWith(
      pausedUntil: null,
      pauseReason: null,
      pausedPhase: null,
    );
  } else {
    return;
  }
  if (next.pausedUntil == task.pausedUntil &&
      next.pauseReason == task.pauseReason &&
      next.pausedPhase == task.pausedPhase) {
    return;
  }
  final updated = await Task.db.updateRow(
    session,
    next,
    columns: (t) => [t.pausedUntil, t.pauseReason, t.pausedPhase],
  );
  await publishTask(session, updated);
}

/// Review comment states that still wait for a fix or a decision.
const unresolvedCommentStates = {
  ReviewCommentState.open,
  ReviewCommentState.sentToFix,
};

/// Counts [taskId]'s unresolved review comments across all its reviews —
/// only those of [severities], when given.
Future<int> countUnresolvedComments(
  Session session,
  int taskId, {
  Set<ReviewCommentSeverity>? severities,
}) async {
  final reviewIds = (await CodeReview.db.find(
    session,
    where: (r) => r.taskId.equals(taskId),
  )).map((r) => r.id!).toSet();
  if (reviewIds.isEmpty) return 0;
  return ReviewComment.db.count(
    session,
    where: (c) {
      var where =
          c.reviewId.inSet(reviewIds) & c.state.inSet(unresolvedCommentStates);
      if (severities != null) where = where & c.severity.inSet(severities);
      return where;
    },
  );
}

/// Recounts [taskId]'s unresolved review comments into
/// `Task.openReviewComments` for the kanban, and notifies the panel when the
/// count changed.
Future<void> refreshOpenReviewComments(Session session, int taskId) async {
  final task = await Task.db.findById(session, taskId);
  if (task == null) return;
  final open = await countUnresolvedComments(session, taskId);
  if (open == task.openReviewComments) return;
  // Only this column: the daemon and the panel write the task's other
  // fields concurrently.
  final updated = await Task.db.updateRow(
    session,
    task.copyWith(openReviewComments: open),
    columns: (t) => [t.openReviewComments],
  );
  await publishTask(session, updated);
}

/// Adds a system event to [taskId]'s timeline, inside its latest run (an
/// entry without a run would land in a separate legacy run).
Future<void> logTaskEvent(Session session, int taskId, String text) async {
  final latest = await TaskLogEntry.db.findFirstRow(
    session,
    where: (e) =>
        e.taskId.equals(taskId) &
        e.runId.notEquals(null) &
        e.reviewId.equals(null),
    orderBy: (e) => e.createdAt.desc(),
  );
  final entry = await TaskLogEntry.db.insertRow(
    session,
    TaskLogEntry(
      taskId: taskId,
      content: text,
      source: LogSource.system,
      kind: LogKind.event,
      runId: latest?.runId,
      phase: latest?.phase,
    ),
  );
  await session.messages.postMessage(channelForTaskLogs(taskId), entry);
}

/// Channel a machine's daemon receives its assigned reviews on
/// (`CodeReviewEndpoint.watchAssignedReviews`).
String reviewChannelForMachine(int machineId) => 'machine-$machineId-reviews';

/// Queues a review of [task]'s PR by [reviewer] and wakes its daemon.
Future<CodeReview> queueCodeReview(
  Session session,
  Task task,
  Agent reviewer,
) async {
  var review = await CodeReview.db.insertRow(
    session,
    CodeReview(taskId: task.id!, reviewerAgentId: reviewer.id!),
  );
  await session.messages.postMessage(
    reviewChannelForMachine(reviewer.machineId),
    review,
  );
  return postReviewChanged(session, review.id!);
}

/// Auto review (`Task.autoReview`): queues a review of the version a run
/// just left awaiting review. Best effort — a missing reviewer or a review
/// already in flight is noted on the timeline instead of failing the run.
Future<void> autoReviewIfEnabled(Session session, Task task) async {
  final reviewerId = task.reviewerAgentId;
  if (!task.autoReview || task.prUrl == null) return;
  try {
    final reviewer = reviewerId == null
        ? null
        : await Agent.db.findById(session, reviewerId);
    if (reviewer == null) {
      await logTaskEvent(
        session,
        task.id!,
        'Auto review skipped — no reviewer agent is set',
      );
      return;
    }
    final active = await CodeReview.db.count(
      session,
      where: (r) =>
          r.taskId.equals(task.id!) & r.status.inSet(activeCodeReviewStatuses),
    );
    if (active > 0) return;
    await queueCodeReview(session, task, reviewer);
    await logTaskEvent(
      session,
      task.id!,
      'Auto review requested from ${reviewer.name}',
    );
  } catch (e) {
    session.log(
      'Auto review of task ${task.id} failed: $e',
      level: LogLevel.warning,
    );
  }
}

/// Sends [comments] — plus an optional [note] from the dev — to [task]'s
/// agent as one review-feedback iteration. They're marked `sentToFix`, then
/// `resolved` once that run finishes (`TaskEndpoint.update`).
Future<TaskFeedback> sendCommentsToAgent(
  Session session,
  Task task,
  List<ReviewComment> comments,
  String? note,
) async {
  var trimmedNote = note?.trim() ?? '';
  if (comments.isEmpty && trimmedNote.isEmpty) {
    throw InvalidStateException(
      message: 'Nothing to send: pick at least one comment',
    );
  }

  var message = StringBuffer();
  if (trimmedNote.isNotEmpty) {
    message.writeln(trimmedNote);
  }
  if (comments.isNotEmpty) {
    if (message.isNotEmpty) message.writeln();
    message.writeln('Address these code review comments:');
    for (var i = 0; i < comments.length; i++) {
      var c = comments[i];
      var location = c.line == null ? c.path : '${c.path}:${c.line}';
      message.writeln('${i + 1}. $location [${c.severity.name}] ${c.body}');
    }
  }

  var feedback = await queueReviewFeedback(
    session,
    task,
    message.toString().trim(),
    kind: TaskFeedbackKind.reviewComments,
    alsoWrite: comments.isEmpty
        ? null
        : (transaction) => ReviewComment.db.update(
            session,
            [
              for (var c in comments)
                c.copyWith(state: ReviewCommentState.sentToFix),
            ],
            columns: (c) => [c.state],
            transaction: transaction,
          ),
  );

  for (var reviewId in comments.map((c) => c.reviewId).toSet()) {
    await postReviewChanged(session, reviewId);
  }
  return feedback;
}

/// Severities auto fix sends to the agent; nits are left to the dev.
const autoFixSeverities = {
  ReviewCommentSeverity.blocker,
  ReviewCommentSeverity.issue,
};

/// Auto fix (`Task.autoFixReview`): once a review completes, sends its open
/// blocker/issue [comments] to the task's agent, at most
/// `Task.maxReviewFixRounds` times per task. Best effort — anything that
/// stops it is noted on the timeline, and the task waits for the dev.
Future<void> autoFixReviewIfEnabled(
  Session session,
  int taskId,
  List<ReviewComment> comments,
) async {
  try {
    final task = await Task.db.findById(session, taskId);
    if (task == null || !task.autoFixReview) return;
    if (task.status != TaskStatus.awaitingReview) return;
    final toFix = comments
        .where(
          (c) =>
              c.state == ReviewCommentState.open &&
              autoFixSeverities.contains(c.severity),
        )
        .toList();
    if (toFix.isEmpty) {
      await logTaskEvent(
        session,
        taskId,
        'Auto fix: the review found no blockers or issues — over to you',
      );
      return;
    }
    if (task.reviewFixRounds >= task.maxReviewFixRounds) {
      await logTaskEvent(
        session,
        taskId,
        'Auto fix stopped after ${task.reviewFixRounds} '
        '${task.reviewFixRounds == 1 ? 'round' : 'rounds'} — '
        '${toFix.length} ${toFix.length == 1 ? 'comment is' : 'comments are'} '
        'left for you',
      );
      return;
    }
    final round = task.reviewFixRounds + 1;
    await sendCommentsToAgent(session, task, toFix, null);
    await Task.db.updateRow(
      session,
      task.copyWith(reviewFixRounds: round),
      columns: (t) => [t.reviewFixRounds],
    );
    await logTaskEvent(
      session,
      taskId,
      'Auto fix: sent ${toFix.length} review '
      '${toFix.length == 1 ? 'comment' : 'comments'} to the agent '
      '(round $round of ${task.maxReviewFixRounds})',
    );
  } catch (e) {
    session.log(
      'Auto fix of task $taskId failed: $e',
      level: LogLevel.warning,
    );
  }
}
