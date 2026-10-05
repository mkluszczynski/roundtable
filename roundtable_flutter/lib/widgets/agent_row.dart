import 'package:flutter/material.dart';
import '../utils/agent_role_label.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../screens/task_detail_screen.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/task_status_label.dart';
import 'agent_avatar.dart';
import 'status_pill.dart';
import 'tag_chip.dart';
import '../utils/task_title.dart';

/// One agent in a machine's list: avatar, name with live status, role and
/// — when it has one — the task it's on, linked to that task.
class AgentRow extends StatelessWidget {
  const AgentRow({
    super.key,
    required this.agent,
    this.currentTask,
    this.showDetails = true,
    this.trailing,
  });

  final Agent agent;
  final Task? currentTask;

  /// Shows the role and model/effort chips; off for compact lists.
  final bool showDetails;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final task = currentTask;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgentAvatar(name: agent.name),
          const SizedBox(width: Spacing.sm),
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
                      agentStatusLabel(agent.status),
                      style: AppTypography.caption,
                    ),
                    if (showDetails) ...[
                      const Spacer(),
                      Text(
                        agent.roleLabel,
                        style: AppTypography.caption,
                      ),
                    ],
                  ],
                ),
                if (task != null) ...[
                  const SizedBox(height: 2),
                  _CurrentTaskLink(task: task),
                ],
                if (showDetails) ...[
                  const SizedBox(height: Spacing.xs),
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
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

String agentStatusLabel(AgentStatus status) => switch (status) {
  AgentStatus.idle => 'idle',
  AgentStatus.busy => 'busy',
  AgentStatus.waitingForResponse => 'waiting',
};

class _CurrentTaskLink extends StatelessWidget {
  const _CurrentTaskLink({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final appearance = taskStatusAppearance(task.status);
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskDetailScreen(initialTaskId: task.id!),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.subdirectory_arrow_right,
            size: 12,
            color: appearance.color,
          ),
          const SizedBox(width: Spacing.xs),
          Text('#${task.id}', style: AppTypography.code),
          const SizedBox(width: Spacing.xs),
          Text(
            task.status.label,
            style: AppTypography.caption.copyWith(color: appearance.color),
          ),
          const SizedBox(width: Spacing.xs),
          Expanded(
            child: Text(
              taskDisplayTitle(task),
              style: AppTypography.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
