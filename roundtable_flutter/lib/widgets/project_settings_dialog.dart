import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../repositories/project_repository.dart';
import '../repositories/settings_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/error_message.dart';
import '../utils/task_options.dart';
import '../utils/tool_catalog.dart';
import 'app_modal.dart';
import 'pill_selector.dart';
import 'reviewer_select.dart';
import 'setting_row.dart';
import 'tool_list_editor.dart';

/// A project's overrides of the workspace task defaults, saved as each one
/// changes: every option either inherits the workspace value (shown in
/// brackets) or is set for this project. The workspace values are read
/// fresh each time the dialog opens. Pops the saved project.
class ProjectSettingsDialog extends StatefulWidget {
  const ProjectSettingsDialog({super.key, required this.project});

  final Project project;

  @override
  State<ProjectSettingsDialog> createState() => _ProjectSettingsDialogState();
}

class _ProjectSettingsDialogState extends State<ProjectSettingsDialog> {
  late final _repository = SettingsRepository(client);
  late final _projects = ProjectRepository(client);
  late Project _project = widget.project;
  WorkspaceSettings? _workspace;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _repository
        .getWorkspace()
        .then((w) {
          if (mounted) setState(() => _workspace = w);
        })
        .catchError((Object e) {
          if (mounted) setState(() => _loadError = errorMessage(e));
        });
  }

  Future<void> _save(Project updated) async {
    final previous = _project;
    setState(() => _project = updated);
    try {
      await _repository.updateProjectTaskDefaults(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _project = previous);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text("Couldn't save: ${errorMessage(e)}")),
      );
    }
  }

  Future<void> _saveTools(List<ProjectTool> tools) async {
    final previous = _project;
    setState(() => _project = _project.copyWith(tools: tools));
    try {
      final saved = await _projects.updateTools(_project.id!, tools);
      if (mounted) {
        setState(() => _project = _project.copyWith(tools: saved.tools));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _project = previous);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text("Couldn't save the tools: ${errorMessage(e)}")),
      );
    }
  }

  Widget _bool(
    TaskOptionInfo option, {
    required bool? value,
    required bool workspaceValue,
    required ValueChanged<bool?> onChanged,
  }) {
    return SettingRow(
      title: option.title,
      description: option.description,
      control: PillSelector<bool?>(
        options: const [null, true, false],
        labelBuilder: (v) => switch (v) {
          null => 'Workspace (${workspaceValue ? 'on' : 'off'})',
          true => 'On',
          false => 'Off',
        },
        selected: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _count(
    TaskOptionInfo option, {
    required int? value,
    required int workspaceValue,
    required ValueChanged<int?> onChanged,
  }) {
    return SettingRow(
      title: option.title,
      description: option.description,
      control: PillSelector<int?>(
        options: const [null, ...fixRoundChoices],
        labelBuilder: (n) => n == null ? 'Workspace ($workspaceValue)' : '$n',
        selected: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(top: Spacing.lg, bottom: Spacing.xs),
    child: Text(label, style: AppTypography.label),
  );

  @override
  Widget build(BuildContext context) {
    final workspace = _workspace;
    final p = _project;
    return AppModal(
      icon: Icons.tune,
      title: '${p.name} settings',
      subtitle:
          'Toolchains and defaults for new tasks in this project — each '
          'task can still change its options in the form. Changes save '
          'right away.',
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_project),
          child: const Text('Done'),
        ),
      ],
      child: SizedBox(
        width: 720,
        child: _loadError != null
            ? Text(_loadError!, style: const TextStyle(color: AppColors.red))
            : workspace == null
            ? const Padding(
                padding: EdgeInsets.all(Spacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section('TOOLS'),
                    Text(
                      toolsDescription,
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: Spacing.xs),
                    ToolListEditor(
                      tools: p.tools ?? const [],
                      onChanged: _saveTools,
                      onDetect: () => _projects.detectTools(
                        p.repoUrl,
                        projectId: p.id,
                      ),
                    ),
                    _section('PLANNING'),
                    _bool(
                      skipPlanningOption,
                      value: p.skipPlanning,
                      workspaceValue: workspace.skipPlanning,
                      onChanged: (v) => _save(p.copyWith(skipPlanning: v)),
                    ),
                    _section('REVIEW'),
                    _bool(
                      autoReviewOption,
                      value: p.autoReview,
                      workspaceValue: workspace.autoReview,
                      onChanged: (v) => _save(p.copyWith(autoReview: v)),
                    ),
                    SettingRow(
                      title: reviewerOption.title,
                      description: reviewerOption.description,
                      control: ReviewerSelect(
                        selected: p.reviewerAgentId,
                        noneLabel: 'Workspace',
                        noneSubtitle: 'Use the workspace reviewer',
                        inherits: true,
                        inheritedAgentId: workspace.reviewerAgentId,
                        onChanged: (id) =>
                            _save(p.copyWith(reviewerAgentId: id)),
                      ),
                    ),
                    _bool(
                      autoFixOption,
                      value: p.autoFixReview,
                      workspaceValue: workspace.autoFixReview,
                      onChanged: (v) => _save(p.copyWith(autoFixReview: v)),
                    ),
                    _count(
                      maxFixRoundsOption,
                      value: p.maxReviewFixRounds,
                      workspaceValue: workspace.maxReviewFixRounds,
                      onChanged: (n) =>
                          _save(p.copyWith(maxReviewFixRounds: n)),
                    ),
                    _section('MERGE & CI'),
                    _bool(
                      autoMergeOption,
                      value: p.autoMerge,
                      workspaceValue: workspace.autoMerge,
                      onChanged: (v) => _save(p.copyWith(autoMerge: v)),
                    ),
                    _bool(
                      autoFixChecksOption,
                      value: p.autoFixFailingChecks,
                      workspaceValue: workspace.autoFixFailingChecks,
                      onChanged: (v) =>
                          _save(p.copyWith(autoFixFailingChecks: v)),
                    ),
                    _count(
                      maxCheckFixAttemptsOption,
                      value: p.maxCheckFixAttempts,
                      workspaceValue: workspace.maxCheckFixAttempts,
                      onChanged: (n) =>
                          _save(p.copyWith(maxCheckFixAttempts: n)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
