import 'package:roundtable_client/roundtable_client.dart';

class MachineRepository {
  MachineRepository(this._client);

  final Client _client;

  Future<List<Machine>> listMachines() => _client.machine.list();

  Future<void> deleteMachine(int id) => _client.machine.delete(id);
}
