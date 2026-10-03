import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
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

    return Opacity(
      opacity: isOpen || comment.state == ReviewCommentState.sentToFix
          ? 1
          : 0.55,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: severityColor(comment.severity), width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOpen && onToggleSelected != null)
              Checkbox(
                value: selected,
                onChanged: (_) => onToggleSelected!(),
                visualDensity: VisualDensity.compact,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusPill(
                        color: severityColor(comment.severity),
                        label: comment.severity.name,
                      ),
                      if (!isOpen)
                        Text(
                          stateLabel(comment.state),
                          style: AppTypography.caption,
                        ),
                      if (showLocation)
                        InkWell(
                          onTap: onOpenLocation,
                          child: Text(
                            line == null
                                ? comment.path
                                : '${comment.path}:$line',
                            style: AppTypography.code.copyWith(
                              color: onOpenLocation == null
                                  ? AppColors.text1
                                  : AppColors.accentSoft,
                              decoration: onOpenLocation == null
                                  ? null
                                  : TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  SelectableText(comment.body, style: AppTypography.body),
                ],
              ),
            ),
            if (onStateChanged != null) ...[
              if (isOpen) ...[
                IconButton(
                  tooltip: 'Dismiss',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => onStateChanged(ReviewCommentState.dismissed),
                ),
                IconButton(
                  tooltip: 'Mark resolved',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.check, size: 16),
                  onPressed: () => onStateChanged(ReviewCommentState.resolved),
                ),
              ] else if (comment.state != ReviewCommentState.sentToFix)
                IconButton(
                  tooltip: 'Reopen',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.undo, size: 16),
                  onPressed: () => onStateChanged(ReviewCommentState.open),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
