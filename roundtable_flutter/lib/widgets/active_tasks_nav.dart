import '../utils/status_rules.dart';
import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../cubits/dashboard_cubit.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/task_status_label.dart';
import 'status_pill.dart';

/// The tasks in the kanban's In progress and Review columns, across all
/// projects, for the nav rail: waiting on the dev first, then the most
/// recently active. Jumping between them skips the kanban.
List<Task> activeTasks(Iterable<Task> tasks) {
  bool waits(Task t) => needsAttentionStatuses.contains(t.status);
  DateTime touched(Task t) => t.lastProgressAt;
  return tasks.where((t) {
    final column = kanbanColumnFor(t.status);
    return column == KanbanColumn.inProgress || column == KanbanColumn.review;
  }).toList()..sort((a, b) {
    if (waits(a) != waits(b)) return waits(a) ? -1 : 1;
    return touched(b).compareTo(touched(a));
  });
}

/// The nav rail's "ACTIVE TASKS" section, see [activeTasks].
class ActiveTasksNav extends StatelessWidget {
  const ActiveTasksNav({
    super.key,
    required this.tasks,
    required this.onOpen,
    required this.onShowAll,
    this.agentNames = const {},
    this.openTaskId,
    this.limit = 10,
  });

  /// Already filtered and ordered by [activeTasks].
  final List<Task> tasks;
  final ValueChanged<Task> onOpen;

  /// "+N more": to the kanban.
  final VoidCallback onShowAll;
  final Map<int, String> agentNames;

  /// Highlighted: the task detail screen currently open.
  final int? openTaskId;
  final int limit;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final shown = tasks.take(limit).toList();
    final hidden = tasks.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          child: Text('ACTIVE TASKS', style: AppTypography.label),
        ),
        const SizedBox(height: Spacing.sm),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            children: [
              for (final task in shown)
                _ActiveTaskRow(
                  task: task,
                  agentName: agentNames[task.agentId],
                  selected: task.id == openTaskId,
                  onTap: () => onOpen(task),
                ),
              if (hidden > 0)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.xs),
                  child: TextButton(
                    onPressed: onShowAll,
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text('+$hidden more'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveTaskRow extends StatefulWidget {
  const _ActiveTaskRow({
    required this.task,
    required this.agentName,
    required this.selected,
    required this.onTap,
  });

  final Task task;
  final String? agentName;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ActiveTaskRow> createState() => _ActiveTaskRowState();
}

class _ActiveTaskRowState extends State<_ActiveTaskRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final appearance = taskStatusAppearance(task.status);
    final waits = needsAttentionStatuses.contains(task.status);
    final detail = [?widget.agentName, _statusLabel(task)].join(' · ');
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.bg3
                : _hovered
                ? AppColors.bg2
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  color: waits ? appearance.color : Colors.transparent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.sm,
                      Spacing.sm,
                      Spacing.sm,
                      Spacing.sm,
                    ),
                    child: Row(
                      children: [
                        StatusDot.fromAppearance(appearance),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title ?? task.prompt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: widget.selected
                                    ? AppTypography.bodyStrong
                                    : AppTypography.body,
                              ),
                              Text(
                                detail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
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
    );
  }

  static String _statusLabel(Task task) {
    final until = task.pausedUntil;
    if (task.status == TaskStatus.paused && until != null) {
      return 'Paused · ${resumeTimeLabel(until)}';
    }
    if (task.isReviewPaused && until != null) {
      return 'Review paused · ${resumeTimeLabel(until)}';
    }
    final label = task.status.label;
    return label[0].toUpperCase() + label.substring(1);
  }
}
