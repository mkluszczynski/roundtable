part of 'task_dispatcher.dart';

/// The permission-prompt-tool as Claude Code names it: the
/// `roundtable-permission` MCP server's `approval_prompt` tool.
const permissionPromptToolName = 'mcp__roundtable-permission__approval_prompt';

/// What a run needs besides the worktree, set up once before `claude`
/// starts.
typedef _RunSetup = ({
  String prompt,
  String mcpConfigPath,
  List<String> attachmentDirs,
});

/// One run of a task, from the worktree to the final status, in steps
/// (docs/FLOWS.md §4). Holds what the steps share: the task, the agent, the
/// cancellation flag and the resources [_cleanUp] releases.
class _TaskRun {
  _TaskRun(this._d, this.task, this.kind, this.agentId);

  final TaskDispatcher _d;
  Task task;
  RunKind kind;
  final int agentId;

  int get projectId => task.projectId;
  int get taskId => task.id!;

  Agent? _agent;
  Agent get agent => _agent!;
  var _cancelRequested = false;
  Process? _liveProcess;
  StreamSubscription<Task>? _watchSub;
  Directory? _mcpConfigDir;
  RunEnvironment? _environment;

  /// One formatter per run: planning and execution share a single
  /// continuous `claude` process (see `runPlanning`'s doc comment), so its
  /// content-block buffering must persist across both phases.
  final _formatter = StreamJsonFormatter();
  late final String _runId = newRunId('task-$taskId');

  /// Continues the session interrupted by the usage limit.
  bool get _resumesPausedSession =>
      kind is PauseResume && task.claudeSessionId != null;

  void _log(String message) => _d.log('task $taskId: $message');

  void _append(LogItem item) {
    _d
        .appendLog(
          logEntryFor(item, taskId: taskId, runId: _runId, phase: kind.phase),
        )
        .catchError((Object e) => _log('appendLog failed: $e'));
  }

  Future<void> execute() async {
    _log('starting (${kind.label})');
    try {
      final cloneUrl = await _d.getCloneUrl(projectId);
      final worktreePath = await _prepareWorktree(cloneUrl);
      if (!await _refreshQueuedTask()) return;
      await _markStarted();
      _append(LogItem(kind: LogKind.runStarted, content: _runStartedText()));
      _watchForCancellation();
      final setup = await _prepare(worktreePath);
      if (_cancelRequested) return await _stopCancelled();

      final result = await _runClaude(setup, worktreePath);
      if (_cancelRequested) return await _stopCancelled();
      _log(
        'claude exited (code=${result.exitCode}, success=${result.success})',
      );

      if (!result.success && isUsageLimitMessage(result.errorSummary)) {
        return await _pauseForUsageLimit(result);
      }
      await _publish(result, cloneUrl);
    } catch (e) {
      await _fail(e);
    } finally {
      await _cleanUp();
    }
  }

  Future<String> _prepareWorktree(String cloneUrl) async {
    await _d.worktreeManager.ensureProjectCloned(
      projectId: '$projectId',
      cloneUrl: cloneUrl,
    );
    final path = await _d.worktreeManager.createWorktree(
      projectId: '$projectId',
      taskId: '$taskId',
    );
    _log('worktree ready at $path');
    return path;
  }

  /// The dev may edit the prompt and skip planning while the task is queued
  /// (`TaskEndpoint.updateTaskSettings`), and cloning takes a while: start
  /// from the current row, not the dispatch snapshot. False when the run
  /// should not go ahead.
  Future<bool> _refreshQueuedTask() async {
    final fetchTask = _d.fetchTask;
    if (kind is FeedbackResume || fetchTask == null) return true;
    final current = await fetchTask(taskId);
    if (current == null ||
        current.status != TaskStatus.queued ||
        current.agentId != agentId) {
      _log('deleted, reassigned or no longer queued while preparing, skipping');
      return false;
    }
    task = current;
    kind = RunKind.queued(current);
    return true;
  }

  Future<void> _markStarted() async {
    _agent = await _d.fetchAgent(agentId);
    await _d.updateAgent(agent.copyWith(status: AgentStatus.busy));
    await _d.updateTask(
      task.copyWith(
        status: kind.needsPlanning ? TaskStatus.planning : TaskStatus.running,
        startedAt: task.startedAt ?? DateTime.now().toUtc(),
        pausedPhase: null,
        pauseReason: null,
      ),
    );
  }

  String _runStartedText() => switch (kind) {
    _ when _resumesPausedSession =>
      '${agent.name} resumed after the usage limit reset',
    FeedbackResume() => '${agent.name} resumed with your feedback',
    _ when kind.needsPlanning => '${agent.name} started planning',
    _ => '${agent.name} started working',
  };

  /// Subscribed for as long as the task runs, to detect a cancellation via
  /// `TaskEndpoint.cancelTask` (docs/FLOWS.md §4 "Cancelling mid-run"): the
  /// task moves back to `draft` (or `cancelled` from an older server). There
  /// is a small window between [_markStarted] and this subscription where a
  /// cancellation could be missed — an accepted limitation. During planning
  /// it also mirrors `Task.status` into `Agent.status`.
  void _watchForCancellation() {
    _watchSub = _d.watchTask(taskId).listen((updated) {
      if (updated.status == TaskStatus.draft ||
          updated.status == TaskStatus.cancelled) {
        _cancelRequested = true;
        if (_liveProcess case final process?) {
          ClaudeCodeExecutor.terminate(process);
        }
      } else if (kind.needsPlanning) {
        final status = planningAgentStatus(updated.status);
        if (status != null) {
          unawaited(_d.updateAgent(agent.copyWith(status: status)));
        }
      }
    }, onError: (Object e) => _log('watchTask stream error: $e'));
  }

  /// The MCP config, attached images, toolchains and (docker mode) the
  /// container, plus the prompts for `claude`.
  Future<_RunSetup> _prepare(String worktreePath) async {
    final mcpDir = _mcpConfigDir = await Directory.systemTemp.createTemp(
      'roundtable-task-$taskId-',
    );
    final inContainer = agent.executionMode == AgentExecutionMode.docker;
    final mcpConfigPath = await _writeMcpConfig(mcpDir, inContainer);

    var prompt = switch (kind) {
      FeedbackResume(:final message) => message,
      _ when _resumesPausedSession => usageLimitResumePrompt,
      _ => '${buildRolePrompt(agent)} ${task.prompt}',
    };

    // A resumed session already saw the images in its first run.
    final attachmentDirs = <String>[];
    if (kind is! FeedbackResume && !_resumesPausedSession) {
      final images = await _d.fetchAttachments(taskId);
      if (images.isNotEmpty) {
        final dir = await Directory('${mcpDir.path}/attachments').create();
        final paths = await writeTaskImages(dir, images);
        attachmentDirs.add(dir.path);
        prompt = attachedImagesPrompt(prompt, paths);
        _log('${images.length} attached image(s)');
      }
    }

    _environment = await _d._environments.prepare(
      agent: agent,
      label: 'task $taskId',
      projectId: projectId,
      containerName: 'roundtable-task-$taskId',
      worktreePath: worktreePath,
      readOnlyDirectories: [mcpDir.path],
      append: _append,
    );
    return (
      prompt: prompt,
      mcpConfigPath: mcpConfigPath,
      attachmentDirs: attachmentDirs,
    );
  }

  Future<ClaudeCodeExecutionResult> _runClaude(
    _RunSetup setup,
    String worktreePath,
  ) {
    final environment = _environment!;
    final executor = environment.executor;
    final systemPrompt = environment.systemPrompt([
      if (task.title == null) taskTitlePrompt(),
    ]);
    void onLine(String line) => _formatter.feedEntries(line).forEach(_append);
    void onProcessStarted(Process process) {
      _liveProcess = process;
      // A cancel that arrived between the last check and the spawn.
      if (_cancelRequested) ClaudeCodeExecutor.terminate(process);
    }

    if (kind.needsPlanning) {
      _log('running claude (planning)');
      return executor.runPlanning(
        prompt: setup.prompt,
        workingDirectory: worktreePath,
        permissionPromptTool: permissionPromptToolName,
        mcpConfigPath: setup.mcpConfigPath,
        oauthToken: _d.oauthToken?.call(),
        model: agent.defaultModel,
        effort: agent.defaultEffort?.name,
        additionalDirectories: setup.attachmentDirs,
        appendSystemPrompt: systemPrompt,
        environment: environment.environment,
        resumeSessionId: _resumesPausedSession ? task.claudeSessionId : null,
        onLine: onLine,
        onProcessStarted: onProcessStarted,
      );
    }
    _log('running claude (execution)');
    return executor.run(
      prompt: setup.prompt,
      workingDirectory: worktreePath,
      oauthToken: _d.oauthToken?.call(),
      model: agent.defaultModel,
      effort: agent.defaultEffort?.name,
      resumeSessionId: task.claudeSessionId,
      permissionPromptTool: permissionPromptToolName,
      mcpConfigPath: setup.mcpConfigPath,
      additionalDirectories: setup.attachmentDirs,
      appendSystemPrompt: systemPrompt,
      environment: environment.environment,
      onLine: onLine,
      onProcessStarted: onProcessStarted,
    );
  }

  /// The server already moved the task back to the backlog; there's no
  /// status left to report.
  Future<void> _stopCancelled() async {
    _log('cancelled, resetting worktree');
    await _d.worktreeManager.resetWorktree(
      projectId: '$projectId',
      taskId: '$taskId',
    );
    await _d.updateAgent(agent.copyWith(status: AgentStatus.idle));
  }

  Future<void> _pauseForUsageLimit(ClaudeCodeExecutionResult result) async {
    final message = result.errorSummary!;
    final resumeAt = usageLimitResetAt(message);
    _d.usageLimit.hit(resumeAt);
    _log('usage limit, paused until $resumeAt');
    _append(
      LogItem(
        kind: LogKind.event,
        content:
            'Paused by the Claude usage limit — resumes at '
            '${localClock(resumeAt)}',
      ),
    );
    await _d.updateTask(
      task.copyWith(
        status: TaskStatus.paused,
        pausedUntil: resumeAt,
        pauseReason: message,
        pausedPhase: kind.phase,
        claudeSessionId: result.sessionId ?? task.claudeSessionId,
      ),
    );
    await _d.updateAgent(agent.copyWith(status: AgentStatus.idle));
  }

  /// Commits and pushes a successful run's changes, opens the PR the first
  /// time, and reports the final status.
  Future<void> _publish(
    ClaudeCodeExecutionResult result,
    String cloneUrl,
  ) async {
    String? branchName;
    String? prUrl;
    final failureReason = result.success
        ? null
        : _environment!.describeFailure(result.errorSummary);
    var finishedWithoutCode = false;
    if (result.success) {
      final branch = 'task-$taskId';
      final title = 'Roundtable task #$taskId: ${_shortSummary(task.prompt)}';
      final committed = await _d.worktreeManager.commitAndPush(
        projectId: '$projectId',
        taskId: '$taskId',
        commitMessage: title,
        pushUrl: cloneUrl,
      );
      if (committed) {
        branchName = branch;
        if (task.prUrl == null) {
          prUrl = await _d.openPullRequest(
            cloneUrl: cloneUrl,
            branchName: branch,
            title: title,
            body: pullRequestBody(
              agentName: agent.name,
              prompt: task.prompt,
              summary: result.resultText,
            ),
          );
        } else {
          _log('pushed additional commits to existing PR');
        }
      } else if (task.branchName == null) {
        // E.g. the prompt was a question, or the agent found nothing to
        // change — its reply is the result, not a failure.
        _log('no changes to commit, done without a PR');
        finishedWithoutCode = true;
      } else {
        _log('no new changes, keeping existing PR');
      }
    }

    final outcome = runOutcome(
      failureReason: failureReason,
      finishedWithoutCode: finishedWithoutCode,
      branchName: branchName,
      prUrl: prUrl,
    );
    if (outcome.event case final event?) {
      _append(LogItem(kind: LogKind.event, content: event));
    }
    await _d.updateTask(
      task.copyWith(
        status: outcome.status,
        finishedAt: DateTime.now().toUtc(),
        claudeSessionId: result.sessionId ?? task.claudeSessionId,
        failureReason: failureReason,
        resultSummary: result.resultText ?? task.resultSummary,
        branchName: branchName ?? task.branchName,
        prUrl: prUrl ?? task.prUrl,
      ),
    );
    await _d.updateAgent(agent.copyWith(status: AgentStatus.idle));
    _log('finished with status ${outcome.status.name}');
  }

  /// Reports the run failed and frees the agent. Each report is retried on
  /// its own, so a server that's briefly unreachable leaves neither the task
  /// `running` nor the agent `busy`.
  Future<void> _fail(Object e) async {
    _log('execution failed: $e');
    if (!_cancelRequested) {
      await retrying(
        'task $taskId: reporting the failure',
        () => _d.updateTask(
          task.copyWith(
            status: TaskStatus.failed,
            finishedAt: DateTime.now().toUtc(),
            failureReason: e is ProcessException
                ? describeClaudeLaunchFailure(e)
                : '$e',
          ),
        ),
        log: _d.log,
        delays: _d.retryDelays,
      );
    }
    if (_agent case final agent?) {
      await retrying(
        'task $taskId: freeing the agent',
        () => _d.updateAgent(agent.copyWith(status: AgentStatus.idle)),
        log: _d.log,
        delays: _d.retryDelays,
      );
    }
  }

  Future<void> _cleanUp() async {
    await _watchSub?.cancel();
    await _environment?.dispose();
    try {
      await _mcpConfigDir?.delete(recursive: true);
    } catch (e) {
      _log('could not remove MCP config dir: $e');
    }
  }

  /// Writes the `--mcp-config` JSON registering the permission-prompt-tool
  /// (docs/FLOWS.md §4). Kept outside the worktree so it never ends up in
  /// the task's commit. The tool process reads `SERVER_URL` /
  /// `ROUNDTABLE_TASK_ID` from its environment (see
  /// `bin/permission_prompt_tool.dart`) since `--mcp-config` only supports a
  /// static command/args/env per server. In a container, the server URL is
  /// rewritten to reach the host.
  Future<String> _writeMcpConfig(Directory dir, bool container) async {
    final command = _d.permissionPromptToolCommand;
    final configFile = File('${dir.path}/mcp-config.json');
    await configFile.writeAsString(
      jsonEncode({
        'mcpServers': {
          'roundtable-permission': {
            'command': command.first,
            'args': command.skip(1).toList(),
            'env': {
              'SERVER_URL': container
                  ? containerServerUrl(_d.serverUrl)
                  : _d.serverUrl,
              'ROUNDTABLE_TASK_ID': '$taskId',
            },
          },
        },
      }),
    );
    return configFile.path;
  }
}
