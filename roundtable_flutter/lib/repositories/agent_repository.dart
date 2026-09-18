import 'package:roundtable_client/roundtable_client.dart';

class AgentRepository {
  AgentRepository(this._client);

  final Client _client;

  Future<List<Agent>> listAgents() => _client.agent.list();
}
