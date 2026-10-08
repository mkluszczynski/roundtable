import '../utils/status_rules.dart';
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
import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/open_task.dart';
import '../widgets/active_tasks_nav.dart';
import '../widgets/nav_rail.dart';
import '../widgets/rail_nav_item.dart';
import '../widgets/runner_update_banner.dart';
import '../widgets/status_pill.dart';
import 'dashboard_screen.dart';
import 'machines_screen.dart';
import 'projects_screen.dart';
import 'settings_screen.dart';
import 'task_detail_screen.dart';

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

  /// The Dashboard tab's navigator, where the rail's active tasks open.
  final _dashboardNavigator = GlobalKey<NavigatorState>();

  /// Opens [task] in the Dashboard tab, in place of whatever detail screen
  /// is open there — jumping between tasks never stacks them, and back
  /// always leads to the kanban.
  void _openTask(Task task) {
    setState(() => _selectedIndex = 0);
    final navigator = _dashboardNavigator.currentState;
    if (navigator == null) return;
    navigator.popUntil((route) => route.isFirst);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(initialTaskId: task.id!),
      ),
    );
  }

  void _showKanban() {
    setState(() => _selectedIndex = 0);
    _dashboardNavigator.currentState?.popUntil((route) => route.isFirst);
  }

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
          create: (_) => AgentListCubit(AgentRepository(client))
            ..fetchAgents()
            ..watchStatuses(),
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
          body: _ShellLayout(
            layout: LayoutSize.of(context),
            nav: _ShellNavRail(
              items: _items,
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
              onOpenTask: _openTask,
              onShowKanban: _showKanban,
              layout: LayoutSize.of(context),
            ),
            content: IndexedStack(
              index: _selectedIndex,
              // Each tab gets its own Navigator so detail screens it pushes
              // (project/machine/task detail) stack within that tab's area
              // instead of covering the nav rail via the app-root Navigator.
              children: [
                for (final (i, screen) in _rootScreens.indexed)
                  Navigator(
                    key: i == 0 ? _dashboardNavigator : null,
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (_) => screen,
                      settings: settings,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The navigation beside the content (a rail) or under it (a bottom bar on
/// phones).
class _ShellLayout extends StatelessWidget {
  const _ShellLayout({
    required this.layout,
    required this.nav,
    required this.content,
  });

  final LayoutSize layout;
  final Widget nav;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    if (layout.isCompact) {
      // Touch: every icon button gets a 48 px target, however small its
      // icon (copy, edit, menus).
      return Theme(
        data: Theme.of(
          context,
        ).copyWith(materialTapTargetSize: MaterialTapTargetSize.padded),
        child: Column(
          children: [
            Expanded(child: SafeArea(bottom: false, child: content)),
            nav,
          ],
        ),
      );
    }
    return Row(
      children: [
        nav,
        Container(width: 1, color: AppColors.border),
        Expanded(child: content),
      ],
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
    required this.onOpenTask,
    required this.onShowKanban,
    required this.layout,
  });

  final LayoutSize layout;
  final List<NavRailItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<Task> onOpenTask;
  final VoidCallback onShowKanban;

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
        ? taskState.tasks.values.where((t) => waitsOnDev(t.status)).length
        : 0;
    final agentState = context.watch<AgentListCubit>().state;
    final agentNames = {
      if (agentState is AgentListLoaded)
        for (final a in agentState.agents) a.id!: a.name,
    };
    final machines = machineState is MachineListLoaded
        ? machineState.machines
        : const <Machine>[];
    final online = machines.where((m) => m.isOnline).length;
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

    final (connectionColor, connectionLabel) = switch (taskState) {
      DashboardLoaded(reconnecting: true) => (
        AppColors.warning,
        'Reconnecting…',
      ),
      DashboardLoaded() => (AppColors.live, 'Live updates on'),
      DashboardError() => (AppColors.red, 'Disconnected — reload'),
      DashboardLoading() => (AppColors.text2, 'Connecting…'),
    };
    final badges = {
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
    };

    if (widget.layout.isCompact) {
      return _BottomNav(
        items: widget.items,
        selectedIndex: widget.selectedIndex,
        onSelected: _select,
        badges: badges,
        // Only worth the room when something's wrong.
        connection: connectionColor == AppColors.live
            ? null
            : (connectionColor, connectionLabel),
      );
    }

    return AppNavRail(
      items: widget.items,
      selectedIndex: widget.selectedIndex,
      onSelected: _select,
      collapsed: !widget.layout.isExpanded,
      collapsedFooter: Tooltip(
        message:
            '$connectionLabel · $online / ${machines.length} machines online',
        child: StatusDot(color: connectionColor),
      ),
      badges: badges,
      section: ValueListenableBuilder(
        valueListenable: openTaskId,
        builder: (context, openId, _) => ActiveTasksNav(
          tasks: taskState is DashboardLoaded
              ? activeTasks(taskState.tasks.values)
              : const [],
          agentNames: agentNames,
          openTaskId: openId,
          onOpen: widget.onOpenTask,
          onShowAll: widget.onShowKanban,
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusDot(color: connectionColor),
              const SizedBox(width: Spacing.sm),
              Text(connectionLabel, style: AppTypography.caption),
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

/// The phone's navigation: one tab per screen along the bottom, and the
/// connection state above it when it isn't live.
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.badges,
    this.connection,
  });

  final List<NavRailItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Map<int, Widget> badges;
  final (Color, String)? connection;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (connection case (final color, final label))
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatusDot(color: color),
                    const SizedBox(width: Spacing.sm),
                    Text(label, style: AppTypography.caption),
                  ],
                ),
              ),
            Row(
              children: [
                for (final (i, item) in items.indexed)
                  Expanded(
                    child: _BottomNavItem(
                      item: item,
                      selected: i == selectedIndex,
                      badge: badges[i],
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
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
    final color = selected ? AppColors.accent : AppColors.text2;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? item.selectedIcon : item.icon, color: color),
                if (badge != null)
                  Positioned(top: -4, right: -14, child: badge!),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              item.label,
              style: AppTypography.caption.copyWith(
                color: selected ? AppColors.text0 : AppColors.text2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
