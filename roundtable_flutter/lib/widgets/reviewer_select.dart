import 'package:flutter/material.dart';
import '../utils/agent_role_label.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../repositories/agent_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'agent_avatar.dart';

/// A compact agent dropdown for settings and forms where the full
/// `AgentPicker` cards don't fit (rails, settings rows). Loads the agents
/// itself, so it also works inside dialogs outside the panel's providers.
class ReviewerSelect extends StatefulWidget {
  const ReviewerSelect({
    super.key,
    required this.selected,
    required this.onChanged,
    this.noneLabel = 'No reviewer',
    this.width = 220,
  });

  final int? selected;
  final ValueChanged<int?> onChanged;
  final String noneLabel;
  final double width;

  @override
  State<ReviewerSelect> createState() => _ReviewerSelectState();
}

class _ReviewerSelectState extends State<ReviewerSelect> {
  List<Agent>? _agents;

  @override
  void initState() {
    super.initState();
    AgentRepository(client)
        .listAgents()
        .then((agents) {
          if (mounted) setState(() => _agents = agents);
        })
        .catchError((_) {
          if (mounted) setState(() => _agents = const []);
        });
  }

  @override
  Widget build(BuildContext context) {
    final agents = _agents;
    final selected = agents?.where((a) => a.id == widget.selected).firstOrNull;
    return SizedBox(
      width: widget.width,
      child: PopupMenuButton<int?>(
        enabled: agents != null,
        tooltip: 'Pick the reviewer',
        color: AppColors.bg2,
        position: PopupMenuPosition.under,
        onSelected: widget.onChanged,
        itemBuilder: (_) => [
          PopupMenuItem<int?>(
            value: null,
            child: Text(widget.noneLabel, style: AppTypography.body),
          ),
          for (final agent in agents ?? const <Agent>[])
            PopupMenuItem<int?>(
              value: agent.id,
              child: _AgentLabel(agent: agent),
            ),
        ],
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bg2,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: agents == null
                      ? Text('Loading…', style: AppTypography.caption)
                      : selected == null
                      ? Text(
                          widget.selected == null
                              ? widget.noneLabel
                              : 'Deleted agent',
                          style: AppTypography.body.copyWith(
                            color: AppColors.text1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : _AgentLabel(agent: selected),
                ),
                const Icon(
                  Icons.expand_more,
                  size: 16,
                  color: AppColors.text1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgentLabel extends StatelessWidget {
  const _AgentLabel({required this.agent});

  final Agent agent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AgentAvatar(name: agent.name),
        const SizedBox(width: Spacing.sm),
        Flexible(
          child: Text(
            agent.name,
            style: AppTypography.body,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Text(agent.roleLabel, style: AppTypography.caption),
      ],
    );
  }
}
