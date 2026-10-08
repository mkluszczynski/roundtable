import 'package:serverpod/serverpod.dart';

import 'endpoints/task_endpoint.dart';
import 'generated/protocol.dart';
import 'task_review_support.dart';

/// Broadcasts a changed [task] to the panel: its own watchers (task detail)
/// and the board. With [machineId], also to that machine's daemon, which
/// picks up new and resumed work from its channel — it is notified first.
Future<void> publishTask(Session session, Task task, {int? machineId}) async {
  if (machineId != null) {
    await session.messages.postMessage(taskChannelForMachine(machineId), task);
  }
  await session.messages.postMessage(
    TaskEndpoint.channelForTask(task.id!),
    task,
  );
  await session.messages.postMessage(TaskEndpoint.channelForAllTasks(), task);
}
