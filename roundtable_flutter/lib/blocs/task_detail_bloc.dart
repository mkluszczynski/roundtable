import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

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
    this.pendingQuestion,
    this.submitting = false,
  });

  final Task task;
  final TaskQuestion? pendingQuestion;
  final bool submitting;

  TaskDetailLoaded copyWith({
    Task? task,
    TaskQuestion? pendingQuestion,
    bool clearPendingQuestion = false,
    bool? submitting,
  }) {
    return TaskDetailLoaded(
      task: task ?? this.task,
      pendingQuestion: clearPendingQuestion
          ? null
          : (pendingQuestion ?? this.pendingQuestion),
      submitting: submitting ?? this.submitting,
    );
  }
}

/// Reacts to a task's live status (design doc §6.4) and to the dev's
/// actions on it (answering a question, approving or giving feedback on a
/// plan) — a full Bloc rather than a Cubit, per the design doc's own rule of
/// thumb (§3.3), since there's genuinely more than one event source here.
class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
  TaskDetailBloc(this._repository) : super(const TaskDetailInitial()) {
    on<TaskDetailSubscribed>(_onSubscribed);
    on<AnswerSubmitted>(_onAnswerSubmitted);
    on<PlanApproved>(_onPlanApproved);
    on<PlanFeedbackSubmitted>(_onPlanFeedbackSubmitted);
  }

  final TaskRepository _repository;

  Future<void> _onSubscribed(
    TaskDetailSubscribed event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(const TaskDetailLoading());
    try {
      await for (final task in _repository.watchTask(event.taskId)) {
        emit(await _stateFor(task));
      }
    } catch (e) {
      emit(TaskDetailError(e.toString()));
    }
  }

  Future<TaskDetailState> _stateFor(Task task) async {
    TaskQuestion? pendingQuestion;
    if (task.status == TaskStatus.waitingForAnswer) {
      pendingQuestion = await _repository.latestQuestion(task.id!);
    }
    return TaskDetailLoaded(task: task, pendingQuestion: pendingQuestion);
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
}
