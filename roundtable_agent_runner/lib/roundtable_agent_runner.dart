import 'dart:async';
import 'dart:io';

import 'package:roundtable_client/roundtable_client.dart';

import 'src/agent_work_queue.dart';
import 'src/claude_code_executor.dart';
import 'src/container_sandbox.dart';
import 'src/github_pull_request_opener.dart';
import 'src/metrics_collector.dart';
import 'src/review_dispatcher.dart';
import 'src/runner_update.dart';
import 'src/environment_prompt.dart';
import 'src/task_dispatcher.dart';
import 'src/task_images.dart';
import 'src/toolchain_installer.dart';
import 'src/worktree_janitor.dart';
import 'src/worktree_manager.dart';

export 'src/agent_work_queue.dart';
export 'src/claude_code_executor.dart';
export 'src/container_sandbox.dart';
export 'src/github_pull_request_opener.dart';
export 'src/metrics_collector.dart';
export 'src/permission_prompt_tool.dart';
export 'src/review_dispatcher.dart';
export 'src/runner_update.dart';
export 'src/stream_json_formatter.dart';
export 'src/environment_prompt.dart';
export 'src/log_entries.dart';
export 'src/task_dispatcher.dart';
export 'src/task_images.dart';
export 'src/toolchain_installer.dart';
export 'src/usage_limit.dart';
export 'src/worktree_janitor.dart';
export 'src/worktree_manager.dart';

const _heartbeatInterval = Duration(seconds: 20);
const _metricsInterval = Duration(seconds: 8);
const _janitorInterval = Duration(minutes: 30);

/// Delay before resubscribing to `watchAssignedTasks` after the stream
/// errors or closes unexpectedly (e.g. a transient WebSocket hiccup) — see
/// [AgentRunnerService._subscribeToAssignedTasks].
const _taskStreamResubscribeDelay = Duration(seconds: 5);

/// Config for the agent-runner daemon, read from a `KEY=VALUE` env file
/// rather than CLI flags — the file is written by `scripts/install-agent.sh`
/// with restrictive permissions (chmod 600), so the token never shows up in
/// `ps`/`systemctl status`/the unit file (docs/FLOWS.md §1–3).
class AgentRunnerConfig {
  AgentRunnerConfig({
    required this.registrationToken,
    required this.serverUrl,
    this.claudeCodeOauthToken,
    this.workspaceRoot = 'workspace',
    this.claudeExecutable = 'claude',
    this.permissionPromptToolPath,
    this.updateFlagPath,
  });

  final String registrationToken;
  final String serverUrl;

  /// Passed as `CLAUDE_CODE_OAUTH_TOKEN` to the `claude` subprocess
  /// (docs/ARCHITECTURE.md) — never sent to the server.
  final String? claudeCodeOauthToken;

  /// Path (or bare name resolved via PATH) to the `claude` CLI. Defaults to
  /// bare `'claude'`, which only resolves under systemd if it's on the
  /// service's restricted PATH — often not the case for a CLI installed via
  /// nvm/npm in a regular user's home directory. `scripts/install-agent.sh`
  /// resolves an absolute path at install time and sets `CLAUDE_EXECUTABLE`
  /// when it can find one, to avoid a `ProcessException: No such file or
  /// directory` at task-run time.
  final String claudeExecutable;

  /// Root directory for [WorktreeManager]'s per-project bare clones and
  /// per-task worktrees (docs/ARCHITECTURE.md).
  final String workspaceRoot;

  /// Path to the compiled `permission_prompt_tool` executable, when
  /// installed (`scripts/install-agent.sh` always sets this). `null` in a
  /// dev-mode run from a repo checkout, where the MCP server is instead
  /// launched by re-running `bin/permission_prompt_tool.dart` from source
  /// (see [AgentRunnerService._permissionPromptToolCommand]) — a deployed
  /// daemon has no Dart SDK to do that with, so it needs this precompiled
  /// binary instead (docs/FLOWS.md §4).
  final String? permissionPromptToolPath;

  /// File watched by the root-side updater `scripts/install-agent.sh`
  /// installs — writing it asks for the binaries to be re-downloaded and the
  /// service restarted (see [requestRunnerUpdate]). `null` for installs that
  /// predate in-panel updates, or dev-mode runs.
  final String? updateFlagPath;

  /// Reads REGISTRATION_TOKEN/SERVER_URL/CLAUDE_CODE_OAUTH_TOKEN/WORKSPACE_ROOT.
  ///
  /// Under systemd, `EnvironmentFile=/etc/agent-runner/config.env` in the
  /// unit (written by `scripts/install-agent.sh`) is parsed by the systemd
  /// manager itself — running as root — which then injects the resulting
  /// variables into this process's environment before exec. That's why the
  /// daemon (running as the unprivileged `roundtable-agent` user, unable to
  /// open a chmod-600 root-owned file on its own) can read them here via
  /// [Platform.environment] rather than opening the config file directly.
  ///
  /// For local development without systemd, pass [path] or set the
  /// `AGENT_RUNNER_CONFIG_PATH` env var to parse a `KEY=VALUE` file instead.
  ///
  /// Throws a [StateError] with a clear message when a required key isn't
  /// set, so the failure surfaces loudly in `journalctl -u agent-runner`
  /// instead of failing silently.
  static AgentRunnerConfig load({String? path}) {
    final configPath = path ?? Platform.environment['AGENT_RUNNER_CONFIG_PATH'];
    final values = configPath == null
        ? Platform.environment
        : _parseEnvFile(configPath);

    final token = values['REGISTRATION_TOKEN'];
    final server = values['SERVER_URL'];
    final source = configPath ?? 'the process environment';
    if (token == null || token.isEmpty) {
      throw StateError('Missing REGISTRATION_TOKEN in $source');
    }
    if (server == null || server.isEmpty) {
      throw StateError('Missing SERVER_URL in $source');
    }

    return AgentRunnerConfig(
      registrationToken: token,
      serverUrl: server,
      claudeCodeOauthToken: values['CLAUDE_CODE_OAUTH_TOKEN'],
      workspaceRoot: values['WORKSPACE_ROOT'] ?? 'workspace',
      claudeExecutable: values['CLAUDE_EXECUTABLE'] ?? 'claude',
      permissionPromptToolPath: values['PERMISSION_PROMPT_TOOL_PATH'],
      updateFlagPath: values['UPDATE_FLAG_PATH'],
    );
  }

  static Map<String, String> _parseEnvFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('Config file not found: $path');
    }

    final values = <String, String>{};
    for (final rawLine in file.readAsLinesSync()) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final separator = line.indexOf('=');
      if (separator == -1) continue;
      values[line.substring(0, separator).trim()] = line
          .substring(separator + 1)
          .trim();
    }
    return values;
  }
}

/// The daemon: identifies this machine, subscribes to its assigned tasks
/// and code reviews (handed to [TaskDispatcher] / [ReviewDispatcher]),
/// checks in every [_heartbeatInterval] (heartbeat, runner version, update
/// requests), reports CPU/RAM every [_metricsInterval], and periodically
/// sweeps leftover worktrees ([WorktreeJanitor]). See
/// `docs/ARCHITECTURE.md` (Agent runner) and `docs/FLOWS.md`.
class AgentRunnerService {
  AgentRunnerService(this._config, {Client? client})
    : _client = client ?? Client(_normalizeServerUrl(_config.serverUrl));

  final AgentRunnerConfig _config;
  final Client _client;
  Timer? _timer;
  Timer? _metricsTimer;
  Timer? _janitorTimer;
  StreamSubscription<Task>? _taskSubscription;
  Timer? _taskResubscribeTimer;
  StreamSubscription<CodeReview>? _reviewSubscription;
  Timer? _reviewResubscribeTimer;
  final _stopped = Completer<void>();
  final _metricsCollector = MetricsCollector();
  bool _updateHandedOff = false;

  /// This install's version, reported on every check-in so the panel can
  /// tell when it's out of date (see [installedRunnerVersion]).
  late final String? _runnerVersion = installedRunnerVersion(
    executablePath: Platform.resolvedExecutable,
    permissionPromptToolPath: _config.permissionPromptToolPath,
  );

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
    oauthToken: _config.claudeCodeOauthToken,
    getCloneUrl: (projectId) => _client.project.getCloneUrl(projectId),
    fetchAgent: _fetchAgent,
    startReview: (reviewId) => _client.codeReview.startReview(reviewId),
    completeReview: (reviewId, summary, comments, checks) => _client.codeReview
        .completeReview(reviewId, summary, comments, checks: checks),
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
    sandboxFor: _sandboxFor,
    workQueue: _workQueue,
  );

  /// Shared by both dispatchers: one task run or review at a time per agent.
  final _workQueue = AgentWorkQueue();

  late final TaskDispatcher _dispatcher = TaskDispatcher(
    worktreeManager: _worktreeManager,
    executorFactory: () =>
        ClaudeCodeExecutor(executable: _config.claudeExecutable),
    oauthToken: _config.claudeCodeOauthToken,
    getCloneUrl: (projectId) => _client.project.getCloneUrl(projectId),
    fetchAgent: _fetchAgent,
    updateTask: (task) => _client.task.update(task),
    updateAgent: (agent) => _client.agent.setStatus(agent.id!, agent.status),
    appendLog: (entry) => _client.task.appendLogEntry(entry),
    fetchLatestFeedback: (taskId) => _client.task.latestFeedback(taskId),
    openPullRequest: GitHubPullRequestOpener().open,
    watchTask: (taskId) => _client.task.watchTask(taskId),
    log: _log,
    serverUrl: _normalizeServerUrl(_config.serverUrl),
    permissionPromptToolCommand: _permissionPromptToolCommand(_config),
    fetchAttachments: _fetchAttachments,
    environmentPrompt: ({container = false}) =>
        _environmentPrompt(container: container),
    fetchProject: (projectId) => _client.project.get(projectId),
    fetchTask: (taskId) async =>
        (await _client.task.findTasks([taskId])).firstOrNull,
    toolchainInstaller: _toolchainInstaller,
    sandboxFor: _sandboxFor,
    workQueue: _workQueue,
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

  /// The container of a docker-mode agent's run (docs/FLOWS.md §8): the
  /// task's worktree and the project's bare repo (its git data) read-write,
  /// the toolchains and pub cache read-write (Flutter writes into its own
  /// SDK), `claude` and the permission-prompt-tool read-only, and a home
  /// per project, so Claude Code's sessions survive for `--resume`.
  ContainerSandbox _sandboxFor(ContainerRequest request) {
    final podman = _toolchain?.any(
      (t) => t.name == 'podman' && t.version != null,
    );
    if (podman != true) {
      throw StateError(
        'this agent runs in docker mode, but podman is not installed on this '
        'machine — re-run install-agent.sh with --docker, or switch the agent '
        'to native',
      );
    }
    final home = _home;
    final containerHome = Directory(
      '$home/containers/project-${request.projectId}',
    )..createSync(recursive: true);
    _copyClaudeCredentials(home, containerHome.path);
    final claude = _resolveExecutable(_config.claudeExecutable);
    final workspace = Directory(_config.workspaceRoot).absolute.path;
    final shared = ['$home/.local/share/mise', '$home/.pub-cache'];
    for (final dir in shared) {
      Directory(dir).createSync(recursive: true);
    }
    return ContainerSandbox(
      image: request.image?.trim().isNotEmpty == true
          ? request.image!.trim()
          : defaultContainerImage,
      name: request.name,
      workingDirectory: request.worktreePath,
      home: containerHome.path,
      claudePath: claude,
      podman: _resolveExecutable('podman'),
      mounts: [
        (path: request.worktreePath, readOnly: false),
        (path: '$workspace/${request.projectId}/repo.git', readOnly: false),
        (path: containerHome.path, readOnly: false),
        for (final dir in shared) (path: dir, readOnly: false),
        (path: claude, readOnly: true),
        if (_permissionPromptToolCommand(_config) case [final tool])
          (path: tool, readOnly: true),
        for (final dir in request.readOnlyDirectories)
          (path: dir, readOnly: true),
      ],
    );
  }

  /// A machine logged in with `claude login` (no `CLAUDE_CODE_OAUTH_TOKEN`)
  /// keeps its credentials in `~/.claude`; containers get a copy, never the
  /// rest of that directory (other projects' sessions).
  static void _copyClaudeCredentials(String home, String containerHome) {
    final credentials = File('$home/.claude/.credentials.json');
    if (!credentials.existsSync()) return;
    Directory('$containerHome/.claude').createSync(recursive: true);
    credentials.copySync('$containerHome/.claude/.credentials.json');
  }

  /// The absolute, symlink-free path of [executable] (a path or a name on
  /// PATH), so it can be mounted into a container.
  static String _resolveExecutable(String executable) {
    if (!executable.contains('/')) {
      for (final dir in (Platform.environment['PATH'] ?? '').split(':')) {
        if (dir.isNotEmpty && File('$dir/$executable').existsSync()) {
          executable = '$dir/$executable';
          break;
        }
      }
    }
    return File(executable).resolveSymbolicLinksSync();
  }

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

  /// Prefers `_config.permissionPromptToolPath` — the compiled binary
  /// `scripts/install-agent.sh` downloads alongside the main daemon
  /// (docs/FLOWS.md §4), since a deployed machine has no Dart SDK to run
  /// `bin/permission_prompt_tool.dart` from source. Falls back to that
  /// dev-mode source invocation, re-running this same Dart SDK against the
  /// sibling script resolved relative to [Platform.script] (this process's
  /// own entrypoint, `bin/roundtable_agent_runner.dart`) — used for local
  /// runs from a repo checkout, where no such compiled path is configured.
  static List<String> _permissionPromptToolCommand(AgentRunnerConfig config) {
    final compiledPath = config.permissionPromptToolPath;
    if (compiledPath != null && File(compiledPath).existsSync()) {
      return [compiledPath];
    }
    final toolUri = Platform.script.resolve('permission_prompt_tool.dart');
    return [Platform.resolvedExecutable, 'run', toolUri.toFilePath()];
  }

  static String _normalizeServerUrl(String url) =>
      url.endsWith('/') ? url : '$url/';

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

    _subscribeToAssignedTasks(machine.id!);
    _subscribeToAssignedReviews(machine.id!);
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
      );
    } catch (e) {
      _log('reportClaudeStatus failed, will retry: $e');
    }
  }

  /// Subscribes to `watchAssignedTasks`, resubscribing after a short delay
  /// if the stream ever errors or closes unexpectedly (e.g. a transient
  /// WebSocket hiccup). Without this, one dropped stream would silently and
  /// permanently stop the daemon from picking up any task — created,
  /// retried, or fed back — while its unrelated heartbeat/metrics timers
  /// kept it looking "online" the whole time.
  void _subscribeToAssignedTasks(int machineId) {
    _taskSubscription = _client.task
        .watchAssignedTasks(machineId)
        .listen(
          (task) {
            _log('assigned task ${task.id} (status=${task.status})');
            unawaited(
              _dispatcher
                  .handle(task)
                  .catchError(
                    (Object error) =>
                        _log('task ${task.id} dispatch failed: $error'),
                  ),
            );
          },
          onError: (Object error) {
            _log('watchAssignedTasks stream error: $error — resubscribing');
            _scheduleResubscribeToAssignedTasks(machineId);
          },
          onDone: () {
            if (_stopped.isCompleted) return;
            _log(
              'watchAssignedTasks stream closed unexpectedly — resubscribing',
            );
            _scheduleResubscribeToAssignedTasks(machineId);
          },
        );
  }

  void _scheduleResubscribeToAssignedTasks(int machineId) {
    if (_stopped.isCompleted) return;
    _taskResubscribeTimer?.cancel();
    _taskResubscribeTimer = Timer(_taskStreamResubscribeDelay, () {
      if (_stopped.isCompleted) return;
      _subscribeToAssignedTasks(machineId);
    });
  }

  /// Like [_subscribeToAssignedTasks], for `watchAssignedReviews`.
  void _subscribeToAssignedReviews(int machineId) {
    void resubscribe() {
      if (_stopped.isCompleted) return;
      _reviewResubscribeTimer?.cancel();
      _reviewResubscribeTimer = Timer(_taskStreamResubscribeDelay, () {
        if (_stopped.isCompleted) return;
        _subscribeToAssignedReviews(machineId);
      });
    }

    _reviewSubscription = _client.codeReview
        .watchAssignedReviews(machineId)
        .listen(
          (review) {
            _log('assigned review ${review.id} of task ${review.taskId}');
            unawaited(
              _reviewDispatcher
                  .handle(review)
                  .catchError(
                    (Object error) =>
                        _log('review ${review.id} dispatch failed: $error'),
                  ),
            );
          },
          onError: (Object error) {
            _log('watchAssignedReviews stream error: $error — resubscribing');
            resubscribe();
          },
          onDone: () {
            if (_stopped.isCompleted) return;
            _log(
              'watchAssignedReviews stream closed unexpectedly — resubscribing',
            );
            resubscribe();
          },
        );
  }

  Future<void> _tick() async {
    try {
      final updateRequested = await _client.machine.checkIn(
        _config.registrationToken,
        _runnerVersion,
      );
      _log('heartbeat ok');
      if (updateRequested) _handOffUpdate();
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

  /// Triggers the root-side updater once per process — it restarts this
  /// service, so the next process reports the new version and the server
  /// clears the request.
  void _handOffUpdate() {
    if (_updateHandedOff) return;
    final flagPath = _config.updateFlagPath;
    if (flagPath == null) {
      _log(
        'update requested, but this install has no updater — re-run '
        'scripts/install-agent.sh once to enable in-panel updates',
      );
    } else if (requestRunnerUpdate(flagPath)) {
      _log('update requested, handed off to agent-runner-update');
    } else {
      _log('update requested, but could not write $flagPath');
      return;
    }
    _updateHandedOff = true;
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
    _taskResubscribeTimer?.cancel();
    _taskResubscribeTimer = null;
    _taskSubscription?.cancel();
    _taskSubscription = null;
    _reviewResubscribeTimer?.cancel();
    _reviewResubscribeTimer = null;
    _reviewSubscription?.cancel();
    _reviewSubscription = null;
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
