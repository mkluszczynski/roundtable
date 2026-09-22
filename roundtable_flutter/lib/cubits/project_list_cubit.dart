import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

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
    emit(const ProjectListLoading());
    try {
      final projects = await _repository.listProjects();
      emit(ProjectListLoaded(projects));
    } catch (e) {
      emit(ProjectListError(e.toString()));
    }
  }

  /// Deletion is blocked while the project has non-terminal tasks (design
  /// doc §5) — surfaced as a plain [ProjectListError], unlike
  /// [MachineListCubit.deleteMachine]'s online guard, since there's no
  /// follow-up flow to offer here.
  Future<void> deleteProject(int id) async {
    try {
      await _repository.deleteProject(id);
    } on DeletionBlockedException catch (e) {
      emit(ProjectListError(e.message));
    } catch (e) {
      emit(ProjectListError(e.toString()));
    }
    await fetchProjects();
  }
}
