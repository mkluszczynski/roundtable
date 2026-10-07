import 'package:roundtable_client/roundtable_client.dart';

class AgentRepository {
  AgentRepository(this._client);

  final Client _client;

  Future<List<Agent>> listAgents() => _client.agent.list();

  Future<Agent?> getAgent(int id) => _client.agent.get(id);

  /// Every agent on subscribe, then each agent as it changes (created,
  /// edited, or its status reported by a daemon). Deletions aren't streamed.
  Stream<Agent> watchAgents() => _client.agent.watchAgents();

  Future<Agent> createAgent({
    required String name,
    required int machineId,
    int? roleId,
    String? defaultModel,
    AgentEffort? defaultEffort,
    AgentExecutionMode? executionMode,
  }) => _client.agent.create(
    name,
    machineId,
    roleId: roleId,
    defaultModel: defaultModel,
    defaultEffort: defaultEffort,
    executionMode: executionMode,
  );

  /// Saves [agent]'s name, role, model, effort and execution mode (the
  /// last one only while it has no open task).
  Future<Agent> updateAgent(Agent agent) => _client.agent.update(agent);

  /// Throws `DeletionBlockedException` while the agent has unfinished tasks.
  Future<void> deleteAgent(int id) => _client.agent.delete(id);
}
