import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import '../theme/typography.dart';

/// A labelled block in a detail screen's side rail (task, project).
class RailSection extends StatelessWidget {
  const RailSection({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTypography.label),
          const SizedBox(height: Spacing.sm),
          child,
        ],
      ),
    );
  }
}
