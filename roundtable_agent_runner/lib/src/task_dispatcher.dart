import 'dart:async';
import 'dart:io';

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
    required this.fetchLatestFeedback,
    required this.openPullRequest,
    required this.watchTask,
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

  /// Fetches the most recently submitted [TaskFeedback] for a task, used to
  /// resume an `awaitingReview` task after [TaskEndpoint.submitFeedback]
  /// wakes the daemon (design doc §6.1 step 9). Bound to
  /// `client.task.latestFeedback` in production.
  final Future<TaskFeedback?> Function(int taskId) fetchLatestFeedback;

  /// Streams a task's status (design doc §6.1 "Cancelling mid-run") —
  /// subscribed to for the task currently being executed, to detect a
  /// transition to `cancelled` while [ClaudeCodeExecutor.run] is in flight.
  /// Bound to `client.task.watchTask` in production.
  final Stream<Task> Function(int taskId) watchTask;

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

  /// Handles one assigned [task]: either a fresh `queued` task (planning-
  /// phase tasks are deliberately left untouched — planning-phase execution
  /// isn't implemented yet, design doc §6.4), or an `awaitingReview` task
  /// woken by [TaskEndpoint.submitFeedback] (design doc §6.1 step 9) — in
  /// which case it's resumed via `--resume` with the feedback message as the
  /// new prompt. Any other case (e.g. replayed on reconnect while already
  /// running, or `awaitingReview` with no new feedback pending) is left
  /// untouched.
  Future<void> handle(Task task) async {
    final isResume = task.status == TaskStatus.awaitingReview;
    String? resumePrompt;

    if (!isResume) {
      if (!task.skipPlanning) {
        log('task ${task.id}: planning phase not implemented yet, skipping');
        return;
      }
      if (task.status != TaskStatus.queued) {
        log('task ${task.id}: not queued (status=${task.status}), skipping');
        return;
      }
    }

    final projectId = task.projectId;
    final agentId = task.agentId;
    if (agentId == null) {
      log('task ${task.id}: missing agentId, skipping');
      return;
    }

    if (isResume) {
      final sessionId = task.claudeSessionId;
      if (sessionId == null) {
        log('task ${task.id}: awaitingReview but no claudeSessionId, skipping');
        return;
      }
      final feedback = await fetchLatestFeedback(task.id!);
      final finishedAt = task.finishedAt;
      final isFresh =
          feedback != null &&
          feedback.phase == TaskFeedbackPhase.review &&
          (finishedAt == null || feedback.createdAt.isAfter(finishedAt));
      if (!isFresh) {
        // Either no feedback was ever submitted (the task is just sitting in
        // awaitingReview for human review), or this is a stale replay of
        // already-consumed feedback (e.g. daemon restart while the task sits
        // in awaitingReview again after a resumed run finished) — comparing
        // against `finishedAt` (bumped every time a run completes) is what
        // tells the two apart without adding a schema field.
        log('task ${task.id}: no new review feedback pending, skipping');
        return;
      }
      resumePrompt = feedback.message;
    }

    Agent? agent;
    var cancelRequested = false;
    StreamSubscription<Task>? watchSub;
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
          startedAt: task.startedAt ?? DateTime.now().toUtc(),
        ),
      );

      final resumeSessionId = task.claudeSessionId;
      final prompt = isResume
          ? resumePrompt!
          : '${buildRolePrompt(agent.role, agent.name)} ${task.prompt}';

      // Subscribed for as long as this task is running, to detect a
      // cancellation requested via `TaskEndpoint.cancelTask` (design doc
      // §6.1 "Cancelling mid-run"). There's a small window between the
      // `running` update above and this subscription starting where a
      // cancellation could be missed — an accepted limitation, not solved
      // here.
      Process? liveProcess;
      watchSub = watchTask(task.id!).listen((updated) {
        if (updated.status == TaskStatus.cancelled) {
          cancelRequested = true;
          liveProcess?.kill(ProcessSignal.sigterm);
        }
      });

      final result = await executorFactory().run(
        prompt: prompt,
        workingDirectory: worktreePath,
        oauthToken: oauthToken,
        model: agent.defaultModel,
        effort: agent.defaultEffort?.name,
        resumeSessionId: resumeSessionId,
        onLine: (line) => appendLog(task.id!, line),
        onProcessStarted: (p) => liveProcess = p,
      );

      if (cancelRequested) {
        log('task ${task.id}: cancelled, resetting worktree');
        await worktreeManager.resetWorktree(
          projectId: '$projectId',
          taskId: '${task.id}',
        );
        await updateTask(
          task.copyWith(
            status: TaskStatus.cancelled,
            finishedAt: DateTime.now().toUtc(),
          ),
        );
        await updateAgent(agent.copyWith(status: AgentStatus.idle));
        return;
      }

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
          if (task.prUrl == null) {
            prUrl = await openPullRequest(
              cloneUrl: cloneUrl,
              branchName: branch,
              title:
                  'Roundtable task #${task.id}: ${_shortSummary(task.prompt)}',
              body:
                  'Opened by ${agent.name} (Roundtable agent).\n\n'
                  '${task.prompt}',
            );
          } else {
            log('task ${task.id}: pushed additional commits to existing PR');
          }
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
          status: cancelRequested ? TaskStatus.cancelled : TaskStatus.failed,
          finishedAt: DateTime.now().toUtc(),
          failureReason: cancelRequested ? null : '$e',
        ),
      );
      if (agent != null) {
        await updateAgent(agent.copyWith(status: AgentStatus.idle));
      }
    } finally {
      await watchSub?.cancel();
    }
  }
}

/// Truncates [prompt] to its first line, capped at 72 characters, for use as
/// a commit message / PR title summary.
String _shortSummary(String prompt) {
  final firstLine = prompt.trim().split('\n').first;
  return firstLine.length > 72 ? '${firstLine.substring(0, 69)}...' : firstLine;
}
