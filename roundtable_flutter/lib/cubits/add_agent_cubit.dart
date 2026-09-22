import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

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
    required AgentRole role,
    String? defaultModel,
    AgentEffort? defaultEffort,
  }) async {
    emit(const AddAgentSubmitting());
    try {
      final agent = await _repository.createAgent(
        name: name,
        machineId: machineId,
        role: role,
        defaultModel: defaultModel,
        defaultEffort: defaultEffort,
      );
      emit(AddAgentSuccess(agent));
    } catch (e) {
      emit(AddAgentError(e.toString()));
    }
  }
}
