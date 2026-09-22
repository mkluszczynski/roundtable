import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/agent_list_cubit.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/machine_list_cubit.dart';
import '../cubits/project_list_cubit.dart';
import '../repositories/agent_repository.dart';
import '../repositories/machine_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/add_machine_dialog.dart';
import '../widgets/create_task_dialog.dart';
import '../widgets/kanban_column.dart';
import '../widgets/machine_summary_card.dart';

/// Live overview: a kanban board of every task (design doc §4 "Should"
/// kanban) plus a machines panel. Management (add/edit/delete) stays on the
/// standalone Projects/Machines screens — this is a landing screen, not a
/// replacement for them.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DashboardCubit(TaskRepository(client))..subscribe(),
        ),
        BlocProvider(
          create: (_) =>
              MachineListCubit(MachineRepository(client))..fetchMachines(),
        ),
        BlocProvider(
          create: (_) => AgentListCubit(AgentRepository(client))..fetchAgents(),
        ),
        BlocProvider(
          create: (_) =>
              ProjectListCubit(ProjectRepository(client))..fetchProjects(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DashboardHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 3, child: _KanbanBoard()),
                VerticalDivider(width: 1, color: AppColors.border),
                const SizedBox(width: 280, child: _MachinesPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The dashboard shows a single "current" project — the first one returned
/// by the server. Multi-project dashboards aren't in the Must scope (design
/// doc §4); once project switching exists this becomes a real selection.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.xl,
        Spacing.xl,
        0,
      ),
      child: BlocBuilder<ProjectListCubit, ProjectListState>(
        builder: (context, projectState) {
          final project = switch (projectState) {
            ProjectListLoaded(:final projects) when projects.isNotEmpty =>
              projects.first,
            _ => null,
          };
          return BlocBuilder<MachineListCubit, MachineListState>(
            builder: (context, machineState) {
              final machineCount = switch (machineState) {
                MachineListLoaded(:final machines) => machines.length,
                _ => 0,
              };
              return BlocBuilder<AgentListCubit, AgentListState>(
                builder: (context, agentState) {
                  final agents = switch (agentState) {
                    AgentListLoaded(:final agents) => agents,
                    _ => const <Agent>[],
                  };
                  final taskCount = switch (context
                      .watch<DashboardCubit>()
                      .state) {
                    DashboardLoaded(:final tasks) => tasks.length,
                    _ => 0,
                  };
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project?.name ?? 'No project yet',
                              style: AppTypography.screenTitle,
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              '$machineCount machines · '
                              '${agents.length} agents · $taskCount tasks',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: project == null
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                builder: (_) => const CreateTaskDialog(),
                              ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New task'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard();

  static const _titles = {
    KanbanColumn.backlog: 'Backlog',
    KanbanColumn.inProgress: 'In progress',
    KanbanColumn.review: 'Review',
    KanbanColumn.done: 'Done',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return switch (state) {
          DashboardLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          DashboardError(:final message) => Center(
            child: Text(
              'Failed to load tasks: $message',
              style: AppTypography.body.copyWith(color: AppColors.red),
            ),
          ),
          DashboardLoaded(:final columns) => Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final column in KanbanColumn.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                      ),
                      child: KanbanColumnView(
                        title: _titles[column]!,
                        tasks: columns[column]!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        };
      },
    );
  }
}

class _MachinesPanel extends StatelessWidget {
  const _MachinesPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MACHINES', style: AppTypography.label),
          const SizedBox(height: Spacing.md),
          Expanded(
            child: BlocBuilder<MachineListCubit, MachineListState>(
              builder: (context, state) {
                return switch (state) {
                  MachineListInitial() ||
                  MachineListLoading() ||
                  MachineDeletionBlockedOnline() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  MachineListError(:final message) => Text(
                    'Failed to load machines: $message',
                    style: AppTypography.body.copyWith(color: AppColors.red),
                  ),
                  MachineListLoaded(:final machines) =>
                    BlocBuilder<AgentListCubit, AgentListState>(
                      builder: (context, agentState) {
                        final agents = switch (agentState) {
                          AgentListLoaded(:final agents) => agents,
                          _ => const <Agent>[],
                        };
                        return machines.isEmpty
                            ? Text(
                                'No machines yet',
                                style: AppTypography.caption,
                              )
                            : ListView(
                                children: [
                                  for (final machine in machines)
                                    MachineSummaryCard(
                                      machine: machine,
                                      agents: agents
                                          .where(
                                            (a) => a.machineId == machine.id,
                                          )
                                          .toList(),
                                    ),
                                ],
                              );
                      },
                    ),
                };
              },
            ),
          ),
          const SizedBox(height: Spacing.sm),
          OutlinedButton.icon(
            onPressed: () async {
              final cubit = context.read<MachineListCubit>();
              final added = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const AddMachineDialog(),
              );
              if (added ?? false) cubit.fetchMachines();
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add machine'),
          ),
        ],
      ),
    );
  }
}
