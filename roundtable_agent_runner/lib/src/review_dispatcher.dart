import 'dart:io';

import 'package:roundtable_client/roundtable_client.dart';

import 'agent_work_queue.dart';
import 'claude_code_executor.dart';
import 'container_sandbox.dart';
import 'role_prompts.dart';
import 'server_retry.dart';
import 'log_entries.dart';
import 'stream_json_formatter.dart';
import 'task_images.dart';
import 'review_prompt.dart';
import 'run_environment.dart';
import 'toolchain_installer.dart';
import 'task_dispatcher.dart';
import 'usage_limit.dart';
import 'worktree_manager.dart';

export 'review_prompt.dart';

part 'review_run.dart';

/// Runs an assigned [CodeReview]: checks the task's branch out read-only,
/// asks Claude Code to review the diff, and uploads its findings.
///
/// Server-facing dependencies are plain functions, like [TaskDispatcher].
class ReviewDispatcher {
  ReviewDispatcher({
    required this.worktreeManager,
    required this.executorFactory,
    required this.oauthToken,
    required this.getCloneUrl,
    required this.fetchAgent,
    required this.startReview,
    required this.completeReview,
    required this.failReview,
    required this.appendLog,
    required this.log,
    this.environmentPrompt,
    this.fetchAttachments = _noAttachments,
    this.fetchPreviousComments = _noPreviousComments,
    this.fetchProject,
    this.sandboxFor,
    this.toolchainInstaller,
    AgentWorkQueue? workQueue,
    UsageLimitGate? usageLimit,
    this.retryDelays = defaultRetryDelays,
    this.requeueReview,
    this.pauseQueuedReview,
  }) : workQueue = workQueue ?? AgentWorkQueue(),
       usageLimit = usageLimit ?? UsageLimitGate();

  /// The machine's Claude usage limit, shared with `TaskDispatcher`: a
  /// review waits (still `queued`) while it's active.
  final UsageLimitGate usageLimit;

  /// Waits between retries of a run's final status reports
  /// ([retrying]); shortened in tests.
  final List<Duration> retryDelays;

  /// Bound to `client.codeReview.requeueReview`: puts a review cut short
  /// by the usage limit back to `queued`, paused [until] the reset (the
  /// panel shows [reason]), to run again then. Without it, such a review
  /// fails.
  final Future<void> Function(int reviewId, DateTime until, String reason)?
  requeueReview;

  /// Bound to `client.codeReview.pauseQueuedReview`: shows that a queued
  /// review waits for the usage limit to reset at [until] before starting.
  final Future<void> Function(int reviewId, DateTime until)? pauseQueuedReview;

  /// One piece of work at a time per agent, shared with `TaskDispatcher`: a
  /// review by a busy agent stays `queued` here until it's free.
  final AgentWorkQueue workQueue;

  static Future<List<TaskImage>> _noAttachments(int taskId) async => const [];
  static Future<List<ReviewComment>> _noPreviousComments(int reviewId) async =>
      const [];

  /// The comments of earlier reviews of the same task, for the reviewer to
  /// check — bound to `client.codeReview.previousComments` in production.
  final Future<List<ReviewComment>> Function(int reviewId)
  fetchPreviousComments;

  /// The images attached to the task's prompt — part of the requirements the
  /// reviewer checks the change against. Bound to `client.taskAttachment` in
  /// production.
  final Future<List<TaskImage>> Function(int taskId) fetchAttachments;

  /// Describes this machine to the reviewer (`--append-system-prompt`) —
  /// see `buildEnvironmentPrompt`. Null when not yet known.
  final String? Function({bool container})? environmentPrompt;

  /// The project under review — its `dockerImage` for a docker-mode
  /// reviewer.
  final Future<Project?> Function(int projectId)? fetchProject;

  /// Builds the container a docker-mode reviewer runs in, like
  /// `TaskDispatcher.sandboxFor`: only the review worktree, the project's
  /// git data and the attached images are visible, never the machine's
  /// other files. Null when the machine has no container runtime.
  final ContainerSandbox Function(ContainerRequest request)? sandboxFor;

  /// Installs the project's toolchains for a docker-mode reviewer, which
  /// can then run the project's checks (docs/FLOWS.md §5).
  final ToolchainInstaller? toolchainInstaller;

  late final _environments = RunEnvironments(
    executorFactory: executorFactory,
    sandboxFor: sandboxFor,
    toolchainInstaller: toolchainInstaller,
    fetchProject: fetchProject,
    environmentPrompt: environmentPrompt,
    log: log,
  );

  final WorktreeManager worktreeManager;
  final ClaudeCodeExecutor Function() executorFactory;

  /// The current Claude Code OAuth token: it can change from the panel
  /// while the daemon runs (docs/FLOWS.md §1). Null: `claude login`.
  final String? Function()? oauthToken;
  final Future<String> Function(int projectId) getCloneUrl;
  final Future<Agent> Function(int agentId) fetchAgent;

  /// Bound to `client.codeReview.startReview`; returns the task under review.
  final Future<Task> Function(int reviewId) startReview;
  final Future<void> Function(int reviewId, ReviewFindings findings)
  completeReview;
  final Future<void> Function(int reviewId, String reason) failReview;

  /// Persists one structured log entry. Bound to
  /// `client.task.appendLogEntry` in production.
  final Future<void> Function(TaskLogEntry entry) appendLog;
  final void Function(String message) log;

  Future<void> handle(CodeReview review) async {
    final reviewId = review.id!;
    final agentId = review.reviewerAgentId;
    if (review.status != CodeReviewStatus.queued || agentId == null) {
      log('review $reviewId: not queued (status=${review.status}), skipping');
      return;
    }
    await usageLimit.wait(
      onWaiting: (until) {
        log('review $reviewId: usage limit, waiting until $until');
        pauseQueuedReview
            ?.call(reviewId, until)
            .catchError(
              (Object e) =>
                  log('review $reviewId: pauseQueuedReview failed: $e'),
            );
        _logEvent(
          review.taskId,
          reviewId,
          'Review waiting for the Claude usage limit to reset at '
          '${localClock(until)}',
        );
      },
    );
    final requeued = await workQueue.run(
      agentId,
      'the review of task #${review.taskId}',
      () => _handle(review, reviewId, agentId),
      onWaiting: (busyWith) {
        log('review $reviewId: reviewer $agentId is busy with $busyWith');
        _logEvent(
          review.taskId,
          reviewId,
          'Review waiting — the reviewer is busy with $busyWith',
        );
      },
    );
    // Cut short by the usage limit: run it again once the limit resets.
    if (requeued) {
      await handle(review.copyWith(status: CodeReviewStatus.queued));
    }
  }

  void _logEvent(int taskId, int reviewId, String content) {
    appendLog(
      TaskLogEntry(
        taskId: taskId,
        content: content,
        source: LogSource.system,
        kind: LogKind.event,
      ),
    ).catchError((Object e) => log('review $reviewId: appendLog failed: $e'));
  }

  /// Reports the review failed with [reason], retrying while the server is
  /// unreachable — otherwise it would stay `running` with nothing to pick
  /// it up again.
  Future<void> _fail(int reviewId, String reason) => retrying(
    'review $reviewId: reporting the failure',
    () => failReview(reviewId, reason),
    log: log,
    delays: retryDelays,
  );

  /// Starts the review on the server and runs it; returns true when the
  /// usage limit cut it short and it went back to `queued`.
  Future<bool> _handle(CodeReview review, int reviewId, int agentId) async {
    final Task task;
    try {
      task = await startReview(reviewId);
    } catch (e) {
      // Another subscription (e.g. a replay after reconnect) won the race.
      log('review $reviewId: could not start: $e');
      return false;
    }
    return _ReviewRun(this, reviewId, task, agentId).execute();
  }
}
