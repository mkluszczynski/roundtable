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
    this.collapsed = false,
    this.collapsedFooter,
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

  /// Icons only, for medium widths: no labels, no [section], and the
  /// [collapsedFooter] instead of the [footer].
  final bool collapsed;
  final Widget? collapsedFooter;

  @override
  Widget build(BuildContext context) {
    if (collapsed) return _buildCollapsed();
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
                const BrandMark(),
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

  Widget _buildCollapsed() {
    return Container(
      width: collapsedWidth,
      color: AppColors.bg1,
      child: Column(
        children: [
          const SizedBox(height: Spacing.xl),
          const BrandMark(),
          const SizedBox(height: Spacing.xxl),
          for (var i = 0; i < items.length; i++)
            _CollapsedItem(
              item: items[i],
              selected: i == selectedIndex,
              badge: badges[i],
              onTap: () => onSelected(i),
            ),
          const Spacer(),
          if (collapsedFooter != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xl),
              child: collapsedFooter,
            ),
        ],
      ),
    );
  }

  static const collapsedWidth = 72.0;
}

/// The app's logo tile.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Text(
        'R',
        style: AppTypography.cardTitle.copyWith(
          color: AppColors.accentInk,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// One icon of the collapsed rail: a 48 px touch target, the label as a
/// tooltip, the badge on the icon's corner.
class _CollapsedItem extends StatelessWidget {
  const _CollapsedItem({
    required this.item,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final NavRailItem item;
  final bool selected;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Tooltip(
        message: item.label,
        child: Material(
          color: selected ? AppColors.bg2 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 20,
                    color: selected ? AppColors.accent : AppColors.text2,
                  ),
                  if (badge != null)
                    Positioned(top: 4, right: 2, child: badge!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
