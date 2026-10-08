import 'package:serverpod/serverpod.dart';

import 'generated/protocol.dart';
import 'task_events.dart';

/// Task statuses in which a live `claude` process on the agent's machine is
/// driving the task. If that process is gone (machine offline, daemon
/// restarted), the task can't continue.
const agentDrivenTaskStatuses = {
  TaskStatus.cloning,
  TaskStatus.planning,
  TaskStatus.waitingForAnswer,
  TaskStatus.planReady,
  TaskStatus.running,
};

/// Marks each of [tasks] `failed` with [reason] and broadcasts the change to
/// the panel. Shared by the future calls and [MachineEndpoint.reportStartup]
/// — kept out of the endpoint classes so it isn't exposed as an RPC method.
Future<void> failTasks(
  Session session,
  Iterable<Task> tasks,
  String reason,
) async {
  for (final task in tasks) {
    final updated = await Task.db.updateRow(
      session,
      task.copyWith(
        status: TaskStatus.failed,
        failureReason: reason,
        finishedAt: DateTime.now().toUtc(),
      ),
    );
    await publishTask(session, updated);
  }
}

/// Puts a paused [task] back in the queue so its agent's daemon resumes the
/// same Claude session in the phase it was paused in (`pausedPhase`).
Future<Task> resumePausedTask(Session session, Task task) async {
  final updated = await Task.db.updateRow(
    session,
    task.copyWith(
      status: TaskStatus.queued,
      pausedUntil: null,
      lastProgressAt: DateTime.now().toUtc(),
    ),
    columns: (t) => [t.status, t.pausedUntil, t.lastProgressAt],
  );
  final agentId = updated.agentId;
  final agent = agentId == null
      ? null
      : await Agent.db.findById(session, agentId);
  await publishTask(session, updated, machineId: agent?.machineId);
  return updated;
}
