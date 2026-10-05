import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import '../theme/typography.dart';

/// A labelled block in a detail screen's side rail (task, project).
class RailSection extends StatelessWidget {
  const RailSection({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
  });

  final String label;
  final Widget child;

  /// A small action next to the label, e.g. a copy button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trailing == null)
            Text(label.toUpperCase(), style: AppTypography.label)
          else
            Row(
              children: [
                Expanded(
                  child: Text(label.toUpperCase(), style: AppTypography.label),
                ),
                trailing!,
              ],
            ),
          const SizedBox(height: Spacing.sm),
          child,
        ],
      ),
    );
  }
}
