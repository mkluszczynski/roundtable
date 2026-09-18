import 'non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// CRUD for [Machine]. Deletion is blocked while the machine is `online`, or
/// while any of its agents has a non-terminal task (design doc §5, §6.8).
class MachineEndpoint extends Endpoint {
  Future<Machine> create(Session session, String name) async {
    return Machine.db.insertRow(session, Machine(name: name));
  }

  Future<Machine?> get(Session session, int id) async {
    return Machine.db.findById(session, id);
  }

  Future<List<Machine>> list(Session session) async {
    return Machine.db.find(session);
  }

  Future<Machine> update(Session session, Machine machine) async {
    return Machine.db.updateRow(session, machine);
  }

  Future<void> delete(Session session, int id) async {
    var machine = await Machine.db.findById(session, id);
    if (machine == null) {
      throw Exception('Machine $id not found');
    }

    if (machine.status == MachineStatus.online) {
      throw DeletionBlockedException(
        message: 'Cannot delete an online machine',
      );
    }

    var agentIds = (await Agent.db.find(
      session,
      where: (t) => t.machineId.equals(id),
    )).map((agent) => agent.id!).toSet();

    var nonTerminalTaskCount = await Task.db.count(
      session,
      where: (t) =>
          t.agentId.inSet(agentIds) & t.status.inSet(nonTerminalTaskStatuses),
    );
    if (nonTerminalTaskCount > 0) {
      throw DeletionBlockedException(
        message: 'Cannot delete a machine with non-terminal tasks',
      );
    }

    await Machine.db.deleteRow(session, machine);
  }
}
