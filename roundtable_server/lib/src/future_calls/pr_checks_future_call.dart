import '../generated/protocol.dart';
import '../auto_merge.dart';
import '../pr_checks.dart';
import 'package:serverpod/serverpod.dart';

/// Polls the GitHub Actions checks of every task waiting in review — every
/// run while they're pending, every `settledPollInterval` once settled
/// (docs/FLOWS.md §4 "CI checks") — there's no webhook, since the server
/// needn't be reachable from GitHub. Tasks whose agent is running aren't
/// polled: its push gets picked up once the task is back in review.
/// Scheduled to run recurringly from `server.dart`.
class PrChecksFutureCall extends FutureCall {
  Future<void> check(Session session) async {
    final tasks = await Task.db.find(
      session,
      where: (t) =>
          t.status.equals(TaskStatus.awaitingReview) & t.prUrl.notEquals(null),
    );
    for (final task in tasks) {
      // Settled checks are polled less often, to spare the token's GitHub
      // rate limit (shared with merges, reviews and conflict checks).
      if (!shouldPollChecks(task)) continue;
      // Logs (doesn't throw) per task, so one broken repo can't starve the
      // others.
      await syncChecksQuietly(session, task);
    }
    // Re-read: the syncs above may have changed the checks.
    final ready = await Task.db.find(
      session,
      where: (t) =>
          t.status.equals(TaskStatus.awaitingReview) &
          t.prUrl.notEquals(null) &
          t.autoMerge.equals(true),
    );
    for (final task in ready) {
      await autoMergeIfReady(session, task);
    }
  }
}
