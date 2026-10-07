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
import '../utils/agent_role_label.dart';
import 'agent_avatar.dart';

/// Picks a reviewer agent from a menu styled like the dashboard's project
/// filter: avatar, name, role and machine per agent, the current one
/// checked. Uses the panel's shared `AgentListCubit`/`MachineListCubit`
/// when an ancestor provides them, so an agent added elsewhere shows up
/// right away (the Settings tab is kept alive by the panel's
/// IndexedStack); inside dialogs outside the panel's providers it loads
/// agents and machines itself.
class ReviewerSelect extends StatefulWidget {
  const ReviewerSelect({
    super.key,
    required this.selected,
    required this.onChanged,
    this.noneLabel = 'No reviewer',
    this.noneSubtitle = 'Reviews only when you request one',
    this.inherits = false,
    this.inheritedAgentId,
    this.width = 260,
  });

  final int? selected;
  final ValueChanged<int?> onChanged;

  /// The "no agent" entry, selected when [selected] is null — e.g.
  /// "Workspace default" for a project that inherits the reviewer.
  final String noneLabel;
  final String noneSubtitle;

  /// Whether the "no agent" entry inherits a reviewer from elsewhere — it
  /// then names [inheritedAgentId] in brackets, like the other inherited
  /// defaults ("Workspace default (Rex)").
  final bool inherits;
  final int? inheritedAgentId;
  final double width;

  @override
  State<ReviewerSelect> createState() => _ReviewerSelectState();
}

class _ReviewerSelectState extends State<ReviewerSelect> {
  List<Agent>? _agents;
  Map<int, String> _machineNames = const {};

  @override
  void initState() {
    super.initState();
    if (context.read<AgentListCubit?>() == null) _load();
  }

  Future<void> _load() async {
    try {
      final agents = await AgentRepository(client).listAgents();
      final machines = await MachineRepository(
        client,
      ).listMachines().catchError((_) => <Machine>[]);
      if (!mounted) return;
      setState(() {
        _agents = agents..sort((a, b) => a.name.compareTo(b.name));
        _machineNames = {for (final m in machines) m.id!: m.name};
      });
    } catch (_) {
      if (mounted) setState(() => _agents = const []);
    }
  }

  /// The shared list when the panel provides one, else the self-loaded
  /// one; null while loading. Keeps the last loaded shared list through a
  /// failed refresh, so the chosen reviewer isn't shown as deleted.
  List<Agent>? _watchAgents(BuildContext context) {
    final shared = context.watch<AgentListCubit?>();
    if (shared == null) return _agents;
    return switch (shared.state) {
      AgentListLoaded(:final agents) => _agents = [
        ...agents,
      ]..sort((a, b) => a.name.compareTo(b.name)),
      AgentListError() => _agents ?? const [],
      _ => _agents,
    };
  }

  /// Keeps the last loaded names through the shared cubit's transient
  /// states (e.g. `MachineDeletionBlockedOnline`) until its refetch lands.
  Map<int, String> _watchMachineNames(BuildContext context) {
    final state = context.watch<MachineListCubit?>()?.state;
    if (state is MachineListLoaded) {
      _machineNames = {for (final m in state.machines) m.id!: m.name};
    }
    return _machineNames;
  }

  Agent? _agent(List<Agent>? agents, int? id) =>
      id == null ? null : agents?.where((a) => a.id == id).firstOrNull;

  String _noneTitle(List<Agent>? agents) {
    if (!widget.inherits) return widget.noneLabel;
    final inherited = _agent(agents, widget.inheritedAgentId);
    return '${widget.noneLabel} (${inherited?.name ?? 'none'})';
  }

  String _subtitle(Agent agent, Map<int, String> machineNames) {
    final machine = machineNames[agent.machineId];
    return machine == null
        ? agent.roleLabel
        : '${agent.roleLabel} · on $machine';
  }

  @override
  Widget build(BuildContext context) {
    final agents = _watchAgents(context);
    final machineNames = _watchMachineNames(context);
    final selected = _agent(agents, widget.selected);
    final noneTitle = _noneTitle(agents);
    return SizedBox(
      width: widget.width,
      child: PopupMenuButton<int>(
        enabled: agents != null,
        tooltip: 'Pick the reviewer',
        color: AppColors.bg1,
        position: PopupMenuPosition.under,
        offset: const Offset(0, Spacing.xs),
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 320),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.borderStrong),
        ),
        // -1 stands for "no agent": PopupMenuButton ignores a null value.
        onSelected: (id) => widget.onChanged(id == -1 ? null : id),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: -1,
            padding: EdgeInsets.zero,
            child: _Option(
              leading: const Icon(
                Icons.person_off_outlined,
                size: 18,
                color: AppColors.text1,
              ),
              title: noneTitle,
              subtitle: widget.noneSubtitle,
              selected: widget.selected == null,
              dividerBelow: true,
            ),
          ),
          for (final agent in agents ?? const <Agent>[])
            PopupMenuItem(
              value: agent.id!,
              padding: EdgeInsets.zero,
              child: _Option(
                leading: AgentAvatar(name: agent.name),
                title: agent.name,
                subtitle: _subtitle(agent, machineNames),
                selected: widget.selected == agent.id,
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (selected != null) ...[
                AgentAvatar(name: selected.name),
                const SizedBox(width: Spacing.sm),
              ],
              Expanded(
                child: agents == null
                    ? Text('Loading agents…', style: AppTypography.caption)
                    : Text(
                        selected?.name ??
                            (widget.selected == null
                                ? noneTitle
                                : 'Deleted agent'),
                        style: AppTypography.body.copyWith(
                          color: selected == null
                              ? AppColors.text1
                              : AppColors.text0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              if (selected != null)
                Text(selected.roleLabel, style: AppTypography.caption),
              const SizedBox(width: Spacing.xs),
              const Icon(Icons.unfold_more, size: 16, color: AppColors.text1),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.dividerBelow = false,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final bool selected;

  /// Separates the "no agent" entry from the agents with the menu's own
  /// hairline (PopupMenuDivider uses the brighter theme divider).
  final bool dividerBelow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.accent.withValues(alpha: 0.12) : null,
        border: dividerBelow
            ? Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyStrong,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (selected) ...[
            const SizedBox(width: Spacing.sm),
            const Icon(Icons.check, size: 16, color: AppColors.accentSoft),
          ],
        ],
      ),
    );
  }
}
