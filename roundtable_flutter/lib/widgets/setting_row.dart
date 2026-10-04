import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import '../theme/typography.dart';

/// A labelled setting: title and description on the left, its control
/// (switch, pill selector) on the right.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    required this.description,
    required this.control,
  });

  final String title;
  final String description;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyStrong),
                const SizedBox(height: 2),
                Text(description, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: Spacing.lg),
          control,
        ],
      ),
    );
  }
}
