import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../client.dart';
import '../cubits/machine_list_cubit.dart';
import '../cubits/machine_metric_cubit.dart';
import '../repositories/machine_repository.dart';
import '../widgets/machine_online_delete_blocked_dialog.dart';

class MachinesScreen extends StatelessWidget {
  const MachinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MachineListCubit(MachineRepository(client))..fetchMachines(),
      child: BlocConsumer<MachineListCubit, MachineListState>(
        listener: (context, state) {
          if (state is MachineDeletionBlockedOnline) {
            showDialog<void>(
              context: context,
              builder: (_) => const MachineOnlineDeleteBlockedDialog(),
            );
          } else if (state is MachineListError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            MachineListInitial() ||
            MachineListLoading() ||
            MachineDeletionBlockedOnline() => const Center(
              child: CircularProgressIndicator(),
            ),
            MachineListError(:final message) => Center(
              child: Text('Failed to load machines: $message'),
            ),
            MachineListLoaded(:final machines) =>
              machines.isEmpty
                  ? const Center(child: Text('No machines yet'))
                  : ListView.builder(
                      itemCount: machines.length,
                      itemBuilder: (context, index) {
                        final machine = machines[index];
                        return ListTile(
                          leading: const Icon(Icons.computer),
                          title: Text(machine.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(machine.status.name),
                              BlocProvider(
                                create: (_) => MachineMetricCubit(
                                  MachineRepository(client),
                                  machine.id!,
                                ),
                                child:
                                    BlocBuilder<
                                      MachineMetricCubit,
                                      MachineMetricState
                                    >(
                                      builder: (context, metricState) =>
                                          switch (metricState) {
                                            MachineMetricInitial() =>
                                              const SizedBox.shrink(),
                                            MachineMetricLoaded(
                                              :final metric,
                                            ) =>
                                              Text(
                                                'CPU ${metric.cpuPercent.toStringAsFixed(0)}% · '
                                                'RAM ${metric.memoryUsedMb}/${metric.memoryTotalMb} MB',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                          },
                                    ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => context
                                .read<MachineListCubit>()
                                .deleteMachine(machine.id!),
                          ),
                        );
                      },
                    ),
          };
        },
      ),
    );
  }
}
