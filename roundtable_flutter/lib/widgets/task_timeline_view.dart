import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/relative_time.dart';
import '../utils/task_timeline.dart';
import 'status_pill.dart';

/// A task's [TimelineStep]s as a vertical line of dots: what happened, when,
/// and for how long. A step with a link opens its log or review.
class TaskTimelineView extends StatelessWidget {
  const TaskTimelineView({super.key, required this.steps, this.onOpen});

  final List<TimelineStep> steps;
  final ValueChanged<TimelineLink>? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, step) in steps.indexed)
          _StepRow(
            step: step,
            last: i == steps.length - 1,
            onTap: step.link == null || onOpen == null
                ? null
                : () => onOpen!(step.link!),
          ),
      ],
    );
  }
}

Color _colorFor(TimelineStepState state) => switch (state) {
  TimelineStepState.running => AppColors.live,
  TimelineStepState.done => AppColors.accentSoft,
  TimelineStepState.failed => AppColors.red,
  TimelineStepState.warning => AppColors.warning,
  TimelineStepState.neutral => AppColors.text2,
};

class _StepRow extends StatefulWidget {
  const _StepRow({required this.step, required this.last, this.onTap});

  final TimelineStep step;
  final bool last;
  final VoidCallback? onTap;

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final color = _colorFor(step.state);
    final duration = _duration(step);
    final detail = step.detail;
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 16,
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    StatusDot(
                      color: color,
                      pulsing: step.state == TimelineStepState.running,
                    ),
                    if (!widget.last)
                      Expanded(
                        child: Container(
                          width: 1,
                          margin: const EdgeInsets.only(top: 4),
                          color: AppColors.border,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.label,
                              style: AppTypography.body.copyWith(
                                color: _hovered && widget.onTap != null
                                    ? AppColors.accentSoft
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            relativeTime(step.at),
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                      if (detail != null || duration != null)
                        Text(
                          [?detail, ?duration].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color:
                                step.state == TimelineStepState.failed ||
                                    step.state == TimelineStepState.warning
                                ? color
                                : null,
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
    );
  }

  static String? _duration(TimelineStep step) {
    final end = step.endedAt;
    if (end == null) return null;
    final elapsed = end.difference(step.at);
    if (elapsed.inSeconds < 1) return null;
    if (elapsed.inMinutes == 0) return '${elapsed.inSeconds}s';
    if (elapsed.inHours == 0) {
      return '${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s';
    }
    return '${elapsed.inHours}h ${elapsed.inMinutes % 60}m';
  }
}
