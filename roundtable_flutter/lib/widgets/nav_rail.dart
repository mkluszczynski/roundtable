import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'rail_nav_item.dart';

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

/// The panel's left navigation rail: brand mark, nav items (with optional
/// live [badges]) and a pinned [footer] — replaces the stock
/// `NavigationRail` (see `docs/UI-DESIGN.md` §3).
class AppNavRail extends StatelessWidget {
  const AppNavRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.badges = const {},
    this.footer,
    this.section,
  });

  final List<NavRailItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Trailing widget per item index, e.g. a count of tasks waiting.
  final Map<int, Widget> badges;
  final Widget? footer;

  /// Fills the space between the items and the [footer] (scrolls itself),
  /// e.g. the active tasks.
  final Widget? section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      color: AppColors.bg1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.xl,
              Spacing.xl,
              0,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accent, AppColors.accentSoft],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'R',
                    style: TextStyle(
                      color: AppColors.accentInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Flexible(
                  child: Text(
                    'Roundtable',
                    style: AppTypography.cardTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
            child: Text('WORKSPACE', style: AppTypography.label),
          ),
          const SizedBox(height: Spacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  RailNavItem(
                    icon: items[i].icon,
                    selectedIcon: items[i].selectedIcon,
                    label: items[i].label,
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                    trailing: badges[i],
                    dense: false,
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Expanded(child: section ?? const SizedBox.shrink()),
          if (footer != null)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.all(Spacing.xl),
              child: footer,
            ),
        ],
      ),
    );
  }
}
