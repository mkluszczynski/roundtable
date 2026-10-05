import 'package:roundtable_client/roundtable_client.dart';

class AgentRoleRepository {
  AgentRoleRepository(this._client);

  final Client _client;

  Future<List<AgentRoleDefinition>> listRoles() => _client.agentRole.list();

  Future<AgentRoleDefinition> createRole(AgentRoleDefinition role) =>
      _client.agentRole.create(role);

  Future<AgentRoleDefinition> updateRole(AgentRoleDefinition role) =>
      _client.agentRole.update(role);

  /// Throws `DeletionBlockedException` while an agent uses the role.
  Future<void> deleteRole(int id) => _client.agentRole.delete(id);
}
