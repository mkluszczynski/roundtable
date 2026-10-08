import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../repositories/machine_repository.dart';
import '../utils/closeable_streams.dart';

sealed class MachineMetricState {
  const MachineMetricState();
}

class MachineMetricInitial extends MachineMetricState {
  const MachineMetricInitial();
}

class MachineMetricLoaded extends MachineMetricState {
  const MachineMetricLoaded(this.metric);

  final MachineMetric metric;
}

/// Wraps [MachineRepository.watchLatestMetric] for a single machine
/// (docs/FLOWS.md §6 snapshot), reconnecting when the stream drops.
class MachineMetricCubit extends Cubit<MachineMetricState>
    with CloseableStreams<MachineMetricState> {
  MachineMetricCubit(this._repository, this._machineId)
    : super(const MachineMetricInitial()) {
    unawaited(_watch());
  }

  final MachineRepository _repository;
  final int _machineId;

  Future<void> _watch() async {
    await for (final metric in keepAlive(
      () => _repository.watchLatestMetric(_machineId),
    )) {
      emit(MachineMetricLoaded(metric));
    }
  }
}
