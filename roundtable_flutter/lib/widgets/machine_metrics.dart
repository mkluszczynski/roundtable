import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/machine_metric_cubit.dart';
import '../repositories/machine_repository.dart';
import '../theme/spacing.dart';
import 'metric_bar.dart';

/// Live CPU/RAM bars for one machine, fed by its own [MachineMetricCubit].
/// Renders nothing until the first sample arrives.
class MachineMetrics extends StatelessWidget {
  const MachineMetrics({super.key, required this.machineId});

  final int machineId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MachineMetricCubit(MachineRepository(client), machineId),
      child: BlocBuilder<MachineMetricCubit, MachineMetricState>(
        builder: (context, state) => switch (state) {
          MachineMetricInitial() => const SizedBox.shrink(),
          MachineMetricLoaded(:final metric) => MachineMetricBars(
            metric: metric,
          ),
        },
      ),
    );
  }
}

/// The CPU and RAM [MetricBar]s for one [metric] sample.
class MachineMetricBars extends StatelessWidget {
  const MachineMetricBars({super.key, required this.metric});

  final MachineMetric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetricBar(
          label: 'CPU',
          fraction: metric.cpuPercent / 100,
          valueLabel: '${metric.cpuPercent.toStringAsFixed(0)}%',
        ),
        const SizedBox(height: Spacing.xs),
        MetricBar(
          label: 'RAM',
          fraction: metric.memoryTotalMb == 0
              ? 0
              : metric.memoryUsedMb / metric.memoryTotalMb,
          valueLabel: '${(metric.memoryUsedMb / 1024).toStringAsFixed(1)}G',
        ),
      ],
    );
  }
}
