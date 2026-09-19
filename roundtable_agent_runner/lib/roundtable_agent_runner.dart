import 'dart:async';
import 'dart:io';

import 'package:roundtable_client/roundtable_client.dart';

export 'src/worktree_manager.dart';

const _heartbeatInterval = Duration(seconds: 20);

/// Config for the agent-runner daemon, read from a `KEY=VALUE` env file
/// rather than CLI flags — the file is written by `scripts/install-agent.sh`
/// with restrictive permissions (chmod 600), so the token never shows up in
/// `ps`/`systemctl status`/the unit file (design doc §6.8).
class AgentRunnerConfig {
  AgentRunnerConfig({
    required this.registrationToken,
    required this.serverUrl,
    this.claudeCodeOauthToken,
  });

  final String registrationToken;
  final String serverUrl;

  /// Held for a future Claude Code subprocess to consume (design doc §6.11);
  /// this stub doesn't launch any subprocess yet.
  final String? claudeCodeOauthToken;

  /// Reads REGISTRATION_TOKEN/SERVER_URL/CLAUDE_CODE_OAUTH_TOKEN.
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

/// Reports a periodic heartbeat to the roundtable server, and subscribes to
/// [TaskEndpoint.watchAssignedTasks] for as long as the process runs.
///
/// Subscribing to task assignments is currently log-only — picking up a
/// task's worktree, running Claude Code, and managing the PR flow are
/// separate, not-yet-implemented pieces of the full agent-runner daemon
/// (design doc §6.2, §6.10). Its purpose is to give `scripts/install-agent.sh`
/// a real, testable systemd service to install.
class AgentRunnerService {
  AgentRunnerService(this._config, {Client? client})
    : _client = client ?? Client(_normalizeServerUrl(_config.serverUrl));

  final AgentRunnerConfig _config;
  final Client _client;
  Timer? _timer;
  StreamSubscription<Task>? _taskSubscription;
  final _stopped = Completer<void>();

  static String _normalizeServerUrl(String url) =>
      url.endsWith('/') ? url : '$url/';

  /// Resolves this machine's id, subscribes to its assigned-task stream,
  /// then sends one heartbeat immediately and every [_heartbeatInterval]
  /// after — until [stop] is called or the server rejects the registration
  /// token.
  Future<void> run() async {
    _log('starting, server=${_config.serverUrl}');

    final Machine machine;
    try {
      machine = await _client.machine.identify(_config.registrationToken);
    } on InvalidTokenException catch (e) {
      _log(
        'FATAL: registration token rejected by server (${e.message}) — '
        're-run scripts/install-agent.sh to obtain a new token',
      );
      stop(exitCode: 1);
      return;
    }

    _subscribeToAssignedTasks(machine.id!);
    await _tick();
    _timer = Timer.periodic(_heartbeatInterval, (_) => _tick());
    return _stopped.future;
  }

  void _subscribeToAssignedTasks(int machineId) {
    _taskSubscription = _client.task
        .watchAssignedTasks(machineId)
        .listen(
          (task) => _log('assigned task ${task.id} (status=${task.status})'),
          onError: (Object error) =>
              _log('watchAssignedTasks stream error: $error'),
        );
  }

  Future<void> _tick() async {
    try {
      await _client.machine.heartbeat(_config.registrationToken);
      _log('heartbeat ok');
    } on InvalidTokenException catch (e) {
      _log(
        'FATAL: registration token rejected by server (${e.message}) — '
        're-run scripts/install-agent.sh to obtain a new token',
      );
      stop(exitCode: 1);
    } catch (e) {
      _log('heartbeat failed, will retry: $e');
    }
  }

  /// Cancels the heartbeat loop and lets [run] return. Passing a non-zero
  /// [exitCode] additionally terminates the process, used for an
  /// unrecoverable [InvalidTokenException] as opposed to an ordinary
  /// SIGTERM shutdown.
  void stop({int exitCode = 0}) {
    _timer?.cancel();
    _timer = null;
    _taskSubscription?.cancel();
    _taskSubscription = null;
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
