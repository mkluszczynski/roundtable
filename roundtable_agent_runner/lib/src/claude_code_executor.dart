import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'container_sandbox.dart';

/// POSIX `EACCES` — the OS error code `ProcessException.errorCode` carries
/// when a subprocess couldn't be launched due to a permissions problem
/// (as opposed to `ENOENT`, "no such file or directory").
const _eaccesErrorCode = 13;

/// Human-readable, actionable description of a [ProcessException] thrown by
/// [Process.start]/[Process.run] when launching the configured `claude`
/// executable. Shared between [TaskDispatcher]'s per-task `Task.failureReason`
/// and the daemon's startup/periodic health check
/// (`AgentRunnerService._checkClaudeExecutable`), so both surfaces give the
/// same diagnosis instead of a raw exception dump.
String describeClaudeLaunchFailure(ProcessException e) {
  if (e.errorCode == _eaccesErrorCode) {
    return 'Permission denied launching the claude CLI ("${e.executable}") — '
        'the agent-runner service user cannot execute this file. This '
        "usually means CLAUDE_EXECUTABLE points at a regular user's own "
        "install (e.g. via nvm/npm) and that user's home directory blocks "
        'this cross-user access. Re-run scripts/install-agent.sh, which '
        'installs claude directly for the agent-runner service account '
        'instead (its own self-contained install, no cross-user permissions '
        'needed), then restart the agent-runner service.';
  }
  return 'Could not launch the claude CLI ("${e.executable}"): ${e.message}. '
      'Set CLAUDE_EXECUTABLE in /etc/agent-runner/config.env to its full '
      'path and restart the agent-runner service.';
}

/// The outcome of one `claude` execution-phase run (docs/FLOWS.md §4).
class ClaudeCodeExecutionResult {
  ClaudeCodeExecutionResult({
    required this.success,
    required this.exitCode,
    this.sessionId,
    this.errorSummary,
    this.resultText,
  });

  /// True when the process exited 0 and the final NDJSON `result` message
  /// reported `subtype: "success"`.
  final bool success;

  final int exitCode;

  /// From the final `result` message's `session_id` field, if one arrived —
  /// stored as `Task.claudeSessionId` so a later feedback iteration can pass
  /// it back via `--resume`.
  final String? sessionId;

  /// Set when [success] is false: the final result message (the model's
  /// error, e.g. a usage limit), else stderr, else the exit code.
  final String? errorSummary;

  /// The final `result` message's `result` field — the model's last reply.
  final String? resultText;
}

/// Spawns `claude` in execution-phase mode (docs/FLOWS.md §4 "Execution
/// phase") and parses its `--output-format stream-json` stdout as NDJSON,
/// one line at a time.
class ClaudeCodeExecutor {
  ClaudeCodeExecutor({
    this.executable = 'claude',
    this.pipeDrainTimeout = const Duration(seconds: 5),
    this.sandbox,
  });

  /// Overridable in tests to point at a fake script instead of the real CLI.
  final String executable;

  /// When set, `claude` runs inside this container (a docker-mode agent)
  /// instead of directly on the machine.
  final ContainerSandbox? sandbox;

  /// This executor, running `claude` inside [sandbox].
  ClaudeCodeExecutor inContainer(ContainerSandbox sandbox) =>
      ClaudeCodeExecutor(
        executable: executable,
        pipeDrainTimeout: pipeDrainTimeout,
        sandbox: sandbox,
      );

  /// How long to keep reading stdout/stderr after the process has exited.
  final Duration pipeDrainTimeout;

  /// Runs one execution-phase invocation. [prompt] is always passed to `-p`
  /// as given — the caller decides what it should be (empty for a
  /// no-message resume; the feedback text for a review-phase resume).
  ///
  /// [onLine] is called once per non-blank line of stdout, with the raw
  /// NDJSON text exactly as emitted — that's what the caller persists via
  /// `TaskEndpoint.appendLog` (docs/FLOWS.md §4).
  ///
  /// [additionalDirectories] are passed as `--add-dir`, granting access
  /// outside the worktree (e.g. the task's attached images).
  ///
  /// [onProcessStarted], if given, is called once with the live [Process]
  /// right after it's spawned — so a caller can send it a signal (e.g.
  /// `SIGTERM` on cancellation, docs/FLOWS.md §4) without this method
  /// otherwise exposing the process.
  Future<ClaudeCodeExecutionResult> run({
    required String prompt,
    required String workingDirectory,
    String? oauthToken,
    Map<String, String>? environment,
    String? model,
    String? effort,
    String? resumeSessionId,
    String? permissionPromptTool,
    String? mcpConfigPath,
    List<String> additionalDirectories = const [],
    String? appendSystemPrompt,
    required void Function(String line) onLine,
    void Function(Process process)? onProcessStarted,
  }) {
    final args = [
      '-p',
      prompt,
      '--output-format',
      'stream-json',
      '--verbose',
      '--include-partial-messages',
      // Headless `-p` auto-denies anything needing approval (Edit, Bash…);
      // the permission-prompt-tool auto-allows those instead.
      if (permissionPromptTool != null && mcpConfigPath != null) ...[
        '--mcp-config',
        mcpConfigPath,
        '--strict-mcp-config',
        '--permission-prompt-tool',
        permissionPromptTool,
      ] else ...[
        '--permission-prompts',
        'none',
      ],
      if (resumeSessionId != null) ...['--resume', resumeSessionId],
      if (model != null) ...['--model', model],
      if (effort != null) ...['--effort', effort],
      for (final dir in additionalDirectories) ...['--add-dir', dir],
      if (appendSystemPrompt != null) ...[
        '--append-system-prompt',
        appendSystemPrompt,
      ],
    ];

    return _runProcess(
      args: args,
      workingDirectory: workingDirectory,
      oauthToken: oauthToken,
      environment: environment,
      onLine: onLine,
      onProcessStarted: onProcessStarted,
    );
  }

  /// Runs one planning-phase invocation (docs/FLOWS.md §4):
  /// `--permission-mode plan routes every non-read-only tool call —
  /// `AskUserQuestion`, `ExitPlanMode`, and (once a plan is approved) the
  /// implementation tools that follow — through [permissionPromptTool], an
  /// MCP tool registered via [mcpConfigPath] (see
  /// `PermissionPromptTool`/`bin/permission_prompt_tool.dart`). Confirmed by
  /// a manual spike against the real `claude` CLI: an approved `ExitPlanMode`
  /// does **not** end the process — planning and execution happen in this
  /// one continuous invocation, so there's no separate execution-phase call
  /// to chain afterward for a fresh (non-`skipPlanning`) task. [permissionPromptTool]
  /// is the tool's fully-qualified name, e.g.
  /// `mcp__roundtable-permission__approval_prompt`.
  Future<ClaudeCodeExecutionResult> runPlanning({
    required String prompt,
    required String workingDirectory,
    required String permissionPromptTool,
    required String mcpConfigPath,
    String? oauthToken,
    Map<String, String>? environment,
    String? model,
    String? effort,
    List<String> additionalDirectories = const [],
    String? appendSystemPrompt,
    String? resumeSessionId,
    required void Function(String line) onLine,
    void Function(Process process)? onProcessStarted,
  }) {
    final args = [
      '-p',
      prompt,
      '--output-format',
      'stream-json',
      '--verbose',
      '--include-partial-messages',
      if (resumeSessionId != null) ...['--resume', resumeSessionId],
      '--permission-mode',
      'plan',
      '--mcp-config',
      mcpConfigPath,
      '--strict-mcp-config',
      '--permission-prompt-tool',
      permissionPromptTool,
      if (model != null) ...['--model', model],
      if (effort != null) ...['--effort', effort],
      for (final dir in additionalDirectories) ...['--add-dir', dir],
      if (appendSystemPrompt != null) ...[
        '--append-system-prompt',
        appendSystemPrompt,
      ],
    ];

    return _runProcess(
      args: args,
      workingDirectory: workingDirectory,
      oauthToken: oauthToken,
      environment: environment,
      onLine: onLine,
      onProcessStarted: onProcessStarted,
    );
  }

  /// Runs one read-only code-review invocation: only tools that can't
  /// change the working tree are allowed (headless `-p` denies everything
  /// else), so the reviewer can explore the code and diff but never edit it.
  ///
  /// [additionalDirectories] are passed as `--add-dir` (e.g. the task's
  /// attached images). [allowBash] lets the reviewer run any command — only
  /// inside a container, to run the project's checks; otherwise it gets
  /// git's read-only commands. Editing tools stay off either way.
  Future<ClaudeCodeExecutionResult> runReview({
    required String prompt,
    required String workingDirectory,
    String? oauthToken,
    Map<String, String>? environment,
    String? model,
    String? effort,
    List<String> additionalDirectories = const [],
    String? appendSystemPrompt,
    bool allowBash = false,
    required void Function(String line) onLine,
    void Function(Process process)? onProcessStarted,
  }) {
    final args = [
      '-p',
      prompt,
      '--output-format',
      'stream-json',
      '--verbose',
      '--include-partial-messages',
      '--allowedTools',
      allowBash
          ? 'Read,Grep,Glob,Bash'
          : 'Read,Grep,Glob,Bash(git diff:*),Bash(git log:*),Bash(git show:*)',
      '--disallowedTools',
      'Edit,Write,NotebookEdit',
      if (model != null) ...['--model', model],
      if (effort != null) ...['--effort', effort],
      for (final dir in additionalDirectories) ...['--add-dir', dir],
      if (appendSystemPrompt != null) ...[
        '--append-system-prompt',
        appendSystemPrompt,
      ],
    ];

    return _runProcess(
      args: args,
      workingDirectory: workingDirectory,
      oauthToken: oauthToken,
      environment: environment,
      onLine: onLine,
      onProcessStarted: onProcessStarted,
    );
  }

  Future<ClaudeCodeExecutionResult> _runProcess({
    required List<String> args,
    required String workingDirectory,
    String? oauthToken,
    Map<String, String>? environment,
    required void Function(String line) onLine,
    void Function(Process process)? onProcessStarted,
  }) async {
    final env = {...?environment, 'CLAUDE_CODE_OAUTH_TOKEN': ?oauthToken};
    final sandbox = this.sandbox;
    final Process process;
    if (sandbox == null) {
      process = await Process.start(
        executable,
        args,
        workingDirectory: workingDirectory,
        environment: env,
      );
    } else {
      // The container sets its own HOME; everything else is passed through.
      env.remove('HOME');
      process = await Process.start(
        sandbox.podman,
        sandbox.runArgs(sandbox.claudePath, args, environment: env.keys),
        workingDirectory: workingDirectory,
        environment: env,
      );
    }
    // The prompt goes in via `-p`; an open stdin makes `claude` wait 3s and
    // print a warning to stderr, which used to become the failure reason.
    unawaited(process.stdin.close());
    onProcessStarted?.call(process);

    String? sessionId;
    String? resultText;
    var reportedSuccess = false;

    final stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.trim().isEmpty) return;
          onLine(line);

          Map<String, dynamic> event;
          try {
            event = jsonDecode(line) as Map<String, dynamic>;
          } catch (_) {
            return;
          }
          if (event['type'] == 'result') {
            sessionId = event['session_id'] as String?;
            reportedSuccess = event['subtype'] == 'success';
            resultText = event['result'] as String?;
          }
        });
    final stdoutDone = stdoutSub.asFuture<void>();

    final stderrBuffer = StringBuffer();
    final stderrSub = process.stderr
        .transform(utf8.decoder)
        .listen(stderrBuffer.write);
    final stderrDone = stderrSub.asFuture<void>();

    final exitCode = await process.exitCode;
    // A grandchild (e.g. the permission-prompt-tool MCP server) can inherit
    // and keep the pipes open after `claude` exits, so EOF may never come.
    try {
      await Future.wait([stdoutDone, stderrDone]).timeout(pipeDrainTimeout);
    } on TimeoutException {
      await stdoutSub.cancel();
      await stderrSub.cancel();
    }

    final success = reportedSuccess && exitCode == 0;
    return ClaudeCodeExecutionResult(
      success: success,
      exitCode: exitCode,
      sessionId: sessionId,
      resultText: resultText,
      // Prefer the model's own error (e.g. "You've hit your session limit")
      // over stderr noise.
      errorSummary: success
          ? null
          : (resultText?.trim().isNotEmpty ?? false)
          ? resultText!.trim()
          : (stderrBuffer.isEmpty
                ? 'claude exited with code $exitCode'
                : stderrBuffer.toString().trim()),
    );
  }
}
