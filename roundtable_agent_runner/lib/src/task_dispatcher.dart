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
    required this.openPullRequest,
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

  /// Opens a GitHub PR for a pushed task branch (design doc §6.1 step 7) and
  /// returns its URL. Bound to [GitHubPullRequestOpener.open] in production.
  final Future<String> Function({
    required String cloneUrl,
    required String branchName,
    required String title,
    String? body,
  })
  openPullRequest;

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

      String? branchName;
      String? prUrl;
      if (result.success) {
        final branch = 'task-${task.id}';
        final committed = await worktreeManager.commitAndPush(
          projectId: '$projectId',
          taskId: '${task.id}',
          commitMessage:
              'Roundtable task #${task.id}: ${_shortSummary(task.prompt)}',
          pushUrl: cloneUrl,
        );
        if (committed) {
          branchName = branch;
          prUrl = await openPullRequest(
            cloneUrl: cloneUrl,
            branchName: branch,
            title: 'Roundtable task #${task.id}: ${_shortSummary(task.prompt)}',
            body:
                'Opened by ${agent.name} (Roundtable agent).\n\n'
                '${task.prompt}',
          );
        } else {
          log('task ${task.id}: no changes to commit, skipping PR');
        }
      }

      await updateTask(
        task.copyWith(
          status: result.success
              ? TaskStatus.awaitingReview
              : TaskStatus.failed,
          finishedAt: DateTime.now().toUtc(),
          claudeSessionId: result.sessionId ?? task.claudeSessionId,
          failureReason: result.success ? null : result.errorSummary,
          branchName: branchName ?? task.branchName,
          prUrl: prUrl ?? task.prUrl,
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

/// Truncates [prompt] to its first line, capped at 72 characters, for use as
/// a commit message / PR title summary.
String _shortSummary(String prompt) {
  final firstLine = prompt.trim().split('\n').first;
  return firstLine.length > 72 ? '${firstLine.substring(0, 69)}...' : firstLine;
}
