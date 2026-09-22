import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../repositories/machine_repository.dart';

sealed class AddMachineState {
  const AddMachineState();
}

class AddMachineInitial extends AddMachineState {
  const AddMachineInitial();
}

class AddMachineSubmitting extends AddMachineState {
  const AddMachineSubmitting();
}

/// The machine is registered — [token] is shown to the dev exactly once and
/// is never fetchable again (design doc §6.8).
class AddMachineRegistered extends AddMachineState {
  const AddMachineRegistered(this.machine, this.token);

  final Machine machine;
  final String token;
}

class AddMachineError extends AddMachineState {
  const AddMachineError(this.message);

  final String message;
}

class AddMachineCubit extends Cubit<AddMachineState> {
  AddMachineCubit(this._repository) : super(const AddMachineInitial());

  final MachineRepository _repository;

  Future<void> submit(String name, {String? hostInfo}) async {
    emit(const AddMachineSubmitting());
    try {
      final registration = await _repository.registerMachine(
        name,
        hostInfo: hostInfo,
      );
      emit(
        AddMachineRegistered(registration.machine, registration.token),
      );
    } catch (e) {
      emit(AddMachineError(e.toString()));
    }
  }
}
