import 'package:roundtable_client/roundtable_client.dart';

class MachineRepository {
  MachineRepository(this._client);

  final Client _client;

  Future<List<Machine>> listMachines() => _client.machine.list();

  Future<Machine?> getMachine(int id) => _client.machine.get(id);

  /// Registers a new machine, returning it along with the one-time raw
  /// registration token — only ever available here, never persisted or
  /// re-fetchable (design doc §6.8).
  Future<MachineRegistration> registerMachine(
    String name, {
    String? hostInfo,
  }) => _client.machine.register(name, hostInfo: hostInfo);

  Future<void> deleteMachine(int id) => _client.machine.delete(id);

  Stream<MachineMetric> watchLatestMetric(int machineId) =>
      _client.machine.watchLatestMetric(machineId);
}
