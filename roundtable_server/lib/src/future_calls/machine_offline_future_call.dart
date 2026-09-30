import '../endpoints/non_terminal_task_statuses.dart';
import '../endpoints/task_endpoint.dart';
import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Detects machines whose daemon has stopped heartbeating and marks them
/// offline, failing any non-terminal tasks belonging to that machine's
/// agents (design doc §6.8). Scheduled to run recurringly from `server.dart`.
class MachineOfflineFutureCall extends FutureCall {
  static const _offlineThreshold = Duration(seconds: 60);

  Future<void> check(Session session) async {
    final cutoff = DateTime.now().toUtc().subtract(_offlineThreshold);

    final staleMachines = await Machine.db.find(
      session,
      where: (t) =>
          t.status.equals(MachineStatus.online) & (t.lastSeenAt < cutoff),
    );

    for (final machine in staleMachines) {
      await Machine.db.updateRow(
        session,
        machine.copyWith(status: MachineStatus.offline),
      );

      final agentIds = (await Agent.db.find(
        session,
        where: (t) => t.machineId.equals(machine.id!),
      )).map((agent) => agent.id!).toSet();
      if (agentIds.isEmpty) continue;

      final staleTasks = await Task.db.find(
        session,
        where: (t) =>
            t.agentId.inSet(agentIds) & t.status.inSet(nonTerminalTaskStatuses),
      );
      for (final task in staleTasks) {
        final updated = await Task.db.updateRow(
          session,
          task.copyWith(
            status: TaskStatus.failed,
            failureReason: 'Machine went offline mid-task',
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
  }
}
