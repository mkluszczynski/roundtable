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
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/add_machine_dialog.dart';
import 'task_detail_screen.dart';
import '../widgets/status_pill.dart';
import '../widgets/app_card.dart';
import '../widgets/add_project_dialog.dart';
import '../widgets/add_agent_dialog.dart';
import '../widgets/create_task_dialog.dart';
import '../widgets/kanban_column.dart';
import '../widgets/machine_summary_card.dart';

/// Live overview: a kanban board of tasks — every project's, or one picked
/// in the header — plus a machines panel. Management (add/edit/delete) stays
/// on the standalone Projects/Machines screens — this is a landing screen,
/// not a replacement for them.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// The project the board is filtered to; null shows every project.
  int? _projectId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              MachineListCubit(MachineRepository(client))..fetchMachines(),
        ),
        BlocProvider(
          create: (_) => AgentListCubit(AgentRepository(client))..fetchAgents(),
        ),
        BlocProvider(
          create: (_) =>
              ProjectListCubit(ProjectRepository(client))..fetchProjects(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final machineState = context.watch<MachineListCubit>().state;
          final agentState = context.watch<AgentListCubit>().state;
          final projectState = context.watch<ProjectListCubit>().state;
          final setupIncomplete =
              machineState is MachineListLoaded &&
              agentState is AgentListLoaded &&
              projectState is ProjectListLoaded &&
              (machineState.machines.isEmpty ||
                  agentState.agents.isEmpty ||
                  projectState.projects.isEmpty);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardHeader(
                projectId: _projectId,
                onProjectChanged: (id) => setState(() => _projectId = id),
              ),
              _NeedsYouStrip(projectId: _projectId),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: setupIncomplete
                          ? const _Onboarding()
                          : _KanbanBoard(projectId: _projectId),
                    ),
                    VerticalDivider(width: 1, color: AppColors.border),
                    const SizedBox(width: 300, child: _MachinesPanel()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Title doubles as the project filter: "All projects" or one project.
/// Below it, live numbers for what's happening right now.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.projectId,
    required this.onProjectChanged,
  });

  final int? projectId;
  final ValueChanged<int?> onProjectChanged;

  @override
  Widget build(BuildContext context) {
    final projects = switch (context.watch<ProjectListCubit>().state) {
      ProjectListLoaded(:final projects) => projects,
      _ => const <Project>[],
    };
    final machines = switch (context.watch<MachineListCubit>().state) {
      MachineListLoaded(:final machines) => machines,
      _ => const <Machine>[],
    };
    final agents = switch (context.watch<AgentListCubit>().state) {
      AgentListLoaded(:final agents) => agents,
      _ => const <Agent>[],
    };
    final project = projects.where((p) => p.id == projectId).firstOrNull;
    final tasks = switch (context.watch<DashboardCubit>().state) {
      DashboardLoaded(:final tasks) =>
        tasks.values
            .where((t) => project == null || t.projectId == project.id)
            .toList(),
      _ => const <Task>[],
    };
    final running = tasks
        .where(
          (t) =>
              t.status == TaskStatus.planning ||
              t.status == TaskStatus.running ||
              t.status == TaskStatus.cloning,
        )
        .length;
    final waiting = tasks
        .where(
          (t) =>
              needsAttentionStatuses.contains(t.status) &&
              t.status != TaskStatus.failed,
        )
        .length;
    final busyAgents = agents.where((a) => a.status != AgentStatus.idle).length;
    final online = machines
        .where((m) => m.status == MachineStatus.online)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.xl,
        Spacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _ProjectFilter(
                    projects: projects,
                    selected: project,
                    onChanged: onProjectChanged,
                  ),
                ),
              ),
              Tooltip(
                message: projects.isEmpty
                    ? 'Add a project first (Projects tab)'
                    : '',
                child: FilledButton.icon(
                  onPressed: projects.isEmpty
                      ? null
                      : () => showDialog<void>(
                          context: context,
                          builder: (_) =>
                              CreateTaskDialog(initialProjectId: project?.id),
                        ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New task'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.md,
            children: [
              _StatTile(
                label: 'Running',
                value: '$running',
                color: AppColors.live,
                pulsing: running > 0,
              ),
              _StatTile(
                label: 'Waiting on you',
                value: '$waiting',
                color: waiting > 0 ? AppColors.accentSoft : AppColors.text2,
              ),
              _StatTile(
                label: 'Agents busy',
                value: '$busyAgents / ${agents.length}',
                color: AppColors.text1,
              ),
              _StatTile(
                label: 'Machines online',
                value: '$online / ${machines.length}',
                color: online > 0 ? AppColors.live : AppColors.text2,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    this.pulsing = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusDot(color: color, pulsing: pulsing),
          const SizedBox(width: Spacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTypography.cardTitle),
              Text(label, style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tasks blocked on the dev, newest first — the dashboard's inbox.
class _NeedsYouStrip extends StatelessWidget {
  const _NeedsYouStrip({required this.projectId});

  final int? projectId;

  static const _failedWindow = Duration(hours: 24);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardCubit>().state;
    if (state is! DashboardLoaded) return const SizedBox.shrink();
    final projects = switch (context.watch<ProjectListCubit>().state) {
      ProjectListLoaded(:final projects) => {
        for (final p in projects) p.id: p.name,
      },
      _ => const <int?, String>{},
    };
    final now = DateTime.now();
    final tasks =
        state.tasks.values
            .where(
              (t) =>
                  (projectId == null || t.projectId == projectId) &&
                  needsAttentionStatuses.contains(t.status) &&
                  (t.status != TaskStatus.failed ||
                      now.difference(t.finishedAt ?? t.createdAt) <
                          _failedWindow),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.xl,
        Spacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEEDS YOU · ${tasks.length}',
            style: AppTypography.label.copyWith(color: AppColors.accentSoft),
          ),
          const SizedBox(height: Spacing.sm),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tasks.length,
              separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
              itemBuilder: (context, i) => _NeedsYouTile(
                task: tasks[i],
                projectName: projectId == null
                    ? projects[tasks[i].projectId]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsYouTile extends StatelessWidget {
  const _NeedsYouTile({required this.task, required this.projectName});

  final Task task;
  final String? projectName;

  @override
  Widget build(BuildContext context) {
    final appearance = taskStatusAppearance(task.status);
    final (icon, action) = switch (task.status) {
      TaskStatus.waitingForAnswer => (Icons.help_outline, 'Answer question'),
      TaskStatus.planReady => (Icons.fact_check_outlined, 'Approve plan'),
      TaskStatus.awaitingReview => (Icons.rate_review_outlined, 'Review PR'),
      _ => (Icons.error_outline, 'Failed'),
    };
    return SizedBox(
      width: 300,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TaskDetailScreen(initialTaskId: task.id!),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: appearance.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: appearance.color),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        action,
                        style: AppTypography.caption.copyWith(
                          color: appearance.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text('#${task.id}', style: AppTypography.code),
                      if (projectName != null) ...[
                        Text('  ·  ', style: AppTypography.caption),
                        Flexible(
                          child: Text(
                            projectName!,
                            style: AppTypography.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.prompt.split('\n').first,
                    style: AppTypography.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// First-run checklist shown instead of an empty board until there's a
/// machine, an agent and a project to give tasks to.
class _Onboarding extends StatelessWidget {
  const _Onboarding();

  @override
  Widget build(BuildContext context) {
    final machines = switch (context.watch<MachineListCubit>().state) {
      MachineListLoaded(:final machines) => machines,
      _ => const <Machine>[],
    };
    final hasAgent = switch (context.watch<AgentListCubit>().state) {
      AgentListLoaded(:final agents) => agents.isNotEmpty,
      _ => false,
    };
    final hasProject = switch (context.watch<ProjectListCubit>().state) {
      ProjectListLoaded(:final projects) => projects.isNotEmpty,
      _ => false,
    };
    final machine = machines.firstOrNull;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: AppCard(
          padding: const EdgeInsets.all(Spacing.huge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Get Roundtable ready', style: AppTypography.screenTitle),
              const SizedBox(height: Spacing.xs),
              Text(
                'Three steps until your agents can pick up work.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: Spacing.xl),
              _OnboardingStep(
                index: 1,
                title: 'Register a machine',
                description:
                    'Install the agent runner on your laptop or a VPS.',
                done: machines.isNotEmpty,
                actionLabel: 'Add machine',
                onAction: () async {
                  final cubit = context.read<MachineListCubit>();
                  final added = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const AddMachineDialog(),
                  );
                  if (added ?? false) cubit.fetchMachines();
                },
              ),
              _OnboardingStep(
                index: 2,
                title: 'Add an agent',
                description: 'A persona on that machine with a role and model.',
                done: hasAgent,
                actionLabel: 'Add agent',
                onAction: machine == null
                    ? null
                    : () async {
                        final cubit = context.read<AgentListCubit>();
                        final added = await showDialog<bool>(
                          context: context,
                          builder: (_) => AddAgentDialog(
                            machineId: machine.id!,
                            machineName: machine.name,
                          ),
                        );
                        if (added ?? false) cubit.fetchAgents();
                      },
              ),
              _OnboardingStep(
                index: 3,
                title: 'Connect a project',
                description: 'The GitHub repository your agents work on.',
                done: hasProject,
                actionLabel: 'Add project',
                onAction: () async {
                  final cubit = context.read<ProjectListCubit>();
                  final added = await showDialog<bool>(
                    context: context,
                    builder: (_) => const AddProjectDialog(),
                  );
                  if (added ?? false) cubit.fetchProjects();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.index,
    required this.title,
    required this.description,
    required this.done,
    required this.actionLabel,
    required this.onAction,
  });

  final int index;
  final String title;
  final String description;
  final bool done;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? AppColors.live.withValues(alpha: 0.16)
                  : AppColors.bg3,
            ),
            child: done
                ? const Icon(Icons.check, size: 16, color: AppColors.live)
                : Text('$index', style: AppTypography.bodyStrong),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyStrong.copyWith(
                    color: done ? AppColors.text2 : AppColors.text0,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(description, style: AppTypography.caption),
              ],
            ),
          ),
          if (!done)
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

/// The screen title as a dropdown: "All projects" or a single project.
class _ProjectFilter extends StatelessWidget {
  const _ProjectFilter({
    required this.projects,
    required this.selected,
    required this.onChanged,
  });

  final List<Project> projects;
  final Project? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Text('No project yet', style: AppTypography.screenTitle);
    }
    final tasks = switch (context.watch<DashboardCubit>().state) {
      DashboardLoaded(:final tasks) => tasks.values,
      _ => const <Task>[],
    };
    int activeIn(int? projectId) => tasks
        .where(
          (t) =>
              (projectId == null || t.projectId == projectId) &&
              kanbanColumnFor(t.status) != KanbanColumn.done,
        )
        .length;

    return PopupMenuButton<int>(
      tooltip: 'Filter by project',
      color: AppColors.bg1,
      position: PopupMenuPosition.under,
      offset: const Offset(0, Spacing.sm),
      constraints: const BoxConstraints(minWidth: 340, maxWidth: 340),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderStrong),
      ),
      // -1 stands for "All projects": PopupMenuButton ignores a null value.
      onSelected: (id) => onChanged(id == -1 ? null : id),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: -1,
          padding: EdgeInsets.zero,
          child: _ProjectFilterOption(
            icon: Icons.dashboard_outlined,
            title: 'All projects',
            subtitle: '${projects.length} projects',
            activeCount: activeIn(null),
            selected: selected == null,
          ),
        ),
        const PopupMenuDivider(height: 1),
        for (final p in projects)
          PopupMenuItem(
            value: p.id!,
            padding: EdgeInsets.zero,
            child: _ProjectFilterOption(
              icon: Icons.folder_outlined,
              title: p.name,
              subtitle: _repoSlug(p.repoUrl),
              activeCount: activeIn(p.id),
              selected: selected?.id == p.id,
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected == null
                  ? Icons.dashboard_outlined
                  : Icons.folder_outlined,
              size: 20,
              color: AppColors.accentSoft,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              selected?.name ?? 'All projects',
              style: AppTypography.screenTitle,
            ),
            const SizedBox(width: Spacing.xs),
            Icon(Icons.unfold_more, size: 20, color: AppColors.text1),
          ],
        ),
      ),
    );
  }
}

/// `https://github.com/owner/repo(.git)` → `owner/repo`.
String _repoSlug(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  final slug = uri.pathSegments
      .where((s) => s.isNotEmpty)
      .join('/')
      .replaceFirst(RegExp(r'\.git$'), '');
  return slug.isEmpty ? url : slug;
}

class _ProjectFilterOption extends StatelessWidget {
  const _ProjectFilterOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.activeCount,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int activeCount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected ? AppColors.accent.withValues(alpha: 0.12) : null,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? AppColors.accentSoft : AppColors.text1,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyStrong,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (activeCount > 0)
            Tooltip(
              message: 'Active tasks',
              child: Text('$activeCount active', style: AppTypography.caption),
            ),
          if (selected) ...[
            const SizedBox(width: Spacing.sm),
            const Icon(Icons.check, size: 16, color: AppColors.accentSoft),
          ],
        ],
      ),
    );
  }
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({required this.projectId});

  /// Null shows every project's tasks.
  final int? projectId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return switch (state) {
          DashboardLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          DashboardError(:final message) => Center(
            child: Text(
              'Failed to load tasks: $message',
              style: AppTypography.body.copyWith(color: AppColors.red),
            ),
          ),
          DashboardLoaded() => Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final column in KanbanColumn.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                      ),
                      child: KanbanColumnView(
                        title: kanbanColumnTitle(column),
                        accent: kanbanColumnAccent(column),
                        tasks: state.columnsFor(projectId: projectId)[column]!,
                        // A single project's board doesn't need the label.
                        showProject: projectId == null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        };
      },
    );
  }
}

class _MachinesPanel extends StatelessWidget {
  const _MachinesPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MACHINES', style: AppTypography.label),
          const SizedBox(height: Spacing.md),
          Expanded(
            child: BlocBuilder<MachineListCubit, MachineListState>(
              builder: (context, state) {
                return switch (state) {
                  MachineListInitial() ||
                  MachineListLoading() ||
                  MachineDeletionBlockedOnline() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  MachineListError(:final message) => Text(
                    'Failed to load machines: $message',
                    style: AppTypography.body.copyWith(color: AppColors.red),
                  ),
                  MachineListLoaded(:final machines) =>
                    BlocBuilder<AgentListCubit, AgentListState>(
                      builder: (context, agentState) {
                        final agents = switch (agentState) {
                          AgentListLoaded(:final agents) => agents,
                          _ => const <Agent>[],
                        };
                        return machines.isEmpty
                            ? Text(
                                'No machines yet',
                                style: AppTypography.caption,
                              )
                            : ListView(
                                children: [
                                  // Online first; offline ones collapse.
                                  for (final machine in [
                                    ...machines.where(
                                      (m) => m.status == MachineStatus.online,
                                    ),
                                    ...machines.where(
                                      (m) => m.status != MachineStatus.online,
                                    ),
                                  ])
                                    MachineSummaryCard(
                                      machine: machine,
                                      agents: agents
                                          .where(
                                            (a) => a.machineId == machine.id,
                                          )
                                          .toList(),
                                    ),
                                ],
                              );
                      },
                    ),
                };
              },
            ),
          ),
          const SizedBox(height: Spacing.sm),
          OutlinedButton.icon(
            onPressed: () async {
              final cubit = context.read<MachineListCubit>();
              final added = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const AddMachineDialog(),
              );
              if (added ?? false) cubit.fetchMachines();
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add machine'),
          ),
        ],
      ),
    );
  }
}
