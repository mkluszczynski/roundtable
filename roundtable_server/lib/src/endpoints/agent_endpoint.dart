import 'non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// CRUD for [Agent]. Deletion is blocked while the agent has a non-terminal
/// task (docs/ARCHITECTURE.md).
class AgentEndpoint extends Endpoint {
  Future<Agent> create(
    Session session,
    String name,
    int machineId, {
    int? roleId,
    String? defaultModel,
    AgentEffort? defaultEffort,
  }) async {
    if (await Machine.db.findById(session, machineId) == null) {
      throw NotFoundException(message: 'Machine $machineId not found');
    }
    return Agent.db.insertRow(
      session,
      Agent(
        name: name,
        machineId: machineId,
        roleId: roleId,
        defaultModel: defaultModel,
        defaultEffort: defaultEffort,
      ),
    );
  }

  /// With its role — the daemon builds the prompt prefix from it.
  Future<Agent?> get(Session session, int id) async {
    return Agent.db.findById(
      session,
      id,
      include: Agent.include(role: AgentRoleDefinition.include()),
    );
  }

  Future<List<Agent>> list(Session session) async {
    return Agent.db.find(
      session,
      include: Agent.include(role: AgentRoleDefinition.include()),
    );
  }

  /// Edits an agent's settings from the panel. The machine it lives on,
  /// its execution mode and its status can't be changed here — status is
  /// reported by the daemon through [setStatus].
  Future<Agent> update(Session session, Agent agent) async {
    await _requireAgent(session, agent.id!);
    return Agent.db.updateRow(
      session,
      agent,
      columns: (t) => [t.name, t.roleId, t.defaultModel, t.defaultEffort],
    );
  }

  /// Reports what an agent is doing (`idle`/`busy`/`waitingForResponse`),
  /// called by the daemon running its tasks and reviews.
  Future<Agent> setStatus(
    Session session,
    int agentId,
    AgentStatus status,
  ) async {
    var agent = await _requireAgent(session, agentId);
    return Agent.db.updateRow(
      session,
      agent.copyWith(status: status),
      columns: (t) => [t.status],
    );
  }

  Future<Agent> _requireAgent(
    Session session,
    int id, {
    Transaction? transaction,
  }) async {
    var agent = await Agent.db.findById(session, id, transaction: transaction);
    if (agent == null) {
      throw NotFoundException(message: 'Agent $id not found');
    }
    return agent;
  }

  Future<void> delete(Session session, int id) async {
    await guardedDelete(session, (transaction) async {
      var agent = await _requireAgent(session, id, transaction: transaction);

      var nonTerminalTaskCount = await Task.db.count(
        session,
        where: (t) =>
            t.agentId.equals(id) & t.status.inSet(nonTerminalTaskStatuses),
        transaction: transaction,
      );
      if (nonTerminalTaskCount > 0) {
        throw DeletionBlockedException(
          message: 'Cannot delete an agent with non-terminal tasks',
          reason: DeletionBlockReason.nonTerminalTasks,
        );
      }

      await Agent.db.deleteRow(session, agent, transaction: transaction);
    });
  }
}
