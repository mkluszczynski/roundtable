import '../endpoints/non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Detects tasks that have made no progress for longer than
/// [_stalledThreshold] — e.g. a hung Claude Code subprocess on a machine
/// that's still heartbeating, unlike [MachineOfflineFutureCall] which only
/// catches a machine that's gone entirely (design doc §4 "Timeout for a
/// stuck task"). Scheduled to run recurringly from `server.dart`.
class StalledTaskFutureCall extends FutureCall {
  static const _stalledThreshold = Duration(minutes: 15);

  Future<void> check(Session session) async {
    final cutoff = DateTime.now().toUtc().subtract(_stalledThreshold);

    final stalledTasks = await Task.db.find(
      session,
      where: (t) =>
          t.status.inSet(nonTerminalTaskStatuses) & (t.lastProgressAt < cutoff),
    );

    for (final task in stalledTasks) {
      await Task.db.updateRow(
        session,
        task.copyWith(
          status: TaskStatus.failed,
          failureReason:
              'Task made no progress for over ${_stalledThreshold.inMinutes} minutes',
          finishedAt: DateTime.now().toUtc(),
        ),
      );
    }
  }
}
