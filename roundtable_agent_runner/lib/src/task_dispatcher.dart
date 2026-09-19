import 'package:roundtable_client/roundtable_client.dart';

import 'claude_code_executor.dart';
import 'role_prompts.dart';
import 'worktree_manager.dart';

/// Turns an assigned [Task] into a running Claude Code execution-phase
/// process (design doc §6.1 step 5, §6.2), for tasks that skip planning.
///
/// Server-facing dependencies are injected as plain functions rather than
/// the concrete generated `Client`, so this class is unit-testable without
/// mocking Serverpod's generated code.
class TaskDispatcher {
  TaskDispatcher({
    required this.worktreeManager,
    required this.executorFactory,
    required this.oauthToken,
    required this.getCloneUrl,
    required this.fetchAgent,
    required this.updateTask,
    required this.updateAgent,
    required this.appendLog,
    required this.log,
  });

  final WorktreeManager worktreeManager;
  final ClaudeCodeExecutor Function() executorFactory;
  final String? oauthToken;
  final Future<String> Function(int projectId) getCloneUrl;
  final Future<Agent> Function(int agentId) fetchAgent;
  final Future<void> Function(Task task) updateTask;
  final Future<void> Function(Agent agent) updateAgent;
  final Future<void> Function(int taskId, String content) appendLog;
  final void Function(String message) log;

  /// Handles one assigned [task]. Planning-phase tasks (`skipPlanning ==
  /// false`) and tasks not in their initial `queued` state (e.g. replayed on
  /// reconnect while already running) are deliberately left untouched —
  /// planning-phase execution isn't implemented yet (design doc §6.4).
  Future<void> handle(Task task) async {
    if (!task.skipPlanning) {
      log('task ${task.id}: planning phase not implemented yet, skipping');
      return;
    }
    if (task.status != TaskStatus.queued) {
      log('task ${task.id}: not queued (status=${task.status}), skipping');
      return;
    }

    final projectId = task.projectId;
    final agentId = task.agentId;
    if (agentId == null) {
      log('task ${task.id}: missing agentId, skipping');
      return;
    }

    Agent? agent;
    try {
      final cloneUrl = await getCloneUrl(projectId);
      await worktreeManager.ensureProjectCloned(
        projectId: '$projectId',
        cloneUrl: cloneUrl,
      );
      final worktreePath = await worktreeManager.createWorktree(
        projectId: '$projectId',
        taskId: '${task.id}',
      );

      agent = await fetchAgent(agentId);
      await updateAgent(agent.copyWith(status: AgentStatus.busy));
      await updateTask(
        task.copyWith(
          status: TaskStatus.running,
          startedAt: DateTime.now().toUtc(),
        ),
      );

      final resumeSessionId = task.claudeSessionId;
      final prompt = resumeSessionId != null
          ? ''
          : '${buildRolePrompt(agent.role, agent.name)} ${task.prompt}';

      final result = await executorFactory().run(
        prompt: prompt,
        workingDirectory: worktreePath,
        oauthToken: oauthToken,
        model: agent.defaultModel,
        effort: agent.defaultEffort?.name,
        resumeSessionId: resumeSessionId,
        onLine: (line) => appendLog(task.id!, line),
      );

      await updateTask(
        task.copyWith(
          status: result.success
              ? TaskStatus.awaitingReview
              : TaskStatus.failed,
          finishedAt: DateTime.now().toUtc(),
          claudeSessionId: result.sessionId ?? task.claudeSessionId,
          failureReason: result.success ? null : result.errorSummary,
        ),
      );
      await updateAgent(agent.copyWith(status: AgentStatus.idle));
    } catch (e) {
      log('task ${task.id}: execution failed: $e');
      await updateTask(
        task.copyWith(
          status: TaskStatus.failed,
          finishedAt: DateTime.now().toUtc(),
          failureReason: '$e',
        ),
      );
      if (agent != null) {
        await updateAgent(agent.copyWith(status: AgentStatus.idle));
      }
    }
  }
}
