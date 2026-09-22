import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_card.dart';
import 'status_pill.dart';

/// A single task on the dashboard's kanban board. Tapping it navigates to
/// `task_detail_screen.dart` for that task — the first real list→detail
/// navigation path in the app.
class KanbanCard extends StatelessWidget {
  const KanbanCard({
    super.key,
    required this.task,
    required this.onTap,
    this.agentName,
    this.machineName,
  });

  final Task task;
  final VoidCallback onTap;

  /// Resolved from `Task.agentId`/the agent's `machineId` by the caller —
  /// `watchAllTasks` only carries the raw foreign keys.
  final String? agentName;
  final String? machineName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.prompt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyStrong,
            ),
            const SizedBox(height: Spacing.sm),
            StatusPill.fromAppearance(
              taskStatusAppearance(task.status),
              label: task.status.name,
            ),
            if (agentName != null || machineName != null) ...[
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Text(agentName ?? 'Unassigned', style: AppTypography.body),
                  const Spacer(),
                  if (machineName != null)
                    Text(machineName!, style: AppTypography.code),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
