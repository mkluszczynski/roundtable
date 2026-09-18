import '../generated/protocol.dart';

/// [TaskStatus] values that count as "in progress" for the deletion guards on
/// [MachineEndpoint] and [AgentEndpoint] (design doc §5, §6.8).
const nonTerminalTaskStatuses = {
  TaskStatus.queued,
  TaskStatus.cloning,
  TaskStatus.planning,
  TaskStatus.waitingForAnswer,
  TaskStatus.planReady,
  TaskStatus.running,
  TaskStatus.awaitingReview,
};
