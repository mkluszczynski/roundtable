import 'package:serverpod/serverpod.dart';

import 'endpoints/task_endpoint.dart';
import 'generated/protocol.dart';
import 'pr_checks.dart';
import 'task_review_support.dart';

/// Why [task] isn't ready to auto merge yet, or null when it is. Only
/// reads the database — the merge itself re-checks CI fresh from GitHub.
Future<String?> autoMergeWaitingFor(Session session, Task task) async {
  if (task.status != TaskStatus.awaitingReview || task.prUrl == null) {
    return 'not awaiting review';
  }
  final taskId = task.id!;
  final activeReviews = await CodeReview.db.count(
    session,
    where: (r) =>
        r.taskId.equals(taskId) & r.status.inSet(activeCodeReviewStatuses),
  );
  if (activeReviews > 0) return 'a review is running';
  if (await hasQueuedFixRun(session, task)) return 'a fix run is queued';

  if (task.autoReview) {
    final latestReview = await CodeReview.db.findFirstRow(
      session,
      where: (r) => r.taskId.equals(taskId),
      orderBy: (r) => r.createdAt.desc(),
    );
    if (latestReview == null ||
        latestReview.status != CodeReviewStatus.completed) {
      return 'the latest version is not reviewed';
    }
    // Feedback after the review means the PR changed since.
    final latestFeedback = await TaskFeedback.db.findFirstRow(
      session,
      where: (f) => f.taskId.equals(taskId),
      orderBy: (f) => f.createdAt.desc(),
    );
    if (latestFeedback != null &&
        latestFeedback.createdAt.isAfter(latestReview.createdAt)) {
      return 'the latest version is not reviewed';
    }
    // Reviews from before verdicts existed (null) go by their comments.
    if (latestReview.verdict == CodeReviewVerdict.changesRequested) {
      return 'the reviewer requested changes';
    }
    final unresolved = await countUnresolvedComments(
      session,
      taskId,
      severities: autoFixSeverities,
    );
    if (unresolved > 0) return 'review blockers or issues are open';
  }

  if (task.checkState != PrCheckState.success &&
      task.checkState != PrCheckState.none) {
    return 'CI is ${task.checkState.name}';
  }
  return null;
}

/// Auto merge (`Task.autoMerge`): merges [task]'s PR once
/// [autoMergeWaitingFor] has nothing left to wait for. If GitHub refuses
/// (conflicts, failing checks it saw fresh, branch protection), auto merge
/// is switched off for the task and the reason logged — the dev takes over
/// instead of the server retrying every poll.
Future<void> autoMergeIfReady(Session session, Task task) async {
  if (!task.autoMerge) return;
  if (await autoMergeWaitingFor(session, task) != null) return;
  try {
    await TaskEndpoint().acceptTask(session, task.id!);
    await logTaskEvent(session, task.id!, 'Auto merged — all checks passed');
  } catch (e) {
    final reason = switch (e) {
      InvalidStateException(:final message) => message,
      GitHubException(:final message) => message,
      _ => '$e',
    };
    final current = await Task.db.findById(session, task.id!);
    if (current == null) return;
    // CI re-read fresh can still be pending: wait for the next poll.
    if (current.checkState == PrCheckState.pending) return;
    final updated = await Task.db.updateRow(
      session,
      current.copyWith(autoMerge: false),
      columns: (t) => [t.autoMerge],
    );
    await session.messages.postMessage(
      TaskEndpoint.channelForTask(task.id!),
      updated,
    );
    await logTaskEvent(
      session,
      task.id!,
      'Auto merge stopped — $reason Merge it by hand.',
    );
  }
}
