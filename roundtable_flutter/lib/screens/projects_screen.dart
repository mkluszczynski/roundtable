import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/project_list_cubit.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/add_project_dialog.dart';
import '../widgets/app_card.dart';
import 'project_detail_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ProjectListCubit(ProjectRepository(client))..fetchProjects(),
        ),
        BlocProvider(
          create: (_) => DashboardCubit(TaskRepository(client))..subscribe(),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ProjectsHeader(),
            Expanded(
              child: BlocBuilder<ProjectListCubit, ProjectListState>(
                builder: (context, state) {
                  return switch (state) {
                    ProjectListInitial() ||
                    ProjectListLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    ProjectListError(:final message) => Center(
                      child: Text(
                        'Failed to load projects: $message',
                        style: AppTypography.body.copyWith(
                          color: AppColors.red,
                        ),
                      ),
                    ),
                    ProjectListLoaded(:final projects) =>
                      projects.isEmpty
                          ? Center(
                              child: Text(
                                'No projects yet',
                                style: AppTypography.body,
                              ),
                            )
                          : _ProjectsList(projects: projects),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectsHeader extends StatelessWidget {
  const _ProjectsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: BlocBuilder<ProjectListCubit, ProjectListState>(
        builder: (context, state) {
          final count = switch (state) {
            ProjectListLoaded(:final projects) => projects.length,
            _ => 0,
          };
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Projects', style: AppTypography.screenTitle),
                    const SizedBox(height: Spacing.xs),
                    Text('$count projects', style: AppTypography.caption),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final cubit = context.read<ProjectListCubit>();
                  final added = await showDialog<bool>(
                    context: context,
                    builder: (_) => const AddProjectDialog(),
                  );
                  if (added ?? false) cubit.fetchProjects();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New project'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectsList extends StatelessWidget {
  const _ProjectsList({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final tasksByProject = switch (context.watch<DashboardCubit>().state) {
      DashboardLoaded(:final tasks) => _groupByProject(tasks.values),
      _ => const <int, List<Task>>{},
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        0,
        Spacing.xl,
        Spacing.xl,
      ),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < projects.length; i++)
              _ProjectRow(
                project: projects[i],
                tasks: tasksByProject[projects[i].id] ?? const [],
                showDivider: i != projects.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  Map<int, List<Task>> _groupByProject(Iterable<Task> tasks) {
    final byProject = <int, List<Task>>{};
    for (final task in tasks) {
      byProject.putIfAbsent(task.projectId, () => []).add(task);
    }
    return byProject;
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({
    required this.project,
    required this.tasks,
    required this.showDivider,
  });

  final Project project;
  final List<Task> tasks;
  final bool showDivider;

  /// Daily task counts for the trailing 7 days (today last), computed
  /// client-side from the already-subscribed task stream — no dedicated
  /// activity endpoint needed.
  List<int> _weekCounts() {
    final today = DateTime.now();
    final counts = List<int>.filled(7, 0);
    for (final task in tasks) {
      final daysAgo = today
          .difference(
            DateTime(
              task.createdAt.year,
              task.createdAt.month,
              task.createdAt.day,
            ),
          )
          .inDays;
      final index = 6 - daysAgo;
      if (index >= 0 && index < 7) counts[index]++;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final week = _weekCounts();
    final maxCount = week.fold(1, (m, v) => v > m ? v : m);
    final hasActivity = week.any((v) => v > 0);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProjectDetailScreen(projectId: project.id!),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.lg,
        ),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.folder_outlined,
                  size: 16,
                  color: AppColors.text1,
                ),
              ),
            ),
            const SizedBox(width: Spacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.name, style: AppTypography.bodyStrong),
                  Text(
                    project.repoUrl,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.code,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                '${tasks.length} tasks',
                style: AppTypography.body.copyWith(color: AppColors.text1),
              ),
            ),
            SizedBox(
              width: 90,
              child: hasActivity
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < week.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Container(
                              width: 5,
                              height: (3 + (week[i] / maxCount) * 21)
                                  .clamp(3, 24)
                                  .toDouble(),
                              decoration: BoxDecoration(
                                color: i == week.length - 1
                                    ? AppColors.live
                                    : AppColors.text2,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Text('no tasks yet', style: AppTypography.caption),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.text2,
            ),
          ],
        ),
      ),
    );
  }
}
