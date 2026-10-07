import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/cubits/agent_list_cubit.dart';
import 'package:roundtable_flutter/repositories/agent_repository.dart';

class _FakeAgentRepository implements AgentRepository {
  final statuses = StreamController<Agent>();

  @override
  Future<List<Agent>> listAgents() async => [
    Agent(id: 1, machineId: 1, name: 'Ana', status: AgentStatus.idle),
    Agent(id: 2, machineId: 1, name: 'Rex', status: AgentStatus.busy),
  ];

  @override
  Stream<Agent> watchAgentStatuses() => statuses.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a status change from the server updates that agent only', () async {
    final repository = _FakeAgentRepository();
    final cubit = AgentListCubit(repository);
    await cubit.fetchAgents();
    unawaited(cubit.watchStatuses());

    repository.statuses.add(
      Agent(id: 1, machineId: 1, name: 'Ana', status: AgentStatus.busy),
    );
    final loaded = await cubit.stream.first as AgentListLoaded;

    expect(loaded.agents.map((a) => (a.name, a.status)), [
      ('Ana', AgentStatus.busy),
      ('Rex', AgentStatus.busy),
    ]);
    await cubit.close();
  });
}
