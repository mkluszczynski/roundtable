import '../endpoints/non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import '../task_lifecycle.dart';
import 'package:serverpod/serverpod.dart';

/// Detects machines whose daemon has stopped heartbeating and marks them
/// offline, failing any non-terminal tasks belonging to that machine's
/// agents (docs/FLOWS.md §1–3). Scheduled to run recurringly from
/// `server.dart`.
class MachineOfflineFutureCall extends FutureCall {
  static const _offlineThreshold = Duration(seconds: 60);

  /// A Claude token set in the panel that no daemon picked up by then (the
  /// machine is offline, or its runner predates the feature) is dropped,
  /// so the secret doesn't linger in the database (docs/FLOWS.md §1).
  static const claudeTokenTtl = Duration(minutes: 10);

  Future<void> check(Session session) async {
    final cutoff = DateTime.now().toUtc().subtract(_offlineThreshold);

    await Machine.db.updateWhere(
      session,
      columnValues: (t) => [
        t.pendingClaudeToken(null),
        t.claudeTokenRequestedAt(null),
      ],
      where: (t) =>
          t.claudeTokenRequestedAt <
          DateTime.now().toUtc().subtract(claudeTokenTtl),
    );

    final staleMachines = await Machine.db.find(
      session,
      where: (t) =>
          t.status.equals(MachineStatus.online) & (t.lastSeenAt < cutoff),
    );

    for (final machine in staleMachines) {
      await Machine.db.updateRow(
        session,
        machine.copyWith(status: MachineStatus.offline),
        columns: (t) => [t.status],
      );

      final agentIds = (await Agent.db.find(
        session,
        where: (t) => t.machineId.equals(machine.id!),
      )).map((agent) => agent.id!).toSet();
      if (agentIds.isEmpty) continue;

      final staleTasks = await Task.db.find(
        session,
        where: (t) =>
            t.agentId.inSet(agentIds) &
            // A paused task has no live process to lose; it resumes once
            // the machine is back.
            t.status.inSet(
              nonTerminalTaskStatuses.difference({TaskStatus.paused}),
            ),
      );
      await failTasks(session, staleTasks, 'Machine went offline mid-task');
    }
  }
}
