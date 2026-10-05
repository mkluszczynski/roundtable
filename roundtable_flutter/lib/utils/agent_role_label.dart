import 'package:roundtable_client/roundtable_client.dart';

extension AgentRoleLabel on Agent {
  /// The agent's role name (roles are edited in Settings); an agent without
  /// one gets the runner's generalist prompt.
  String get roleLabel => role?.name ?? 'generalist';
}
