import 'package:serverpod/serverpod.dart';

import 'endpoints/task_endpoint.dart';
import 'generated/protocol.dart';

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
    await session.messages.postMessage(
      TaskEndpoint.channelForTask(updated.id!),
      updated,
    );
    await session.messages.postMessage(
      TaskEndpoint.channelForAllTasks(),
      updated,
    );
  }
}
