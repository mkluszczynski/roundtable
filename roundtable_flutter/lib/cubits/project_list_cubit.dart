import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../utils/error_message.dart';
import '../repositories/project_repository.dart';

sealed class ProjectListState {
  const ProjectListState();
}

class ProjectListInitial extends ProjectListState {
  const ProjectListInitial();
}

class ProjectListLoading extends ProjectListState {
  const ProjectListLoading();
}

class ProjectListLoaded extends ProjectListState {
  const ProjectListLoaded(this.projects);

  final List<Project> projects;
}

class ProjectListError extends ProjectListState {
  const ProjectListError(this.message);

  final String message;
}

class ProjectListCubit extends Cubit<ProjectListState> {
  ProjectListCubit(this._repository) : super(const ProjectListInitial());

  final ProjectRepository _repository;

  Future<void> fetchProjects() async {
    // Refreshes keep showing the current list; the cubit is shared
    // app-wide (PanelShell), so a spinner would blank every screen.
    if (state is! ProjectListLoaded) emit(const ProjectListLoading());
    try {
      final projects = await _repository.listProjects();
      emit(ProjectListLoaded(projects));
    } catch (e) {
      emit(ProjectListError(errorMessage(e)));
    }
  }

  /// Deletion is blocked while the project has non-terminal tasks
  /// (docs/ARCHITECTURE.md) — surfaced as a plain [ProjectListError], unlike
  /// [MachineListCubit.deleteMachine]'s online guard, since there's no
  /// follow-up flow to offer here.
  ///
  /// Returns `null` on success, or the error message on failure. The
  /// trailing [fetchProjects] refetch always overwrites the emitted
  /// [ProjectListError] state, so callers must use this return value rather
  /// than reading [state] after this call resolves.
  Future<String?> deleteProject(int id) async {
    String? failure;
    try {
      await _repository.deleteProject(id);
    } catch (e) {
      failure = errorMessage(e);
      emit(ProjectListError(failure));
    }
    await fetchProjects();
    return failure;
  }
}
