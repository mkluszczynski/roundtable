import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// [TaskStatus] values that count as "in progress" for the deletion guards on
/// [MachineEndpoint] and [AgentEndpoint] (docs/ARCHITECTURE.md).
const nonTerminalTaskStatuses = {
  TaskStatus.draft,
  TaskStatus.queued,
  TaskStatus.cloning,
  TaskStatus.planning,
  TaskStatus.waitingForAnswer,
  TaskStatus.planReady,
  TaskStatus.running,
  TaskStatus.awaitingReview,
};

/// Runs a delete guard (check for blocking rows, then delete) as one
/// serializable transaction, so a task created or a heartbeat arriving
/// between the check and the delete can't slip past the guard — Postgres
/// aborts one of the two conflicting transactions instead.
Future<void> guardedDelete(
  Session session,
  Future<void> Function(Transaction transaction) body,
) => session.db.transaction(
  body,
  settings: const TransactionSettings(
    isolationLevel: IsolationLevel.serializable,
  ),
);
