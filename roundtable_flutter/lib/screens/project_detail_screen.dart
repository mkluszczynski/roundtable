import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/project_list_cubit.dart';
import '../repositories/project_repository.dart';
import '../repositories/settings_repository.dart';
import '../utils/task_options.dart';
import '../utils/error_message.dart';
import '../widgets/load_failed_view.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/relative_time.dart';
import '../widgets/add_project_dialog.dart';
import '../widgets/app_modal.dart';
import '../widgets/create_task_dialog.dart';
import '../widgets/kanban_column.dart';
import '../widgets/pill_selector.dart';
import '../widgets/reviewer_select.dart';
import '../widgets/rail_section.dart';
import '../widgets/status_pill.dart';
import '../widgets/update_token_dialog.dart';

/// One project: a rail with repo info, access-token status and project
/// actions, next to a kanban board scoped to just its tasks — pushed from `projects_screen.dart`.
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
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: FutureBuilder<Project?>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return LoadFailedView(
              title: "Couldn't load this project",
              message: errorMessage(snapshot.error!),
              onRetry: _reload,
            );
          }
          final project = snapshot.data;
          if (project == null) {
            return const LoadFailedView(
              title: 'Project not found',
              message: 'It may have been deleted.',
            );
          }
          return _ProjectDetailBody(project: project, onChanged: _reload);
        },
      ),
    );
  }
}

class _ProjectDetailBody extends StatelessWidget {
  const _ProjectDetailBody({required this.project, required this.onChanged});

  final Project project;
  final VoidCallback onChanged;

  /// Below this the columns keep a fixed width and the board scrolls.
  static const _minColumnWidth = 280.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(project: project),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 300,
                    child: _ProjectRail(
                      project: project,
                      columns: columns,
                      onChanged: onChanged,
                    ),
                  ),
                  VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(child: _Board(columns: columns)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.columns});

  final Map<KanbanColumn, List<Task>> columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = Spacing.lg;
        const padding = Spacing.xl;
        final count = KanbanColumn.values.length;
        final fits =
            constraints.maxWidth - 2 * padding >=
            count * _ProjectDetailBody._minColumnWidth + (count - 1) * gap;
        Widget column(KanbanColumn c) => KanbanColumnView(
          title: kanbanColumnTitle(c),
          accent: kanbanColumnAccent(c),
          tasks: columns[c]!,
        );
        final children = [
          for (final (i, c) in KanbanColumn.values.indexed) ...[
            if (i > 0) const SizedBox(width: gap),
            fits
                ? Expanded(child: column(c))
                : SizedBox(
                    width: _ProjectDetailBody._minColumnWidth,
                    child: column(c),
                  ),
          ],
        ];
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
        if (fits) {
          return Padding(padding: const EdgeInsets.all(padding), child: row);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(padding),
          child: SizedBox(
            height: constraints.maxHeight - 2 * padding,
            child: row,
          ),
        );
      },
    );
  }
}

/// Project identity only; the one frequent action, New task, stays here.
class _Header extends StatelessWidget {
  const _Header({required this.project});

  final Project project;

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
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, color: AppColors.text1),
            onPressed: () => Navigator.of(context).pop(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: Spacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.folder_outlined,
                size: 18,
                color: AppColors.accentSoft,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: AppTypography.screenTitle),
                Text(
                  _repoSlug(project.repoUrl),
                  style: AppTypography.code.copyWith(color: AppColors.text1),
                ),
              ],
            ),
          ),
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

class _ProjectRail extends StatelessWidget {
  const _ProjectRail({
    required this.project,
    required this.columns,
    required this.onChanged,
  });

  final Project project;
  final Map<KanbanColumn, List<Task>> columns;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RailSection(
                  label: 'Repository',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.code,
                            size: 14,
                            color: AppColors.text1,
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Text(
                              _repoSlug(project.repoUrl),
                              style: AppTypography.code,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Open repository',
                            icon: const Icon(Icons.open_in_new, size: 14),
                            color: AppColors.text1,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => launchUrl(
                              Uri.parse(project.repoUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Created ${relativeTime(project.createdAt, words: true)}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                RailSection(
                  label: 'Access token',
                  child: _TokenStatus(project: project, onChanged: onChanged),
                ),
                RailSection(
                  label: 'Tasks',
                  child: _TaskStats(columns: columns),
                ),
                RailSection(
                  label: 'Task defaults',
                  child: _TaskDefaults(project: project),
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final saved = await showDialog<bool>(
                    context: context,
                    builder: (_) => AddProjectDialog(existingProject: project),
                  );
                  if (saved ?? false) onChanged();
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit project'),
              ),
              const SizedBox(height: Spacing.sm),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: BorderSide(color: AppColors.red.withValues(alpha: 0.5)),
                ),
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete project'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<ProjectListCubit>();
    final confirmed = await showAppModal<bool>(
      context,
      icon: Icons.delete_outline,
      tone: AppModalTone.danger,
      title: 'Delete ${project.name}?',
      subtitle:
          'This removes the project from Roundtable. The GitHub '
          'repository is not touched.',
      child: const SizedBox.shrink(),
      actions: [
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ),
        Builder(
          builder: (context) => FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ),
      ],
    );
    if (!(confirmed ?? false)) return;
    final errorMessage = await cubit.deleteProject(project.id!);
    if (!context.mounted) return;
    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } else {
      Navigator.of(context).pop();
    }
  }
}

class _TokenStatus extends StatelessWidget {
  const _TokenStatus({required this.project, required this.onChanged});

  final Project project;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final updatedAt = project.repoAccessTokenUpdatedAt;
    final configured = updatedAt != null;
    final color = configured ? AppColors.live : AppColors.warning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                configured ? Icons.lock_outline : Icons.lock_open,
                size: 16,
                color: color,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      configured ? 'Configured' : 'No token',
                      style: AppTypography.bodyStrong.copyWith(color: color),
                    ),
                    Text(
                      configured
                          ? 'Added ${relativeTime(updatedAt, words: true)}'
                          : 'Private repos will fail to clone and PRs '
                                "can't be opened.",
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        OutlinedButton.icon(
          onPressed: () async {
            final updated = await showDialog<bool>(
              context: context,
              builder: (_) => UpdateTokenDialog(projectId: project.id!),
            );
            if (updated ?? false) onChanged();
          },
          icon: const Icon(Icons.key_outlined, size: 16),
          label: Text(configured ? 'Update token' : 'Add token'),
        ),
      ],
    );
  }
}

class _TaskStats extends StatelessWidget {
  const _TaskStats({required this.columns});

  final Map<KanbanColumn, List<Task>> columns;

  @override
  Widget build(BuildContext context) {
    final needsYou = columns.values
        .expand((tasks) => tasks)
        .where(
          (t) =>
              t.status == TaskStatus.waitingForAnswer ||
              t.status == TaskStatus.planReady ||
              t.status == TaskStatus.awaitingReview,
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in KanbanColumn.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                StatusDot(color: kanbanColumnAccent(c)),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(kanbanColumnTitle(c), style: AppTypography.body),
                ),
                Text('${columns[c]!.length}', style: AppTypography.code),
              ],
            ),
          ),
        if (needsYou > 0) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            '$needsYou waiting on you',
            style: AppTypography.caption.copyWith(color: AppColors.accentSoft),
          ),
        ],
      ],
    );
  }
}

/// The project's overrides of the workspace task defaults: each option is
/// inherited (showing the workspace value) or set for this project.
class _TaskDefaults extends StatefulWidget {
  const _TaskDefaults({required this.project});

  final Project project;

  @override
  State<_TaskDefaults> createState() => _TaskDefaultsState();
}

class _TaskDefaultsState extends State<_TaskDefaults> {
  late final _repository = SettingsRepository(client);
  late Project _project = widget.project;
  WorkspaceSettings? _workspace;

  @override
  void initState() {
    super.initState();
    _repository.getWorkspace().then((w) {
      if (mounted) setState(() => _workspace = w);
    }).ignore();
  }

  Future<void> _save(Project updated) async {
    final previous = _project;
    setState(() => _project = updated);
    try {
      await _repository.updateProjectTaskDefaults(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _project = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save: ${errorMessage(e)}")),
      );
    }
  }

  Widget _boolOverride({
    required TaskOptionInfo option,
    required bool? value,
    required bool? workspaceValue,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: option.description,
            child: Text(option.title, style: AppTypography.body),
          ),
          const SizedBox(height: Spacing.sm),
          PillSelector<bool?>(
            options: const [null, true, false],
            labelBuilder: (v) => switch (v) {
              null =>
                workspaceValue == null
                    ? 'Workspace'
                    : 'Workspace (${workspaceValue ? 'on' : 'off'})',
              true => 'On',
              false => 'Off',
            },
            selected: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pre-filled in the new-task form.', style: AppTypography.caption),
        const SizedBox(height: Spacing.md),
        _boolOverride(
          option: skipPlanningOption,
          value: _project.skipPlanning,
          workspaceValue: _workspace?.skipPlanning,
          onChanged: (v) => _save(_project.copyWith(skipPlanning: v)),
        ),
        _boolOverride(
          option: autoReviewOption,
          value: _project.autoReview,
          workspaceValue: _workspace?.autoReview,
          onChanged: (v) => _save(_project.copyWith(autoReview: v)),
        ),
        _boolOverride(
          option: autoFixOption,
          value: _project.autoFixReview,
          workspaceValue: _workspace?.autoFixReview,
          onChanged: (v) => _save(_project.copyWith(autoFixReview: v)),
        ),
        Tooltip(
          message: maxFixRoundsOption.description,
          child: Text(maxFixRoundsOption.title, style: AppTypography.body),
        ),
        const SizedBox(height: Spacing.sm),
        PillSelector<int?>(
          options: const [null, ...fixRoundChoices],
          labelBuilder: (n) => n == null
              ? (_workspace == null
                    ? 'Workspace'
                    : 'Workspace (${_workspace!.maxReviewFixRounds})')
              : '$n',
          selected: _project.maxReviewFixRounds,
          onChanged: (n) => _save(_project.copyWith(maxReviewFixRounds: n)),
        ),
        const SizedBox(height: Spacing.md),
        Tooltip(
          message: reviewerOption.description,
          child: Text(reviewerOption.title, style: AppTypography.body),
        ),
        const SizedBox(height: Spacing.sm),
        ReviewerSelect(
          width: double.infinity,
          selected: _project.reviewerAgentId,
          noneLabel: 'Workspace default',
          onChanged: (id) => _save(_project.copyWith(reviewerAgentId: id)),
        ),
      ],
    );
  }
}
