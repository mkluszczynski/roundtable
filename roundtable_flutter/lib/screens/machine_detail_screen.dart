import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/agent_list_cubit.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/machine_metric_cubit.dart';
import '../cubits/project_list_cubit.dart';
import '../repositories/agent_repository.dart';
import '../repositories/machine_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/relative_time.dart';
import '../widgets/add_agent_dialog.dart';
import '../widgets/agent_avatar.dart';
import '../widgets/app_card.dart';
import '../widgets/metric_bar.dart';
import '../widgets/status_pill.dart';
import '../widgets/tag_chip.dart';

/// One machine: resources, its agents, and its recent tasks — pushed from
/// `machines_screen.dart`.
class MachineDetailScreen extends StatefulWidget {
  const MachineDetailScreen({super.key, required this.machineId});

  final int machineId;

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  late final _machineRepository = MachineRepository(client);
  late final Future<Machine?> _machineFuture = _machineRepository.getMachine(
    widget.machineId,
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AgentListCubit(AgentRepository(client))..fetchAgents(),
        ),
        BlocProvider(
          create: (_) =>
              ProjectListCubit(ProjectRepository(client))..fetchProjects(),
        ),
        BlocProvider(
          create: (_) => DashboardCubit(TaskRepository(client))..subscribe(),
        ),
        BlocProvider(
          create: (_) =>
              MachineMetricCubit(_machineRepository, widget.machineId),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: FutureBuilder<Machine?>(
          future: _machineFuture,
          builder: (context, snapshot) {
            final machine = snapshot.data;
            if (machine == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _MachineDetailBody(machine: machine);
          },
        ),
      ),
    );
  }
}

class _MachineDetailBody extends StatelessWidget {
  const _MachineDetailBody({required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(machine: machine),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ResourcesCard(machineId: machine.id!),
                        const SizedBox(height: Spacing.xxl),
                        _AgentsCard(machineId: machine.id!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.xxl),
                SizedBox(
                  width: 340,
                  child: _RecentTasksPanel(machineId: machine.id!),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (machine.hostInfo != null) machine.hostInfo!,
      'registered ${relativeTime(machine.createdAt, words: true)}',
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xl,
        vertical: Spacing.lg,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text1),
            onPressed: () => Navigator.of(context).pop(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: Spacing.sm),
          StatusDot.fromAppearance(machineStatusAppearance(machine.status)),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(machine.name, style: AppTypography.screenTitle),
                Text(meta, style: AppTypography.code),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AddAgentDialog(
                machineId: machine.id!,
                machineName: machine.name,
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add agent'),
          ),
        ],
      ),
    );
  }
}

class _ResourcesCard extends StatelessWidget {
  const _ResourcesCard({required this.machineId});

  final int machineId;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RESOURCES', style: AppTypography.label),
          const SizedBox(height: Spacing.lg),
          BlocBuilder<MachineMetricCubit, MachineMetricState>(
            builder: (context, state) => switch (state) {
              MachineMetricInitial() => Text(
                'No metrics reported yet',
                style: AppTypography.caption,
              ),
              MachineMetricLoaded(:final metric) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MetricBar(
                    label: 'CPU',
                    fraction: metric.cpuPercent / 100,
                    valueLabel: '${metric.cpuPercent.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: Spacing.sm),
                  MetricBar(
                    label: 'RAM',
                    fraction: metric.memoryTotalMb == 0
                        ? 0
                        : metric.memoryUsedMb / metric.memoryTotalMb,
                    valueLabel:
                        '${(metric.memoryUsedMb / 1024).toStringAsFixed(1)}G',
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'Snapshot · last reported ${relativeTime(metric.recordedAt)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _AgentsCard extends StatelessWidget {
  const _AgentsCard({required this.machineId});

  final int machineId;

  @override
  Widget build(BuildContext context) {
    final agents = switch (context.watch<AgentListCubit>().state) {
      AgentListLoaded(:final agents) =>
        agents.where((a) => a.machineId == machineId).toList(),
      _ => const <Agent>[],
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AGENTS ON THIS MACHINE', style: AppTypography.label),
          const SizedBox(height: Spacing.md),
          if (agents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              child: Text(
                'No agents on this machine yet',
                style: AppTypography.caption,
              ),
            )
          else
            for (var i = 0; i < agents.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                decoration: BoxDecoration(
                  border: i == agents.length - 1
                      ? null
                      : Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    AgentAvatar(name: agents[i].name),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agents[i].name,
                            style: AppTypography.bodyStrong,
                          ),
                          Text(
                            '${agents[i].role.name} specialist',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: Spacing.xs,
                      children: [
                        TagChip(agents[i].defaultModel ?? 'default model'),
                        TagChip(
                          agents[i].defaultEffort?.name ?? 'default effort',
                        ),
                      ],
                    ),
                    const SizedBox(width: Spacing.md),
                    StatusPill.fromAppearance(
                      agentStatusAppearance(agents[i].status),
                      label: switch (agents[i].status) {
                        AgentStatus.idle => 'Idle',
                        AgentStatus.busy => 'Busy',
                        AgentStatus.waitingForResponse => 'Waiting',
                      },
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _RecentTasksPanel extends StatelessWidget {
  const _RecentTasksPanel({required this.machineId});

  final int machineId;

  @override
  Widget build(BuildContext context) {
    final agentIds = switch (context.watch<AgentListCubit>().state) {
      AgentListLoaded(:final agents) =>
        agents.where((a) => a.machineId == machineId).map((a) => a.id).toSet(),
      _ => const <int?>{},
    };
    final agentsById = switch (context.watch<AgentListCubit>().state) {
      AgentListLoaded(:final agents) => {
        for (final a in agents) a.id: a,
      },
      _ => const <int?, Agent>{},
    };
    final projectsById = switch (context.watch<ProjectListCubit>().state) {
      ProjectListLoaded(:final projects) => {
        for (final p in projects) p.id: p,
      },
      _ => const <int?, Project>{},
    };
    final tasks = switch (context.watch<DashboardCubit>().state) {
      DashboardLoaded(:final tasks) =>
        tasks.values.where((t) => agentIds.contains(t.agentId)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      _ => const <Task>[],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT TASKS ON THIS MACHINE', style: AppTypography.label),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: tasks.isEmpty
              ? Text('No tasks yet', style: AppTypography.caption)
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final agent = agentsById[task.agentId];
                    final project = projectsById[task.projectId];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.md),
                      child: AppCard(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.prompt, style: AppTypography.bodyStrong),
                            const SizedBox(height: Spacing.sm),
                            StatusPill.fromAppearance(
                              taskStatusAppearance(task.status),
                              label: task.status.name,
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(
                              '${agent?.name ?? 'Unassigned'} · '
                              '${project?.name ?? '…'}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
