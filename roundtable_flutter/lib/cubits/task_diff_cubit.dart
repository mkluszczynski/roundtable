import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../repositories/task_repository.dart';

sealed class TaskDiffState {
  const TaskDiffState();
}

class TaskDiffInitial extends TaskDiffState {
  const TaskDiffInitial();
}

class TaskDiffLoading extends TaskDiffState {
  const TaskDiffLoading();
}

class TaskDiffError extends TaskDiffState {
  const TaskDiffError(this.message);

  final String message;
}

class TaskDiffLoaded extends TaskDiffState {
  const TaskDiffLoaded({
    required this.files,
    this.selectedFile,
    this.fileContent,
    this.fileContentLoading = false,
    this.fileContentError,
  });

  final List<DiffFile> files;
  final DiffFile? selectedFile;
  final String? fileContent;
  final bool fileContentLoading;
  final String? fileContentError;

  TaskDiffLoaded copyWith({
    DiffFile? selectedFile,
    String? fileContent,
    bool? fileContentLoading,
    String? fileContentError,
    bool clearFileContent = false,
  }) {
    return TaskDiffLoaded(
      files: files,
      selectedFile: selectedFile ?? this.selectedFile,
      fileContent: clearFileContent ? null : (fileContent ?? this.fileContent),
      fileContentLoading: fileContentLoading ?? this.fileContentLoading,
      fileContentError: clearFileContent ? null : fileContentError,
    );
  }
}

class TaskDiffCubit extends Cubit<TaskDiffState> {
  TaskDiffCubit(this._repository) : super(const TaskDiffInitial());

  final TaskRepository _repository;
  int? _taskId;

  Future<void> fetchChangedFiles(int taskId) async {
    _taskId = taskId;
    emit(const TaskDiffLoading());
    try {
      final files = await _repository.getChangedFiles(taskId);
      emit(TaskDiffLoaded(files: files));
    } catch (e) {
      emit(TaskDiffError(e.toString()));
    }
  }

  void selectFile(DiffFile file) {
    final current = state;
    if (current is! TaskDiffLoaded) return;
    emit(
      current.copyWith(selectedFile: file, clearFileContent: true),
    );
  }

  Future<void> loadFullFileContent() async {
    final current = state;
    final taskId = _taskId;
    final selectedFile = current is TaskDiffLoaded
        ? current.selectedFile
        : null;
    if (current is! TaskDiffLoaded || taskId == null || selectedFile == null) {
      return;
    }

    emit(current.copyWith(fileContentLoading: true));
    try {
      final content = await _repository.getFileContent(
        taskId,
        selectedFile.contentsUrl,
      );
      emit(current.copyWith(fileContent: content, fileContentLoading: false));
    } catch (e) {
      emit(
        current.copyWith(
          fileContentLoading: false,
          fileContentError: e.toString(),
        ),
      );
    }
  }
}
