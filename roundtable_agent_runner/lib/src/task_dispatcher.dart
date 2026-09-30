import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:roundtable_client/roundtable_client.dart';

import 'claude_code_executor.dart';
import 'role_prompts.dart';
import 'stream_json_formatter.dart';
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
    required this.serverUrl,
    required this.permissionPromptToolCommand,
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

  /// Base URL of the roundtable server, passed as `SERVER_URL` to the
  /// spawned permission-prompt-tool process (design doc §6.4) so it can
  /// build its own [Client].
  final String serverUrl;

  /// The command (executable + leading args) that launches the
  /// permission-prompt-tool binary (`bin/permission_prompt_tool.dart`),
  /// e.g. `[Platform.resolvedExecutable, 'run', '<path>']` in dev mode. Used
  /// as the `command`/`args` of the `--mcp-config` JSON written for each
  /// planning-phase run.
  final List<String> permissionPromptToolCommand;

  /// Handles one assigned [task]: a fresh `queued` task — planning-phase
  /// (design doc §6.2, §6.4) unless `skipPlanning` is set — or an
  /// `awaitingReview` task woken by [TaskEndpoint.submitFeedback] (design
  /// doc §6.1 step 9), resumed via `--resume` with the feedback message as
  /// the new prompt. Any other case (e.g. replayed on reconnect while
  /// already running, or `awaitingReview` with no new feedback pending, or a
  /// planning-phase task replayed mid-flight after a daemon restart) is
  /// left untouched — resuming an in-flight planning conversation isn't
  /// supported, matching the existing accepted limitations around restarts.
  Future<void> handle(Task task) async {
    final isResume = task.status == TaskStatus.awaitingReview;
    final needsPlanning =
        !isResume && task.status == TaskStatus.queued && !task.skipPlanning;
    String? resumePrompt;

    if (!isResume) {
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
    Directory? mcpConfigDir;
    log(
      'task ${task.id}: starting (${isResume ? 'resume' : (needsPlanning ? 'planning' : 'execution')})',
    );
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
      log('task ${task.id}: worktree ready at $worktreePath');

      agent = await fetchAgent(agentId);
      await updateAgent(agent.copyWith(status: AgentStatus.busy));
      await updateTask(
        task.copyWith(
          status: needsPlanning ? TaskStatus.planning : TaskStatus.running,
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
      // `running`/`planning` update above and this subscription starting
      // where a cancellation could be missed — an accepted limitation, not
      // solved here. For a planning-phase task, also mirrors `Task.status`
      // into `Agent.status` (`waitingForResponse` while a question/plan
      // decision is pending, `busy` once planning resumes) — design doc
      // §6.1 step 4.
      // One formatter per invocation: planning and execution share a single
      // continuous `claude` process (see `runPlanning`'s doc comment), so
      // its content-block buffering must persist across both phases.
      final formatter = StreamJsonFormatter();
      void onLine(String line) {
        for (final formatted in formatter.feed(line)) {
          appendLog(task.id!, formatted).catchError(
            (Object e) => log('task ${task.id}: appendLog failed: $e'),
          );
        }
      }

      Process? liveProcess;
      watchSub = watchTask(task.id!).listen(
        (updated) {
          if (updated.status == TaskStatus.cancelled) {
            cancelRequested = true;
            liveProcess?.kill(ProcessSignal.sigterm);
          } else if (needsPlanning) {
            switch (updated.status) {
              case TaskStatus.waitingForAnswer:
              case TaskStatus.planReady:
                unawaited(
                  updateAgent(
                    agent!.copyWith(status: AgentStatus.waitingForResponse),
                  ),
                );
              case TaskStatus.planning:
                unawaited(
                  updateAgent(agent!.copyWith(status: AgentStatus.busy)),
                );
              default:
                break;
            }
          }
        },
        onError: (Object e) =>
            log('task ${task.id}: watchTask stream error: $e'),
      );

      const permissionPromptTool =
          'mcp__roundtable-permission__approval_prompt';
      mcpConfigDir = await Directory.systemTemp.createTemp(
        'roundtable-task-${task.id}-',
      );
      final mcpConfigPath = await _writeMcpConfig(mcpConfigDir, task.id!);

      final ClaudeCodeExecutionResult result;
      if (needsPlanning) {
        log('task ${task.id}: running claude (planning)');
        result = await executorFactory().runPlanning(
          prompt: prompt,
          workingDirectory: worktreePath,
          permissionPromptTool: permissionPromptTool,
          mcpConfigPath: mcpConfigPath,
          oauthToken: oauthToken,
          model: agent.defaultModel,
          effort: agent.defaultEffort?.name,
          onLine: onLine,
          onProcessStarted: (p) => liveProcess = p,
        );
      } else {
        log('task ${task.id}: running claude (execution)');
        result = await executorFactory().run(
          prompt: prompt,
          workingDirectory: worktreePath,
          oauthToken: oauthToken,
          model: agent.defaultModel,
          effort: agent.defaultEffort?.name,
          resumeSessionId: resumeSessionId,
          permissionPromptTool: permissionPromptTool,
          mcpConfigPath: mcpConfigPath,
          onLine: onLine,
          onProcessStarted: (p) => liveProcess = p,
        );
      }

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

      log(
        'task ${task.id}: claude exited (code=${result.exitCode}, '
        'success=${result.success})',
      );

      String? branchName;
      String? prUrl;
      String? failureReason = result.success ? null : result.errorSummary;
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
        } else if (task.branchName == null) {
          log('task ${task.id}: no changes to commit, marking failed');
          failureReason = 'Agent finished without changing any files.';
        } else {
          log('task ${task.id}: no new changes, keeping existing PR');
        }
      }

      final status = failureReason == null
          ? TaskStatus.awaitingReview
          : TaskStatus.failed;
      await updateTask(
        task.copyWith(
          status: status,
          finishedAt: DateTime.now().toUtc(),
          claudeSessionId: result.sessionId ?? task.claudeSessionId,
          failureReason: failureReason,
          branchName: branchName ?? task.branchName,
          prUrl: prUrl ?? task.prUrl,
        ),
      );
      await updateAgent(agent.copyWith(status: AgentStatus.idle));
      log('task ${task.id}: finished with status ${status.name}');
    } catch (e) {
      log('task ${task.id}: execution failed: $e');
      final failureReason = cancelRequested
          ? null
          : (e is ProcessException ? describeClaudeLaunchFailure(e) : '$e');
      await updateTask(
        task.copyWith(
          status: cancelRequested ? TaskStatus.cancelled : TaskStatus.failed,
          finishedAt: DateTime.now().toUtc(),
          failureReason: failureReason,
        ),
      );
      if (agent != null) {
        await updateAgent(agent.copyWith(status: AgentStatus.idle));
      }
    } finally {
      await watchSub?.cancel();
      try {
        await mcpConfigDir?.delete(recursive: true);
      } catch (e) {
        log('task ${task.id}: could not remove MCP config dir: $e');
      }
    }
  }

  /// Writes the `--mcp-config` JSON registering the permission-prompt-tool
  /// (design doc §6.4) for [taskId]'s planning-phase run. Kept outside the
  /// worktree so it never ends up in the task's commit. The tool process
  /// reads `SERVER_URL`/`ROUNDTABLE_TASK_ID` from its environment (see
  /// `bin/permission_prompt_tool.dart`) since `--mcp-config` only supports a
  /// static command/args/env per server, not per-call params.
  Future<String> _writeMcpConfig(Directory dir, int taskId) async {
    final configFile = File('${dir.path}/mcp-config.json');
    await configFile.writeAsString(
      jsonEncode({
        'mcpServers': {
          'roundtable-permission': {
            'command': permissionPromptToolCommand.first,
            'args': permissionPromptToolCommand.skip(1).toList(),
            'env': {'SERVER_URL': serverUrl, 'ROUNDTABLE_TASK_ID': '$taskId'},
          },
        },
      }),
    );
    return configFile.path;
  }
}

/// Truncates [prompt] to its first line, capped at 72 characters, for use as
/// a commit message / PR title summary.
String _shortSummary(String prompt) {
  final firstLine = prompt.trim().split('\n').first;
  return firstLine.length > 72 ? '${firstLine.substring(0, 69)}...' : firstLine;
}
