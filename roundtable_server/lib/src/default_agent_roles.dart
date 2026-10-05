import 'package:serverpod/serverpod.dart';

import 'generated/protocol.dart';

/// The roles a new workspace starts with — the same ones the
/// `agent-roles` migration seeds an existing database with.
final defaultAgentRoles = [
  AgentRoleDefinition(
    name: 'frontend',
    description: 'UI, components, styling and client-side logic',
    prompt:
        'You are {name}, the frontend specialist on this team. Focus on UI, '
        'components, styling and client-side logic.',
  ),
  AgentRoleDefinition(
    name: 'backend',
    description: 'API design, data models and server-side logic',
    prompt:
        'You are {name}, the backend specialist. Focus on API design, data '
        'models and server-side logic.',
  ),
  AgentRoleDefinition(
    name: 'devops',
    description: 'Deployment, CI/CD and infrastructure',
    prompt:
        'You are {name}, the DevOps specialist. Focus on deployment, CI/CD '
        'and infrastructure configuration.',
  ),
  AgentRoleDefinition(
    name: 'fullstack',
    description: 'Works across the whole stack',
    prompt: 'You are {name}, a fullstack generalist on this team.',
  ),
  AgentRoleDefinition(
    name: 'generalist',
    description: 'Any kind of task',
    prompt: 'You are {name}, a generalist engineer on this team.',
  ),
];

/// Seeds [defaultAgentRoles] into a database that has no roles yet (a
/// fresh one is created from `definition.sql`, which carries no data).
Future<void> seedDefaultAgentRoles(Session session) async {
  if (await AgentRoleDefinition.db.count(session) > 0) return;
  await AgentRoleDefinition.db.insert(session, defaultAgentRoles);
}
