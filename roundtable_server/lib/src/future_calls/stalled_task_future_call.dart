import '../endpoints/non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import '../task_lifecycle.dart';
import 'package:serverpod/serverpod.dart';

/// Detects tasks that have made no progress for longer than
/// [_stalledThreshold] — e.g. a hung Claude Code subprocess on a machine
/// that's still heartbeating, unlike [MachineOfflineFutureCall] which only
/// catches a machine that's gone entirely (docs/ARCHITECTURE.md "Timeout for a
/// stuck task"). Scheduled to run recurringly from `server.dart`.
class StalledTaskFutureCall extends FutureCall {
  static const _stalledThreshold = Duration(minutes: 15);

  /// Statuses where the task is waiting on the developer, not the agent, so
  /// a lack of progress is expected.
  static const _waitingOnHumanStatuses = {
    TaskStatus.draft,
    TaskStatus.waitingForAnswer,
    TaskStatus.planReady,
    TaskStatus.awaitingReview,
    // Waiting for the usage limit to reset, by design.
    TaskStatus.paused,
  };

  Future<void> check(Session session) async {
    final cutoff = DateTime.now().toUtc().subtract(_stalledThreshold);

    final stalledTasks = await Task.db.find(
      session,
      where: (t) =>
          t.status.inSet(
            nonTerminalTaskStatuses.difference(_waitingOnHumanStatuses),
          ) &
          (t.lastProgressAt < cutoff),
    );

    final waiting = <int>{};
    for (final task in stalledTasks) {
      if (task.status == TaskStatus.queued &&
          await _waitsForItsTurn(session, task)) {
        waiting.add(task.id!);
      }
    }

    await failTasks(
      session,
      [
        for (final t in stalledTasks)
          if (!waiting.contains(t.id)) t,
      ],
      'Task made no progress for over ${_stalledThreshold.inMinutes} minutes',
    );
  }

  /// A queued task isn't stalled while the runner holds it back on purpose
  /// (docs/FLOWS.md §5): its agent is busy with another task or review —
  /// one piece of work per agent — or its machine is usage limited.
  Future<bool> _waitsForItsTurn(Session session, Task task) async {
    final agentId = task.agentId;
    if (agentId == null) return false;
    final otherWork = await Task.db.count(
      session,
      where: (t) =>
          t.agentId.equals(agentId) &
          t.id.notEquals(task.id) &
          t.status.inSet(_agentBusyStatuses),
    );
    if (otherWork > 0) return true;
    final reviewing = await CodeReview.db.count(
      session,
      where: (r) =>
          r.reviewerAgentId.equals(agentId) &
          r.status.equals(CodeReviewStatus.running),
    );
    if (reviewing > 0) return true;
    final agent = await Agent.db.findById(
      session,
      agentId,
      include: Agent.include(machine: Machine.include()),
    );
    final limitedUntil = agent?.machine?.usageLimitedUntil;
    return limitedUntil != null && limitedUntil.isAfter(DateTime.now());
  }

  /// Task statuses that occupy their agent's turn on the runner.
  static const _agentBusyStatuses = {
    TaskStatus.cloning,
    TaskStatus.planning,
    TaskStatus.running,
    TaskStatus.waitingForAnswer,
  };
}
