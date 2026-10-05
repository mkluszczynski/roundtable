import 'package:serverpod/serverpod.dart';

import 'endpoints/task_endpoint.dart';
import 'generated/protocol.dart';
import 'github_repo_client.dart';

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
    await session.messages.postMessage(
      TaskEndpoint.channelForTask(task.id!),
      updated,
    );
    await session.messages.postMessage(
      TaskEndpoint.channelForAllTasks(),
      updated,
    );
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
  return review;
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
