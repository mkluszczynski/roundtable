import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// One navigation entry in a rail — the app's nav rail and a detail screen's
/// side panel. Selected: raised background, accent edge and icon.
class RailNavItem extends StatefulWidget {
  const RailNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedIcon,
    this.trailing,
    this.dense = true,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Compact padding for in-screen rails; the app nav uses roomier rows.
  final bool dense;

  @override
  State<RailNavItem> createState() => _RailNavItemState();
}

class _RailNavItemState extends State<RailNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final color = selected ? AppColors.text0 : AppColors.text1;
    final background = selected
        ? AppColors.bg2
        : _hovered
        ? AppColors.bg2.withValues(alpha: 0.5)
        : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    width: 2,
                    color: selected ? AppColors.accent : Colors.transparent,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: widget.dense ? Spacing.sm : Spacing.smd,
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? (widget.selectedIcon ?? widget.icon)
                        : widget.icon,
                    size: widget.dense ? 16 : 18,
                    color: selected ? AppColors.accent : AppColors.text2,
                  ),
                  SizedBox(width: widget.dense ? Spacing.sm : Spacing.md),
                  Expanded(
                    child: Text(
                      widget.label,
                      style:
                          (selected
                                  ? AppTypography.bodyStrong
                                  : AppTypography.body)
                              .copyWith(color: color),
                    ),
                  ),
                  ?widget.trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small pill with a number, e.g. open comments or tasks waiting.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.color = AppColors.warning});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: AppTypography.caption.copyWith(color: color),
      ),
    );
  }
}
