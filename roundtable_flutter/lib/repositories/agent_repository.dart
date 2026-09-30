import 'package:roundtable_client/roundtable_client.dart';

class AgentRepository {
  AgentRepository(this._client);

  final Client _client;

  Future<List<Agent>> listAgents() => _client.agent.list();

  Future<Agent?> getAgent(int id) => _client.agent.get(id);

  Future<Agent> createAgent({
    required String name,
    required int machineId,
    AgentRole role = AgentRole.generalist,
    String? defaultModel,
    AgentEffort? defaultEffort,
  }) => _client.agent.create(
    name,
    machineId,
    role: role,
    defaultModel: defaultModel,
    defaultEffort: defaultEffort,
  );
}
