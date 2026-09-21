import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../repositories/machine_repository.dart';

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

/// Wraps [MachineRepository.watchLatestMetric] for a single machine (design
/// doc §6.9 snapshot).
class MachineMetricCubit extends Cubit<MachineMetricState> {
  MachineMetricCubit(this._repository, this._machineId)
    : super(const MachineMetricInitial()) {
    _subscription = _repository
        .watchLatestMetric(_machineId)
        .listen(
          (metric) => emit(MachineMetricLoaded(metric)),
        );
  }

  final MachineRepository _repository;
  final int _machineId;
  late final StreamSubscription<MachineMetric> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
