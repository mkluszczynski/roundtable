import 'package:roundtable_client/roundtable_client.dart';

/// Used when an agent has no role (its role was deleted, or it was created
/// without one).
const fallbackRolePrompt =
    'You are {name}, a generalist engineer on this team.';

/// The prompt prefix of [agent]'s role (edited in the panel's Settings, sent
/// along by `AgentEndpoint.get`) — a plain string template, no AI/routing
/// involved. `{name}` is substituted with the agent's own name.
String buildRolePrompt(Agent agent) {
  final template = agent.role?.prompt ?? fallbackRolePrompt;
  return template.replaceAll('{name}', agent.name);
}
