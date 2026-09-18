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
}
