import 'package:flutter/material.dart';

import 'agents_screen.dart';
import 'machines_screen.dart';
import 'projects_screen.dart';
import 'task_detail_screen.dart';
import 'task_diff_screen.dart';

class PanelShell extends StatefulWidget {
  const PanelShell({super.key});

  @override
  State<PanelShell> createState() => _PanelShellState();
}

class _PanelShellState extends State<PanelShell> {
  int _selectedIndex = 0;

  static const _screens = [
    ProjectsScreen(),
    MachinesScreen(),
    AgentsScreen(),
    TaskDetailScreen(),
    TaskDiffScreen(),
  ];

  static const _titles = [
    'Projects',
    'Machines',
    'Agents',
    'Task Detail',
    'Task Diff',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: Text('Projects'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.computer_outlined),
                selectedIcon: Icon(Icons.computer),
                label: Text('Machines'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.smart_toy_outlined),
                selectedIcon: Icon(Icons.smart_toy),
                label: Text('Agents'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.help_outline),
                selectedIcon: Icon(Icons.help),
                label: Text('Task Detail'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.difference_outlined),
                selectedIcon: Icon(Icons.difference),
                label: Text('Task Diff'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}
