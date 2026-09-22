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
  static String _channelForMachineMetrics(int machineId) =>
      'machine-$machineId-metrics';

  Future<MachineRegistration> register(
    Session session,
    String name, {
    String? hostInfo,
  }) async {
    final token = _generateRegistrationToken();
    final machine = await Machine.db.insertRow(
      session,
      Machine(name: name, hostInfo: hostInfo, tokenHash: _hashToken(token)),
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

  /// Called periodically by the agent-runner daemon on a registered
  /// machine. Marks the machine online and refreshes [Machine.lastSeenAt].
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine (unknown, or revoked via [deregister]).
  Future<void> heartbeat(Session session, String token) async {
    final machine = await _findByToken(session, token);
    await Machine.db.updateRow(
      session,
      machine.copyWith(
        status: MachineStatus.online,
        lastSeenAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// Called by the uninstall script as a deliberate deregistration, so the
  /// server doesn't have to wait for the heartbeat timeout to notice the
  /// machine is gone (design doc §6.8). Marks the machine offline and clears
  /// [Machine.tokenHash] so the raw token can never match again.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<void> deregister(Session session, String token) async {
    final machine = await _findByToken(session, token);
    await Machine.db.updateRow(
      session,
      machine.copyWith(status: MachineStatus.offline, tokenHash: null),
    );
  }

  /// Resolves the [Machine] a registration token belongs to, without
  /// mutating heartbeat state. Used by the agent-runner daemon at startup to
  /// learn its own machine id before subscribing to
  /// [TaskEndpoint.watchAssignedTasks] (design doc §6.1).
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<Machine> identify(Session session, String token) async {
    return _findByToken(session, token);
  }

  /// Called periodically by the agent-runner daemon (design doc §6.9). Stores
  /// a new [MachineMetric] row and notifies [watchLatestMetric] subscribers.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<void> reportMetric(
    Session session,
    String token,
    double cpuPercent,
    int memoryUsedMb,
    int memoryTotalMb,
  ) async {
    final machine = await _findByToken(session, token);
    final metric = await MachineMetric.db.insertRow(
      session,
      MachineMetric(
        machineId: machine.id!,
        cpuPercent: cpuPercent,
        memoryUsedMb: memoryUsedMb,
        memoryTotalMb: memoryTotalMb,
      ),
    );
    await session.messages.postMessage(
      _channelForMachineMetrics(machine.id!),
      metric,
    );
  }

  /// Streams the latest [MachineMetric] for [machineId] (design doc §6.9
  /// snapshot) — replays the current latest row on subscribe, then yields
  /// each new one as [reportMetric] stores it.
  Stream<MachineMetric> watchLatestMetric(
    Session session,
    int machineId,
  ) async* {
    final latest = await MachineMetric.db.findFirstRow(
      session,
      where: (t) => t.machineId.equals(machineId),
      orderBy: (t) => t.recordedAt.desc(),
    );
    if (latest != null) yield latest;

    final updates = session.messages.createStream<MachineMetric>(
      _channelForMachineMetrics(machineId),
    );
    await for (final metric in updates) {
      yield metric;
    }
  }

  Future<Machine> _findByToken(Session session, String token) async {
    final machine = await Machine.db.findFirstRow(
      session,
      where: (t) => t.tokenHash.equals(_hashToken(token)),
    );
    if (machine == null) {
      throw InvalidTokenException(
        message: 'Unknown or revoked registration token',
      );
    }
    return machine;
  }

  Future<void> delete(Session session, int id) async {
    var machine = await Machine.db.findById(session, id);
    if (machine == null) {
      throw Exception('Machine $id not found');
    }

    if (machine.status == MachineStatus.online) {
      throw DeletionBlockedException(
        message: 'Cannot delete an online machine',
        reason: DeletionBlockReason.machineOnline,
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
        reason: DeletionBlockReason.nonTerminalTasks,
      );
    }

    await Machine.db.deleteRow(session, machine);
  }
}
