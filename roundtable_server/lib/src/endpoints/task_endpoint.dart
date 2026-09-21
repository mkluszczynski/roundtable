import 'non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Task creation and the daemon's assignment feed (design doc §6.1).
class TaskEndpoint extends Endpoint {
  static String _channelForMachine(int machineId) => 'machine-$machineId-tasks';
  static String _channelForTaskLogs(int taskId) => 'task-$taskId-logs';
  static String _channelForTask(int taskId) => 'task-$taskId';

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
  /// (design doc §6.3) and notifies any [watchLogs] subscribers for this
  /// task.
  Future<TaskLogEntry> appendLog(
    Session session,
    int taskId,
    String content, {
    LogSource source = LogSource.agent,
  }) async {
    var entry = await TaskLogEntry.db.insertRow(
      session,
      TaskLogEntry(taskId: taskId, content: content, source: source),
    );

    await session.messages.postMessage(_channelForTaskLogs(taskId), entry);

    return entry;
  }

  /// Cancels a task that hasn't reached a terminal state yet (design doc
  /// §6.1 "Cancelling mid-run"): marks it `cancelled` and notifies
  /// [watchTask] subscribers — the daemon running the task reacts by
  /// sending `SIGTERM` to the Claude Code subprocess and resetting the
  /// worktree.
  Future<Task> cancelTask(Session session, int taskId) async {
    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw Exception('Task $taskId not found');
    }
    if (!nonTerminalTaskStatuses.contains(task.status)) {
      throw Exception(
        'Task $taskId is not in a cancellable state (${task.status})',
      );
    }

    task = await Task.db.updateRow(
      session,
      task.copyWith(
        status: TaskStatus.cancelled,
        finishedAt: DateTime.now().toUtc(),
      ),
    );
    await session.messages.postMessage(_channelForTask(taskId), task);

    return task;
  }

  /// Records feedback on a completed run (design doc §6.1 step 9, §6.4) and
  /// wakes the daemon via the same channel [createTask] uses — the daemon
  /// picks it up through its existing [watchAssignedTasks] subscription and
  /// resumes the same Claude Code session (`TaskDispatcher.handle`).
  Future<TaskFeedback> submitFeedback(
    Session session,
    int taskId,
    String message,
  ) async {
    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw Exception('Task $taskId not found');
    }
    if (task.status != TaskStatus.awaitingReview) {
      throw Exception('Task $taskId is not awaiting review (${task.status})');
    }
    var agentId = task.agentId;
    if (agentId == null) {
      throw Exception('Task $taskId has no assigned agent');
    }
    var agent = await Agent.db.findById(session, agentId);
    if (agent == null) {
      throw Exception('Agent $agentId not found');
    }

    var feedback = await TaskFeedback.db.insertRow(
      session,
      TaskFeedback(
        taskId: taskId,
        message: message,
        phase: TaskFeedbackPhase.review,
      ),
    );

    // Status is deliberately left as `awaitingReview` here — the dispatcher
    // itself flips it to `running` once it actually picks the resume up,
    // mirroring how it already does that transition for a fresh `queued`
    // task.
    await session.messages.postMessage(
      _channelForMachine(agent.machineId),
      task,
    );

    return feedback;
  }

  /// Returns the most recently submitted [TaskFeedback] for [taskId], or
  /// `null` if none exists. Used by the daemon to fetch the message text of
  /// a review-phase feedback that woke it via [submitFeedback], and to tell
  /// a stale replay (e.g. after a daemon restart) apart from a real pending
  /// one — see `TaskDispatcher.handle`'s use of `Task.finishedAt`.
  Future<TaskFeedback?> latestFeedback(Session session, int taskId) async {
    var results = await TaskFeedback.db.find(
      session,
      where: (t) => t.taskId.equals(taskId),
      orderBy: (t) => t.createdAt.desc(),
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
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

  /// Streams a task's execution output as it's persisted via [appendLog]
  /// (design doc §6.3), for the panel to render live. On subscribe, first
  /// replays every already-persisted [TaskLogEntry] for [taskId] in order,
  /// then yields each new entry as it's appended.
  Stream<TaskLogEntry> watchLogs(Session session, int taskId) async* {
    var existing = await TaskLogEntry.db.find(
      session,
      where: (t) => t.taskId.equals(taskId),
      orderBy: (t) => t.createdAt,
    );
    for (var entry in existing) {
      yield entry;
    }

    var updates = session.messages.createStream<TaskLogEntry>(
      _channelForTaskLogs(taskId),
    );
    await for (var entry in updates) {
      yield entry;
    }
  }

  /// Streams [taskId]'s status, for the daemon running it (to detect a
  /// cancellation mid-run, design doc §6.1) and the panel alike. On
  /// subscribe, first replays the task's current row, then yields it again
  /// each time [cancelTask] cancels it.
  Stream<Task> watchTask(Session session, int taskId) async* {
    var task = await Task.db.findById(session, taskId);
    if (task != null) {
      yield task;
    }

    var updates = session.messages.createStream<Task>(_channelForTask(taskId));
    await for (var t in updates) {
      yield t;
    }
  }
}
