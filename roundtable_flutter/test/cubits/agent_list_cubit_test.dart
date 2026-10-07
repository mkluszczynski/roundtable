import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/cubits/agent_list_cubit.dart';
import 'package:roundtable_flutter/repositories/agent_repository.dart';

class _FakeAgentRepository implements AgentRepository {
  _FakeAgentRepository(this.agents);

  final List<Agent> agents;
  final updates = StreamController<Agent>();

  @override
  Future<List<Agent>> listAgents() async => agents;

  @override
  Stream<Agent> watchAgents() => updates.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Agent agent(int id, {AgentStatus status = AgentStatus.idle}) => Agent(
    id: id,
    machineId: 1,
    name: 'Agent $id',
    executionMode: AgentExecutionMode.native,
    status: status,
  );

  List<AgentStatus> statuses(AgentListCubit cubit) =>
      (cubit.state as AgentListLoaded).agents.map((a) => a.status).toList();

  test('a streamed status change updates the loaded agent', () async {
    final repository = _FakeAgentRepository([agent(1), agent(2)]);
    final cubit = AgentListCubit(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());

    repository.updates.add(agent(2, status: AgentStatus.busy));
    await pumpEventQueue();

    expect(statuses(cubit), [AgentStatus.idle, AgentStatus.busy]);
    await cubit.close();
  });

  test('a streamed agent the list does not know is added', () async {
    final repository = _FakeAgentRepository([agent(1)]);
    final cubit = AgentListCubit(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());

    repository.updates.add(agent(3, status: AgentStatus.busy));
    await pumpEventQueue();

    expect((cubit.state as AgentListLoaded).agents.map((a) => a.id), [1, 3]);
    await cubit.close();
  });

  test('a dropped stream keeps the last list', () async {
    final repository = _FakeAgentRepository([agent(1)]);
    final cubit = AgentListCubit(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());

    repository.updates.addError(Exception('connection lost'));
    await pumpEventQueue();

    expect(statuses(cubit), [AgentStatus.idle]);
    await cubit.close();
  });
}
