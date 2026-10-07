import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/agent_list_cubit.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/machine_list_cubit.dart';
import '../cubits/machine_metric_cubit.dart';
import '../cubits/project_list_cubit.dart';
import '../repositories/machine_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/error_message.dart';
import '../utils/machine_os_description.dart';
import '../utils/relative_time.dart';
import '../widgets/usage_limit_note.dart';
import '../widgets/add_agent_dialog.dart';
import '../widgets/agent_row.dart';
import '../widgets/app_card.dart';
import '../widgets/app_modal.dart';
import '../widgets/claude_warning_banner.dart';
import '../widgets/kanban_card.dart';
import '../widgets/load_failed_view.dart';
import '../widgets/machine_online_delete_blocked_dialog.dart';
import '../widgets/metric_bar.dart';
import '../widgets/rail_section.dart';
import '../widgets/runner_update_banner.dart';
import '../widgets/status_pill.dart';
import '../widgets/toolchain_chips.dart';
import 'task_detail_screen.dart';

/// One machine: a rail with status, resources, runner/CLI health and
/// actions, next to its agents and recent tasks — pushed from
/// `machines_screen.dart`.
class MachineDetailScreen extends StatefulWidget {
  const MachineDetailScreen({super.key, required this.machineId});

  final int machineId;

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  late final _machineRepository = MachineRepository(client);
  late Future<Machine?> _machineFuture = _machineRepository.getMachine(
    widget.machineId,
  );

  void _reload() {
    setState(
      () => _machineFuture = _machineRepository.getMachine(widget.machineId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return LoadFailedView(
                title: "Couldn't load this machine",
                message: errorMessage(snapshot.error!),
                onRetry: _reload,
              );
            }
            final machine = snapshot.data;
            if (machine == null) {
              return const LoadFailedView(
                title: 'Machine not found',
                message: 'It may have been deleted.',
              );
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

  /// As loaded when the screen opened; the live copy from
  /// `MachineListCubit` wins once it's there (status, runner version).
  final Machine machine;

  @override
  Widget build(BuildContext context) {
    final machineState = context.watch<MachineListCubit>().state;
    final live = machineState is MachineListLoaded
        ? machineState.machines.where((m) => m.id == machine.id).firstOrNull
        : null;
    final current = live ?? machine;
    return BlocListener<MachineListCubit, MachineListState>(
      listener: (context, state) {
        if (state is MachineDeletionBlockedOnline) {
          showDialog<void>(
            context: context,
            builder: (_) =>
                MachineOnlineDeleteBlockedDialog(scriptUrl: state.scriptUrl),
          );
        } else if (state is MachineListError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(machine: current),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 300, child: _MachineRail(machine: current)),
                VerticalDivider(width: 1, color: AppColors.border),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.xl),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: _AgentsCard(machine: current),
                          ),
                        ),
                        const SizedBox(width: Spacing.xxl),
                        SizedBox(
                          width: 380,
                          child: _RecentTasksPanel(machineId: current.id!),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Machine identity only; everything else lives in the rail.
class _Header extends StatelessWidget {
  const _Header({required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context) {
    final online = machine.status == MachineStatus.online;
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
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, color: AppColors.text1),
            onPressed: () => Navigator.of(context).pop(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: Spacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.dns_outlined,
                size: 18,
                color: AppColors.accentSoft,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Flexible(
            child: Text(
              machine.name,
              style: AppTypography.screenTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: Spacing.md),
          StatusPill.fromAppearance(
            machineStatusAppearance(machine.status),
            label: online ? 'Online' : 'Offline',
          ),
        ],
      ),
    );
  }
}

class _MachineRail extends StatelessWidget {
  const _MachineRail({required this.machine});

  final Machine machine;

  RunnerUpdateStatus _updateStatus(
    MachineListState state,
    List<Agent> agents,
  ) => runnerUpdateStatus(
    installedVersion: machine.runnerVersion,
    latestVersion: state is MachineListLoaded
        ? state.latestRunnerVersion
        : null,
    updateRequestedAt: machine.updateRequestedAt,
    busy: agents.any((a) => a.status != AgentStatus.idle),
  );

  Future<void> _remove(BuildContext context, int agentCount) async {
    final cubit = context.read<MachineListCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showAppModal<bool>(
      context,
      icon: Icons.delete_outline,
      tone: AppModalTone.danger,
      title: 'Remove ${machine.name}?',
      subtitle: agentCount == 0
          ? 'The machine is unregistered from Roundtable.'
          : 'Its $agentCount agent${agentCount == 1 ? '' : 's'} will be '
                'removed too.',
      child: const SizedBox.shrink(),
      actions: [
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ),
        Builder(
          builder: (context) => FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ),
      ],
    );
    if (!(confirmed ?? false)) return;
    await cubit.deleteMachine(machine.id!);
    final state = cubit.state;
    if (state is MachineListLoaded &&
        !state.machines.any((m) => m.id == machine.id)) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final machineState = context.watch<MachineListCubit>().state;
    final agents = switch (context.watch<AgentListCubit>().state) {
      AgentListLoaded(:final agents) =>
        agents.where((a) => a.machineId == machine.id).toList(),
      _ => const <Agent>[],
    };
    final online = machine.status == MachineStatus.online;
    final lastSeen = machine.lastSeenAt;
    final osDescription = machine.osDescription;
    final updateStatus = _updateStatus(machineState, agents);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RailSection(
                  label: 'Status',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        online
                            ? 'Online'
                            : lastSeen == null
                            ? 'Offline — never seen'
                            : 'Offline — last seen ${relativeTime(lastSeen)}',
                        style: AppTypography.bodyStrong,
                      ),
                      if (osDescription != null)
                        Text(osDescription, style: AppTypography.code),
                      Text(
                        'Registered '
                        '${relativeTime(machine.createdAt, words: true)}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                RailSection(
                  label: 'Resources',
                  child: online
                      ? const _Resources()
                      : Text(
                          'Available while the machine is online.',
                          style: AppTypography.caption,
                        ),
                ),
                RailSection(
                  label: 'Agent runner',
                  child: updateStatus == RunnerUpdateStatus.upToDate
                      ? const _CheckLine(ok: true, text: 'Up to date')
                      : RunnerUpdateBanner(
                          status: updateStatus,
                          onUpdate: () => context
                              .read<MachineListCubit>()
                              .requestRunnerUpdate(machine.id!),
                        ),
                ),
                RailSection(
                  label: 'Toolchain',
                  child: ToolchainChips(toolchain: machine.toolchain),
                ),
                if (UsageLimitNote.isActive(machine.usageLimitedUntil))
                  RailSection(
                    label: 'Claude usage',
                    child: UsageLimitNote(until: machine.usageLimitedUntil),
                  ),
                RailSection(
                  label: 'Claude CLI',
                  child: switch (machine.claudeExecutableOk) {
                    true => const _CheckLine(ok: true, text: 'Working'),
                    false => ClaudeWarningBanner(
                      message:
                          machine.claudeExecutableError ??
                          'claude CLI could not be launched.',
                    ),
                    null => Text(
                      'Not checked yet',
                      style: AppTypography.caption,
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
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
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add agent'),
              ),
              const SizedBox(height: Spacing.sm),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: BorderSide(color: AppColors.red.withValues(alpha: 0.5)),
                ),
                onPressed: () => _remove(context, agents.length),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Remove machine'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.error_outline,
          size: 16,
          color: ok ? AppColors.live : AppColors.warning,
        ),
        const SizedBox(width: Spacing.sm),
        Text(text, style: AppTypography.body),
      ],
    );
  }
}

class _Resources extends StatelessWidget {
  const _Resources();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MachineMetricCubit, MachineMetricState>(
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
              valueLabel: '${(metric.memoryUsedMb / 1024).toStringAsFixed(1)}G',
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Last reported ${relativeTime(metric.recordedAt)}',
              style: AppTypography.caption,
            ),
          ],
        ),
      },
    );
  }
}

class _AgentsCard extends StatelessWidget {
  const _AgentsCard({required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context) {
    final agents = switch (context.watch<AgentListCubit>().state) {
      AgentListLoaded(:final agents) =>
        agents.where((a) => a.machineId == machine.id).toList(),
      _ => const <Agent>[],
    };
    final dashboard = context.watch<DashboardCubit>().state;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AGENTS · ${agents.length}', style: AppTypography.label),
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
            for (final (i, agent) in agents.indexed)
              Container(
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                decoration: BoxDecoration(
                  border: i == agents.length - 1
                      ? null
                      : Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: AgentRow(
                  agent: agent,
                  currentTask: dashboard is DashboardLoaded
                      ? dashboard.currentTaskFor(agent.id!)
                      : null,
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
    final agents = switch (context.watch<AgentListCubit>().state) {
      AgentListLoaded(:final agents) =>
        agents.where((a) => a.machineId == machineId).toList(),
      _ => const <Agent>[],
    };
    final agentsById = {for (final a in agents) a.id: a};
    final projectsById = switch (context.watch<ProjectListCubit>().state) {
      ProjectListLoaded(:final projects) => {
        for (final p in projects) p.id: p,
      },
      _ => const <int?, Project>{},
    };
    final tasks = switch (context.watch<DashboardCubit>().state) {
      DashboardLoaded(:final tasks) =>
        tasks.values.where((t) => agentsById.containsKey(t.agentId)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      _ => const <Task>[],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT TASKS · ${tasks.length}', style: AppTypography.label),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: tasks.isEmpty
              ? Text('No tasks yet', style: AppTypography.caption)
              : ListView(
                  children: [
                    for (final task in tasks)
                      KanbanCard(
                        task: task,
                        agentName: agentsById[task.agentId]?.name,
                        projectName: projectsById[task.projectId]?.name,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TaskDetailScreen(initialTaskId: task.id!),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
