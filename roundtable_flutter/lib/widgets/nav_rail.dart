import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class NavRailItem {
  const NavRailItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The panel's left navigation rail: brand mark, a stack of nav items, and
/// "Settings" pinned to the bottom — replaces the stock `NavigationRail` per
/// `docs/UI-DESIGN.md` §3 (Dashboard artboard).
class AppNavRail extends StatelessWidget {
  const AppNavRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.onSettingsTap,
  });

  final List<NavRailItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.bg1,
      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          color: AppColors.accentInk,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Text('Roundtable', style: AppTypography.cardTitle),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xxl),
          for (var i = 0; i < items.length; i++)
            _NavRailTile(
              item: items[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
          const Spacer(),
          _NavRailTile(
            item: const NavRailItem(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: 'Settings',
            ),
            selected: false,
            onTap: onSettingsTap ?? () {},
          ),
        ],
      ),
    );
  }
}

class _NavRailTile extends StatelessWidget {
  const _NavRailTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavRailItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.text1;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? AppColors.accent.withValues(alpha: 0.14) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.smd,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: Spacing.md),
                Text(
                  item.label,
                  style:
                      (selected ? AppTypography.bodyStrong : AppTypography.body)
                          .copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
