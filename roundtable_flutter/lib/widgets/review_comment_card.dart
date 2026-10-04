import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'plan_content.dart';
import 'status_pill.dart';

/// One AI review comment with its triage controls: a checkbox to include it
/// in the next "send to agent", and dismiss/resolve/reopen. Controls are
/// hidden when [onToggleSelected]/[onStateChanged] are null (read-only, e.g.
/// once the task is done).
class ReviewCommentCard extends StatelessWidget {
  const ReviewCommentCard({
    super.key,
    required this.comment,
    this.showLocation = true,
    this.selected = false,
    this.onToggleSelected,
    this.onStateChanged,
    this.onOpenLocation,
  });

  final ReviewComment comment;

  /// Whether to show `path:line` — redundant when shown inline in a diff.
  final bool showLocation;
  final bool selected;
  final VoidCallback? onToggleSelected;
  final ValueChanged<ReviewCommentState>? onStateChanged;

  /// Makes the `path:line` location a link, e.g. to jump to the file's diff.
  final VoidCallback? onOpenLocation;

  static Color severityColor(ReviewCommentSeverity severity) =>
      switch (severity) {
        ReviewCommentSeverity.blocker => AppColors.red,
        ReviewCommentSeverity.issue => AppColors.warning,
        ReviewCommentSeverity.nit => AppColors.text2,
      };

  static String stateLabel(ReviewCommentState state) => switch (state) {
    ReviewCommentState.open => 'Open',
    ReviewCommentState.dismissed => 'Dismissed',
    ReviewCommentState.sentToFix => 'Sent to agent',
    ReviewCommentState.resolved => 'Resolved',
  };

  @override
  Widget build(BuildContext context) {
    final isOpen = comment.state == ReviewCommentState.open;
    final line = comment.line;
    final onStateChanged = this.onStateChanged;

    final severity = severityColor(comment.severity);
    final fileName = comment.path.split('/').last;
    final location = line == null ? fileName : '$fileName:$line';

    return Opacity(
      opacity: isOpen || comment.state == ReviewCommentState.sentToFix
          ? 1
          : 0.55,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Spacing.md,
          Spacing.md,
          Spacing.lg,
          Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: severity, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOpen && onToggleSelected != null)
              Tooltip(
                message: 'Select to send to the agent',
                child: Checkbox(
                  value: selected,
                  onChanged: (_) => onToggleSelected!(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusPill(color: severity, label: comment.severity.name),
                      if (showLocation) ...[
                        const SizedBox(width: Spacing.sm),
                        Flexible(
                          child: Tooltip(
                            message: line == null
                                ? comment.path
                                : '${comment.path}:$line',
                            child: Text(
                              location,
                              style: AppTypography.code.copyWith(
                                color: AppColors.text1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (onOpenLocation != null) ...[
                          const SizedBox(width: Spacing.sm),
                          InkWell(
                            onTap: onOpenLocation,
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              'Open in diff',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.accentSoft,
                              ),
                            ),
                          ),
                        ],
                      ],
                      const Spacer(),
                      if (!isOpen)
                        Text(
                          stateLabel(comment.state),
                          style: AppTypography.caption,
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  PlanContent(markdown: comment.body),
                  if (onStateChanged != null &&
                      comment.state != ReviewCommentState.sentToFix)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: Spacing.xs,
                        children: isOpen
                            ? [
                                TextButton(
                                  onPressed: () => onStateChanged(
                                    ReviewCommentState.dismissed,
                                  ),
                                  child: const Text('Dismiss'),
                                ),
                                TextButton(
                                  onPressed: () => onStateChanged(
                                    ReviewCommentState.resolved,
                                  ),
                                  child: const Text('Resolve'),
                                ),
                              ]
                            : [
                                TextButton(
                                  onPressed: () =>
                                      onStateChanged(ReviewCommentState.open),
                                  child: const Text('Reopen'),
                                ),
                              ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
