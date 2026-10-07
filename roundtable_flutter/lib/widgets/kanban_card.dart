import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../cubits/dashboard_cubit.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/pr_checks.dart';
import '../utils/relative_time.dart';
import '../utils/task_status_label.dart';
import 'agent_avatar.dart';
import 'status_pill.dart';

/// A single task on a kanban board. Tapping it navigates to
/// `task_detail_screen.dart` for that task.
class KanbanCard extends StatefulWidget {
  const KanbanCard({
    super.key,
    required this.task,
    required this.onTap,
    this.agentName,
    this.machineName,
    this.projectName,
  });

  final Task task;
  final VoidCallback onTap;

  /// Resolved from `Task.agentId`/the agent's `machineId` by the caller —
  /// `watchAllTasks` only carries the raw foreign keys.
  final String? agentName;
  final String? machineName;

  /// Shown on boards mixing projects (the Dashboard); null hides it.
  final String? projectName;

  @override
  State<KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends State<KanbanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final appearance = taskStatusAppearance(task.status);
    final attention = needsAttentionStatuses.contains(task.status);
    final failure = task.status == TaskStatus.failed
        ? task.failureReason
        : null;
    // CI only matters while the PR is still open for changes.
    final showChecks =
        task.prUrl != null &&
        task.checkState != PrCheckState.none &&
        (task.status == TaskStatus.awaitingReview ||
            task.status == TaskStatus.running);
    final ciFailed = showChecks && task.checkState == PrCheckState.failure;
    final pausedUntil = task.status == TaskStatus.paused
        ? task.pausedUntil
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bg2 : AppColors.bg1,
              border: Border.all(
                color: _hovered ? AppColors.borderStrong : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (attention)
                    Container(
                      width: 3,
                      color: ciFailed ? AppColors.red : appearance.color,
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MetaRow(
                            task: task,
                            projectName: widget.projectName,
                            appearance: appearance,
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            task.title ?? task.prompt,
                            maxLines: task.title == null ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyStrong,
                          ),
                          if (failure != null) ...[
                            const SizedBox(height: Spacing.xs),
                            Text(
                              failure,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.red,
                              ),
                            ),
                          ],
                          if (pausedUntil != null) ...[
                            const SizedBox(height: Spacing.xs),
                            Text(
                              'Usage limit — resumes at '
                              '${resumeTimeLabel(pausedUntil)}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                          if (task.branchName != null) ...[
                            const SizedBox(height: Spacing.sm),
                            Row(
                              children: [
                                const Icon(
                                  Icons.call_split,
                                  size: 12,
                                  color: AppColors.text2,
                                ),
                                const SizedBox(width: Spacing.xs),
                                Flexible(
                                  child: Text(
                                    task.branchName!,
                                    style: AppTypography.code.copyWith(
                                      color: AppColors.text1,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (showChecks) ...[
                                  const SizedBox(width: Spacing.md),
                                  _ChecksBadge(state: task.checkState),
                                ],
                              ],
                            ),
                          ],
                          const SizedBox(height: Spacing.md),
                          _AssigneeRow(
                            agentName: widget.agentName,
                            machineName: widget.machineName,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.task,
    required this.projectName,
    required this.appearance,
  });

  final Task task;
  final String? projectName;
  final StatusAppearance appearance;

  @override
  Widget build(BuildContext context) {
    // Left part takes the free space so the status stays flush right; a
    // Flexible next to a Spacer would split it between them.
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (projectName != null) ...[
                const Icon(
                  Icons.folder_outlined,
                  size: 12,
                  color: AppColors.text2,
                ),
                const SizedBox(width: Spacing.xs),
                Flexible(
                  child: Text(
                    projectName!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.text1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('  ·  ', style: AppTypography.caption),
              ],
              // One text, so a narrow column cuts the time, not the layout.
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '#${task.id}', style: AppTypography.code),
                      TextSpan(
                        text: '  ·  ${relativeTime(task.createdAt)}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        StatusDot.fromAppearance(appearance),
        const SizedBox(width: Spacing.xs),
        Text(
          task.status.label,
          style: AppTypography.caption.copyWith(
            color: appearance.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// The PR's CI result next to the branch name.
class _ChecksBadge extends StatelessWidget {
  const _ChecksBadge({required this.state});

  final PrCheckState state;

  @override
  Widget build(BuildContext context) {
    final appearance = checkStateAppearance(state);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot.fromAppearance(appearance),
        const SizedBox(width: Spacing.xs),
        Text(
          checkStateLabel(state),
          style: AppTypography.caption.copyWith(color: appearance.color),
        ),
      ],
    );
  }
}

class _AssigneeRow extends StatelessWidget {
  const _AssigneeRow({required this.agentName, required this.machineName});

  final String? agentName;
  final String? machineName;

  @override
  Widget build(BuildContext context) {
    final agentName = this.agentName;
    if (agentName == null) {
      return Row(
        children: [
          const Icon(
            Icons.person_outline,
            size: 14,
            color: AppColors.text2,
          ),
          const SizedBox(width: Spacing.xs),
          Text('Unassigned', style: AppTypography.caption),
        ],
      );
    }
    return Row(
      children: [
        AgentAvatar(name: agentName),
        const SizedBox(width: Spacing.sm),
        Flexible(
          child: Text(
            agentName,
            style: AppTypography.body,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (machineName != null) ...[
          Text('  ·  ', style: AppTypography.caption),
          const Icon(Icons.dns_outlined, size: 12, color: AppColors.text2),
          const SizedBox(width: Spacing.xs),
          Flexible(
            child: Text(
              machineName!,
              style: AppTypography.caption,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ],
    );
  }
}
