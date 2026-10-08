import 'dart:async';
import 'dart:io';

import 'package:roundtable_client/roundtable_client.dart';

import 'src/agent_runner_config.dart';
import 'src/agent_work_queue.dart';
import 'src/claude_code_executor.dart';
import 'src/claude_token_store.dart';
import 'src/github_pull_request_opener.dart';
import 'src/metrics_collector.dart';
import 'src/review_dispatcher.dart';
import 'src/resilient_subscription.dart';
import 'src/runner_update.dart';
import 'src/sandbox_factory.dart';
import 'src/environment_prompt.dart';
import 'src/task_dispatcher.dart';
import 'src/task_images.dart';
import 'src/toolchain_installer.dart';
import 'src/worktree_janitor.dart';
import 'src/usage_limit.dart';
import 'src/update_coordinator.dart';
import 'src/worktree_manager.dart';

export 'src/agent_runner_config.dart';
export 'src/agent_work_queue.dart';
export 'src/claude_code_executor.dart';
export 'src/container_sandbox.dart';
export 'src/github_pull_request_opener.dart';
export 'src/metrics_collector.dart';
export 'src/permission_prompt_tool.dart';
export 'src/resilient_subscription.dart';
export 'src/review_dispatcher.dart';
export 'src/run_environment.dart';
export 'src/runner_update.dart';
export 'src/sandbox_factory.dart';
export 'src/server_retry.dart';
export 'src/stream_json_formatter.dart';
export 'src/environment_prompt.dart';
export 'src/log_entries.dart';
export 'src/task_dispatcher.dart';
export 'src/task_images.dart';
export 'src/toolchain_installer.dart';
export 'src/update_coordinator.dart';
export 'src/usage_limit.dart';
export 'src/worktree_janitor.dart';
export 'src/worktree_manager.dart';

const _heartbeatInterval = Duration(seconds: 20);
const _metricsInterval = Duration(seconds: 8);
const _janitorInterval = Duration(minutes: 30);

/// The daemon: identifies this machine, subscribes to its assigned tasks
/// and code reviews (handed to [TaskDispatcher] / [ReviewDispatcher]),
/// checks in every [_heartbeatInterval] (heartbeat, runner version, update
/// requests), reports CPU/RAM every [_metricsInterval], and periodically
/// sweeps leftover worktrees ([WorktreeJanitor]). See
/// `docs/ARCHITECTURE.md` (Agent runner) and `docs/FLOWS.md`.
class AgentRunnerService {
  AgentRunnerService(this._config, {Client? client})
    : _client = client ?? Client(_config.normalizedServerUrl);

  final AgentRunnerConfig _config;
  final Client _client;
  Timer? _timer;
  Timer? _metricsTimer;
  Timer? _janitorTimer;
  final _subscriptions = <ResilientSubscription<Object?>>[];
  final _stopped = Completer<void>();
  final _metricsCollector = MetricsCollector();

  late final _updates = UpdateCoordinator(
    workQueue: _workQueue,
    updateFlagPath: _config.updateFlagPath,
    log: _log,
  );

  /// This install's version, reported on every check-in so the panel can
  /// tell when it's out of date (see [installedRunnerVersion]).
  late final String? _runnerVersion = installedRunnerVersion(
    executablePath: Platform.resolvedExecutable,
    permissionPromptToolPath: _config.permissionPromptToolPath,
  );

  /// The Claude token `claude` runs with; the panel can replace it.
  late final _claudeToken = () {
    final home = Platform.environment['HOME'];
    final path =
        _config.claudeTokenPath ??
        (home == null ? null : '$home/.roundtable/claude-oauth-token');
    if (path == null) {
      // Never a shared directory like /tmp: the token would be exposed.
      throw StateError('HOME is not set — set CLAUDE_TOKEN_PATH in the config');
    }
    return ClaudeTokenStore(
      path,
      installToken: _config.claudeCodeOauthToken,
      loginCredentialsPath: home == null
          ? null
          : '$home/.claude/.credentials.json',
    );
  }();

  late final _worktreeManager = WorktreeManager(
    workspaceRoot: _config.workspaceRoot,
  );

  Future<Agent> _fetchAgent(int agentId) async {
    final agent = await _client.agent.get(agentId);
    if (agent == null) {
      throw StateError('Agent $agentId not found');
    }
    return agent;
  }

  late final ReviewDispatcher _reviewDispatcher = ReviewDispatcher(
    worktreeManager: _worktreeManager,
    executorFactory: () =>
        ClaudeCodeExecutor(executable: _config.claudeExecutable),
    oauthToken: () => _claudeToken.token,
    getCloneUrl: (projectId) => _client.project.getCloneUrl(projectId),
    fetchAgent: _fetchAgent,
    startReview: (reviewId) => _client.codeReview.startReview(reviewId),
    completeReview: (reviewId, findings) => _client.codeReview.completeReview(
      reviewId,
      findings.summary,
      findings.comments,
      checks: findings.checks,
      verdict: findings.verdict,
    ),
    fetchPreviousComments: (reviewId) =>
        _client.codeReview.previousComments(reviewId),
    failReview: (reviewId, reason) =>
        _client.codeReview.failReview(reviewId, reason),
    appendLog: (entry) => _client.task.appendLogEntry(entry),
    log: _log,
    environmentPrompt: ({container = false}) =>
        _environmentPrompt(review: true, container: container),
    fetchAttachments: _fetchAttachments,
    fetchProject: (projectId) => _client.project.get(projectId),
    sandboxFor: _sandboxes.build,
    toolchainInstaller: _toolchainInstaller,
    workQueue: _workQueue,
    usageLimit: _usageLimit,
    requeueReview: (reviewId, until, reason) => _client.codeReview
        .requeueReview(reviewId, until: until, reason: reason),
    pauseQueuedReview: (reviewId, until) =>
        _client.codeReview.pauseQueuedReview(reviewId, until, null),
  );

  /// Shared by both dispatchers: one task run or review at a time per agent.
  final _workQueue = AgentWorkQueue();

  /// Shared by both dispatchers: the machine's Claude usage limit, reported
  /// to the panel (`Machine.usageLimitedUntil`) when a run hits it.
  late final _usageLimit = UsageLimitGate(
    onHit: (until) => unawaited(
      _client.machine
          .reportUsageLimit(_config.registrationToken, until)
          .catchError((Object e) => _log('reportUsageLimit failed: $e')),
    ),
  );

  late final TaskDispatcher _dispatcher = TaskDispatcher(
    worktreeManager: _worktreeManager,
    executorFactory: () =>
        ClaudeCodeExecutor(executable: _config.claudeExecutable),
    oauthToken: () => _claudeToken.token,
    getCloneUrl: (projectId) => _client.project.getCloneUrl(projectId),
    fetchAgent: _fetchAgent,
    updateTask: (task) => _client.task.update(task),
    updateAgent: (agent) => _client.agent.setStatus(agent.id!, agent.status),
    appendLog: (entry) => _client.task.appendLogEntry(entry),
    fetchLatestFeedback: (taskId) => _client.task.latestFeedback(taskId),
    openPullRequest: GitHubPullRequestOpener().open,
    watchTask: (taskId) => _client.task.watchTask(taskId),
    log: _log,
    serverUrl: _config.normalizedServerUrl,
    permissionPromptToolCommand: _config.permissionPromptToolCommand,
    fetchAttachments: _fetchAttachments,
    environmentPrompt: ({container = false}) =>
        _environmentPrompt(container: container),
    fetchProject: (projectId) => _client.project.get(projectId),
    fetchTask: (taskId) async =>
        (await _client.task.findTasks([taskId])).firstOrNull,
    toolchainInstaller: _toolchainInstaller,
    sandboxFor: _sandboxes.build,
    workQueue: _workQueue,
    usageLimit: _usageLimit,
  );

  // Under the service account's own home (/var/lib/agent-runner), which
  // it owns — installs need no sudo and outlive every worktree.
  late final _toolchainInstaller = ToolchainInstaller(home: _home);
  DateTime? _lastToolchainPrune;

  /// This machine's name and detected tools, set during [run].
  String? _machineName;
  List<ToolInfo>? _toolchain;

  String? _environmentPrompt({bool review = false, bool container = false}) {
    final toolchain = _toolchain;
    if (toolchain == null) return null;
    return buildEnvironmentPrompt(
      machineName: _machineName ?? 'unknown',
      user: Platform.environment['USER'] ?? 'roundtable-agent',
      tools: toolchain,
      review: review,
      container: container,
    );
  }

  String get _home => Platform.environment['HOME'] ?? Directory.systemTemp.path;

  late final _sandboxes = SandboxFactory(
    home: _home,
    workspaceRoot: _config.workspaceRoot,
    claudeExecutable: _config.claudeExecutable,
    permissionPromptToolCommand: _config.permissionPromptToolCommand,
    hasPodman: () =>
        _toolchain?.any((t) => t.name == 'podman' && t.version != null) ??
        false,
  );

  /// Detects the tools on PATH, for the agent's system prompt and the
  /// machine's card in the panel. Once per process: a new SDK shows up
  /// after a restart (e.g. via "Update runner").
  Future<void> _detectToolchain() async {
    final toolchain = await detectToolchain();
    _toolchain = toolchain;
    final available = [
      for (final t in toolchain)
        if (t.version != null) '${t.name}: ${t.version}',
    ];
    _log('toolchain: ${available.isEmpty ? '(none)' : available.join(', ')}');
    try {
      await _client.machine.reportToolchain(
        _config.registrationToken,
        available,
      );
    } catch (e) {
      _log('reportToolchain failed: $e');
    }
  }

  /// Reports the OS (e.g. "Ubuntu 24.04") for the machine's card in the
  /// panel, so the dev doesn't have to type it when registering the machine.
  Future<void> _detectOsVersion() async {
    final osVersion = await detectOsVersion();
    _log('os: $osVersion');
    try {
      await _client.machine.reportOsVersion(
        _config.registrationToken,
        osVersion,
      );
    } catch (e) {
      _log('reportOsVersion failed: $e');
    }
  }

  Future<List<TaskImage>> _fetchAttachments(int taskId) async {
    final attachments = await _client.taskAttachment.list(taskId);
    return [
      for (final a in attachments)
        (
          fileName: a.fileName,
          bytes: (await _client.taskAttachment.download(
            a.id!,
          )).buffer.asUint8List(),
        ),
    ];
  }

  late final _janitor = WorktreeJanitor(
    worktreeManager: _worktreeManager,
    findTasks: (taskIds) => _client.task.findTasks(taskIds),
    isActive: _dispatcher.isActive,
    log: _log,
  );

  Future<void> _sweepWorktrees() async {
    try {
      await _janitor.sweep();
    } catch (e) {
      _log('worktree cleanup failed, will retry: $e');
    }
    await _pruneToolchains();
  }

  /// Uninstalls toolchain versions no project uses anymore — once a day,
  /// riding the janitor's timer.
  Future<void> _pruneToolchains() async {
    final last = _lastToolchainPrune;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(days: 1)) {
      return;
    }
    _lastToolchainPrune = DateTime.now();
    try {
      final removed = await _toolchainInstaller.prune();
      if (removed.isNotEmpty) {
        _log('toolchains: removed unused ${removed.join(', ')}');
      }
    } catch (e) {
      _log('toolchain cleanup failed, will retry tomorrow: $e');
    }
  }

  /// Resolves this machine's id, subscribes to its assigned-task stream,
  /// then sends one heartbeat immediately and every [_heartbeatInterval]
  /// after — until [stop] is called or the server rejects the registration
  /// token.
  Future<void> run() async {
    _log('starting, server=${_config.serverUrl}');

    Machine? machine;
    var retryDelay = const Duration(seconds: 1);
    while (machine == null) {
      try {
        machine = await _client.machine.identify(_config.registrationToken);
      } on InvalidTokenException catch (e) {
        _log(
          'FATAL: registration token rejected by server (${e.message}) — '
          're-run scripts/install-agent.sh to obtain a new token',
        );
        stop(exitCode: 1);
        return;
      } catch (e) {
        _log('server unreachable ($e), retrying in ${retryDelay.inSeconds}s');
        await Future<void>.delayed(retryDelay);
        retryDelay = retryDelay * 2 > const Duration(seconds: 30)
            ? const Duration(seconds: 30)
            : retryDelay * 2;
      }
    }

    // A fresh process has no `claude` runs, so tell the server to fail any
    // task/review this machine was in the middle of before the restart —
    // before subscribing, so the replayed tasks already reflect that.
    try {
      await _client.machine.reportStartup(_config.registrationToken);
    } catch (e) {
      _log('reportStartup failed: $e');
    }

    _machineName = machine.name;
    // Before taking tasks, so even the first run knows its environment.
    await _detectToolchain();
    await _detectOsVersion();

    _subscribeToAssignedWork(machine.id!);
    await _tick();
    _timer = Timer.periodic(_heartbeatInterval, (_) => _tick());
    unawaited(_reportMetrics());
    _metricsTimer = Timer.periodic(_metricsInterval, (_) => _reportMetrics());
    unawaited(_sweepWorktrees());
    _janitorTimer = Timer.periodic(_janitorInterval, (_) => _sweepWorktrees());
    return _stopped.future;
  }

  /// Verifies `_config.claudeExecutable` can actually be launched, logging a
  /// clear warning and reporting the result to the server (surfaced as a
  /// warning banner on this machine's card in the panel — see
  /// `MachineEndpoint.reportClaudeStatus`) rather than letting the first
  /// assigned task surface a raw `ProcessException` that's easy to miss in
  /// install/journal logs. Called once at startup and again on every
  /// [_tick], so a fix applied without restarting the daemon (e.g. a
  /// `setfacl` permission grant) clears the warning within one heartbeat
  /// interval instead of requiring a restart. Deliberately non-fatal: the
  /// daemon still comes online and reports heartbeat/metrics so the machine
  /// doesn't look dead, it just can't run tasks yet.
  Future<void> _checkClaudeExecutable() async {
    String? failureMessage;
    try {
      await Process.run(_config.claudeExecutable, ['--version']);
    } on ProcessException catch (e) {
      failureMessage = describeClaudeLaunchFailure(e);
      _log('WARNING: $failureMessage');
    }
    try {
      await _client.machine.reportClaudeStatus(
        _config.registrationToken,
        failureMessage == null,
        failureMessage,
        authSource: _claudeToken.source,
      );
    } catch (e) {
      _log('reportClaudeStatus failed, will retry: $e');
    }
  }

  /// Hands every task and review assigned to this machine to its
  /// dispatcher, resubscribing whenever a stream drops.
  void _subscribeToAssignedWork(int machineId) {
    _subscriptions.addAll([
      ResilientSubscription<Task>(
        name: 'watchAssignedTasks',
        subscribe: () => _client.task.watchAssignedTasks(machineId),
        log: _log,
        onData: (task) {
          _log('assigned task ${task.id} (status=${task.status})');
          unawaited(
            _dispatcher
                .handle(task)
                .catchError(
                  (Object e) => _log('task ${task.id} dispatch failed: $e'),
                ),
          );
        },
      ),
      ResilientSubscription<CodeReview>(
        name: 'watchAssignedReviews',
        subscribe: () => _client.codeReview.watchAssignedReviews(machineId),
        log: _log,
        onData: (review) {
          _log('assigned review ${review.id} of task ${review.taskId}');
          unawaited(
            _reviewDispatcher
                .handle(review)
                .catchError(
                  (Object e) => _log('review ${review.id} dispatch failed: $e'),
                ),
          );
        },
      ),
    ]);
    for (final subscription in _subscriptions) {
      subscription.start();
    }
  }

  Future<void> _tick() async {
    try {
      final updateRequested = await _client.machine.checkIn(
        _config.registrationToken,
        _runnerVersion,
        drainsForUpdate: true,
      );
      _log('heartbeat ok');
      _updates.onCheckIn(updateRequested: updateRequested);
      await _pickUpClaudeToken();
    } on InvalidTokenException catch (e) {
      _log(
        'FATAL: registration token rejected by server (${e.message}) — '
        're-run scripts/install-agent.sh to obtain a new token',
      );
      stop(exitCode: 1);
    } catch (e) {
      _log('heartbeat failed, will retry: $e');
    }
    await _checkClaudeExecutable();
  }

  /// Saves a Claude token set in the panel since the last check-in, then
  /// tells the server it can drop it. A failure leaves it on the server for
  /// the next check-in. Runs already in progress keep the token they
  /// started with.
  Future<void> _pickUpClaudeToken() async {
    try {
      final token = await _client.machine.takeClaudeToken(
        _config.registrationToken,
      );
      if (token == null) return;
      await _claudeToken.save(token);
      await _client.machine.confirmClaudeToken(
        _config.registrationToken,
        token,
      );
      _log('Claude token updated from the panel');
    } catch (e) {
      _log('could not update the Claude token: $e');
    }
  }

  /// Reads local CPU/RAM usage and reports it to the server (docs/FLOWS.md §6).
  /// Deliberately doesn't treat [InvalidTokenException] as fatal here
  /// — the heartbeat tick already owns that responsibility on its own
  /// cadence; just log and retry.
  Future<void> _reportMetrics() async {
    try {
      final reading = await _metricsCollector.collect();
      await _client.machine.reportMetric(
        _config.registrationToken,
        reading.cpuPercent,
        reading.memoryUsedMb,
        reading.memoryTotalMb,
      );
    } catch (e) {
      _log('metrics report failed, will retry: $e');
    }
  }

  /// Cancels the heartbeat loop and lets [run] return. Passing a non-zero
  /// [exitCode] additionally terminates the process, used for an
  /// unrecoverable [InvalidTokenException] as opposed to an ordinary
  /// SIGTERM shutdown.
  void stop({int exitCode = 0}) {
    _timer?.cancel();
    _timer = null;
    _metricsTimer?.cancel();
    _metricsTimer = null;
    _janitorTimer?.cancel();
    _janitorTimer = null;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    if (!_stopped.isCompleted) {
      _stopped.complete();
    }
    if (exitCode != 0) {
      exit(exitCode);
    }
  }

  void _log(String message) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    stdout.writeln('[$timestamp] $message');
  }
}
