import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

/// A small status pill: a colored dot (pulsing when [pulsing]) plus [label],
/// per `docs/UI-DESIGN.md` §2. Use [StatusPill.fromAppearance] with the
/// `*StatusAppearance` helpers in `theme/colors.dart` to keep status colors
/// consistent everywhere.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.color,
    required this.label,
    this.pulsing = false,
  });

  factory StatusPill.fromAppearance(
    StatusAppearance appearance, {
    required String label,
    Key? key,
  }) {
    return StatusPill(
      key: key,
      color: appearance.color,
      label: label,
      pulsing: appearance.pulsing,
    );
  }

  final Color color;
  final String label;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusDot(color: color, pulsing: pulsing),
            const SizedBox(width: Spacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The colored (optionally pulsing) dot alone, for rows that need a status
/// dot next to plain text rather than a full [StatusPill] (e.g. a machine or
/// agent name in a list, where only the dot should carry the status color).
class StatusDot extends StatefulWidget {
  const StatusDot({super.key, required this.color, this.pulsing = false});

  factory StatusDot.fromAppearance(StatusAppearance appearance, {Key? key}) {
    return StatusDot(
      key: key,
      color: appearance.color,
      pulsing: appearance.pulsing,
    );
  }

  final Color color;
  final bool pulsing;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.pulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !oldWidget.pulsing) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulsing && oldWidget.pulsing) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    if (!widget.pulsing) return dot;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 1.0 - (_controller.value * 0.65),
          child: child,
        );
      },
      child: dot,
    );
  }
}
