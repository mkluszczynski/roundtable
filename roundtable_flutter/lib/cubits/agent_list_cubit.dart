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
  AgentListCubit(
    this._repository, {
    this.retryDelay = const Duration(seconds: 2),
    this.maxRetryDelay = const Duration(seconds: 30),
  }) : super(const AgentListInitial());

  final AgentRepository _repository;

  /// How long [subscribe] waits before reconnecting after the stream drops;
  /// doubles on every consecutive failure, up to [maxRetryDelay].
  final Duration retryDelay;
  final Duration maxRetryDelay;

  /// Loads the list. A [silent] refresh keeps the current list when it
  /// fails instead of replacing it with an error — for background refreshes.
  Future<void> fetchAgents({bool silent = false}) async {
    // Refreshes keep showing the current list; the cubit is shared
    // app-wide (PanelShell), so a spinner would blank every screen.
    if (state is! AgentListLoaded) emit(const AgentListLoading());
    try {
      final agents = await _repository.listAgents();
      if (isClosed) return;
      emit(AgentListLoaded(agents));
    } catch (e) {
      if (isClosed || (silent && state is AgentListLoaded)) return;
      emit(AgentListError(errorMessage(e)));
    }
  }

  /// Merges every agent `AgentEndpoint.watchAgents` streams into the loaded
  /// list by id. Events before the first [fetchAgents] completes are
  /// dropped — the fetch returns the same rows. When the stream errors or
  /// ends (server restart, laptop sleep, network blip) it keeps the last
  /// list, then after a backoff refetches it silently — catching changes
  /// missed while disconnected, deletions included — and resubscribes, so
  /// statuses never stay frozen. Runs until the cubit closes.
  Future<void> subscribe() async {
    var delay = retryDelay;
    while (!isClosed) {
      try {
        await for (final agent in untilClosed(_repository.watchAgents())) {
          delay = retryDelay;
          _merge(agent);
        }
      } catch (_) {
        // Reconnect below.
      }
      if (isClosed) return;
      await Future<void>.delayed(delay);
      if (isClosed) return;
      final doubled = delay * 2;
      delay = doubled > maxRetryDelay ? maxRetryDelay : doubled;
      await fetchAgents(silent: true);
    }
  }

  void _merge(Agent agent) {
    final current = state;
    if (isClosed || current is! AgentListLoaded) return;
    final agents = [...current.agents];
    final index = agents.indexWhere((a) => a.id == agent.id);
    if (index == -1) {
      agents.add(agent);
    } else {
      agents[index] = agent;
    }
    emit(AgentListLoaded(agents));
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
