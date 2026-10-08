import 'dart:io';

import 'claude_token_store.dart';
import 'runner_update.dart';
import 'worktree_manager.dart';

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
    this.claudeTokenPath,
  });

  final String registrationToken;
  final String serverUrl;

  /// Passed as `CLAUDE_CODE_OAUTH_TOKEN` to the `claude` subprocess
  /// (docs/ARCHITECTURE.md) — never sent to the server. A token set in the
  /// panel replaces it ([ClaudeTokenStore]).
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
  /// (see [permissionPromptToolCommand]) — a deployed
  /// daemon has no Dart SDK to do that with, so it needs this precompiled
  /// binary instead (docs/FLOWS.md §4).
  final String? permissionPromptToolPath;

  /// File watched by the root-side updater `scripts/install-agent.sh`
  /// installs — writing it asks for the binaries to be re-downloaded and the
  /// service restarted (see [requestRunnerUpdate]). `null` for installs that
  /// predate in-panel updates, or dev-mode runs.
  final String? updateFlagPath;

  /// Where a Claude token set in the panel is saved
  /// ([ClaudeTokenStore]). Defaults to `~/.roundtable/claude-oauth-token`.
  final String? claudeTokenPath;

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
      claudeTokenPath: values['CLAUDE_TOKEN_PATH'],
    );
  }

  /// The command (executable + leading args) that launches the
  /// permission-prompt-tool MCP server. Prefers [permissionPromptToolPath]
  /// — the compiled binary `scripts/install-agent.sh` downloads alongside
  /// the daemon (docs/FLOWS.md §4), since a deployed machine has no Dart SDK
  /// to run `bin/permission_prompt_tool.dart` from source. Falls back to
  /// that dev-mode source invocation, re-running this Dart SDK against the
  /// sibling script of [Platform.script] — for local runs from a checkout.
  List<String> get permissionPromptToolCommand {
    final compiledPath = permissionPromptToolPath;
    if (compiledPath != null && File(compiledPath).existsSync()) {
      return [compiledPath];
    }
    final toolUri = Platform.script.resolve('permission_prompt_tool.dart');
    return [Platform.resolvedExecutable, 'run', toolUri.toFilePath()];
  }

  /// [serverUrl] with the trailing slash the generated client expects.
  String get normalizedServerUrl =>
      serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';

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
