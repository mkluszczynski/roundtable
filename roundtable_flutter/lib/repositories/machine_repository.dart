import 'package:roundtable_client/roundtable_client.dart';

class MachineRepository {
  MachineRepository(this._client);

  final Client _client;

  Future<List<Machine>> listMachines() => _client.machine.list();

  Future<Machine?> getMachine(int id) => _client.machine.get(id);

  /// Registers a new machine, returning it along with the one-time raw
  /// registration token — only ever available here, never persisted or
  /// re-fetchable (docs/FLOWS.md §1–3).
  Future<MachineRegistration> registerMachine(
    String name, {
    String? hostInfo,
  }) => _client.machine.register(name, hostInfo: hostInfo);

  Future<void> deleteMachine(int id) => _client.machine.delete(id);

  /// Base URL the install/uninstall scripts are served from — used to render
  /// a working uninstall command when deletion is blocked (docs/FLOWS.md §1–3).
  Future<String> getScriptUrl() => _client.machine.getScriptUrl();

  /// Version of the agent-runner binaries the server currently serves, or
  /// null if they can't be built — compared against
  /// [Machine.runnerVersion] to offer an update.
  Future<String?> getLatestRunnerVersion() =>
      _client.machine.latestRunnerVersion();

  /// Asks the machine's daemon to update itself on its next check-in.
  Future<Machine> requestRunnerUpdate(int id) =>
      _client.machine.requestRunnerUpdate(id);

  Stream<MachineMetric> watchLatestMetric(int machineId) =>
      _client.machine.watchLatestMetric(machineId);
}
