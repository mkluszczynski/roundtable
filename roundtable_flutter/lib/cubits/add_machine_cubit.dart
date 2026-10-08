import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../utils/safe_emit.dart';
import '../utils/error_message.dart';
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

/// The install command is ready and the dialog waits for install-agent.sh
/// to redeem it (docs/FLOWS.md §1). [machine] is set once it has.
class AddMachineCommandReady extends AddMachineState {
  const AddMachineCommandReady(this.command, {this.machine});

  final MachineInstallCommand command;
  final Machine? machine;
}

class AddMachineError extends AddMachineState {
  const AddMachineError(this.message);

  final String message;
}

class AddMachineCubit extends Cubit<AddMachineState>
    with SafeEmit<AddMachineState> {
  AddMachineCubit(
    this._repository, {
    this.pollInterval = const Duration(seconds: 3),
  }) : super(const AddMachineInitial());

  final MachineRepository _repository;
  final Duration pollInterval;
  Timer? _poll;

  /// [name] empty means the machine is named after its hostname.
  Future<void> submit(String name) async {
    _poll?.cancel();
    emit(const AddMachineSubmitting());
    final MachineInstallCommand command;
    try {
      command = await _repository.createInstallCommand(
        name: name.isEmpty ? null : name,
      );
    } catch (e) {
      if (!isClosed) emit(AddMachineError(errorMessage(e)));
      return;
    }
    // The dialog may have been closed while the request was in flight.
    if (isClosed) return;
    emit(AddMachineCommandReady(command));
    _poll = Timer.periodic(pollInterval, (_) => _checkEnrolled(command));
  }

  bool _checking = false;

  Future<void> _checkEnrolled(MachineInstallCommand command) async {
    // A slow server mustn't stack up overlapping polls.
    if (_checking) return;
    _checking = true;
    try {
      final machine = await _repository.enrolledMachine(command.enrollmentId);
      if (machine == null || isClosed) return;
      _poll?.cancel();
      emit(AddMachineCommandReady(command, machine: machine));
    } catch (_) {
      // A dropped request just waits for the next poll.
    } finally {
      _checking = false;
    }
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
