part of 'task_detail_bloc.dart';

/// What the task detail screen decides from a [TaskDetailLoaded]: which
/// sections exist, which one opens, which lifecycle actions are offered.
/// Kept out of the widgets so the rules are testable on their own.

/// Mirrors the server's `cancelTask` guard (`nonTerminalTaskStatuses` minus
/// `draft`, docs/ARCHITECTURE.md): "Cancel task" moves the task back to the
/// backlog as an agent-less draft.
const _cancellableStatuses = {
  TaskStatus.queued,
  TaskStatus.cloning,
  TaskStatus.planning,
  TaskStatus.waitingForAnswer,
  TaskStatus.planReady,
  TaskStatus.running,
  TaskStatus.awaitingReview,
  TaskStatus.paused,
};

/// Mirrors the server's `retryTask` guard: a failed/cancelled run can be
/// re-queued without recreating the task.
const _retryableStatuses = {TaskStatus.failed, TaskStatus.cancelled};

/// Mirrors the server's `deleteTask` guard: only a terminal task can be
/// deleted; a running one has to be cancelled first.
const _deletableStatuses = {
  TaskStatus.draft,
  TaskStatus.done,
  TaskStatus.failed,
  TaskStatus.cancelled,
};

/// Mirrors the server's `reassignAgent` guard: in the backlog or parked in
/// review, not while executing under its current agent.
const _reassignableStatuses = {
  TaskStatus.draft,
  TaskStatus.queued,
  TaskStatus.cloning,
  TaskStatus.awaitingReview,
};

enum TaskSection { overview, plan, changes, review, checks, logs }

/// A lifecycle action pinned under the info rail, in display order.
enum TaskAction {
  resolveConflicts,
  fixChecks,
  accept,

  /// Merge although the CI checks block it (a flaky or non-required job).
  mergeAnyway,
  retry,
  cancel,
  followUp,
  delete,
}

extension TaskRules on Task {
  /// The agent is working: its log is the main view.
  bool get isLive =>
      status == TaskStatus.planning || status == TaskStatus.running;

  bool get canReassign => _reassignableStatuses.contains(status);

  /// In review or done with a PR — not one that finished without changing
  /// code (its result is in Overview instead).
  bool get hasPullRequestViews =>
      (status == TaskStatus.awaitingReview || status == TaskStatus.done) &&
      (prUrl != null || branchName != null);

  /// The section a task opens on: the log while the agent works and while
  /// its PR awaits review (so the dev reads the agent's closing message
  /// before the diff), the diff of a done task's PR, otherwise whatever
  /// needs the dev's attention.
  TaskSection get defaultSection {
    if (isLive) return TaskSection.logs;
    if (hasPullRequestViews) {
      return status == TaskStatus.awaitingReview
          ? TaskSection.logs
          : TaskSection.changes;
    }
    return TaskSection.overview;
  }
}

extension TaskDetailRules on TaskDetailLoaded {
  bool get inReview => task.status == TaskStatus.awaitingReview;

  CodeReview? get latestReview => reviews.isEmpty ? null : reviews.last;

  bool get reviewActive => reviews.any(
    (r) =>
        r.status == CodeReviewStatus.queued ||
        r.status == CodeReviewStatus.running,
  );

  int get openCommentCount =>
      reviewComments.where((c) => c.state == ReviewCommentState.open).length;

  int get sentToFixCommentCount => reviewComments
      .where((c) => c.state == ReviewCommentState.sentToFix)
      .length;

  bool get hasConflicts => mergeStatus?.hasConflicts ?? false;

  int get failedCheckCount =>
      checks?.runs.where(isFailedCheckRun).length ??
      (task.checkState == PrCheckState.failure ? 1 : 0);

  /// Why "Accept & merge" is disabled, or null when the CI checks allow it.
  /// The server enforces the same rule in `acceptTask`.
  String? get mergeBlockedByChecks => switch (task.checkState) {
    PrCheckState.success || PrCheckState.none => null,
    PrCheckState.pending => 'Waiting for the CI checks to finish',
    PrCheckState.failure =>
      'CI checks are failing — send them to the agent or fix them first',
  };

  /// Overview only exists while the status has its own content (question,
  /// plan, failure…) — live tasks have the log, PR tasks have Changes/Review.
  /// Plan stays reachable as a read-only tab once there is one, except right
  /// on `planReady`, where Overview already shows it with approve/feedback.
  /// AI review stays reachable once the task has a PR or a review, so the
  /// dev can read the comments an (auto) fix run is working on.
  Set<TaskSection> get availableSections => {
    if (!task.isLive && !task.hasPullRequestViews) TaskSection.overview,
    if (task.currentPlan != null && task.status != TaskStatus.planReady)
      TaskSection.plan,
    if (task.hasPullRequestViews) TaskSection.changes,
    if (task.hasPullRequestViews || task.prUrl != null || reviews.isNotEmpty)
      TaskSection.review,
    // Also while a fix run is going, so the dev sees what it's fixing.
    if (task.prUrl != null) TaskSection.checks,
    TaskSection.logs,
  };

  /// The lifecycle actions offered for the task: the status's primary
  /// action first, destructive ones last. Whether each is enabled right now
  /// (something in flight) is up to the widget.
  List<TaskAction> get availableActions => [
    if (inReview)
      if (hasConflicts)
        TaskAction.resolveConflicts
      else ...[
        if (task.checkState == PrCheckState.failure) TaskAction.fixChecks,
        TaskAction.accept,
        if (mergeBlockedByChecks != null) TaskAction.mergeAnyway,
      ],
    if (_retryableStatuses.contains(task.status)) TaskAction.retry,
    if (_cancellableStatuses.contains(task.status)) TaskAction.cancel,
    if (task.status == TaskStatus.done) TaskAction.followUp,
    if (_deletableStatuses.contains(task.status)) TaskAction.delete,
  ];
}
