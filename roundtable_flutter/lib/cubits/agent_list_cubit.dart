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

/// The agent list. [fetchAgents] loads it; [subscribe] keeps it live —
/// agent statuses change on the daemon's side (a task starts planning, a
/// review finishes), and the dashboard's "Agents busy" count and the agent
/// rows must follow without a reload.
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

  /// Merges every agent `AgentEndpoint.watchAgents` streams into the loaded
  /// list by id. Events before the first [fetchAgents] completes are
  /// dropped — the fetch returns the same rows. A dropped connection keeps
  /// the last list rather than replacing it with an error.
  Future<void> subscribe() async {
    try {
      await for (final agent in untilClosed(_repository.watchAgents())) {
        final current = state;
        if (current is! AgentListLoaded) continue;
        final agents = [...current.agents];
        final index = agents.indexWhere((a) => a.id == agent.id);
        if (index == -1) {
          agents.add(agent);
        } else {
          agents[index] = agent;
        }
        emit(AgentListLoaded(agents));
      }
    } catch (_) {
      // Statuses go stale until the next fetch; the list itself stays usable.
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
