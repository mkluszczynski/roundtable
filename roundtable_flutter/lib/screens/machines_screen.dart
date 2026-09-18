import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../client.dart';
import '../cubits/machine_list_cubit.dart';
import '../repositories/machine_repository.dart';

class MachinesScreen extends StatelessWidget {
  const MachinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MachineListCubit(MachineRepository(client))..fetchMachines(),
      child: BlocBuilder<MachineListCubit, MachineListState>(
        builder: (context, state) {
          return switch (state) {
            MachineListInitial() || MachineListLoading() => const Center(
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
                          subtitle: Text(machine.status.name),
                        );
                      },
                    ),
          };
        },
      ),
    );
  }
}
