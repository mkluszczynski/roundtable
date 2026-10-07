import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../utils/closeable_streams.dart';
import '../utils/error_message.dart';
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

class AgentListCubit extends Cubit<AgentListState>
    with CloseableStreams<AgentListState> {
  AgentListCubit(this._repository) : super(const AgentListInitial());

  final AgentRepository _repository;

  Future<void> fetchAgents() async {
    // Refreshes keep showing the current list; the cubit is shared
    // app-wide (PanelShell), so a spinner would blank every screen.
    if (state is! AgentListLoaded) emit(const AgentListLoading());
    try {
      final agents = await _repository.listAgents();
      emit(AgentListLoaded(agents));
    } catch (e) {
      emit(AgentListError(errorMessage(e)));
    }
  }

  /// Keeps the loaded agents' statuses live (the dashboard's "Agents busy",
  /// the machine screens) — [fetchAgents] alone is a snapshot. Only the
  /// panel-wide cubit (`PanelShell`) calls this.
  Future<void> watchStatuses() async {
    try {
      await for (final changed in untilClosed(
        _repository.watchAgentStatuses(),
      )) {
        final current = state;
        if (current is! AgentListLoaded) continue;
        emit(
          AgentListLoaded([
            for (final agent in current.agents)
              agent.id == changed.id
                  ? agent.copyWith(status: changed.status)
                  : agent,
          ]),
        );
      }
    } catch (_) {
      // A dropped stream leaves the last statuses; the next fetch fixes it.
    }
  }

  /// Deletes agent [id] and refreshes the list. Returns `null` on success,
  /// or a message to show (e.g. the agent still has unfinished tasks).
  Future<String?> deleteAgent(int id) async {
    String? failure;
    try {
      await _repository.deleteAgent(id);
    } catch (e) {
      failure = errorMessage(e);
    }
    await fetchAgents();
    return failure;
  }
}
