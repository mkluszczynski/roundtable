part of '../task_detail_screen.dart';

/// Task identity only: back, breadcrumb and the status right next to it.
/// Everything that manages the task lives in the rail.
class _Header extends StatelessWidget {
  const _Header({required this.state, this.compact = false});

  final TaskDetailLoaded state;

  /// Phones: the title on its own line, the breadcrumb and status under it.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    if (compact) return _buildCompact(context, task);
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
          if (Navigator.canPop(context)) ...[
            IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back, color: AppColors.text1),
              onPressed: () => Navigator.of(context).pop(),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: Spacing.sm),
          ],
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.text1,
                ),
                children: [
                  TextSpan(text: '${state.project?.name ?? '…'}  /  '),
                  TextSpan(
                    text: 'Task #${task.id}',
                    style: AppTypography.code.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text0,
                    ),
                  ),
                  const TextSpan(text: '  ·  '),
                  task.title == null
                      ? TextSpan(
                          text: 'Untitled',
                          style: AppTypography.body.copyWith(
                            color: AppColors.text2,
                          ),
                        )
                      : TextSpan(
                          text: task.title,
                          style: AppTypography.bodyStrong.copyWith(
                            color: AppColors.text0,
                          ),
                        ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(
              Icons.edit_outlined,
              size: 16,
              color: AppColors.text1,
            ),
            onPressed: () => _openRenameTaskDialog(context, task),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: Spacing.md),
          StatusPill.fromAppearance(
            taskStatusAppearance(task.status),
            label: task.status.label,
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context, Task task) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        Spacing.xs,
        Spacing.sm,
        Spacing.md,
        Spacing.sm,
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back, color: AppColors.text1),
              onPressed: () => Navigator.of(context).pop(),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title ?? task.prompt,
                  style: AppTypography.bodyStrong,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${state.project?.name ?? '…'} · #${task.id}',
                        style: AppTypography.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    StatusPill.fromAppearance(
                      taskStatusAppearance(task.status),
                      label: task.status.label,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.text1,
            ),
            onPressed: () => _openRenameTaskDialog(context, task),
          ),
        ],
      ),
    );
  }
}
