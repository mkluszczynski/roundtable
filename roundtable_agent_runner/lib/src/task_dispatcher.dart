import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:roundtable_client/roundtable_client.dart';

import 'claude_code_executor.dart';
import 'container_sandbox.dart';
import 'environment_prompt.dart';
import 'role_prompts.dart';
import 'log_entries.dart';
import 'usage_limit.dart';
import 'stream_json_formatter.dart';
import 'toolchain_installer.dart';
import 'task_images.dart';
import 'worktree_manager.dart';

/// Runs an assigned [Task]: worktree, Claude Code (planning, execution, or a
/// `--resume` feedback iteration), commit + push, PR, final status — see
/// `docs/FLOWS.md` §4.
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
    this.fetchAttachments = _noAttachments,
    this.environmentPrompt,
    this.fetchProject,
    this.toolchainInstaller,
    this.sandboxFor,
  });

  /// The task's project, for its toolchains ([Project.tools]) and docker
  /// image. With [toolchainInstaller], the toolchains are installed before
  /// each run and put first on `claude`'s `PATH` (docs/FLOWS.md §7).
  final Future<Project?> Function(int projectId)? fetchProject;
  final ToolchainInstaller? toolchainInstaller;

  /// Builds the container a docker-mode agent's run goes in (docs/FLOWS.md
  /// §8). Null on a machine without a container runtime — a docker-mode
  /// task then fails with an explanation.
  final ContainerSandbox Function(ContainerRequest request)? sandboxFor;

  /// Describes this machine to the agent (`--append-system-prompt`) — see
  /// `buildEnvironmentPrompt`. Null when not yet known.
  final String? Function({bool container})? environmentPrompt;

  static Future<List<TaskImage>> _noAttachments(int taskId) async => const [];

  /// The images attached to a task's prompt. Downloaded next to the run's
  /// MCP config and listed in the prompt, so Claude Code can look at them
  /// with its Read tool. Bound to `client.taskAttachment` in production.
  final Future<List<TaskImage>> Function(int taskId) fetchAttachments;

  final WorktreeManager worktreeManager;
  final ClaudeCodeExecutor Function() executorFactory;
  final String? oauthToken;
  final Future<String> Function(int projectId) getCloneUrl;
  final Future<Agent> Function(int agentId) fetchAgent;
  final Future<void> Function(Task task) updateTask;

  /// Reports the agent's `status` — only that field is sent. Bound to
  /// `client.agent.setStatus` in production.
  final Future<void> Function(Agent agent) updateAgent;

  /// Persists one structured log entry. Bound to
  /// `client.task.appendLogEntry` in production.
  final Future<void> Function(TaskLogEntry entry) appendLog;

  /// Fetches the most recently submitted [TaskFeedback] for a task, used to
  /// resume an `awaitingReview` task after [TaskEndpoint.submitFeedback]
  /// wakes the daemon (docs/FLOWS.md §4). Bound to
  /// `client.task.latestFeedback` in production.
  final Future<TaskFeedback?> Function(int taskId) fetchLatestFeedback;

  /// Streams a task's status (docs/FLOWS.md §4 "Cancelling mid-run") —
  /// subscribed to for the task currently being executed, to detect a
  /// transition to `cancelled` while [ClaudeCodeExecutor.run] is in flight.
  /// Bound to `client.task.watchTask` in production.
  final Stream<Task> Function(int taskId) watchTask;

  /// Opens a GitHub PR for a pushed task branch (docs/FLOWS.md §4) and
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
  /// spawned permission-prompt-tool process (docs/FLOWS.md §4) so it can
  /// build its own [Client].
  final String serverUrl;

  /// The command (executable + leading args) that launches the
  /// permission-prompt-tool binary (`bin/permission_prompt_tool.dart`),
  /// e.g. `[Platform.resolvedExecutable, 'run', '<path>']` in dev mode. Used
  /// as the `command`/`args` of the `--mcp-config` JSON written for each
  /// planning-phase run.
  final List<String> permissionPromptToolCommand;

  /// Handles one assigned [task]: a fresh `queued` task — planning-phase
  /// (docs/FLOWS.md §4) unless `skipPlanning` is set — or an
  /// `awaitingReview` task woken by [TaskEndpoint.submitFeedback]
  /// (docs/FLOWS.md §4), resumed via `--resume` with the feedback message as
  /// the new prompt. Any other case (e.g. replayed on reconnect while
  /// already running, or `awaitingReview` with no new feedback pending, or a
  /// planning-phase task replayed mid-flight after a daemon restart) is
  /// left untouched — resuming an in-flight planning conversation isn't
  /// supported, matching the existing accepted limitations around restarts.
  /// How many [handle] calls are in flight per task id — a count, since a
  /// replayed task can be handed in again while its first run is going.
  final Map<int, int> _inFlight = {};

  /// Whether a [handle] call for [taskId] is in flight, i.e. its worktree
  /// may be in use — see `WorktreeJanitor`.
  bool isActive(int taskId) => _inFlight.containsKey(taskId);

  Future<void> handle(Task task) async {
    final id = task.id!;
    _inFlight[id] = (_inFlight[id] ?? 0) + 1;
    try {
      await _handle(task);
    } finally {
      final remaining = _inFlight[id]! - 1;
      if (remaining == 0) {
        _inFlight.remove(id);
      } else {
        _inFlight[id] = remaining;
      }
    }
  }

  Future<void> _handle(Task task) async {
    final isResume = task.status == TaskStatus.awaitingReview;
    // Requeued after a usage-limit pause: continue the interrupted run's
    // session the same way (planning stays in plan mode).
    final pausedPhase = task.status == TaskStatus.queued
        ? task.pausedPhase
        : null;
    final isPauseResume = pausedPhase != null;
    final needsPlanning = isPauseResume
        ? pausedPhase == LogPhase.planning
        : !isResume && task.status == TaskStatus.queued && !task.skipPlanning;
    String? resumePrompt;

    if (task.status == TaskStatus.done) {
      // Accepted and merged — the worktree is no longer needed.
      await worktreeManager.removeWorktree(
        projectId: '${task.projectId}',
        taskId: '${task.id}',
      );
      log('task ${task.id}: done, worktree removed');
      return;
    }

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
    ContainerSandbox? sandbox;
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
          pausedPhase: null,
          pauseReason: null,
        ),
      );

      final resumeSessionId = task.claudeSessionId;
      final canResumeSession = isPauseResume && resumeSessionId != null;
      var prompt = isResume
          ? resumePrompt!
          : canResumeSession
          ? usageLimitResumePrompt
          : '${buildRolePrompt(agent)} ${task.prompt}';

      // Subscribed for as long as this task is running, to detect a
      // cancellation requested via `TaskEndpoint.cancelTask` (docs/FLOWS.md §4
      // "Cancelling mid-run"). There's a small window between the
      // `running`/`planning` update above and this subscription starting
      // where a cancellation could be missed — an accepted limitation, not
      // solved here. For a planning-phase task, also mirrors `Task.status`
      // into `Agent.status` (`waitingForResponse` while a question/plan
      // decision is pending, `busy` once planning resumes) — docs/FLOWS.md §4.
      // One formatter per invocation: planning and execution share a single
      // continuous `claude` process (see `runPlanning`'s doc comment), so
      // its content-block buffering must persist across both phases.
      final formatter = StreamJsonFormatter();
      final runId = newRunId('task-${task.id}');
      final phase =
          pausedPhase ??
          (isResume
              ? LogPhase.feedback
              : needsPlanning
              ? LogPhase.planning
              : LogPhase.execution);
      void append(LogItem item) {
        appendLog(
          logEntryFor(item, taskId: task.id!, runId: runId, phase: phase),
        ).catchError(
          (Object e) => log('task ${task.id}: appendLog failed: $e'),
        );
      }

      append(
        LogItem(
          kind: LogKind.runStarted,
          content: switch (phase) {
            _ when canResumeSession =>
              '${agent.name} resumed after the usage limit reset',
            LogPhase.feedback => '${agent.name} resumed with your feedback',
            LogPhase.planning => '${agent.name} started planning',
            _ => '${agent.name} started working',
          },
        ),
      );
      void onLine(String line) {
        formatter.feedEntries(line).forEach(append);
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
      final inContainer = agent.executionMode == AgentExecutionMode.docker;
      final mcpConfigPath = await _writeMcpConfig(
        mcpConfigDir,
        task.id!,
        container: inContainer,
      );

      // A resumed session already saw the images in its first run.
      final attachmentDirs = <String>[];
      if (!isResume && !canResumeSession) {
        final images = await fetchAttachments(task.id!);
        if (images.isNotEmpty) {
          final dir = await Directory(
            '${mcpConfigDir.path}/attachments',
          ).create();
          final paths = await writeTaskImages(dir, images);
          attachmentDirs.add(dir.path);
          prompt = attachedImagesPrompt(prompt, paths);
          log('task ${task.id}: ${images.length} attached image(s)');
        }
      }

      final project = await fetchProject?.call(projectId);
      final toolchain = await _prepareToolchain(
        task.id!,
        projectId,
        project?.tools ?? const [],
        append,
      );
      if (inContainer) {
        final build = sandboxFor;
        if (build == null) {
          throw StateError(
            '${agent.name} runs in docker mode, but this machine has no '
            'container runtime — install podman (install-agent.sh --docker) '
            'or switch the agent to native',
          );
        }
        sandbox = build((
          projectId: projectId,
          taskId: task.id!,
          worktreePath: worktreePath,
          readOnlyDirectories: [mcpConfigDir.path],
          image: project?.dockerImage,
        ));
        append(
          LogItem(
            kind: LogKind.event,
            content: 'Running in a container (${sandbox.image})',
          ),
        );
      }
      final executor = sandbox == null
          ? executorFactory()
          : executorFactory().inContainer(sandbox);
      final systemPrompt = [
        ?environmentPrompt?.call(container: inContainer),
        if (toolchain != null) projectToolchainPrompt(toolchain.tools),
        if (task.title == null) taskTitlePrompt(),
      ].join('\n\n');

      final ClaudeCodeExecutionResult result;
      if (needsPlanning) {
        log('task ${task.id}: running claude (planning)');
        result = await executor.runPlanning(
          prompt: prompt,
          workingDirectory: worktreePath,
          permissionPromptTool: permissionPromptTool,
          mcpConfigPath: mcpConfigPath,
          oauthToken: oauthToken,
          model: agent.defaultModel,
          effort: agent.defaultEffort?.name,
          additionalDirectories: attachmentDirs,
          appendSystemPrompt: systemPrompt.isEmpty ? null : systemPrompt,
          environment: toolchain?.environment,
          resumeSessionId: canResumeSession ? resumeSessionId : null,
          onLine: onLine,
          onProcessStarted: (p) => liveProcess = p,
        );
      } else {
        log('task ${task.id}: running claude (execution)');
        result = await executor.run(
          prompt: prompt,
          workingDirectory: worktreePath,
          oauthToken: oauthToken,
          model: agent.defaultModel,
          effort: agent.defaultEffort?.name,
          resumeSessionId: resumeSessionId,
          permissionPromptTool: permissionPromptTool,
          mcpConfigPath: mcpConfigPath,
          additionalDirectories: attachmentDirs,
          appendSystemPrompt: systemPrompt.isEmpty ? null : systemPrompt,
          environment: toolchain?.environment,
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

      if (!result.success && isUsageLimitMessage(result.errorSummary)) {
        final message = result.errorSummary!;
        final resumeAt = usageLimitResetAt(message);
        final local = resumeAt.toLocal();
        final at =
            '${local.hour.toString().padLeft(2, '0')}:'
            '${local.minute.toString().padLeft(2, '0')}';
        log('task ${task.id}: usage limit, paused until $resumeAt');
        append(
          LogItem(
            kind: LogKind.event,
            content: 'Paused by the Claude usage limit — resumes at $at',
          ),
        );
        await updateTask(
          task.copyWith(
            status: TaskStatus.paused,
            pausedUntil: resumeAt,
            pauseReason: message,
            pausedPhase: phase,
            claudeSessionId: result.sessionId ?? task.claudeSessionId,
          ),
        );
        await updateAgent(agent.copyWith(status: AgentStatus.idle));
        return;
      }

      String? branchName;
      String? prUrl;
      String? failureReason = result.success
          ? null
          : sandbox != null
          ? describeContainerFailure(result.errorSummary)
          : result.errorSummary;
      var finishedWithoutCode = false;
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
              body: pullRequestBody(
                agentName: agent.name,
                prompt: task.prompt,
                summary: result.resultText,
              ),
            );
          } else {
            log('task ${task.id}: pushed additional commits to existing PR');
          }
        } else if (task.branchName == null) {
          // E.g. the prompt was a question, or the agent found nothing to
          // change — its reply is the result, not a failure.
          log('task ${task.id}: no changes to commit, done without a PR');
          finishedWithoutCode = true;
        } else {
          log('task ${task.id}: no new changes, keeping existing PR');
        }
      }

      if (failureReason == null) {
        final event = finishedWithoutCode
            ? 'Finished without code changes — no pull request'
            : prUrl != null
            ? 'Committed and pushed $branchName, opened pull request $prUrl'
            : branchName != null
            ? 'Pushed new commits to $branchName'
            : 'No new changes — the pull request is unchanged';
        append(LogItem(kind: LogKind.event, content: event));
      }

      final status = failureReason != null
          ? TaskStatus.failed
          : finishedWithoutCode
          ? TaskStatus.done
          : TaskStatus.awaitingReview;
      await updateTask(
        task.copyWith(
          status: status,
          finishedAt: DateTime.now().toUtc(),
          claudeSessionId: result.sessionId ?? task.claudeSessionId,
          failureReason: failureReason,
          resultSummary: result.resultText ?? task.resultSummary,
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
      await sandbox?.remove();
      try {
        await mcpConfigDir?.delete(recursive: true);
      } catch (e) {
        log('task ${task.id}: could not remove MCP config dir: $e');
      }
    }
  }

  /// Installs the project's toolchains before a run, reporting a download
  /// on the task's timeline. A failure is logged there too, but doesn't
  /// fail the task: the agent works on and reports what it couldn't verify.
  Future<PreparedToolchain?> _prepareToolchain(
    int taskId,
    int projectId,
    List<ProjectTool> tools,
    void Function(LogItem item) append,
  ) async {
    final installer = toolchainInstaller;
    if (installer == null || tools.isEmpty) return null;
    try {
      var installed = false;
      final prepared = await installer.prepare(
        projectId: projectId,
        tools: tools,
        onInstalling: (missing) {
          installed = true;
          log('task $taskId: installing ${missing.join(', ')}');
          append(
            LogItem(
              kind: LogKind.event,
              content:
                  'Installing ${missing.join(', ')} — the first time takes '
                  'a few minutes',
            ),
          );
        },
      );
      if (installed) {
        append(
          LogItem(
            kind: LogKind.event,
            content: 'Tools ready: ${prepared.tools.join(', ')}',
          ),
        );
      }
      return prepared;
    } catch (e) {
      log('task $taskId: toolchain install failed: $e');
      append(
        LogItem(
          kind: LogKind.event,
          content: "Couldn't install the project's tools: $e",
          isError: true,
        ),
      );
      return null;
    }
  }

  /// Writes the `--mcp-config` JSON registering the permission-prompt-tool
  /// (docs/FLOWS.md §4) for [taskId]'s planning-phase run. Kept outside the
  /// worktree so it never ends up in the task's commit. The tool process
  /// reads `SERVER_URL`/`ROUNDTABLE_TASK_ID` from its environment (see
  /// `bin/permission_prompt_tool.dart`) since `--mcp-config` only supports a
  /// static command/args/env per server, not per-call params.
  /// In a container, [serverUrl] is rewritten to reach the host.
  Future<String> _writeMcpConfig(
    Directory dir,
    int taskId, {
    bool container = false,
  }) async {
    final configFile = File('${dir.path}/mcp-config.json');
    await configFile.writeAsString(
      jsonEncode({
        'mcpServers': {
          'roundtable-permission': {
            'command': permissionPromptToolCommand.first,
            'args': permissionPromptToolCommand.skip(1).toList(),
            'env': {
              'SERVER_URL': container
                  ? containerServerUrl(serverUrl)
                  : serverUrl,
              'ROUNDTABLE_TASK_ID': '$taskId',
            },
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

/// The PR description: the task's prompt, then the agent's final message —
/// its summary of the change, including anything it couldn't verify.
String pullRequestBody({
  required String agentName,
  required String prompt,
  String? summary,
}) {
  final quotedPrompt = prompt.split('\n').map((l) => '> $l').join('\n');
  final buffer = StringBuffer()
    ..writeln('Opened by $agentName (Roundtable agent).')
    ..writeln()
    ..writeln('## Task')
    ..writeln(quotedPrompt);
  final trimmed = summary?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln("## Agent's summary")
      ..writeln(trimmed);
  }
  return buffer.toString().trimRight();
}

/// Sent when a session interrupted by a usage limit is resumed.
const usageLimitResumePrompt =
    'You were interrupted by the Claude usage limit, which has now reset. '
    'Continue exactly where you left off.';
