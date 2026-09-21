import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../repositories/task_repository.dart';

sealed class CreateTaskState {
  const CreateTaskState();
}

class CreateTaskInitial extends CreateTaskState {
  const CreateTaskInitial();
}

class CreateTaskSubmitting extends CreateTaskState {
  const CreateTaskSubmitting();
}

class CreateTaskSuccess extends CreateTaskState {
  const CreateTaskSuccess(this.task);

  final Task task;
}

class CreateTaskError extends CreateTaskState {
  const CreateTaskError(this.message);

  final String message;
}

class CreateTaskCubit extends Cubit<CreateTaskState> {
  CreateTaskCubit(this._repository) : super(const CreateTaskInitial());

  final TaskRepository _repository;

  Future<void> submit({
    required int projectId,
    required int agentId,
    required String prompt,
    required bool skipPlanning,
  }) async {
    emit(const CreateTaskSubmitting());
    try {
      final task = await _repository.createTask(
        projectId,
        agentId,
        prompt,
        skipPlanning: skipPlanning,
      );
      emit(CreateTaskSuccess(task));
    } catch (e) {
      emit(CreateTaskError(e.toString()));
    }
  }
}
