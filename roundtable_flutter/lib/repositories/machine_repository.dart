import 'package:roundtable_client/roundtable_client.dart';

class MachineRepository {
  MachineRepository(this._client);

  final Client _client;

  Future<List<Machine>> listMachines() => _client.machine.list();

  Future<Machine?> getMachine(int id) => _client.machine.get(id);

  /// A one-time install token for a new machine, valid for an hour. The
  /// machine itself appears only once install-agent.sh redeems it
  /// (docs/FLOWS.md §1). A null [name] means the machine's hostname.
  Future<MachineInstallCommand> createInstallCommand({String? name}) =>
      _client.machine.createEnrollment(name: name);

  /// The machine created from install command [enrollmentId], or null
  /// while it hasn't been run yet.
  Future<Machine?> enrolledMachine(int enrollmentId) =>
      _client.machine.enrolledMachine(enrollmentId);

  /// Sends a Claude Code OAuth token to machine [id]'s daemon, which picks
  /// it up at its next check-in (docs/FLOWS.md §1).
  Future<Machine> setClaudeToken(int id, String token) =>
      _client.machine.setClaudeToken(id, token);

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
