part of 'task_detail_bloc.dart';

sealed class TaskDetailState {
  const TaskDetailState();
}

class TaskDetailInitial extends TaskDetailState {
  const TaskDetailInitial();
}

class TaskDetailLoading extends TaskDetailState {
  const TaskDetailLoading();
}

/// The task couldn't be loaded. A failed action keeps the task on screen
/// ([TaskDetailLoaded.actionError]) instead.
class TaskDetailError extends TaskDetailState {
  const TaskDetailError(this.message);

  final String message;
}

/// Terminal state reached once [TaskDeleteRequested] succeeds — the task no
/// longer exists, so there's nothing left for `_TaskDetailView` to render;
/// the screen listens for this to pop back to the dashboard.
class TaskDetailDeleted extends TaskDetailState {
  const TaskDetailDeleted();
}

class TaskDetailLoaded extends TaskDetailState {
  const TaskDetailLoaded({
    required this.task,
    this.project,
    this.agent,
    this.machine,
    this.pendingQuestion,
    this.submitting = false,
    this.actionError,
    this.logs = const [],
    this.logsSubscribed = false,
    this.feedback = const [],
    this.files,
    this.filesRequested = false,
    this.filesError,
    this.mergeStatus,
    this.selectedFile,
    this.fileContent,
    this.fileContentLoading = false,
    this.fileContentError,
    this.reviews = const [],
    this.reviewsSubscribed = false,
    this.selectedCommentIds = const {},
    this.reviewBusy = false,
    this.reviewError,
    this.checks,
    this.checksSubscribed = false,
    this.selectedCheckJobIds = const {},
    this.checksBusy = false,
    this.checksError,
  });

  final Task task;

  /// Fetched once alongside the task (`Task.projectId`/`agentId` are just
  /// foreign keys — `watchTask` doesn't include relations), for the info
  /// rail's PROJECT/AGENT/BRANCH sections.
  final Project? project;
  final Agent? agent;
  final Machine? machine;

  final TaskQuestion? pendingQuestion;
  final bool submitting;

  /// Why the last task action (answer, approve, retry…) failed. Shown as a
  /// snackbar; the screen stays on the task instead of an error page.
  final String? actionError;

  /// Live-execution sub-state (`planning`/`running`): the task's log tail.
  final List<TaskLogEntry> logs;
  final bool logsSubscribed;

  /// Feedback sent to the agent, oldest first: the timeline names each
  /// feedback run after the kind it started from.
  final List<TaskFeedback> feedback;

  /// Diff-review sub-state (`awaitingReview`/`done`): the PR's changed files.
  final List<DiffFile>? files;
  final bool filesRequested;

  /// Why loading [files] failed — shown with a retry instead of a spinner.
  final String? filesError;

  /// Whether the PR conflicts with its base branch; null until fetched.
  final PrMergeStatus? mergeStatus;
  final DiffFile? selectedFile;
  final String? fileContent;
  final bool fileContentLoading;
  final String? fileContentError;

  /// AI code reviews of the PR, oldest first, each with its comments.
  final List<CodeReview> reviews;
  final bool reviewsSubscribed;

  /// Open comments ticked for the next "send to agent".
  final Set<int> selectedCommentIds;

  /// A review action (request/triage/send/accept) is in flight. Kept apart
  /// from [submitting] since most of these don't change the task itself.
  final bool reviewBusy;

  /// Why the last review action failed (e.g. GitHub refused the merge) —
  /// shown inline instead of replacing the whole screen with an error.
  final String? reviewError;

  /// The PR's GitHub Actions checks; null until the first snapshot.
  final PrChecks? checks;
  final bool checksSubscribed;

  /// Failing jobs ticked for the next "send to agent".
  final Set<int> selectedCheckJobIds;

  /// A checks action (refresh/send) is in flight.
  final bool checksBusy;

  /// Why the last checks action failed, shown in the checks view.
  final String? checksError;

  /// Every comment across [reviews].
  List<ReviewComment> get reviewComments => [
    for (final review in reviews) ...?review.comments,
  ];

  TaskDetailLoaded copyWith({
    Task? task,
    Project? project,
    Agent? agent,
    bool clearAgent = false,
    Machine? machine,
    bool clearMachine = false,
    TaskQuestion? pendingQuestion,
    bool clearPendingQuestion = false,
    bool? submitting,
    String? actionError,
    bool clearActionError = false,
    List<TaskLogEntry>? logs,
    bool? logsSubscribed,
    List<TaskFeedback>? feedback,
    List<DiffFile>? files,
    bool? filesRequested,
    String? filesError,
    bool clearFilesError = false,
    PrMergeStatus? mergeStatus,
    DiffFile? selectedFile,
    String? fileContent,
    bool? fileContentLoading,
    String? fileContentError,
    bool clearFileContent = false,
    List<CodeReview>? reviews,
    bool? reviewsSubscribed,
    Set<int>? selectedCommentIds,
    bool? reviewBusy,
    String? reviewError,
    bool clearReviewError = false,
    PrChecks? checks,
    bool? checksSubscribed,
    Set<int>? selectedCheckJobIds,
    bool? checksBusy,
    String? checksError,
    bool clearChecksError = false,
  }) {
    return TaskDetailLoaded(
      task: task ?? this.task,
      project: project ?? this.project,
      agent: clearAgent ? null : (agent ?? this.agent),
      machine: clearMachine ? null : (machine ?? this.machine),
      pendingQuestion: clearPendingQuestion
          ? null
          : (pendingQuestion ?? this.pendingQuestion),
      submitting: submitting ?? this.submitting,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      logs: logs ?? this.logs,
      logsSubscribed: logsSubscribed ?? this.logsSubscribed,
      feedback: feedback ?? this.feedback,
      files: files ?? this.files,
      filesRequested: filesRequested ?? this.filesRequested,
      filesError: clearFilesError ? null : (filesError ?? this.filesError),
      mergeStatus: mergeStatus ?? this.mergeStatus,
      selectedFile: selectedFile ?? this.selectedFile,
      fileContent: clearFileContent ? null : (fileContent ?? this.fileContent),
      fileContentLoading: fileContentLoading ?? this.fileContentLoading,
      fileContentError: clearFileContent ? null : fileContentError,
      reviews: reviews ?? this.reviews,
      reviewsSubscribed: reviewsSubscribed ?? this.reviewsSubscribed,
      selectedCommentIds: selectedCommentIds ?? this.selectedCommentIds,
      reviewBusy: reviewBusy ?? this.reviewBusy,
      reviewError: clearReviewError ? null : (reviewError ?? this.reviewError),
      checks: checks ?? this.checks,
      checksSubscribed: checksSubscribed ?? this.checksSubscribed,
      selectedCheckJobIds: selectedCheckJobIds ?? this.selectedCheckJobIds,
      checksBusy: checksBusy ?? this.checksBusy,
      checksError: clearChecksError ? null : (checksError ?? this.checksError),
    );
  }
}
