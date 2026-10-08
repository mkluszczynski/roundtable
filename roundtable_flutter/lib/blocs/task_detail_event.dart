part of 'task_detail_bloc.dart';

sealed class TaskDetailEvent {
  const TaskDetailEvent();
}

class TaskDetailSubscribed extends TaskDetailEvent {
  const TaskDetailSubscribed(this.taskId);

  final int taskId;
}

class AnswerSubmitted extends TaskDetailEvent {
  const AnswerSubmitted(this.questionId, this.answer);

  final int questionId;
  final String answer;
}

class PlanApproved extends TaskDetailEvent {
  const PlanApproved(this.taskId);

  final int taskId;
}

class PlanFeedbackSubmitted extends TaskDetailEvent {
  const PlanFeedbackSubmitted(this.taskId, this.message);

  final int taskId;
  final String message;
}

class ReviewFeedbackSubmitted extends TaskDetailEvent {
  const ReviewFeedbackSubmitted(this.taskId, this.message);

  final int taskId;
  final String message;
}

/// Continues a task that finished without code changes, resuming the
/// agent's session with [message].
class TaskContinued extends TaskDetailEvent {
  const TaskContinued(this.taskId, this.message);

  final int taskId;
  final String message;
}

/// Resumes a task paused by a usage limit right away.
class TaskResumed extends TaskDetailEvent {
  const TaskResumed(this.taskId);

  final int taskId;
}

class TaskCancelled extends TaskDetailEvent {
  const TaskCancelled(this.taskId);

  final int taskId;
}

class TaskRetried extends TaskDetailEvent {
  const TaskRetried(this.taskId);

  final int taskId;
}

class AgentReassigned extends TaskDetailEvent {
  const AgentReassigned(this.taskId, this.agentId);

  final int taskId;
  final int agentId;
}

class TaskRenamed extends TaskDetailEvent {
  const TaskRenamed(this.taskId, this.title);

  final int taskId;
  final String title;
}

class TaskDeleteRequested extends TaskDetailEvent {
  const TaskDeleteRequested(this.taskId);

  final int taskId;
}

class TaskAccepted extends TaskDetailEvent {
  const TaskAccepted(this.taskId, {this.force = false});

  final int taskId;

  /// Merge even though the CI checks are pending or failing.
  final bool force;
}

class ConflictsResolveRequested extends TaskDetailEvent {
  const ConflictsResolveRequested(this.taskId);

  final int taskId;
}

/// Refetches the PR's changed files and merge status, e.g. after a failed
/// load.
class ChangedFilesReloaded extends TaskDetailEvent {
  const ChangedFilesReloaded(this.taskId);

  final int taskId;
}

class ReviewRequested extends TaskDetailEvent {
  const ReviewRequested(this.taskId, this.agentId);

  final int taskId;
  final int agentId;
}

/// Ticks/unticks a review comment for the next "send to agent".
class CommentSelectionToggled extends TaskDetailEvent {
  const CommentSelectionToggled(this.commentId);

  final int commentId;
}

/// Replaces the selection, e.g. "Select all open" or "Clear".
class CommentsSelectionSet extends TaskDetailEvent {
  const CommentsSelectionSet(this.commentIds);

  final Set<int> commentIds;
}

class CommentStateChanged extends TaskDetailEvent {
  const CommentStateChanged(this.commentId, this.state);

  final int commentId;
  final ReviewCommentState state;
}

/// Sends the selected comments (and [note]) to the task's agent.
class CommentsSentToFix extends TaskDetailEvent {
  const CommentsSentToFix(this.taskId, this.note);

  final int taskId;
  final String note;
}

/// Reads the PR's CI checks from GitHub now.
class ChecksRefreshRequested extends TaskDetailEvent {
  const ChecksRefreshRequested(this.taskId);

  final int taskId;
}

/// Ticks/unticks a failing CI job for the next "send to agent".
class CheckJobSelectionToggled extends TaskDetailEvent {
  const CheckJobSelectionToggled(this.jobId);

  final int jobId;
}

/// Unticks every failing CI job, so the next send covers all of them.
class CheckJobsSelectionCleared extends TaskDetailEvent {
  const CheckJobsSelectionCleared();
}

/// Sends the selected failing CI jobs (all of them when none is selected)
/// and [note] to the task's agent.
class FailingChecksSentToFix extends TaskDetailEvent {
  const FailingChecksSentToFix(this.taskId, this.note);

  final int taskId;
  final String note;
}

/// Internal: starts the CI checks stream for [taskId]. Added once.
class _ChecksSubscribed extends TaskDetailEvent {
  const _ChecksSubscribed(this.taskId);

  final int taskId;
}

/// Internal: starts the code-review stream for [taskId]. Added once.
class _ReviewsSubscribed extends TaskDetailEvent {
  const _ReviewsSubscribed(this.taskId);

  final int taskId;
}

/// Internal: starts the log tail (history, then live) for [taskId]. Added
/// once, on the first task event.
class _LogsSubscribed extends TaskDetailEvent {
  const _LogsSubscribed(this.taskId);

  final int taskId;
}

/// Internal: fetches the PR's changed files for [taskId]. Added once, the
/// first time the task reaches `awaitingReview`/`done`.
class _ChangedFilesRequested extends TaskDetailEvent {
  const _ChangedFilesRequested(this.taskId);

  final int taskId;
}

class FileSelected extends TaskDetailEvent {
  const FileSelected(this.file);

  final DiffFile file;
}

class FullFileContentRequested extends TaskDetailEvent {
  const FullFileContentRequested();
}
