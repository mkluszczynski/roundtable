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
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/add_machine_dialog.dart';
import '../widgets/create_task_dialog.dart';
import '../widgets/kanban_column.dart';
import '../widgets/machine_summary_card.dart';

/// Live overview: a kanban board of tasks — every project's, or one picked
/// in the header — plus a machines panel. Management (add/edit/delete) stays
/// on the standalone Projects/Machines screens — this is a landing screen,
/// not a replacement for them.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// The project the board is filtered to; null shows every project.
  int? _projectId;

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
        BlocProvider(
          create: (_) =>
              ProjectListCubit(ProjectRepository(client))..fetchProjects(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardHeader(
            projectId: _projectId,
            onProjectChanged: (id) => setState(() => _projectId = id),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _KanbanBoard(projectId: _projectId)),
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

/// Title doubles as the project filter: "All projects" or one project.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.projectId,
    required this.onProjectChanged,
  });

  final int? projectId;
  final ValueChanged<int?> onProjectChanged;

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
          final projects = switch (projectState) {
            ProjectListLoaded(:final projects) => projects,
            _ => const <Project>[],
          };
          final project = projects.where((p) => p.id == projectId).firstOrNull;
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
                    DashboardLoaded(:final tasks) =>
                      tasks.values
                          .where(
                            (t) => project == null || t.projectId == project.id,
                          )
                          .length,
                    _ => 0,
                  };
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProjectFilter(
                              projects: projects,
                              selected: project,
                              onChanged: onProjectChanged,
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
                      Tooltip(
                        message: projects.isEmpty
                            ? 'Add a project first (Projects tab)'
                            : '',
                        child: FilledButton.icon(
                          onPressed: projects.isEmpty
                              ? null
                              : () => showDialog<void>(
                                  context: context,
                                  builder: (_) => CreateTaskDialog(
                                    initialProjectId: project?.id,
                                  ),
                                ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New task'),
                        ),
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

/// The screen title as a dropdown: "All projects" or a single project.
class _ProjectFilter extends StatelessWidget {
  const _ProjectFilter({
    required this.projects,
    required this.selected,
    required this.onChanged,
  });

  final List<Project> projects;
  final Project? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Text('No project yet', style: AppTypography.screenTitle);
    }
    return PopupMenuButton<int>(
      tooltip: 'Filter by project',
      color: AppColors.bg2,
      // -1 stands for "All projects": PopupMenuButton ignores a null value.
      onSelected: (id) => onChanged(id == -1 ? null : id),
      itemBuilder: (_) => [
        const PopupMenuItem(value: -1, child: Text('All projects')),
        for (final p in projects)
          PopupMenuItem(value: p.id!, child: Text(p.name)),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selected?.name ?? 'All projects',
            style: AppTypography.screenTitle,
          ),
          const SizedBox(width: Spacing.xs),
          Icon(Icons.expand_more, color: AppColors.text1),
        ],
      ),
    );
  }
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({required this.projectId});

  /// Null shows every project's tasks.
  final int? projectId;

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
          DashboardLoaded() => Padding(
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
                        tasks: state.columnsFor(projectId: projectId)[column]!,
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
