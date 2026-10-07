import 'package:roundtable_client/roundtable_client.dart';

import 'log_entry_kind.dart';
import 'log_timeline.dart';
import 'task_status_label.dart';

/// Where a [TimelineStep] leads in the task screen.
enum TimelineLink { log, review }

/// How a [TimelineStep] went.
enum TimelineStepState { running, done, failed, warning, neutral }

/// One step of a task's life in the detail screen's timeline: created,
/// planning, implementing, a review, a fix run, merged…
class TimelineStep {
  const TimelineStep({
    required this.label,
    required this.at,
    required this.state,
    this.detail,
    this.endedAt,
    this.link,
  });

  final TimelineLink? link;

  final String label;
  final String? detail;
  final DateTime at;

  /// Null for a point in time, or while the step is still going.
  final DateTime? endedAt;
  final TimelineStepState state;
}

/// Builds [task]'s timeline from its log runs, code reviews and the
/// feedback that started each fix run, oldest first.
List<TimelineStep> buildTaskTimeline({
  required Task task,
  required List<TaskLogEntry> logs,
  required List<CodeReview> reviews,
  required List<TaskFeedback> feedback,
}) {
  final steps = <TimelineStep>[
    TimelineStep(
      label: 'Created',
      at: task.createdAt,
      state: TimelineStepState.neutral,
    ),
  ];
  final active = !const {
    TaskStatus.done,
    TaskStatus.failed,
    TaskStatus.cancelled,
    TaskStatus.draft,
  }.contains(task.status);
  final runs = buildLogTimeline(logs).where((r) => !r.isReview).toList();
  for (final (i, run) in runs.indexed) {
    final start = run.startedAt;
    if (start == null) continue;
    final finished = run.finished;
    final last = i == runs.length - 1;
    final state = finished == null
        ? (last && active
              ? TimelineStepState.running
              : TimelineStepState.neutral)
        : finished.failed
        ? TimelineStepState.failed
        : TimelineStepState.done;
    final resumed = (run.title ?? '').contains('usage limit');
    final resumedNote = resumed ? 'Resumed after the usage limit' : null;
    switch (run.phase) {
      case LogPhase.planning:
        steps.addAll(_planningSteps(run, start, state, resumedNote));
      case LogPhase.feedback:
        steps.add(
          TimelineStep(
            label: _feedbackLabel(_feedbackBefore(feedback, start)),
            detail: resumedNote,
            at: start,
            endedAt: finished?.createdAt,
            state: state,
            link: TimelineLink.log,
          ),
        );
      case LogPhase.execution:
      case LogPhase.review:
      case null:
        steps.add(
          TimelineStep(
            label: run.phase == null ? 'Run' : 'Implementing',
            detail: resumedNote,
            at: start,
            endedAt: finished?.createdAt,
            state: state,
            link: TimelineLink.log,
          ),
        );
    }
  }

  for (final (i, review) in reviews.indexed) {
    steps.add(_reviewStep(review, i + 1));
  }

  final pausedUntil = task.pausedUntil;
  if (task.status == TaskStatus.paused && pausedUntil != null) {
    steps.add(
      TimelineStep(
        label: 'Paused by the usage limit',
        detail: 'Resumes at ${resumeTimeLabel(pausedUntil)}',
        at: task.lastProgressAt,
        state: TimelineStepState.warning,
      ),
    );
  }
  final end = task.finishedAt ?? task.lastProgressAt;
  switch (task.status) {
    case TaskStatus.done:
      steps.add(
        TimelineStep(
          label: task.prUrl != null ? 'Merged' : 'Done',
          at: end,
          state: TimelineStepState.done,
        ),
      );
    case TaskStatus.failed:
      steps.add(
        TimelineStep(
          label: 'Failed',
          detail: task.failureReason,
          at: end,
          state: TimelineStepState.failed,
        ),
      );
    case TaskStatus.cancelled:
      steps.add(
        TimelineStep(
          label: 'Cancelled',
          at: end,
          state: TimelineStepState.neutral,
        ),
      );
    default:
      break;
  }
  // Stable: a point step stays after the run it closes when times tie.
  final indexed = steps.indexed.toList()
    ..sort((a, b) {
      final byTime = a.$2.at.compareTo(b.$2.at);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  return [for (final (_, step) in indexed) step];
}

/// A planning run plans, then — once the dev approves — implements in the
/// same session: two steps split at the approval.
List<TimelineStep> _planningSteps(
  LogRun run,
  DateTime start,
  TimelineStepState state,
  String? resumedNote,
) {
  final plans = run.blocks
      .whereType<DecisionBlock>()
      .where((b) => b.isPlan)
      .toList();
  TaskLogEntry? approval;
  var revisions = 0;
  for (final plan in plans) {
    final result = plan.step.result;
    if (result == null) continue;
    final text = result.detail ?? result.text;
    if (!result.failed && text.contains('approved')) {
      approval = result;
      break;
    }
    revisions++;
  }
  final revised = revisions == 0
      ? null
      : '$revisions ${revisions == 1 ? 'revision' : 'revisions'}';
  if (approval == null) {
    final waiting = plans.isNotEmpty && plans.last.step.result == null;
    return [
      TimelineStep(
        label: 'Planning',
        detail: [
          ?resumedNote,
          if (waiting) 'Plan waiting for your approval',
          ?revised,
        ].join(' · ').nullIfEmpty,
        at: start,
        endedAt: run.finished?.createdAt,
        link: TimelineLink.log,
        state: waiting && state == TimelineStepState.running
            ? TimelineStepState.warning
            : state,
      ),
    ];
  }
  return [
    TimelineStep(
      label: 'Planning',
      detail: ['Plan approved', ?revised].join(' · '),
      at: start,
      endedAt: approval.createdAt,
      state: TimelineStepState.done,
      link: TimelineLink.log,
    ),
    TimelineStep(
      label: 'Implementing',
      detail: resumedNote,
      at: approval.createdAt,
      endedAt: run.finished?.createdAt,
      link: TimelineLink.log,
      state: state,
    ),
  ];
}

TaskFeedback? _feedbackBefore(List<TaskFeedback> feedback, DateTime start) {
  TaskFeedback? latest;
  for (final f in feedback) {
    if (f.phase != TaskFeedbackPhase.review) continue;
    if (f.createdAt.isAfter(start)) break;
    latest = f;
  }
  return latest;
}

String _feedbackLabel(TaskFeedback? feedback) => switch (feedback?.kind) {
  TaskFeedbackKind.reviewComments => 'Fixing review comments',
  TaskFeedbackKind.checks => 'Fixing CI',
  TaskFeedbackKind.conflicts => 'Resolving conflicts',
  TaskFeedbackKind.dev || null => 'Applying your feedback',
};

TimelineStep _reviewStep(CodeReview review, int number) {
  final paused = review.status == CodeReviewStatus.queued
      ? review.pausedUntil
      : null;
  final (detail, state) = switch (review.status) {
    CodeReviewStatus.queued when paused != null => (
      'Paused · resumes at ${resumeTimeLabel(paused)}',
      TimelineStepState.warning,
    ),
    CodeReviewStatus.queued => ('Queued', TimelineStepState.neutral),
    CodeReviewStatus.running => ('Reviewing', TimelineStepState.running),
    CodeReviewStatus.failed => (
      review.failureReason ?? 'Failed',
      TimelineStepState.failed,
    ),
    CodeReviewStatus.completed => switch (review.verdict) {
      CodeReviewVerdict.changesRequested => (
        'Changes requested',
        TimelineStepState.warning,
      ),
      CodeReviewVerdict.approve => ('Approved', TimelineStepState.done),
      null => ('Completed', TimelineStepState.done),
    },
  };
  return TimelineStep(
    label: 'AI review #$number',
    detail: detail,
    at: review.createdAt,
    endedAt: review.finishedAt,
    state: state,
    link: TimelineLink.review,
  );
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
