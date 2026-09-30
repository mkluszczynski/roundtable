import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../widgets/nav_rail.dart';
import 'dashboard_screen.dart';
import 'machines_screen.dart';
import 'projects_screen.dart';

/// No top `AppBar` — each screen owns its own header content, per the
/// design brief (the panel has no persistent app-wide top bar).
class PanelShell extends StatefulWidget {
  const PanelShell({super.key});

  @override
  State<PanelShell> createState() => _PanelShellState();
}

class _PanelShellState extends State<PanelShell> {
  int _selectedIndex = 0;

  static const _screens = [
    DashboardScreen(),
    ProjectsScreen(),
    MachinesScreen(),
  ];

  static const _items = [
    NavRailItem(
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard,
      label: 'Dashboard',
    ),
    NavRailItem(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      label: 'Projects',
    ),
    NavRailItem(
      icon: Icons.computer_outlined,
      selectedIcon: Icons.computer,
      label: 'Machines',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Row(
        children: [
          AppNavRail(
            items: _items,
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),
          Container(width: 1, color: AppColors.border),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      ),
    );
  }
}
