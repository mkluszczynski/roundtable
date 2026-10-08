part of 'task_dispatcher.dart';

/// How a task's run starts — decided once from the task, instead of from a
/// handful of flags.
sealed class RunKind {
  const RunKind();

  /// A `queued` task: requeued after a usage-limit pause (continuing the
  /// interrupted session in its phase), or a fresh run.
  factory RunKind.queued(Task task) => switch (task.pausedPhase) {
    final phase? => PauseResume(phase),
    null => FreshRun(planning: !task.skipPlanning),
  };

  /// Whether `claude` runs in plan mode, asking before it changes anything.
  bool get needsPlanning;

  /// The phase the run's log entries are filed under.
  LogPhase get phase;

  String get label;
}

/// A new run, planning first unless the task skips it.
final class FreshRun extends RunKind {
  const FreshRun({required this.planning});

  final bool planning;

  @override
  bool get needsPlanning => planning;

  @override
  LogPhase get phase => planning ? LogPhase.planning : LogPhase.execution;

  @override
  String get label => planning ? 'planning' : 'execution';
}

/// A run interrupted by the usage limit, continued in [phase].
final class PauseResume extends RunKind {
  const PauseResume(this.phase);

  @override
  final LogPhase phase;

  @override
  bool get needsPlanning => phase == LogPhase.planning;

  @override
  String get label => needsPlanning ? 'planning' : 'execution';
}

/// An `awaitingReview` task resumed (`--resume`) with the dev's review
/// feedback [message] as the prompt.
final class FeedbackResume extends RunKind {
  const FeedbackResume(this.message);

  final String message;

  @override
  bool get needsPlanning => false;

  @override
  LogPhase get phase => LogPhase.feedback;

  @override
  String get label => 'resume';
}

/// What a finished run reports: the task's status and, unless it failed,
/// the event noted on its timeline.
({TaskStatus status, String? event}) runOutcome({
  required String? failureReason,
  required bool finishedWithoutCode,
  String? branchName,
  String? prUrl,
}) {
  if (failureReason != null) return (status: TaskStatus.failed, event: null);
  if (finishedWithoutCode) {
    return (
      status: TaskStatus.done,
      event: 'Finished without code changes — no pull request',
    );
  }
  return (
    status: TaskStatus.awaitingReview,
    event: prUrl != null
        ? 'Committed and pushed $branchName, opened pull request $prUrl'
        : branchName != null
        ? 'Pushed new commits to $branchName'
        : 'No new changes — the pull request is unchanged',
  );
}

/// The agent's status while its planning run waits on the dev, or null
/// when the task's status doesn't change it.
AgentStatus? planningAgentStatus(TaskStatus taskStatus) => switch (taskStatus) {
  TaskStatus.waitingForAnswer ||
  TaskStatus.planReady => AgentStatus.waitingForResponse,
  TaskStatus.planning => AgentStatus.busy,
  _ => null,
};
