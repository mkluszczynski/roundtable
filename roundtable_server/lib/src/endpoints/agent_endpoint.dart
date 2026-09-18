import 'non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// CRUD for [Agent]. Deletion is blocked while the agent has a non-terminal
/// task (design doc §5, §6.8).
class AgentEndpoint extends Endpoint {
  Future<Agent> create(
    Session session,
    String name,
    int machineId, {
    AgentRole role = AgentRole.generalist,
    String? defaultModel,
    AgentEffort? defaultEffort,
  }) async {
    return Agent.db.insertRow(
      session,
      Agent(
        name: name,
        machineId: machineId,
        role: role,
        defaultModel: defaultModel,
        defaultEffort: defaultEffort,
      ),
    );
  }

  Future<Agent?> get(Session session, int id) async {
    return Agent.db.findById(session, id);
  }

  Future<List<Agent>> list(Session session) async {
    return Agent.db.find(session);
  }

  Future<Agent> update(Session session, Agent agent) async {
    return Agent.db.updateRow(session, agent);
  }

  Future<void> delete(Session session, int id) async {
    var agent = await Agent.db.findById(session, id);
    if (agent == null) {
      throw Exception('Agent $id not found');
    }

    var nonTerminalTaskCount = await Task.db.count(
      session,
      where: (t) =>
          t.agentId.equals(id) & t.status.inSet(nonTerminalTaskStatuses),
    );
    if (nonTerminalTaskCount > 0) {
      throw DeletionBlockedException(
        message: 'Cannot delete an agent with non-terminal tasks',
      );
    }

    await Agent.db.deleteRow(session, agent);
  }
}
