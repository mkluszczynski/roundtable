import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../cubits/agent_list_cubit.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/machine_list_cubit.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/machine_os_description.dart';
import '../utils/relative_time.dart';
import '../widgets/usage_limit_note.dart';
import '../widgets/add_agent_dialog.dart';
import '../widgets/add_machine_dialog.dart';
import '../widgets/agent_row.dart';
import '../widgets/app_card.dart';
import '../widgets/app_modal.dart';
import '../widgets/claude_token_dialog.dart';
import '../widgets/claude_warning_banner.dart';
import '../widgets/machine_online_delete_blocked_dialog.dart';
import '../widgets/machine_metrics.dart';
import '../widgets/runner_update_banner.dart';
import '../widgets/status_pill.dart';
import '../widgets/tag_chip.dart';
import '../widgets/toolchain_chips.dart';
import 'machine_detail_screen.dart';

/// Machines, each with the agents hosted on it folded in underneath — per
/// the design brief's nav rail, there's no separate top-level Agents screen
/// (`docs/UI-DESIGN.md` §3).
class MachinesScreen extends StatelessWidget {
  const MachinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    builder: (_) => MachineOnlineDeleteBlockedDialog(
                      scriptUrl: state.scriptUrl,
                    ),
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

/// A manual masonry split rather than `GridView` — card heights vary with
/// each machine's agent count. The column count follows the width.
class _MachinesGrid extends StatelessWidget {
  const _MachinesGrid({required this.machines, required this.agents});

  final List<Machine> machines;
  final List<Agent> agents;

  static const _columnWidth = 460.0;

  @override
  Widget build(BuildContext context) {
    final sorted = [
      ...machines.where((m) => m.status == MachineStatus.online),
      ...machines.where((m) => m.status != MachineStatus.online),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / _columnWidth).floor().clamp(
          1,
          4,
        );
        final columns = List.generate(count, (_) => <Machine>[]);
        for (var i = 0; i < sorted.length; i++) {
          columns[i % count].add(sorted[i]);
        }
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
              for (final (i, items) in columns.indexed) ...[
                if (i > 0) const SizedBox(width: Spacing.xl),
                Expanded(
                  child: Column(
                    children: [
                      for (final machine in items)
                        _MachineCard(
                          machine: machine,
                          agents: agents
                              .where((a) => a.machineId == machine.id)
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MachineCard extends StatelessWidget {
  const _MachineCard({required this.machine, required this.agents});

  final Machine machine;
  final List<Agent> agents;

  RunnerUpdateStatus _updateStatus(BuildContext context) {
    final state = context.read<MachineListCubit>().state;
    return runnerUpdateStatus(
      installedVersion: machine.runnerVersion,
      latestVersion: state is MachineListLoaded
          ? state.latestRunnerVersion
          : null,
      updateRequestedAt: machine.updateRequestedAt,
      busy: agents.any((a) => a.status != AgentStatus.idle),
    );
  }

  /// Updating restarts the daemon, which waits for its agents to finish
  /// their current work first (docs/FLOWS.md §2), so no confirmation needed.
  Future<void> _update(BuildContext context) =>
      context.read<MachineListCubit>().requestRunnerUpdate(machine.id!);

  Future<void> _confirmRemove(BuildContext context) async {
    final cubit = context.read<MachineListCubit>();
    final confirmed = await showAppModal<bool>(
      context,
      icon: Icons.delete_outline,
      tone: AppModalTone.danger,
      title: 'Remove ${machine.name}?',
      subtitle: agents.isEmpty
          ? 'The machine is unregistered from Roundtable.'
          : 'Its ${agents.length} agent${agents.length == 1 ? '' : 's'} '
                'will be removed too.',
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
    if (confirmed ?? false) await cubit.deleteMachine(machine.id!);
  }

  void _setClaudeToken(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<MachineListCubit>(),
      child: ClaudeTokenDialog(machine: machine),
    ),
  );

  Future<void> _addAgent(BuildContext context) async {
    final cubit = context.read<AgentListCubit>();
    final added = await showDialog<bool>(
      context: context,
      builder: (_) =>
          AddAgentDialog(machineId: machine.id!, machineName: machine.name),
    );
    if (added ?? false) cubit.fetchAgents();
  }

  @override
  Widget build(BuildContext context) {
    final online = machine.status == MachineStatus.online;
    final updateStatus = _updateStatus(context);
    final dashboard = context.watch<DashboardCubit>().state;
    final lastSeen = machine.lastSeenAt;
    final osDescription = machine.osDescription;
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.dns_outlined,
                    size: 18,
                    color: online ? AppColors.text0 : AppColors.text2,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        machine.name,
                        style: AppTypography.bodyStrong,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          StatusDot.fromAppearance(
                            machineStatusAppearance(machine.status),
                          ),
                          const SizedBox(width: Spacing.xs),
                          Text(
                            online
                                ? 'online'
                                : lastSeen == null
                                ? 'offline'
                                : 'offline · seen ${relativeTime(lastSeen)}',
                            style: AppTypography.caption,
                          ),
                          if (osDescription != null) ...[
                            Text('  ·  ', style: AppTypography.caption),
                            Flexible(
                              child: Text(
                                osDescription,
                                style: AppTypography.code,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (updateStatus == RunnerUpdateStatus.upToDate)
                  const TagChip('runner up to date'),
                PopupMenuButton<void Function(BuildContext)>(
                  tooltip: 'Machine actions',
                  color: AppColors.bg2,
                  icon: const Icon(Icons.more_horiz, color: AppColors.text1),
                  onSelected: (action) => action(context),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _addAgent,
                      child: const Text('Add agent'),
                    ),
                    if (updateStatus == RunnerUpdateStatus.available)
                      PopupMenuItem(
                        value: _update,
                        child: const Text('Update runner'),
                      ),
                    PopupMenuItem(
                      value: _setClaudeToken,
                      enabled: online && machine.claudeAuthSource != null,
                      child: const Text('Set Claude token'),
                    ),
                    PopupMenuItem(
                      value: _confirmRemove,
                      child: Text(
                        'Remove machine',
                        style: TextStyle(color: AppColors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (updateStatus != RunnerUpdateStatus.upToDate) ...[
              const SizedBox(height: Spacing.md),
              RunnerUpdateBanner(
                status: updateStatus,
                onUpdate: () => _update(context),
              ),
            ],
            if (UsageLimitNote.isActive(machine.usageLimitedUntil)) ...[
              const SizedBox(height: Spacing.md),
              UsageLimitNote(until: machine.usageLimitedUntil),
            ],
            if (ClaudeAuthStatus.needsAttention(machine)) ...[
              const SizedBox(height: Spacing.md),
              ClaudeAuthStatus(machine: machine, compact: true),
            ],
            if (machine.claudeExecutableOk == false) ...[
              const SizedBox(height: Spacing.md),
              ClaudeWarningBanner(
                message:
                    machine.claudeExecutableError ??
                    'claude CLI could not be launched.',
              ),
            ],
            if (online) ...[
              const SizedBox(height: Spacing.lg),
              MachineMetrics(machineId: machine.id!),
            ],
            const SizedBox(height: Spacing.md),
            ToolchainChips(toolchain: machine.toolchain),
            const SizedBox(height: Spacing.lg),
            Divider(height: 1, color: AppColors.border),
            const SizedBox(height: Spacing.md),
            Text('AGENTS · ${agents.length}', style: AppTypography.label),
            const SizedBox(height: Spacing.sm),
            for (final agent in agents)
              AgentRow(
                agent: agent,
                currentTask: dashboard is DashboardLoaded
                    ? dashboard.currentTaskFor(agent.id!)
                    : null,
                trailing: _AgentMenu(agent: agent, machine: machine),
              ),
            const SizedBox(height: Spacing.sm),
            _AddAgentRow(onTap: () => _addAgent(context)),
          ],
        ),
      ),
    );
  }
}

class _AddAgentRow extends StatelessWidget {
  const _AddAgentRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 14, color: AppColors.text1),
            const SizedBox(width: Spacing.xs),
            Text(
              'Add agent',
              style: AppTypography.caption.copyWith(color: AppColors.text1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edit / delete actions for one agent row on a machine card.
class _AgentMenu extends StatelessWidget {
  const _AgentMenu({required this.agent, required this.machine});

  final Agent agent;
  final Machine machine;

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<AgentListCubit>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AddAgentDialog(
        machineId: machine.id!,
        machineName: machine.name,
        existingAgent: agent,
      ),
    );
    if (saved ?? false) cubit.fetchAgents();
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<AgentListCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showAppModal<bool>(
      context,
      icon: Icons.delete_outline,
      tone: AppModalTone.danger,
      title: 'Delete ${agent.name}?',
      subtitle: machine.name,
      child: Text(
        'Its finished tasks stay on the board without an agent.',
        style: AppTypography.body,
      ),
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
            child: const Text('Delete'),
          ),
        ),
      ],
    );
    if (confirmed != true) return;
    final failure = await cubit.deleteAgent(agent.id!);
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void Function(BuildContext)>(
      tooltip: 'Agent actions',
      color: AppColors.bg2,
      iconSize: 16,
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_horiz, color: AppColors.text2),
      onSelected: (action) => action(context),
      itemBuilder: (_) => [
        PopupMenuItem(value: _edit, child: const Text('Edit')),
        PopupMenuItem(
          value: _delete,
          child: Text('Delete', style: TextStyle(color: AppColors.red)),
        ),
      ],
    );
  }
}
