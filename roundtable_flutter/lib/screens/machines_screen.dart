import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/agent_list_cubit.dart';
import '../cubits/machine_list_cubit.dart';
import '../cubits/machine_metric_cubit.dart';
import '../repositories/agent_repository.dart';
import '../repositories/machine_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/relative_time.dart';
import '../widgets/add_agent_dialog.dart';
import '../widgets/add_machine_dialog.dart';
import '../widgets/app_card.dart';
import '../widgets/machine_online_delete_blocked_dialog.dart';
import '../widgets/metric_bar.dart';
import '../widgets/status_pill.dart';
import 'machine_detail_screen.dart';

/// Machines, each with the agents hosted on it folded in underneath — per
/// the design brief's nav rail, there's no separate top-level Agents screen
/// (`docs/UI-DESIGN.md` §3).
class MachinesScreen extends StatelessWidget {
  const MachinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              MachineListCubit(MachineRepository(client))..fetchMachines(),
        ),
        BlocProvider(
          create: (_) => AgentListCubit(AgentRepository(client))..fetchAgents(),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MachinesHeader(),
            Expanded(
              child: BlocConsumer<MachineListCubit, MachineListState>(
                listener: (context, state) {
                  if (state is MachineDeletionBlockedOnline) {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const MachineOnlineDeleteBlockedDialog(),
                    );
                  } else if (state is MachineListError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
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
                      child: Text(
                        'Failed to load machines: $message',
                        style: AppTypography.body.copyWith(
                          color: AppColors.red,
                        ),
                      ),
                    ),
                    MachineListLoaded(:final machines) =>
                      machines.isEmpty
                          ? Center(
                              child: Text(
                                'No machines yet',
                                style: AppTypography.body,
                              ),
                            )
                          : BlocBuilder<AgentListCubit, AgentListState>(
                              builder: (context, agentState) {
                                final agents = switch (agentState) {
                                  AgentListLoaded(:final agents) => agents,
                                  _ => const <Agent>[],
                                };
                                return _MachinesGrid(
                                  machines: machines,
                                  agents: agents,
                                );
                              },
                            ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MachinesHeader extends StatelessWidget {
  const _MachinesHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: BlocBuilder<MachineListCubit, MachineListState>(
        builder: (context, state) {
          final machines = switch (state) {
            MachineListLoaded(:final machines) => machines,
            _ => const <Machine>[],
          };
          final online = machines
              .where((m) => m.status == MachineStatus.online)
              .length;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Machines', style: AppTypography.screenTitle),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '${machines.length} machines · $online online',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final cubit = context.read<MachineListCubit>();
                  final added = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const AddMachineDialog(),
                  );
                  if (added ?? false) cubit.fetchMachines();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add machine'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A manual 2-column split rather than `GridView` — card heights vary with
/// each machine's agent count, and `GridView`'s fixed-cell-height model
/// doesn't accommodate that without a masonry-grid dependency.
class _MachinesGrid extends StatelessWidget {
  const _MachinesGrid({required this.machines, required this.agents});

  final List<Machine> machines;
  final List<Agent> agents;

  @override
  Widget build(BuildContext context) {
    final left = <Machine>[];
    final right = <Machine>[];
    for (var i = 0; i < machines.length; i++) {
      (i.isEven ? left : right).add(machines[i]);
    }

    Widget column(List<Machine> items) => Expanded(
      child: Column(
        children: [
          for (final machine in items)
            _MachineCard(
              machine: machine,
              agents: agents.where((a) => a.machineId == machine.id).toList(),
            ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        0,
        Spacing.xl,
        Spacing.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          column(left),
          const SizedBox(width: Spacing.xl),
          column(right),
        ],
      ),
    );
  }
}

class _MachineCard extends StatelessWidget {
  const _MachineCard({required this.machine, required this.agents});

  final Machine machine;
  final List<Agent> agents;

  @override
  Widget build(BuildContext context) {
    final online = machine.status == MachineStatus.online;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: AppCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MachineDetailScreen(machineId: machine.id!),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusDot.fromAppearance(
                  machineStatusAppearance(machine.status),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(machine.name, style: AppTypography.bodyStrong),
                ),
                if (machine.hostInfo != null)
                  Text(machine.hostInfo!, style: AppTypography.code),
              ],
            ),
            if (online) ...[
              const SizedBox(height: Spacing.md),
              BlocProvider(
                create: (_) =>
                    MachineMetricCubit(MachineRepository(client), machine.id!),
                child: BlocBuilder<MachineMetricCubit, MachineMetricState>(
                  builder: (context, state) => switch (state) {
                    MachineMetricInitial() => const SizedBox.shrink(),
                    MachineMetricLoaded(:final metric) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MetricBar(
                          label: 'CPU',
                          fraction: metric.cpuPercent / 100,
                          valueLabel:
                              '${metric.cpuPercent.toStringAsFixed(0)}%',
                        ),
                        const SizedBox(height: Spacing.xs),
                        MetricBar(
                          label: 'RAM',
                          fraction: metric.memoryTotalMb == 0
                              ? 0
                              : metric.memoryUsedMb / metric.memoryTotalMb,
                          valueLabel:
                              '${(metric.memoryUsedMb / 1024).toStringAsFixed(1)}G',
                        ),
                      ],
                    ),
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: Spacing.md),
              Text(
                machine.lastSeenAt == null
                    ? 'Offline'
                    : 'Offline — last seen ${relativeTime(machine.lastSeenAt!)}',
                style: AppTypography.caption.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: Spacing.lg),
            Divider(height: 1, color: AppColors.border),
            const SizedBox(height: Spacing.md),
            Text('AGENTS', style: AppTypography.label),
            const SizedBox(height: Spacing.sm),
            if (agents.isEmpty)
              Text(
                'No agents on this machine yet',
                style: AppTypography.caption,
              )
            else
              for (final agent in agents)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      StatusDot.fromAppearance(
                        agentStatusAppearance(agent.status),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(agent.name, style: AppTypography.body),
                      ),
                      Text(agent.role.name, style: AppTypography.caption),
                    ],
                  ),
                ),
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final cubit = context.read<AgentListCubit>();
                      final added = await showDialog<bool>(
                        context: context,
                        builder: (_) => AddAgentDialog(
                          machineId: machine.id!,
                          machineName: machine.name,
                        ),
                      );
                      if (added ?? false) cubit.fetchAgents();
                    },
                    child: const Text('+ Add agent'),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: BorderSide(
                      color: AppColors.red.withValues(alpha: 0.4),
                    ),
                  ),
                  onPressed: () =>
                      context.read<MachineListCubit>().deleteMachine(
                        machine.id!,
                      ),
                  child: const Text('Remove machine'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
