import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'non_terminal_task_statuses.dart';

/// CRUD for [AgentRoleDefinition] — the workspace's agent roles, edited in
/// the panel's Settings. Deletion is blocked while an agent uses the role.
class AgentRoleEndpoint extends Endpoint {
  Future<List<AgentRoleDefinition>> list(Session session) =>
      AgentRoleDefinition.db.find(session, orderBy: (r) => r.name);

  Future<AgentRoleDefinition> create(
    Session session,
    AgentRoleDefinition role,
  ) async {
    final valid = await _validated(session, role);
    return AgentRoleDefinition.db.insertRow(
      session,
      valid.copyWith(id: null, createdAt: DateTime.now()),
    );
  }

  Future<AgentRoleDefinition> update(
    Session session,
    AgentRoleDefinition role,
  ) async {
    if (await AgentRoleDefinition.db.findById(session, role.id!) == null) {
      throw NotFoundException(message: 'Role ${role.id} not found');
    }
    final valid = await _validated(session, role);
    return AgentRoleDefinition.db.updateRow(
      session,
      valid,
      columns: (t) => [t.name, t.description, t.prompt],
    );
  }

  Future<void> delete(Session session, int id) async {
    await guardedDelete(session, (transaction) async {
      final role = await AgentRoleDefinition.db.findById(
        session,
        id,
        transaction: transaction,
      );
      if (role == null) {
        throw NotFoundException(message: 'Role $id not found');
      }
      final users = await Agent.db.count(
        session,
        where: (a) => a.roleId.equals(id),
        transaction: transaction,
      );
      if (users > 0) {
        throw DeletionBlockedException(
          message:
              '${role.name} is used by $users '
              '${users == 1 ? 'agent' : 'agents'} — give them another role '
              'first',
          reason: DeletionBlockReason.roleInUse,
        );
      }
      await AgentRoleDefinition.db.deleteRow(
        session,
        role,
        transaction: transaction,
      );
    });
  }

  /// Trims the fields and rejects an empty name or prompt, or a name
  /// another role already has.
  Future<AgentRoleDefinition> _validated(
    Session session,
    AgentRoleDefinition role,
  ) async {
    final name = role.name.trim();
    final prompt = role.prompt.trim();
    final description = role.description?.trim();
    if (name.isEmpty) {
      throw InvalidStateException(message: 'A role needs a name');
    }
    if (prompt.isEmpty) {
      throw InvalidStateException(message: 'A role needs a prompt');
    }
    final clash = await AgentRoleDefinition.db.findFirstRow(
      session,
      where: (r) =>
          r.name.ilike(name) &
          (role.id == null ? Constant.bool(true) : r.id.notEquals(role.id)),
    );
    if (clash != null) {
      throw InvalidStateException(message: 'A role named $name already exists');
    }
    return role.copyWith(
      name: name,
      prompt: prompt,
      description: (description?.isEmpty ?? true) ? null : description,
    );
  }
}
