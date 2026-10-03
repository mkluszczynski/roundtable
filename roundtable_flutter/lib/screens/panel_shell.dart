import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../client.dart';
import '../cubits/dashboard_cubit.dart';
import '../repositories/task_repository.dart';
import '../theme/colors.dart';
import '../widgets/nav_rail.dart';
import 'dashboard_screen.dart';
import 'machines_screen.dart';
import 'projects_screen.dart';

/// No top `AppBar` — each screen owns its own header content, per the
/// design brief (the panel has no persistent app-wide top bar).
///
/// Provides the one shared [DashboardCubit] (the live task list) to every
/// tab and the detail screens they push.
class PanelShell extends StatefulWidget {
  const PanelShell({super.key});

  @override
  State<PanelShell> createState() => _PanelShellState();
}

class _PanelShellState extends State<PanelShell> {
  int _selectedIndex = 0;

  static const _rootScreens = [
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
    return BlocProvider(
      create: (_) => DashboardCubit(TaskRepository(client))..subscribe(),
      child: Scaffold(
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
              child: IndexedStack(
                index: _selectedIndex,
                // Each tab gets its own Navigator so detail screens it pushes
                // (project/machine/task detail) stack within that tab's area
                // instead of covering the nav rail via the app-root Navigator.
                children: [
                  for (final screen in _rootScreens)
                    Navigator(
                      onGenerateRoute: (settings) => MaterialPageRoute(
                        builder: (_) => screen,
                        settings: settings,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
