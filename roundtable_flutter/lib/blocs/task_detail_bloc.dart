import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../utils/error_message.dart';
import '../utils/closeable_streams.dart';
import '../repositories/agent_repository.dart';
import '../repositories/machine_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';

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

class TaskDeleteRequested extends TaskDetailEvent {
  const TaskDeleteRequested(this.taskId);

  final int taskId;
}

class TaskAccepted extends TaskDetailEvent {
  const TaskAccepted(this.taskId);

  final int taskId;
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

sealed class TaskDetailState {
  const TaskDetailState();
}

class TaskDetailInitial extends TaskDetailState {
  const TaskDetailInitial();
}

class TaskDetailLoading extends TaskDetailState {
  const TaskDetailLoading();
}

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
    this.logs = const [],
    this.logsSubscribed = false,
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

  /// Live-execution sub-state (`planning`/`running`): the task's log tail.
  final List<TaskLogEntry> logs;
  final bool logsSubscribed;

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
    List<TaskLogEntry>? logs,
    bool? logsSubscribed,
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
      logs: logs ?? this.logs,
      logsSubscribed: logsSubscribed ?? this.logsSubscribed,
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
    );
  }
}

/// Reacts to a task's live status (docs/FLOWS.md §4), its log tail while it's
/// executing, its diff once it's up for review, and to the dev's actions on
/// it (answering a question, approving/feedback on a plan, picking a file) —
/// a full Bloc rather than a Cubit, per the project's rule of thumb
/// (docs/DEVELOPMENT.md "Conventions"), since there's genuinely more than one event source here. Drives
/// `task_detail_screen.dart`'s 4 status-driven sub-states in one place,
/// folding in what used to be the separate `TaskDiffCubit`/`task_diff_screen`.
class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState>
    with CloseableStreams<TaskDetailState> {
  TaskDetailBloc(
    this._repository, {
    required ProjectRepository projectRepository,
    required AgentRepository agentRepository,
    required MachineRepository machineRepository,
  }) : _projectRepository = projectRepository,
       _agentRepository = agentRepository,
       _machineRepository = machineRepository,
       super(const TaskDetailInitial()) {
    on<TaskDetailSubscribed>(_onSubscribed);
    on<AnswerSubmitted>(_onAnswerSubmitted);
    on<PlanApproved>(_onPlanApproved);
    on<PlanFeedbackSubmitted>(_onPlanFeedbackSubmitted);
    on<ReviewFeedbackSubmitted>(_onReviewFeedbackSubmitted);
    on<TaskContinued>((event, emit) async {
      final current = state;
      if (current is! TaskDetailLoaded) return;
      emit(current.copyWith(submitting: true));
      try {
        await _repository.continueTask(event.taskId, event.message);
      } catch (e) {
        emit(TaskDetailError(errorMessage(e)));
      }
    });
    on<TaskResumed>((event, emit) async {
      final current = state;
      if (current is! TaskDetailLoaded) return;
      emit(current.copyWith(submitting: true));
      try {
        await _repository.resumeTask(event.taskId);
      } catch (e) {
        emit(TaskDetailError(errorMessage(e)));
      }
    });
    on<TaskCancelled>(_onTaskCancelled);
    on<TaskRetried>(_onTaskRetried);
    on<AgentReassigned>(_onAgentReassigned);
    on<TaskDeleteRequested>(_onTaskDeleteRequested);
    on<TaskAccepted>(_onTaskAccepted);
    on<ReviewRequested>(_onReviewRequested);
    on<CommentSelectionToggled>(_onCommentSelectionToggled);
    on<CommentsSelectionSet>((event, emit) {
      final current = state;
      if (current is! TaskDetailLoaded) return;
      emit(current.copyWith(selectedCommentIds: event.commentIds));
    });
    on<CommentStateChanged>(_onCommentStateChanged);
    on<CommentsSentToFix>(_onCommentsSentToFix);
    on<_ReviewsSubscribed>(_onReviewsSubscribed);
    on<_LogsSubscribed>(_onLogsSubscribed);
    on<_ChangedFilesRequested>(
      (event, emit) => _loadChangedFiles(event.taskId, emit),
    );
    on<ChangedFilesReloaded>(
      (event, emit) => _loadChangedFiles(event.taskId, emit),
    );
    on<ConflictsResolveRequested>(_onConflictsResolveRequested);
    on<FileSelected>(_onFileSelected);
    on<FullFileContentRequested>(_onFullFileContentRequested);
  }

  final TaskRepository _repository;
  final ProjectRepository _projectRepository;
  final AgentRepository _agentRepository;
  final MachineRepository _machineRepository;

  static const _reviewStatuses = {TaskStatus.awaitingReview, TaskStatus.done};

  Future<void> _onSubscribed(
    TaskDetailSubscribed event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(const TaskDetailLoading());
    try {
      await for (final task in untilClosed(
        _repository.watchTask(event.taskId),
      )) {
        final current = state;
        emit(await _stateFor(task, previous: current));

        // Logs are subscribed for every status so they stay reachable from
        // the Logs tab after the task leaves planning/running.
        if (current is! TaskDetailLoaded || !current.logsSubscribed) {
          add(_LogsSubscribed(event.taskId));
          add(_ReviewsSubscribed(event.taskId));
        }
        // Refetch each time the task (re-)enters review, e.g. after a
        // feedback iteration pushed new commits.
        // A task done without code changes has no PR to fetch files from.
        if (_reviewStatuses.contains(task.status) &&
            (task.prUrl != null || task.branchName != null) &&
            (current is! TaskDetailLoaded ||
                !current.filesRequested ||
                !_reviewStatuses.contains(current.task.status))) {
          add(_ChangedFilesRequested(event.taskId));
        }
      }
    } catch (e) {
      emit(TaskDetailError(errorMessage(e)));
    }
  }

  Future<TaskDetailState> _stateFor(
    Task task, {
    required TaskDetailState? previous,
  }) async {
    TaskQuestion? pendingQuestion;
    if (task.status == TaskStatus.waitingForAnswer) {
      pendingQuestion = await _repository.latestQuestion(task.id!);
    }
    if (previous is TaskDetailLoaded) {
      // Task.agentId is otherwise immutable, but reassignAgent changes it —
      // refetch agent/machine when that happens rather than caching stale
      // ones (or a stale null after an agent-less task gets one assigned).
      if (task.agentId != previous.task.agentId) {
        final agentId = task.agentId;
        final agent = agentId == null
            ? null
            : await _agentRepository.getAgent(agentId);
        final machine = agent == null
            ? null
            : await _machineRepository.getMachine(agent.machineId);
        return previous.copyWith(
          task: task,
          agent: agent,
          clearAgent: agent == null,
          machine: machine,
          clearMachine: machine == null,
          pendingQuestion: pendingQuestion,
          clearPendingQuestion: pendingQuestion == null,
          submitting: false,
        );
      }
      return previous.copyWith(
        task: task,
        pendingQuestion: pendingQuestion,
        clearPendingQuestion: pendingQuestion == null,
        submitting: false,
      );
    }

    // First load: the task's project never changes and, initially, neither
    // does its agent/machine — fetched once here; reassignAgent's branch
    // above is what keeps agent/machine fresh afterwards.
    final projectFuture = _projectRepository.getProject(task.projectId);
    final agentId = task.agentId;
    final agent = agentId == null
        ? null
        : await _agentRepository.getAgent(agentId);
    final machine = agent == null
        ? null
        : await _machineRepository.getMachine(agent.machineId);
    final project = await projectFuture;

    return TaskDetailLoaded(
      task: task,
      project: project,
      agent: agent,
      machine: machine,
      pendingQuestion: pendingQuestion,
    );
  }

  Future<void> _onAnswerSubmitted(
    AnswerSubmitted event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(submitting: true));
    try {
      await _repository.answerQuestion(event.questionId, event.answer);
    } catch (e) {
      emit(TaskDetailError(errorMessage(e)));
    }
  }

  Future<void> _onPlanApproved(
    PlanApproved event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(submitting: true));
    try {
      await _repository.approvePlan(event.taskId);
    } catch (e) {
      emit(TaskDetailError(errorMessage(e)));
    }
  }

  Future<void> _onPlanFeedbackSubmitted(
    PlanFeedbackSubmitted event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(submitting: true));
    try {
      await _repository.submitPlanFeedback(event.taskId, event.message);
    } catch (e) {
      emit(TaskDetailError(errorMessage(e)));
    }
  }

  Future<void> _onReviewFeedbackSubmitted(
    ReviewFeedbackSubmitted event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(submitting: true));
    try {
      await _repository.submitFeedback(event.taskId, event.message);
    } catch (e) {
      emit(TaskDetailError(errorMessage(e)));
    }
  }

  Future<void> _onTaskCancelled(
    TaskCancelled event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(submitting: true));
    try {
      await _repository.cancelTask(event.taskId);
    } catch (e) {
      emit(TaskDetailError(errorMessage(e)));
    }
  }

  Future<void> _onTaskRetried(
    TaskRetried event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(submitting: true));
    try {
      await _repository.retryTask(event.taskId);
    } catch (e) {
      emit(TaskDetailError(errorMessage(e)));
    }
  }

  Future<void> _onAgentReassigned(
    AgentReassigned event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(submitting: true));
    try {
      await _repository.reassignAgent(event.taskId, event.agentId);
    } catch (e) {
      emit(TaskDetailError(errorMessage(e)));
    }
  }

  Future<void> _onTaskDeleteRequested(
    TaskDeleteRequested event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(submitting: true));
    try {
      await _repository.deleteTask(event.taskId);
      emit(const TaskDetailDeleted());
    } catch (e) {
      emit(TaskDetailError(errorMessage(e)));
    }
  }

  Future<void> _onLogsSubscribed(
    _LogsSubscribed event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is TaskDetailLoaded) {
      emit(current.copyWith(logsSubscribed: true));
    }
    final logs = <TaskLogEntry>[];
    await for (final entry in untilClosed(
      _repository.watchLogs(event.taskId),
    )) {
      logs.add(entry);
      final latest = state;
      if (latest is TaskDetailLoaded) {
        emit(latest.copyWith(logs: List.of(logs)));
      }
    }
  }

  /// Fetches the PR's changed files and its merge status. A failure is kept
  /// in [TaskDetailLoaded.filesError] so the diff tab can offer a retry
  /// instead of spinning forever.
  Future<void> _loadChangedFiles(
    int taskId,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(filesRequested: true, clearFilesError: true));
    await Future.wait([
      _refreshMergeStatus(taskId, emit),
      () async {
        try {
          final files = await _repository.getChangedFiles(taskId);
          final latest = state;
          if (latest is TaskDetailLoaded) {
            emit(latest.copyWith(files: files));
          }
        } catch (e) {
          final latest = state;
          if (latest is TaskDetailLoaded) {
            emit(latest.copyWith(filesError: errorMessage(e)));
          }
        }
      }(),
    ]);
  }

  /// Best effort: on failure the "Accept & merge" button simply stays.
  Future<void> _refreshMergeStatus(
    int taskId,
    Emitter<TaskDetailState> emit,
  ) async {
    try {
      final status = await _repository.getMergeStatus(taskId);
      final latest = state;
      if (latest is TaskDetailLoaded) {
        emit(latest.copyWith(mergeStatus: status));
      }
    } catch (_) {}
  }

  void _onFileSelected(FileSelected event, Emitter<TaskDetailState> emit) {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(selectedFile: event.file, clearFileContent: true));
  }

  Future<void> _onFullFileContentRequested(
    FullFileContentRequested event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    final selectedFile = current is TaskDetailLoaded
        ? current.selectedFile
        : null;
    if (current is! TaskDetailLoaded || selectedFile == null) return;

    emit(current.copyWith(fileContentLoading: true));
    try {
      final content = await _repository.getFileContent(
        current.task.id!,
        selectedFile.contentsUrl,
      );
      final latest = state;
      if (latest is TaskDetailLoaded) {
        emit(latest.copyWith(fileContent: content, fileContentLoading: false));
      }
    } catch (e) {
      final latest = state;
      if (latest is TaskDetailLoaded) {
        emit(
          latest.copyWith(
            fileContentLoading: false,
            fileContentError: errorMessage(e),
          ),
        );
      }
    }
  }

  Future<void> _onReviewsSubscribed(
    _ReviewsSubscribed event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is TaskDetailLoaded) {
      if (current.reviewsSubscribed) return;
      emit(current.copyWith(reviewsSubscribed: true));
    }
    final reviews = <int, CodeReview>{};
    await for (final review in untilClosed(
      _repository.watchReviews(event.taskId),
    )) {
      reviews[review.id!] = review;
      final latest = state;
      if (latest is TaskDetailLoaded) {
        final sorted = reviews.values.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        // Only open comments can be sent; drop ticks that no longer apply.
        final openIds = {
          for (final r in sorted)
            for (final c in r.comments ?? const <ReviewComment>[])
              if (c.state == ReviewCommentState.open) c.id!,
        };
        emit(
          latest.copyWith(
            reviews: sorted,
            selectedCommentIds: latest.selectedCommentIds.intersection(
              openIds,
            ),
          ),
        );
      }
    }
  }

  /// Runs a review action, tracking [TaskDetailLoaded.reviewBusy] and
  /// surfacing a failure as [TaskDetailLoaded.reviewError].
  Future<void> _reviewAction(
    Emitter<TaskDetailState> emit,
    Future<void> Function() action, {
    TaskDetailLoaded Function(TaskDetailLoaded state)? onSuccess,
  }) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(reviewBusy: true, clearReviewError: true));
    String? error;
    try {
      await action();
    } catch (e) {
      error = errorMessage(e);
    }
    final latest = state;
    if (latest is TaskDetailLoaded) {
      final next = latest.copyWith(reviewBusy: false, reviewError: error);
      emit(error == null && onSuccess != null ? onSuccess(next) : next);
    }
  }

  Future<void> _onTaskAccepted(
    TaskAccepted event,
    Emitter<TaskDetailState> emit,
  ) async {
    await _reviewAction(emit, () => _repository.acceptTask(event.taskId));
    // A refused merge is most often a conflict — re-check so the button
    // switches to "Resolve conflicts".
    final latest = state;
    if (latest is TaskDetailLoaded && latest.reviewError != null) {
      await _refreshMergeStatus(event.taskId, emit);
    }
  }

  Future<void> _onConflictsResolveRequested(
    ConflictsResolveRequested event,
    Emitter<TaskDetailState> emit,
  ) => _reviewAction(emit, () => _repository.resolveConflicts(event.taskId));

  Future<void> _onReviewRequested(
    ReviewRequested event,
    Emitter<TaskDetailState> emit,
  ) => _reviewAction(
    emit,
    () => _repository.requestReview(event.taskId, event.agentId),
  );

  void _onCommentSelectionToggled(
    CommentSelectionToggled event,
    Emitter<TaskDetailState> emit,
  ) {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    final selected = Set.of(current.selectedCommentIds);
    if (!selected.remove(event.commentId)) selected.add(event.commentId);
    emit(current.copyWith(selectedCommentIds: selected));
  }

  Future<void> _onCommentStateChanged(
    CommentStateChanged event,
    Emitter<TaskDetailState> emit,
  ) => _reviewAction(
    emit,
    () => _repository.setCommentState(event.commentId, event.state),
  );

  Future<void> _onCommentsSentToFix(
    CommentsSentToFix event,
    Emitter<TaskDetailState> emit,
  ) {
    final current = state;
    if (current is! TaskDetailLoaded) return Future.value();
    final ids = current.selectedCommentIds.toList();
    return _reviewAction(
      emit,
      () => _repository.sendCommentsToFix(event.taskId, ids, event.note),
      onSuccess: (s) => s.copyWith(selectedCommentIds: const {}),
    );
  }
}
