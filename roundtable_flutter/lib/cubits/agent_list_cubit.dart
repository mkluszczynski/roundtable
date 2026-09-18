import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../repositories/agent_repository.dart';

sealed class AgentListState {
  const AgentListState();
}

class AgentListInitial extends AgentListState {
  const AgentListInitial();
}

class AgentListLoading extends AgentListState {
  const AgentListLoading();
}

class AgentListLoaded extends AgentListState {
  const AgentListLoaded(this.agents);

  final List<Agent> agents;
}

class AgentListError extends AgentListState {
  const AgentListError(this.message);

  final String message;
}

class AgentListCubit extends Cubit<AgentListState> {
  AgentListCubit(this._repository) : super(const AgentListInitial());

  final AgentRepository _repository;

  Future<void> fetchAgents() async {
    emit(const AgentListLoading());
    try {
      final agents = await _repository.listAgents();
      emit(AgentListLoaded(agents));
    } catch (e) {
      emit(AgentListError(e.toString()));
    }
  }
}
