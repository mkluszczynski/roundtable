import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The outcome of one `claude` execution-phase run (design doc §6.2).
class ClaudeCodeExecutionResult {
  ClaudeCodeExecutionResult({
    required this.success,
    required this.exitCode,
    this.sessionId,
    this.errorSummary,
  });

  /// True when the process exited 0 and the final NDJSON `result` message
  /// reported `subtype: "success"`.
  final bool success;

  final int exitCode;

  /// From the final `result` message's `session_id` field, if one arrived —
  /// stored as `Task.claudeSessionId` so a later feedback iteration can pass
  /// it back via `--resume`.
  final String? sessionId;

  /// Set when [success] is false: the process's stderr output, or a fallback
  /// describing the exit code if stderr was empty.
  final String? errorSummary;
}

/// Spawns `claude` in execution-phase mode (design doc §6.2 "Execution
/// phase") and parses its `--output-format stream-json` stdout as NDJSON,
/// one line at a time.
class ClaudeCodeExecutor {
  ClaudeCodeExecutor({this.executable = 'claude'});

  /// Overridable in tests to point at a fake script instead of the real CLI.
  final String executable;

  /// Runs one execution-phase invocation. [prompt] is always passed to `-p`
  /// as given — the caller decides what it should be (empty for a
  /// no-message resume, matching the design doc's `<prompt, or empty if
  /// --resume>`; the feedback text for a review-phase resume).
  ///
  /// [onLine] is called once per non-blank line of stdout, with the raw
  /// NDJSON text exactly as emitted — that's what the caller persists via
  /// `TaskEndpoint.appendLog` (design doc §6.3).
  ///
  /// [onProcessStarted], if given, is called once with the live [Process]
  /// right after it's spawned — so a caller can send it a signal (e.g.
  /// `SIGTERM` on cancellation, design doc §6.1) without this method
  /// otherwise exposing the process.
  Future<ClaudeCodeExecutionResult> run({
    required String prompt,
    required String workingDirectory,
    String? oauthToken,
    String? model,
    String? effort,
    String? resumeSessionId,
    required void Function(String line) onLine,
    void Function(Process process)? onProcessStarted,
  }) async {
    final args = [
      '-p',
      prompt,
      '--output-format',
      'stream-json',
      '--verbose',
      '--include-partial-messages',
      '--permission-prompts',
      'none',
      if (resumeSessionId != null) ...['--resume', resumeSessionId],
      if (model != null) ...['--model', model],
      if (effort != null) ...['--effort', effort],
    ];

    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: {'CLAUDE_CODE_OAUTH_TOKEN': ?oauthToken},
    );
    onProcessStarted?.call(process);

    String? sessionId;
    var reportedSuccess = false;

    final stdoutDone = process.stdout
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
          }
        })
        .asFuture<void>();

    final stderrBuffer = StringBuffer();
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .listen(stderrBuffer.write)
        .asFuture<void>();

    final exitCode = await process.exitCode;
    await stdoutDone;
    await stderrDone;

    final success = reportedSuccess && exitCode == 0;
    return ClaudeCodeExecutionResult(
      success: success,
      exitCode: exitCode,
      sessionId: sessionId,
      errorSummary: success
          ? null
          : (stderrBuffer.isEmpty
                ? 'claude exited with code $exitCode'
                : stderrBuffer.toString().trim()),
    );
  }
}
