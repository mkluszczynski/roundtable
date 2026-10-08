import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../utils/error_message.dart';
import '../utils/closeable_streams.dart';
import '../repositories/agent_repository.dart';
import '../repositories/machine_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import '../utils/pr_checks.dart';

part 'task_detail_event.dart';
part 'task_detail_state.dart';

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
    required this._projectRepository,
    required this._agentRepository,
    required this._machineRepository,
  }) : super(const TaskDetailInitial()) {
    on<TaskDetailSubscribed>(_onSubscribed);
    on<AnswerSubmitted>(
      (e, emit) => _submit(
        emit,
        () => _repository.answerQuestion(e.questionId, e.answer),
      ),
    );
    on<PlanApproved>(
      (e, emit) => _submit(emit, () => _repository.approvePlan(e.taskId)),
    );
    on<PlanFeedbackSubmitted>(
      (e, emit) => _submit(
        emit,
        () => _repository.submitPlanFeedback(e.taskId, e.message),
      ),
    );
    on<ReviewFeedbackSubmitted>(
      (e, emit) =>
          _submit(emit, () => _repository.submitFeedback(e.taskId, e.message)),
    );
    on<TaskContinued>(
      (e, emit) =>
          _submit(emit, () => _repository.continueTask(e.taskId, e.message)),
    );
    on<TaskResumed>(
      (e, emit) => _submit(emit, () => _repository.resumeTask(e.taskId)),
    );
    on<TaskCancelled>(
      (e, emit) => _submit(emit, () => _repository.cancelTask(e.taskId)),
    );
    on<TaskRetried>(
      (e, emit) => _submit(emit, () => _repository.retryTask(e.taskId)),
    );
    on<AgentReassigned>(
      (e, emit) => _submit(
        emit,
        () => _repository.reassignAgent(e.taskId, e.agentId),
      ),
    );
    // The new title arrives through `watchTask`, like every other change.
    on<TaskRenamed>(
      (e, emit) => _submit(
        emit,
        () => _repository.setTitle(e.taskId, e.title),
        showProgress: false,
      ),
    );
    on<TaskDeleteRequested>(
      (e, emit) => _submit(
        emit,
        () => _repository.deleteTask(e.taskId),
        onSuccess: () => emit(const TaskDetailDeleted()),
      ),
    );
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
    on<_ChecksSubscribed>(_onChecksSubscribed);
    on<ChecksRefreshRequested>(
      (event, emit) => _checksAction(
        emit,
        () => _repository.refreshChecks(event.taskId),
      ),
    );
    on<CheckJobSelectionToggled>((event, emit) {
      final current = state;
      if (current is! TaskDetailLoaded) return;
      final selected = Set.of(current.selectedCheckJobIds);
      if (!selected.remove(event.jobId)) selected.add(event.jobId);
      emit(current.copyWith(selectedCheckJobIds: selected));
    });
    on<CheckJobsSelectionCleared>((event, emit) {
      final current = state;
      if (current is! TaskDetailLoaded) return;
      emit(current.copyWith(selectedCheckJobIds: const {}));
    });
    on<FailingChecksSentToFix>(_onFailingChecksSentToFix);
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
        if (task.prUrl != null &&
            (current is! TaskDetailLoaded || !current.checksSubscribed)) {
          add(_ChecksSubscribed(event.taskId));
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

  /// Runs a task action. [TaskDetailLoaded.submitting] stays on until
  /// `watchTask` delivers the resulting task; a failure turns it off and is
  /// kept in [TaskDetailLoaded.actionError].
  Future<void> _submit(
    Emitter<TaskDetailState> emit,
    Future<void> Function() action, {
    bool showProgress = true,
    void Function()? onSuccess,
  }) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(
      current.copyWith(
        submitting: showProgress ? true : null,
        clearActionError: true,
      ),
    );
    try {
      await action();
    } catch (e) {
      final latest = state;
      if (latest is TaskDetailLoaded) {
        emit(
          latest.copyWith(
            submitting: showProgress ? false : null,
            actionError: errorMessage(e),
          ),
        );
      }
      return;
    }
    onSuccess?.call();
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
    var feedbackRuns = 0;
    var feedbackFetched = -1;
    await for (final entry in untilClosed(
      _repository.watchLogs(event.taskId),
    )) {
      logs.add(entry);
      final latest = state;
      if (latest is TaskDetailLoaded) {
        emit(latest.copyWith(logs: List.of(logs)));
      }
      if (entry.kind == LogKind.runStarted &&
          entry.phase == LogPhase.feedback) {
        feedbackRuns++;
      }
      // A feedback run whose feedback we haven't seen yet: refetch them.
      if (feedbackRuns > feedbackFetched) {
        feedbackFetched = feedbackRuns;
        try {
          final feedback = await _repository.listFeedback(event.taskId);
          final current = state;
          if (current is TaskDetailLoaded) {
            emit(current.copyWith(feedback: feedback));
          }
        } catch (_) {
          // Best effort: the timeline falls back to "Feedback".
        }
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

  Future<void> _onChecksSubscribed(
    _ChecksSubscribed event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is TaskDetailLoaded) {
      if (current.checksSubscribed) return;
      emit(current.copyWith(checksSubscribed: true));
    }
    await for (final checks in untilClosed(
      _repository.watchChecks(event.taskId),
    )) {
      final latest = state;
      if (latest is TaskDetailLoaded) {
        // Only currently failing jobs can be sent; drop ticks that no
        // longer apply (e.g. a new commit replaced the jobs).
        final failingIds = {
          for (final run in checks.runs)
            if (isFailedCheckRun(run)) run.jobId,
        };
        emit(
          latest.copyWith(
            checks: checks,
            selectedCheckJobIds: latest.selectedCheckJobIds.intersection(
              failingIds,
            ),
          ),
        );
      }
    }
  }

  /// Runs a checks action, tracking [TaskDetailLoaded.checksBusy] and
  /// surfacing a failure as [TaskDetailLoaded.checksError].
  Future<void> _checksAction(
    Emitter<TaskDetailState> emit,
    Future<void> Function() action, {
    TaskDetailLoaded Function(TaskDetailLoaded state)? onSuccess,
  }) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(checksBusy: true, clearChecksError: true));
    String? error;
    try {
      await action();
    } catch (e) {
      error = errorMessage(e);
    }
    final latest = state;
    if (latest is TaskDetailLoaded) {
      final next = latest.copyWith(checksBusy: false, checksError: error);
      emit(error == null && onSuccess != null ? onSuccess(next) : next);
    }
  }

  Future<void> _onFailingChecksSentToFix(
    FailingChecksSentToFix event,
    Emitter<TaskDetailState> emit,
  ) {
    final current = state;
    if (current is! TaskDetailLoaded) return Future.value();
    final ids = current.selectedCheckJobIds;
    return _checksAction(
      emit,
      () => _repository.fixFailingChecks(
        event.taskId,
        jobIds: ids.isEmpty ? null : ids.toList(),
        note: event.note.isEmpty ? null : event.note,
      ),
      onSuccess: (s) => s.copyWith(selectedCheckJobIds: const {}),
    );
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
    await _reviewAction(
      emit,
      () => _repository.acceptTask(event.taskId, force: event.force),
    );
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
