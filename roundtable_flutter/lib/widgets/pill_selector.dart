import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// A wrapped row of toggle pills for single-select choices with a small
/// option set (role, model, effort, execution mode), replacing
/// `DropdownButtonFormField` per `docs/UI-DESIGN.md` §2.
class PillSelector<T> extends StatelessWidget {
  const PillSelector({
    super.key,
    required this.options,
    required this.labelBuilder,
    required this.selected,
    required this.onChanged,
    this.disabledOptions = const {},
    this.disabledHint,
  });

  final List<T> options;
  final String Function(T option) labelBuilder;
  final T? selected;
  final ValueChanged<T> onChanged;
  final Set<T> disabledOptions;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        for (final option in options)
          _Pill(
            label: labelBuilder(option),
            selected: option == selected,
            disabled: disabledOptions.contains(option),
            disabledHint: disabledHint,
            onTap: () => onChanged(option),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.disabledHint,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final String? disabledHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pill = DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.14)
            : AppColors.bg2,
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: disabled
                    ? AppColors.text2
                    : selected
                    ? AppColors.text0
                    : AppColors.text1,
              ),
            ),
            if (disabled && disabledHint != null) ...[
              const SizedBox(width: Spacing.xs),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.xs,
                    vertical: 2,
                  ),
                  child: Text(disabledHint!, style: AppTypography.caption),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (disabled) return Opacity(opacity: 0.6, child: pill);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: pill,
      ),
    );
  }
}
