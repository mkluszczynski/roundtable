import 'non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Task creation and the daemon's assignment feed (design doc §6.1).
class TaskEndpoint extends Endpoint {
  static String _channelForMachine(int machineId) => 'machine-$machineId-tasks';

  /// Creates a [Task] already assigned to [agentId] (design doc §6.1 step 1 —
  /// queueing without an agent is a Should-scope feature, not implemented
  /// here even though the schema allows `Task.agent` to be null).
  ///
  /// Notifies the assigned agent's machine via [watchAssignedTasks].
  Future<Task> createTask(
    Session session,
    int projectId,
    int agentId,
    String prompt, {
    bool skipPlanning = false,
  }) async {
    var agent = await Agent.db.findById(session, agentId);
    if (agent == null) {
      throw Exception('Agent $agentId not found');
    }

    var task = await Task.db.insertRow(
      session,
      Task(
        projectId: projectId,
        agentId: agentId,
        prompt: prompt,
        skipPlanning: skipPlanning,
        status: TaskStatus.queued,
      ),
    );

    await session.messages.postMessage(
      _channelForMachine(agent.machineId),
      task,
    );

    return task;
  }

  /// Streams tasks newly assigned to any agent hosted on [machineId] (design
  /// doc §6.1 step 2 — by machine, not by agent, since one daemon serves
  /// every agent it hosts). On subscribe, first replays any already-queued,
  /// non-terminal tasks for that machine — otherwise a task created while the
  /// daemon was offline/restarting would never surface — then yields each
  /// task as it's created via [createTask].
  /// Generic CRUD update, mirroring [ProjectEndpoint.update] /
  /// [AgentEndpoint.update] / [MachineEndpoint.update]. Used by the agent
  /// daemon to move a task through its lifecycle (design doc §6.1) —
  /// e.g. `running` → `awaitingReview`/`failed` — and to persist
  /// `claudeSessionId` once Claude Code reports one.
  Future<Task> update(Session session, Task task) async {
    return Task.db.updateRow(session, task);
  }

  /// Persists one line of a task's execution output as a [TaskLogEntry]
  /// (design doc §6.3) — the panel's `watchLogs` stream, once it exists,
  /// picks these up via `TaskLogEntry.db.watch()`.
  Future<TaskLogEntry> appendLog(
    Session session,
    int taskId,
    String content, {
    LogSource source = LogSource.agent,
  }) async {
    return TaskLogEntry.db.insertRow(
      session,
      TaskLogEntry(taskId: taskId, content: content, source: source),
    );
  }

  Stream<Task> watchAssignedTasks(Session session, int machineId) async* {
    var agentIds = (await Agent.db.find(
      session,
      where: (t) => t.machineId.equals(machineId),
    )).map((agent) => agent.id!).toSet();

    var pending = await Task.db.find(
      session,
      where: (t) =>
          t.agentId.inSet(agentIds) & t.status.inSet(nonTerminalTaskStatuses),
      orderBy: (t) => t.createdAt,
    );
    for (var task in pending) {
      yield task;
    }

    var updates = session.messages.createStream<Task>(
      _channelForMachine(machineId),
    );
    await for (var task in updates) {
      yield task;
    }
  }
}
