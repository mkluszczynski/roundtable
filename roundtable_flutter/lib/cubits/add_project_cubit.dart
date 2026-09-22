import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../repositories/project_repository.dart';

sealed class AddProjectState {
  const AddProjectState();
}

class AddProjectInitial extends AddProjectState {
  const AddProjectInitial();
}

class AddProjectSubmitting extends AddProjectState {
  const AddProjectSubmitting();
}

class AddProjectSuccess extends AddProjectState {
  const AddProjectSuccess(this.project);

  final Project project;
}

class AddProjectError extends AddProjectState {
  const AddProjectError(this.message);

  final String message;
}

class AddProjectCubit extends Cubit<AddProjectState> {
  AddProjectCubit(this._repository) : super(const AddProjectInitial());

  final ProjectRepository _repository;

  Future<void> submit({
    required String name,
    required String repoUrl,
    String? repoAccessToken,
  }) async {
    emit(const AddProjectSubmitting());
    try {
      final project = await _repository.createProject(
        name: name,
        repoUrl: repoUrl,
        repoAccessToken: repoAccessToken,
      );
      emit(AddProjectSuccess(project));
    } catch (e) {
      emit(AddProjectError(e.toString()));
    }
  }

  /// Renames/repoints an existing project — the token stays untouched here,
  /// it's only ever changed via `ProjectDetailScreen`'s "Update token" flow.
  Future<void> update({
    required Project existing,
    required String name,
    required String repoUrl,
  }) async {
    emit(const AddProjectSubmitting());
    try {
      final project = await _repository.updateProject(
        existing.copyWith(name: name, repoUrl: repoUrl),
      );
      emit(AddProjectSuccess(project));
    } catch (e) {
      emit(AddProjectError(e.toString()));
    }
  }
}
