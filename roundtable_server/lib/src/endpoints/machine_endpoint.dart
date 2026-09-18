import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Generates a cryptographically secure, high-entropy registration token.
String _generateRegistrationToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Hashes a raw token for storage; only the hash is ever persisted.
String _hashToken(String token) {
  return sha256.convert(utf8.encode(token)).toString();
}

/// Registration and CRUD for [Machine]. Deletion is blocked while the machine
/// is `online`, or while any of its agents has a non-terminal task (design
/// doc §5, §6.8).
class MachineEndpoint extends Endpoint {
  Future<MachineRegistration> register(Session session, String name) async {
    final token = _generateRegistrationToken();
    final machine = await Machine.db.insertRow(
      session,
      Machine(name: name, tokenHash: _hashToken(token)),
    );
    return MachineRegistration(machine: machine, token: token);
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
