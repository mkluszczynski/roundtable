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
}
