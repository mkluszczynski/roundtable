import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../repositories/machine_repository.dart';

sealed class MachineListState {
  const MachineListState();
}

class MachineListInitial extends MachineListState {
  const MachineListInitial();
}

class MachineListLoading extends MachineListState {
  const MachineListLoading();
}

class MachineListLoaded extends MachineListState {
  const MachineListLoaded(this.machines);

  final List<Machine> machines;
}

class MachineListError extends MachineListState {
  const MachineListError(this.message);

  final String message;
}

/// Emitted transiently when a delete attempt is blocked because the machine
/// is still `online` (design doc §6.8) — the panel reacts by showing the
/// uninstall-command dialog instead of a plain error. Always followed by a
/// fresh [MachineListLoaded]/[MachineListError] from a re-fetch.
class MachineDeletionBlockedOnline extends MachineListState {
  const MachineDeletionBlockedOnline();
}

class MachineListCubit extends Cubit<MachineListState> {
  MachineListCubit(this._repository) : super(const MachineListInitial());

  final MachineRepository _repository;

  Future<void> fetchMachines() async {
    emit(const MachineListLoading());
    try {
      final machines = await _repository.listMachines();
      emit(MachineListLoaded(machines));
    } catch (e) {
      emit(MachineListError(e.toString()));
    }
  }

  Future<void> deleteMachine(int id) async {
    try {
      await _repository.deleteMachine(id);
    } on DeletionBlockedException catch (e) {
      if (e.reason == DeletionBlockReason.machineOnline) {
        emit(const MachineDeletionBlockedOnline());
      } else {
        emit(MachineListError(e.message));
      }
    } catch (e) {
      emit(MachineListError(e.toString()));
    }
    await fetchMachines();
  }
}
