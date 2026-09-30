import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// A single labeled metric row (CPU/RAM) with a thin progress-bar track,
/// per the dashboard's machine card in the design brief.
class MetricBar extends StatelessWidget {
  const MetricBar({
    super.key,
    required this.label,
    required this.fraction,
    required this.valueLabel,
  });

  final String label;

  /// 0.0–1.0.
  final double fraction;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 28, child: Text(label, style: AppTypography.caption)),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 4,
              backgroundColor: AppColors.bg3,
              valueColor: const AlwaysStoppedAnimation(AppColors.text1),
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        SizedBox(
          width: 48,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: AppTypography.caption,
          ),
        ),
      ],
    );
  }
}
