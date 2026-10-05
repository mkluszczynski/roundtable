import 'package:roundtable_client/roundtable_client.dart';

class AgentRepository {
  AgentRepository(this._client);

  final Client _client;

  Future<List<Agent>> listAgents() => _client.agent.list();

  Future<Agent?> getAgent(int id) => _client.agent.get(id);

  Future<Agent> createAgent({
    required String name,
    required int machineId,
    int? roleId,
    String? defaultModel,
    AgentEffort? defaultEffort,
  }) => _client.agent.create(
    name,
    machineId,
    roleId: roleId,
    defaultModel: defaultModel,
    defaultEffort: defaultEffort,
  );

  /// Saves [agent]'s name, role, model and effort.
  Future<Agent> updateAgent(Agent agent) => _client.agent.update(agent);

  /// Throws `DeletionBlockedException` while the agent has unfinished tasks.
  Future<void> deleteAgent(int id) => _client.agent.delete(id);
}
