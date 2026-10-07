import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/cubits/add_machine_cubit.dart';
import 'package:roundtable_flutter/repositories/machine_repository.dart';

class _FakeMachineRepository implements MachineRepository {
  String? requestedName = 'unset';
  Completer<void>? gate;
  var polls = 0;
  Machine? enrolled;

  @override
  Future<MachineInstallCommand> createInstallCommand({String? name}) async {
    requestedName = name;
    await gate?.future;
    return MachineInstallCommand(
      enrollmentId: 7,
      enrollmentToken: 'tok',
      expiresAt: DateTime(2030),
      serverUrl: 'http://api',
      scriptUrl: 'http://web',
    );
  }

  @override
  Future<Machine?> enrolledMachine(int enrollmentId) async {
    polls++;
    return enrolled;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('an empty name leaves naming to the hostname', () async {
    final repository = _FakeMachineRepository();
    final cubit = AddMachineCubit(repository);

    await cubit.submit('');

    expect(repository.requestedName, isNull);
    expect(cubit.state, isA<AddMachineCommandReady>());
    await cubit.close();
  });

  test('the machine shows up once the install script has run', () async {
    final repository = _FakeMachineRepository();
    final cubit = AddMachineCubit(
      repository,
      pollInterval: const Duration(milliseconds: 10),
    );
    await cubit.submit('vps');
    expect((cubit.state as AddMachineCommandReady).machine, isNull);

    repository.enrolled = Machine(id: 3, name: 'vps');
    final ready = await cubit.stream.first as AddMachineCommandReady;

    expect(ready.machine?.name, 'vps');
    await cubit.close();
  });

  test('closing the dialog mid-request neither emits nor polls', () async {
    final repository = _FakeMachineRepository()..gate = Completer<void>();
    final cubit = AddMachineCubit(
      repository,
      pollInterval: const Duration(milliseconds: 10),
    );
    final submitted = cubit.submit('vps');
    await cubit.close();
    repository.gate!.complete();
    await submitted;

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(repository.polls, 0);
  });
}
