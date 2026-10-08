import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/cubits/machine_list_cubit.dart';
import 'package:roundtable_flutter/repositories/machine_repository.dart';

class _FakeMachineRepository implements MachineRepository {
  Object? updateFails;
  Completer<List<Machine>>? slowList;

  @override
  Future<List<Machine>> listMachines() =>
      slowList?.future ?? Future.value([Machine(id: 1, name: 'VPS')]);

  @override
  Future<String?> getLatestRunnerVersion() async => 'v2';

  @override
  Future<Machine> requestRunnerUpdate(int id) async {
    if (updateFails case final error?) throw error;
    return Machine(id: id, name: 'VPS');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a failed update request is returned, and the list stays', () async {
    final repository = _FakeMachineRepository()
      ..updateFails = Exception('machine is offline');
    final cubit = MachineListCubit(repository);
    await cubit.fetchMachines();

    final failure = await cubit.requestRunnerUpdate(1);

    expect(failure, contains('machine is offline'));
    expect(cubit.state, isA<MachineListLoaded>());
    await cubit.close();
  });

  test('a fetch finishing after the cubit closed is dropped quietly', () async {
    final repository = _FakeMachineRepository()
      ..slowList = Completer<List<Machine>>();
    final cubit = MachineListCubit(repository);
    final fetch = cubit.fetchMachines();
    await cubit.close();

    repository.slowList!.complete([Machine(id: 1, name: 'VPS')]);

    await expectLater(fetch, completes);
  });
}
