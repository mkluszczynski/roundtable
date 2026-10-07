import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/cubits/agent_list_cubit.dart';
import 'package:roundtable_flutter/repositories/agent_repository.dart';

class _FakeAgentRepository implements AgentRepository {
  _FakeAgentRepository(this.agents);

  List<Agent> agents;
  var listCalls = 0;
  Object? listError;

  /// When set, [listAgents] waits for it — to finish a fetch after a
  /// streamed update.
  Completer<void>? listGate;

  /// One per [watchAgents] call — each reconnect opens a new stream.
  final streams = <StreamController<Agent>>[];
  StreamController<Agent> get updates => streams.last;

  @override
  Future<List<Agent>> listAgents() async {
    listCalls++;
    final snapshot = agents;
    await listGate?.future;
    if (listError != null) throw listError!;
    return snapshot;
  }

  @override
  Stream<Agent> watchAgents() {
    final controller = StreamController<Agent>();
    streams.add(controller);
    return controller.stream;
  }

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

  AgentListCubit cubitFor(AgentRepository repository) =>
      AgentListCubit(repository, retryDelay: Duration.zero);

  List<AgentStatus> statuses(AgentListCubit cubit) =>
      (cubit.state as AgentListLoaded).agents.map((a) => a.status).toList();

  test('a streamed status change updates the loaded agent', () async {
    final repository = _FakeAgentRepository([agent(1), agent(2)]);
    final cubit = cubitFor(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());

    repository.updates.add(agent(2, status: AgentStatus.busy));
    await pumpEventQueue();

    expect(statuses(cubit), [AgentStatus.idle, AgentStatus.busy]);
    await cubit.close();
  });

  test('a streamed agent the list does not know is added', () async {
    final repository = _FakeAgentRepository([agent(1)]);
    final cubit = cubitFor(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());

    repository.updates.add(agent(3, status: AgentStatus.busy));
    await pumpEventQueue();

    expect((cubit.state as AgentListLoaded).agents.map((a) => a.id), [1, 3]);
    await cubit.close();
  });

  test('a dropped stream keeps the last list and resubscribes', () async {
    final repository = _FakeAgentRepository([agent(1), agent(2)]);
    final cubit = cubitFor(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());
    await pumpEventQueue();

    repository.updates.addError(Exception('connection lost'));
    await pumpEventQueue();

    expect(statuses(cubit), [AgentStatus.idle, AgentStatus.idle]);
    expect(repository.streams, hasLength(2));
    expect(repository.listCalls, 2);

    repository.updates.add(agent(1, status: AgentStatus.busy));
    await pumpEventQueue();

    expect(statuses(cubit), [AgentStatus.busy, AgentStatus.idle]);
    await cubit.close();
  });

  test('a stream that ends resubscribes too', () async {
    final repository = _FakeAgentRepository([agent(1)]);
    final cubit = cubitFor(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());
    await pumpEventQueue();

    await repository.updates.close();
    await pumpEventQueue();
    repository.updates.add(agent(1, status: AgentStatus.busy));
    await pumpEventQueue();

    expect(repository.streams, hasLength(2));
    expect(statuses(cubit), [AgentStatus.busy]);
    await cubit.close();
  });

  test('the refetch after a drop picks up changes missed meanwhile', () async {
    final repository = _FakeAgentRepository([agent(1), agent(2)]);
    final cubit = cubitFor(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());
    await pumpEventQueue();

    // Agent 2 was deleted and agent 1 started working while disconnected.
    repository.agents = [agent(1, status: AgentStatus.busy)];
    repository.updates.addError(Exception('connection lost'));
    await pumpEventQueue();

    expect((cubit.state as AgentListLoaded).agents.map((a) => a.id), [1]);
    expect(statuses(cubit), [AgentStatus.busy]);
    await cubit.close();
  });

  test('a failed refetch after a drop keeps the last list', () async {
    final repository = _FakeAgentRepository([agent(1)]);
    final cubit = cubitFor(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());
    await pumpEventQueue();

    repository.listError = Exception('server down');
    repository.updates.addError(Exception('connection lost'));
    await pumpEventQueue();

    expect(cubit.state, isA<AgentListLoaded>());
    expect(statuses(cubit), [AgentStatus.idle]);
    await cubit.close();
  });

  test('closing the cubit stops resubscribing', () async {
    final repository = _FakeAgentRepository([agent(1)]);
    final cubit = cubitFor(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());
    await pumpEventQueue();

    await cubit.close();
    await pumpEventQueue();

    expect(repository.streams, hasLength(1));
  });

  test('a fetch finishing after a newer streamed status keeps it', () async {
    final repository = _FakeAgentRepository([agent(1)]);
    final cubit = cubitFor(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());
    await pumpEventQueue();

    // E.g. the refresh after editing an agent: it reads the row as idle...
    repository.listGate = Completer<void>();
    final fetch = cubit.fetchAgents();
    await pumpEventQueue();
    // ...then the agent starts planning before the response arrives.
    repository.updates.add(agent(1, status: AgentStatus.busy));
    await pumpEventQueue();
    repository.listGate!.complete();
    await fetch;

    expect(statuses(cubit), [AgentStatus.busy]);
    await cubit.close();
  });

  test('streamed updates before the first fetch apply to its result', () async {
    final repository = _FakeAgentRepository([agent(1), agent(2)]);
    repository.listGate = Completer<void>();
    final cubit = cubitFor(repository);
    final fetch = cubit.fetchAgents();
    unawaited(cubit.subscribe());
    await pumpEventQueue();

    repository.updates.add(agent(2, status: AgentStatus.busy));
    await pumpEventQueue();
    repository.listGate!.complete();
    await fetch;

    expect(statuses(cubit), [AgentStatus.idle, AgentStatus.busy]);
    await cubit.close();
  });

  test('a deleted agent is not brought back by its streamed row', () async {
    final repository = _FakeAgentRepository([agent(1), agent(2)]);
    final cubit = cubitFor(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());
    await pumpEventQueue();
    repository.updates.add(agent(2, status: AgentStatus.busy));
    await pumpEventQueue();

    repository.agents = [agent(1)];
    await cubit.fetchAgents();

    expect((cubit.state as AgentListLoaded).agents.map((a) => a.id), [1]);
    await cubit.close();
  });

  test('reconnecting does not pile up wrapped streams', () async {
    final repository = _FakeAgentRepository([agent(1)]);
    final cubit = cubitFor(repository);
    await cubit.fetchAgents();
    unawaited(cubit.subscribe());
    await pumpEventQueue();

    for (var i = 0; i < 5; i++) {
      repository.updates.addError(Exception('connection lost'));
      await pumpEventQueue();
    }
    await repository.updates.close();
    await pumpEventQueue();

    expect(repository.streams, hasLength(7));
    expect(cubit.openStreamCount, 1);
    await cubit.close();
    expect(cubit.openStreamCount, 0);
  });
}
