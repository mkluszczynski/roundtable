import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/agent_list_cubit.dart';
import '../cubits/machine_list_cubit.dart';
import '../repositories/agent_repository.dart';
import '../repositories/machine_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'agent_avatar.dart';
import 'status_pill.dart';
import 'tag_chip.dart';

/// Why an agent can't be picked, or null when it can.
typedef AgentAvailability = String? Function(Agent agent, Machine? machine);

/// Picks an agent from cards grouped by the machine hosting them, showing
/// each agent's role, model, effort and live status. Loads agents and
/// machines itself.
class AgentPicker extends StatelessWidget {
  const AgentPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.allowNone = false,
    this.noneLabel = 'None (draft)',
    this.noneHint = 'Save as a draft and assign an agent later',
    this.currentAgentId,
    this.unavailableReason,
  });

  final int? selected;
  final ValueChanged<int?> onChanged;

  /// Offers a "no agent" card on top, selected when [selected] is null.
  final bool allowNone;
  final String noneLabel;
  final String noneHint;

  /// Marked "current" — the agent the task already has.
  final int? currentAgentId;
  final AgentAvailability? unavailableReason;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AgentListCubit(AgentRepository(client))..fetchAgents(),
        ),
        BlocProvider(
          create: (_) =>
              MachineListCubit(MachineRepository(client))..fetchMachines(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final agentState = context.watch<AgentListCubit>().state;
          final machineState = context.watch<MachineListCubit>().state;
          if (agentState is AgentListError) {
            return Text(
              'Could not load agents: ${agentState.message}',
              style: AppTypography.body.copyWith(color: AppColors.red),
            );
          }
          if (agentState is! AgentListLoaded) {
            return const Padding(
              padding: EdgeInsets.all(Spacing.lg),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return AgentPickerList(
            agents: agentState.agents,
            // Without machines the cards still work, just ungrouped by
            // status — don't block picking on that request.
            machines: machineState is MachineListLoaded
                ? machineState.machines
                : const [],
            selected: selected,
            onChanged: onChanged,
            allowNone: allowNone,
            noneLabel: noneLabel,
            noneHint: noneHint,
            currentAgentId: currentAgentId,
            unavailableReason: unavailableReason,
          );
        },
      ),
    );
  }
}

/// The data-free part of [AgentPicker], for tests and callers that already
/// hold the lists.
class AgentPickerList extends StatelessWidget {
  const AgentPickerList({
    super.key,
    required this.agents,
    required this.machines,
    required this.selected,
    required this.onChanged,
    this.allowNone = false,
    this.noneLabel = 'None (draft)',
    this.noneHint = 'Save as a draft and assign an agent later',
    this.currentAgentId,
    this.unavailableReason,
  });

  final List<Agent> agents;
  final List<Machine> machines;
  final int? selected;
  final ValueChanged<int?> onChanged;
  final bool allowNone;
  final String noneLabel;
  final String noneHint;
  final int? currentAgentId;
  final AgentAvailability? unavailableReason;

  @override
  Widget build(BuildContext context) {
    final machinesById = {for (final m in machines) m.id: m};
    final groups = <int, List<Agent>>{};
    for (final agent in agents) {
      (groups[agent.machineId] ??= []).add(agent);
    }
    // Online machines first, then by name.
    final machineIds = groups.keys.toList()
      ..sort((a, b) {
        final ma = machinesById[a];
        final mb = machinesById[b];
        final onlineA = ma?.status == MachineStatus.online ? 0 : 1;
        final onlineB = mb?.status == MachineStatus.online ? 0 : 1;
        if (onlineA != onlineB) return onlineA - onlineB;
        return (ma?.name ?? '').compareTo(mb?.name ?? '');
      });

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 380),
      child: ListView(
        shrinkWrap: true,
        children: [
          if (allowNone)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: SelectableCard(
                selected: selected == null,
                onTap: () => onChanged(null),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.bg3,
                      child: Icon(
                        Icons.edit_note,
                        size: 14,
                        color: AppColors.text1,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(noneLabel, style: AppTypography.bodyStrong),
                          Text(noneHint, style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (agents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              child: Text(
                'No agents yet — add one from the Machines screen.',
                style: AppTypography.body.copyWith(color: AppColors.text1),
              ),
            ),
          for (final machineId in machineIds) ...[
            _MachineHeader(machine: machinesById[machineId]),
            for (final agent in groups[machineId]!)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: _AgentCard(
                  agent: agent,
                  machine: machinesById[machineId],
                  selected: selected == agent.id,
                  current: currentAgentId == agent.id,
                  unavailable: unavailableReason?.call(
                    agent,
                    machinesById[machineId],
                  ),
                  onTap: () => onChanged(agent.id),
                ),
              ),
            const SizedBox(height: Spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _MachineHeader extends StatelessWidget {
  const _MachineHeader({required this.machine});

  final Machine? machine;

  @override
  Widget build(BuildContext context) {
    final machine = this.machine;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        children: [
          const Icon(Icons.dns_outlined, size: 14, color: AppColors.text2),
          const SizedBox(width: Spacing.xs),
          Flexible(
            child: Text(
              (machine?.name ?? 'Unknown machine').toUpperCase(),
              style: AppTypography.label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (machine != null) ...[
            const SizedBox(width: Spacing.sm),
            StatusDot.fromAppearance(machineStatusAppearance(machine.status)),
            const SizedBox(width: Spacing.xs),
            Text(machine.status.name, style: AppTypography.caption),
          ],
        ],
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.agent,
    required this.machine,
    required this.selected,
    required this.current,
    required this.unavailable,
    required this.onTap,
  });

  final Agent agent;
  final Machine? machine;
  final bool selected;
  final bool current;
  final String? unavailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final offline = machine?.status == MachineStatus.offline;
    final note =
        unavailable ??
        (offline ? 'Machine offline — the task will wait' : null);
    return Opacity(
      opacity: unavailable != null || offline ? 0.55 : 1,
      child: SelectableCard(
        selected: selected,
        onTap: unavailable == null ? onTap : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentAvatar(name: agent.name),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          agent.name,
                          style: AppTypography.bodyStrong,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      StatusDot.fromAppearance(
                        agentStatusAppearance(agent.status),
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        _statusLabel(agent.status),
                        style: AppTypography.caption,
                      ),
                      if (current) ...[
                        const SizedBox(width: Spacing.sm),
                        const TagChip('current'),
                      ],
                    ],
                  ),
                  Text(
                    '${agent.role.name} specialist',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.xs,
                    runSpacing: Spacing.xs,
                    children: [
                      TagChip(agent.defaultModel ?? 'default model'),
                      TagChip(
                        'effort: ${agent.defaultEffort?.name ?? 'default'}',
                      ),
                    ],
                  ),
                  if (note != null) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      note,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(AgentStatus status) => switch (status) {
    AgentStatus.idle => 'idle',
    AgentStatus.busy => 'busy',
    AgentStatus.waitingForResponse => 'waiting',
  };
}

/// A bordered, tappable card that highlights when [selected] — the shared
/// look of every rich option list in dialogs. [onTap] null = not pickable.
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.bg2,
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Expanded(child: child),
              if (selected) ...[
                const SizedBox(width: Spacing.sm),
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
