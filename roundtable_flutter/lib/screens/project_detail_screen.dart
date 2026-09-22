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
import '../utils/relative_time.dart';
import '../widgets/add_project_dialog.dart';
import '../widgets/create_task_dialog.dart';
import '../widgets/kanban_column.dart';
import '../widgets/update_token_dialog.dart';

/// One project: repo info, access-token status, and a kanban board scoped
/// to just its tasks — pushed from `projects_screen.dart`.
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final int projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final _repository = ProjectRepository(client);
  late Future<Project?> _projectFuture = _repository.getProject(
    widget.projectId,
  );

  void _reload() {
    setState(() => _projectFuture = _repository.getProject(widget.projectId));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AgentListCubit(AgentRepository(client))..fetchAgents(),
        ),
        BlocProvider(
          create: (_) =>
              MachineListCubit(MachineRepository(client))..fetchMachines(),
        ),
        BlocProvider(
          create: (_) =>
              ProjectListCubit(ProjectRepository(client))..fetchProjects(),
        ),
        BlocProvider(
          create: (_) => DashboardCubit(TaskRepository(client))..subscribe(),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: FutureBuilder<Project?>(
          future: _projectFuture,
          builder: (context, snapshot) {
            final project = snapshot.data;
            if (project == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _ProjectDetailBody(project: project, onChanged: _reload);
          },
        ),
      ),
    );
  }
}

class _ProjectDetailBody extends StatelessWidget {
  const _ProjectDetailBody({required this.project, required this.onChanged});

  final Project project;
  final VoidCallback onChanged;

  static const _titles = {
    KanbanColumn.backlog: 'Backlog',
    KanbanColumn.inProgress: 'In Progress',
    KanbanColumn.review: 'Review',
    KanbanColumn.done: 'Done',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(project: project, onChanged: onChanged),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.lg,
            Spacing.xl,
            0,
          ),
          child: _TokenRow(project: project, onChanged: onChanged),
        ),
        Expanded(
          child: BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              final tasks = switch (state) {
                DashboardLoaded(:final tasks) =>
                  tasks.values.where((t) => t.projectId == project.id).toList(),
                _ => const <Task>[],
              };
              final columns = <KanbanColumn, List<Task>>{
                for (final c in KanbanColumn.values) c: [],
              };
              for (final task in tasks) {
                columns[kanbanColumnFor(task.status)]!.add(task);
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(Spacing.xl),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final column in KanbanColumn.values)
                      Padding(
                        padding: const EdgeInsets.only(right: Spacing.lg),
                        child: SizedBox(
                          width: 240,
                          child: KanbanColumnView(
                            title: _titles[column]!,
                            tasks: columns[column]!,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.project, required this.onChanged});

  final Project project;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xl,
        vertical: Spacing.lg,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text1),
            onPressed: () => Navigator.of(context).pop(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: Spacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.folder_outlined,
                size: 18,
                color: AppColors.text1,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: AppTypography.screenTitle),
                Row(
                  children: [
                    Text(
                      _displayRepoUrl(project.repoUrl),
                      style: AppTypography.code,
                    ),
                    const SizedBox(width: Spacing.xs),
                    const Icon(
                      Icons.open_in_new,
                      size: 12,
                      color: AppColors.text2,
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final saved = await showDialog<bool>(
                context: context,
                builder: (_) => AddProjectDialog(existingProject: project),
              );
              if (saved ?? false) onChanged();
            },
            child: const Text('Edit'),
          ),
          const SizedBox(width: Spacing.sm),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red.withValues(alpha: 0.4)),
            ),
            onPressed: () async {
              final cubit = context.read<ProjectListCubit>();
              await cubit.deleteProject(project.id!);
              if (!context.mounted) return;
              if (cubit.state is ProjectListError) {
                final message = (cubit.state as ProjectListError).message;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete project'),
          ),
          const SizedBox(width: Spacing.sm),
          FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => CreateTaskDialog(initialProjectId: project.id),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New task'),
          ),
        ],
      ),
    );
  }

  String _displayRepoUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return '${uri.host}${uri.path}';
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.project, required this.onChanged});

  final Project project;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final updatedAt = project.repoAccessTokenUpdatedAt;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.lg,
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, size: 14, color: AppColors.text2),
            const SizedBox(width: Spacing.lg),
            SizedBox(
              width: 120,
              child: Text('Access token', style: AppTypography.bodyStrong),
            ),
            Expanded(
              child: Text(
                updatedAt == null
                    ? 'No token configured'
                    : '••••••••••••••••••••••••',
                style: AppTypography.code,
              ),
            ),
            if (updatedAt != null) ...[
              Text(
                'added ${relativeTime(updatedAt, words: true)}',
                style: AppTypography.caption,
              ),
              const SizedBox(width: Spacing.lg),
            ],
            OutlinedButton(
              onPressed: () async {
                final updated = await showDialog<bool>(
                  context: context,
                  builder: (_) => UpdateTokenDialog(projectId: project.id!),
                );
                if (updated ?? false) onChanged();
              },
              child: Text(updatedAt == null ? 'Add token' : 'Update token'),
            ),
          ],
        ),
      ),
    );
  }
}
