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

  /// Below this width a control wider than a switch goes under the text,
  /// so the description keeps a readable line length.
  static const _stackBelow = 480.0;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.bodyStrong),
        const SizedBox(height: 2),
        Text(description, style: AppTypography.caption),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (control is! Switch && constraints.maxWidth < _stackBelow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                const SizedBox(height: Spacing.md),
                control,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: Spacing.lg),
              control,
            ],
          );
        },
      ),
    );
  }
}
