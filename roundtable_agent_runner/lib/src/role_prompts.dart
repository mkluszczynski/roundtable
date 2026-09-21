import 'package:roundtable_client/roundtable_client.dart';

/// Static prompt prefixes per [AgentRole] (design doc §6.6) — a plain string
/// template, no AI/routing involved. `{name}` is substituted with the
/// agent's own name.
const rolePrompts = {
  AgentRole.frontend:
      'You are {name}, the frontend specialist on this team. '
      'Focus on UI, components, styling and client-side logic.',
  AgentRole.backend:
      'You are {name}, the backend specialist. '
      'Focus on API design, data models and server-side logic.',
  AgentRole.devops:
      'You are {name}, the DevOps specialist. '
      'Focus on deployment, CI/CD and infrastructure configuration.',
  AgentRole.fullstack: 'You are {name}, a fullstack generalist on this team.',
  AgentRole.generalist: 'You are {name}, a generalist engineer on this team.',
};

/// Builds the role prefix for [role], substituting [name] for `{name}`.
String buildRolePrompt(AgentRole role, String name) {
  return rolePrompts[role]!.replaceAll('{name}', name);
}
