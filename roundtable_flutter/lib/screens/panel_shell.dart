import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/agent_list_cubit.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/machine_list_cubit.dart';
import '../cubits/project_list_cubit.dart';
import '../repositories/agent_repository.dart';
import '../repositories/machine_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/nav_rail.dart';
import '../widgets/rail_nav_item.dart';
import '../widgets/runner_update_banner.dart';
import '../widgets/status_pill.dart';
import 'dashboard_screen.dart';
import 'machines_screen.dart';
import 'projects_screen.dart';
import 'settings_screen.dart';

/// No top `AppBar` — each screen owns its own header content, per the
/// design brief (the panel has no persistent app-wide top bar).
///
/// Provides the one shared [DashboardCubit] (the live task list) and the
/// project/agent/machine lists to every tab and the detail screens they push.
class PanelShell extends StatefulWidget {
  const PanelShell({super.key});

  @override
  State<PanelShell> createState() => _PanelShellState();
}

class _PanelShellState extends State<PanelShell> {
  int _selectedIndex = 0;

  /// Project/agent ids a task referenced before the lists knew them, already
  /// refetched once — so a dangling id can't trigger a refetch loop.
  final _refetchedProjectIds = <int>{};
  final _refetchedAgentIds = <int>{};

  /// A task can arrive for a project or agent created elsewhere (another
  /// browser tab); refresh the lists so its card isn't left unlabeled.
  void _refreshListsFor(BuildContext context, DashboardState state) {
    if (state is! DashboardLoaded) return;
    final projectCubit = context.read<ProjectListCubit>();
    final agentCubit = context.read<AgentListCubit>();
    final projects = projectCubit.state;
    final agents = agentCubit.state;
    if (projects is ProjectListLoaded) {
      final known = {for (final p in projects.projects) p.id};
      final missing = state.tasks.values
          .map((t) => t.projectId)
          .where((id) => !known.contains(id) && _refetchedProjectIds.add(id));
      if (missing.isNotEmpty) projectCubit.fetchProjects();
    }
    if (agents is AgentListLoaded) {
      final known = {for (final a in agents.agents) a.id};
      final missing = state.tasks.values
          .map((t) => t.agentId)
          .whereType<int>()
          .where((id) => !known.contains(id) && _refetchedAgentIds.add(id));
      if (missing.isNotEmpty) agentCubit.fetchAgents();
    }
  }

  static const _rootScreens = [
    DashboardScreen(),
    ProjectsScreen(),
    MachinesScreen(),
    SettingsScreen(),
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
    NavRailItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DashboardCubit(TaskRepository(client))..subscribe(),
        ),
        // Shared by every tab and detail screen so a project, agent or
        // machine added on one screen shows up everywhere — each tab is kept
        // alive by the IndexedStack and would otherwise hold a stale copy.
        BlocProvider(
          create: (_) =>
              ProjectListCubit(ProjectRepository(client))..fetchProjects(),
        ),
        BlocProvider(
          create: (_) => AgentListCubit(AgentRepository(client))..fetchAgents(),
        ),
        BlocProvider(
          create: (_) =>
              MachineListCubit(MachineRepository(client))..fetchMachines(),
        ),
      ],
      child: BlocListener<DashboardCubit, DashboardState>(
        listener: _refreshListsFor,
        child: Scaffold(
          backgroundColor: AppColors.bg0,
          body: Row(
            children: [
              _ShellNavRail(
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
      ),
    );
  }
}

/// [AppNavRail] fed with live signals from the shared cubits: tasks waiting
/// on the dev, machines needing attention, and the connection state.
///
/// Also keeps the machine list fresh: machine status and the server's
/// latest runner version only change on a refetch, so it reloads silently on
/// an interval and whenever the Machines tab is opened.
class _ShellNavRail extends StatefulWidget {
  const _ShellNavRail({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NavRailItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<_ShellNavRail> createState() => _ShellNavRailState();
}

class _ShellNavRailState extends State<_ShellNavRail> {
  static const _dashboardIndex = 0;
  static const _machinesIndex = 2;
  static const _machineRefreshInterval = Duration(seconds: 30);

  Timer? _machineRefresh;

  @override
  void initState() {
    super.initState();
    _machineRefresh = Timer.periodic(
      _machineRefreshInterval,
      (_) => context.read<MachineListCubit>().fetchMachines(silent: true),
    );
  }

  @override
  void dispose() {
    _machineRefresh?.cancel();
    super.dispose();
  }

  void _select(int index) {
    if (index == _machinesIndex) {
      context.read<MachineListCubit>().fetchMachines(silent: true);
    }
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final taskState = context.watch<DashboardCubit>().state;
    final machineState = context.watch<MachineListCubit>().state;
    final waiting = taskState is DashboardLoaded
        ? taskState.tasks.values
              .where(
                (t) =>
                    needsAttentionStatuses.contains(t.status) &&
                    t.status != TaskStatus.failed,
              )
              .length
        : 0;
    final machines = machineState is MachineListLoaded
        ? machineState.machines
        : const <Machine>[];
    final online = machines
        .where((m) => m.status == MachineStatus.online)
        .length;
    final machineNeedsAttention =
        machineState is MachineListLoaded &&
        machines.any(
          (m) =>
              m.claudeExecutableOk == false ||
              runnerUpdateStatus(
                    installedVersion: m.runnerVersion,
                    latestVersion: machineState.latestRunnerVersion,
                    updateRequestedAt: m.updateRequestedAt,
                  ) ==
                  RunnerUpdateStatus.available,
        );

    return AppNavRail(
      items: widget.items,
      selectedIndex: widget.selectedIndex,
      onSelected: _select,
      badges: {
        if (waiting > 0)
          _dashboardIndex: Tooltip(
            message: '$waiting waiting on you',
            child: CountBadge(waiting, color: AppColors.accentSoft),
          ),
        if (machineNeedsAttention)
          _machinesIndex: const Tooltip(
            message: 'A machine needs an update or has a broken claude CLI',
            child: StatusDot(color: AppColors.warning),
          ),
      },
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusDot(
                color: switch (taskState) {
                  DashboardLoaded() => AppColors.live,
                  DashboardError() => AppColors.red,
                  DashboardLoading() => AppColors.text2,
                },
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                switch (taskState) {
                  DashboardLoaded() => 'Live updates on',
                  DashboardError() => 'Disconnected — reload',
                  DashboardLoading() => 'Connecting…',
                },
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              const Icon(Icons.dns_outlined, size: 12, color: AppColors.text2),
              const SizedBox(width: Spacing.sm),
              Text(
                '$online / ${machines.length} machines online',
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
