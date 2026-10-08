import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:roundtable_client/roundtable_client.dart';

import 'agent_work_queue.dart';
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

part 'run_kind.dart';
part 'task_run.dart';

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
    this.fetchTask,
    this.toolchainInstaller,
    this.sandboxFor,
    AgentWorkQueue? workQueue,
    UsageLimitGate? usageLimit,
  }) : workQueue = workQueue ?? AgentWorkQueue(),
       usageLimit = usageLimit ?? UsageLimitGate();

  /// The machine's Claude usage limit, shared with `ReviewDispatcher`: a
  /// run hitting it closes the gate, and work that hasn't started waits.
  final UsageLimitGate usageLimit;

  /// One piece of work at a time per agent, shared with `ReviewDispatcher`:
  /// a task for a busy agent waits here.
  final AgentWorkQueue workQueue;

  /// The task's project, for its toolchains ([Project.tools]) and docker
  /// image. With [toolchainInstaller], the toolchains are installed before
  /// each run and put first on `claude`'s `PATH` (docs/FLOWS.md §7).
  final Future<Project?> Function(int projectId)? fetchProject;

  /// The task's current row, or null once it's deleted. Bound to
  /// `client.task.findTasks` in production. Used by [handle] when a task is
  /// handed in again while an earlier [handle] of it is still in flight: by
  /// the time that one finishes, the snapshot it was handed is stale. Without
  /// it, the snapshot is used as is.
  final Future<Task?> Function(int taskId)? fetchTask;
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

  /// The current Claude Code OAuth token: it can change from the panel
  /// while the daemon runs (docs/FLOWS.md §1). Null: `claude login`.
  final String? Function()? oauthToken;
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
  /// cancellation while [ClaudeCodeExecutor.run] is in flight: the task moves
  /// back to `draft` (or, from an older server, to `cancelled`).
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

  /// Per task id, completes when the latest [handle] call for it is done —
  /// so a task's runs never overlap (see [handle]).
  final Map<int, Future<void>> _lastRun = {};

  /// Whether a [handle] call for [taskId] is in flight, i.e. its worktree
  /// may be in use — see `WorktreeJanitor`.
  bool isActive(int taskId) => _inFlight.containsKey(taskId);

  ///
  /// Calls for the same task run one after another, never concurrently: a
  /// task cancelled back to the backlog and assigned again may be handed in
  /// while its cancelled run is still tearing down, which would otherwise
  /// reset the worktree under the new run and let the old run's writes land
  /// on the new one. A call that had to wait acts on the task's current row
  /// ([fetchTask]) — skipped if it's gone or was assigned to another agent
  /// since (that agent's machine is handed it on its own).
  Future<void> handle(Task task) async {
    final id = task.id!;
    _inFlight[id] = (_inFlight[id] ?? 0) + 1;
    final previous = _lastRun[id];
    final done = Completer<void>();
    _lastRun[id] = done.future;
    try {
      if (previous != null) {
        await previous;
        final current = await (fetchTask?.call(id) ?? Future.value(task));
        if (current == null) {
          log('task $id: deleted while its previous run finished, skipping');
          return;
        }
        if (current.agentId != task.agentId) {
          log('task $id: reassigned while its previous run finished, skipping');
          return;
        }
        task = current;
      }
      final agentId = task.agentId;
      if (agentId == null) {
        await _handle(task);
      } else {
        var waited = false;
        await workQueue.run(
          agentId,
          'task #$id',
          () async {
            final limited = await usageLimit.wait(
              onWaiting: (until) {
                log('task $id: usage limit, waiting until $until');
                _logEvent(
                  id,
                  'Waiting for the Claude usage limit to reset at '
                  '${localClock(until)}',
                );
              },
            );
            if (waited || limited) {
              final current = await (fetchTask?.call(id) ?? Future.value(task));
              if (current == null || current.agentId != agentId) {
                log('task $id: deleted or reassigned while waiting, skipping');
                return;
              }
              task = current;
            }
            await _handle(task);
          },
          onWaiting: (busyWith) {
            waited = true;
            log('task $id: agent $agentId is busy with $busyWith, waiting');
            _logEvent(id, 'Waiting — the agent is busy with $busyWith');
          },
        );
      }
    } finally {
      done.complete();
      if (identical(_lastRun[id], done.future)) _lastRun.remove(id);
      final remaining = _inFlight[id]! - 1;
      if (remaining == 0) {
        _inFlight.remove(id);
      } else {
        _inFlight[id] = remaining;
      }
    }
  }

  /// Notes [content] on [taskId]'s timeline — best effort.
  void _logEvent(int taskId, String content) {
    appendLog(
      TaskLogEntry(
        taskId: taskId,
        content: content,
        source: LogSource.system,
        kind: LogKind.event,
      ),
    ).catchError((Object e) => log('task $taskId: appendLog failed: $e'));
  }

  /// Removes a done task's worktree, or decides how [task] runs and hands
  /// it to a [_TaskRun]. Anything else (e.g. replayed on reconnect while
  /// already running) is left untouched.
  Future<void> _handle(Task task) async {
    if (task.status == TaskStatus.done) {
      // Accepted and merged — the worktree is no longer needed.
      await worktreeManager.removeWorktree(
        projectId: '${task.projectId}',
        taskId: '${task.id}',
      );
      log('task ${task.id}: done, worktree removed');
      return;
    }
    final agentId = task.agentId;
    final kind = await _runKindFor(task);
    if (kind == null) return;
    await _TaskRun(this, task, kind, agentId!).execute();
  }

  /// How [task] runs, or null (logged) when it shouldn't run now.
  Future<RunKind?> _runKindFor(Task task) async {
    final isResume = task.status == TaskStatus.awaitingReview;
    if (!isResume && task.status != TaskStatus.queued) {
      log('task ${task.id}: not queued (status=${task.status}), skipping');
      return null;
    }
    if (task.agentId == null) {
      log('task ${task.id}: missing agentId, skipping');
      return null;
    }
    if (!isResume) return RunKind.queued(task);

    if (task.claudeSessionId == null) {
      log('task ${task.id}: awaitingReview but no claudeSessionId, skipping');
      return null;
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
      return null;
    }
    return FeedbackResume(feedback.message);
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

/// Installs the project's toolchains before a run, reporting a download
/// on the task's timeline. A failure is logged there too, but doesn't
/// fail the task: the agent works on and reports what it couldn't verify.
Future<PreparedToolchain?> prepareToolchainForRun(
  ToolchainInstaller? installer,
  String label,
  int projectId,
  List<ProjectTool> tools,
  void Function(LogItem item) append,
  void Function(String message) log,
) async {
  if (installer == null || tools.isEmpty) return null;
  try {
    var installed = false;
    final prepared = await installer.prepare(
      projectId: projectId,
      tools: tools,
      onInstalling: (missing) {
        installed = true;
        log('$label: installing ${missing.join(', ')}');
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
    log('$label: toolchain install failed: $e');
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
