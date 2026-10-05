import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../utils/error_message.dart';
import '../repositories/agent_repository.dart';

sealed class AddAgentState {
  const AddAgentState();
}

class AddAgentInitial extends AddAgentState {
  const AddAgentInitial();
}

class AddAgentSubmitting extends AddAgentState {
  const AddAgentSubmitting();
}

class AddAgentSuccess extends AddAgentState {
  const AddAgentSuccess(this.agent);

  final Agent agent;
}

class AddAgentError extends AddAgentState {
  const AddAgentError(this.message);

  final String message;
}

class AddAgentCubit extends Cubit<AddAgentState> {
  AddAgentCubit(this._repository) : super(const AddAgentInitial());

  final AgentRepository _repository;

  Future<void> submit({
    required String name,
    required int machineId,
    required int? roleId,
    String? defaultModel,
    AgentEffort? defaultEffort,
  }) async {
    emit(const AddAgentSubmitting());
    try {
      final agent = await _repository.createAgent(
        name: name,
        machineId: machineId,
        roleId: roleId,
        defaultModel: defaultModel,
        defaultEffort: defaultEffort,
      );
      emit(AddAgentSuccess(agent));
    } catch (e) {
      emit(AddAgentError(errorMessage(e)));
    }
  }

  /// Saves edits to [existing]. Its machine and execution mode stay as they
  /// are.
  Future<void> update({
    required Agent existing,
    required String name,
    required int? roleId,
    String? defaultModel,
    AgentEffort? defaultEffort,
  }) async {
    emit(const AddAgentSubmitting());
    try {
      final agent = await _repository.updateAgent(
        existing.copyWith(
          name: name,
          roleId: roleId,
          role: null,
          defaultModel: defaultModel,
          defaultEffort: defaultEffort,
        ),
      );
      emit(AddAgentSuccess(agent));
    } catch (e) {
      emit(AddAgentError(errorMessage(e)));
    }
  }
}
