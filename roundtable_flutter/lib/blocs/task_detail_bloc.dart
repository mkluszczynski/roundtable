import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

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

class TaskCancelled extends TaskDetailEvent {
  const TaskCancelled(this.taskId);

  final int taskId;
}

/// Internal: starts the live log tail for [taskId]. Added once, the first
/// time the task enters `planning`/`running`.
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
    this.selectedFile,
    this.fileContent,
    this.fileContentLoading = false,
    this.fileContentError,
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
  final DiffFile? selectedFile;
  final String? fileContent;
  final bool fileContentLoading;
  final String? fileContentError;

  TaskDetailLoaded copyWith({
    Task? task,
    Project? project,
    Agent? agent,
    Machine? machine,
    TaskQuestion? pendingQuestion,
    bool clearPendingQuestion = false,
    bool? submitting,
    List<TaskLogEntry>? logs,
    bool? logsSubscribed,
    List<DiffFile>? files,
    bool? filesRequested,
    DiffFile? selectedFile,
    String? fileContent,
    bool? fileContentLoading,
    String? fileContentError,
    bool clearFileContent = false,
  }) {
    return TaskDetailLoaded(
      task: task ?? this.task,
      project: project ?? this.project,
      agent: agent ?? this.agent,
      machine: machine ?? this.machine,
      pendingQuestion: clearPendingQuestion
          ? null
          : (pendingQuestion ?? this.pendingQuestion),
      submitting: submitting ?? this.submitting,
      logs: logs ?? this.logs,
      logsSubscribed: logsSubscribed ?? this.logsSubscribed,
      files: files ?? this.files,
      filesRequested: filesRequested ?? this.filesRequested,
      selectedFile: selectedFile ?? this.selectedFile,
      fileContent: clearFileContent ? null : (fileContent ?? this.fileContent),
      fileContentLoading: fileContentLoading ?? this.fileContentLoading,
      fileContentError: clearFileContent ? null : fileContentError,
    );
  }
}

/// Reacts to a task's live status (design doc §6.4), its log tail while it's
/// executing, its diff once it's up for review, and to the dev's actions on
/// it (answering a question, approving/feedback on a plan, picking a file) —
/// a full Bloc rather than a Cubit, per the design doc's own rule of thumb
/// (§3.3), since there's genuinely more than one event source here. Drives
/// `task_detail_screen.dart`'s 4 status-driven sub-states in one place,
/// folding in what used to be the separate `TaskDiffCubit`/`task_diff_screen`.
class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
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
    on<TaskCancelled>(_onTaskCancelled);
    on<_LogsSubscribed>(_onLogsSubscribed);
    on<_ChangedFilesRequested>(_onChangedFilesRequested);
    on<FileSelected>(_onFileSelected);
    on<FullFileContentRequested>(_onFullFileContentRequested);
  }

  final TaskRepository _repository;
  final ProjectRepository _projectRepository;
  final AgentRepository _agentRepository;
  final MachineRepository _machineRepository;

  static const _liveStatuses = {TaskStatus.planning, TaskStatus.running};
  static const _reviewStatuses = {TaskStatus.awaitingReview, TaskStatus.done};

  Future<void> _onSubscribed(
    TaskDetailSubscribed event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(const TaskDetailLoading());
    try {
      await for (final task in _repository.watchTask(event.taskId)) {
        final current = state;
        emit(await _stateFor(task, previous: current));

        if (_liveStatuses.contains(task.status) &&
            (current is! TaskDetailLoaded || !current.logsSubscribed)) {
          add(_LogsSubscribed(event.taskId));
        }
        if (_reviewStatuses.contains(task.status) &&
            (current is! TaskDetailLoaded || !current.filesRequested)) {
          add(_ChangedFilesRequested(event.taskId));
        }
      }
    } catch (e) {
      emit(TaskDetailError(e.toString()));
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
      return previous.copyWith(
        task: task,
        pendingQuestion: pendingQuestion,
        clearPendingQuestion: pendingQuestion == null,
        submitting: false,
      );
    }

    // First load: the task's relations (project/agent/machine) never change
    // for a given task, so fetch them once rather than on every status tick.
    final project = await _projectRepository.getProject(task.projectId);
    final agentId = task.agentId;
    final agent = agentId == null
        ? null
        : await _agentRepository.getAgent(agentId);
    final machine = agent == null
        ? null
        : await _machineRepository.getMachine(agent.machineId);

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
      emit(TaskDetailError(e.toString()));
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
      emit(TaskDetailError(e.toString()));
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
      emit(TaskDetailError(e.toString()));
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
      emit(TaskDetailError(e.toString()));
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
      emit(TaskDetailError(e.toString()));
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
    await for (final entry in _repository.watchLogs(event.taskId)) {
      logs.add(entry);
      final latest = state;
      if (latest is TaskDetailLoaded) {
        emit(latest.copyWith(logs: List.of(logs)));
      }
    }
  }

  Future<void> _onChangedFilesRequested(
    _ChangedFilesRequested event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(filesRequested: true));
    try {
      final files = await _repository.getChangedFiles(event.taskId);
      final latest = state;
      if (latest is TaskDetailLoaded) {
        emit(latest.copyWith(files: files));
      }
    } catch (_) {
      // The PR may not exist yet for a task that just reached this status;
      // leave `files` unset rather than surfacing a hard error.
    }
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
            fileContentError: e.toString(),
          ),
        );
      }
    }
  }
}
