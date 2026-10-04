import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/add_project_cubit.dart';
import '../repositories/project_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_modal.dart';
import 'pill_selector.dart';
import 'token_help_accordion.dart';

/// Name, repo URL, and (create-mode only) an optional repo access token
/// with in-panel help (docs/ARCHITECTURE.md), or (edit-mode only) the CI
/// auto-fix settings (docs/FLOWS.md §4 "CI checks"). Opened from
/// `projects_screen.dart`
/// to create a project, or from `project_detail_screen.dart`'s "Edit" button
/// with [existingProject] set to rename/repoint one — editing never touches
/// the token, that's `project_detail_screen.dart`'s separate "Update token"
/// flow (`UpdateTokenDialog`).
class AddProjectDialog extends StatelessWidget {
  const AddProjectDialog({super.key, this.existingProject});

  final Project? existingProject;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddProjectCubit(ProjectRepository(client)),
      child: _AddProjectDialogContent(existingProject: existingProject),
    );
  }
}

class _AddProjectDialogContent extends StatefulWidget {
  const _AddProjectDialogContent({this.existingProject});

  final Project? existingProject;

  @override
  State<_AddProjectDialogContent> createState() =>
      _AddProjectDialogContentState();
}

class _AddProjectDialogContentState extends State<_AddProjectDialogContent> {
  late final _nameController = TextEditingController(
    text: widget.existingProject?.name,
  );
  late final _repoUrlController = TextEditingController(
    text: widget.existingProject?.repoUrl,
  );
  final _tokenController = TextEditingController();
  late bool _autoFixFailingChecks =
      widget.existingProject?.autoFixFailingChecks ?? false;
  late int _maxCheckFixAttempts =
      widget.existingProject?.maxCheckFixAttempts ?? 2;

  bool get _editing => widget.existingProject != null;

  @override
  void dispose() {
    _nameController.dispose();
    _repoUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _repoUrlController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddProjectCubit, AddProjectState>(
      listener: (context, state) {
        if (state is AddProjectSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      child: BlocBuilder<AddProjectCubit, AddProjectState>(
        builder: (context, state) {
          final submitting = state is AddProjectSubmitting;
          return AppModal(
            icon: Icons.folder_outlined,

            title: _editing ? 'Edit project' : 'Add project',
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: (_canSubmit && !submitting)
                    ? () => _editing
                          ? context.read<AddProjectCubit>().update(
                              existing: widget.existingProject!,
                              name: _nameController.text.trim(),
                              repoUrl: _repoUrlController.text.trim(),
                              autoFixFailingChecks: _autoFixFailingChecks,
                              maxCheckFixAttempts: _maxCheckFixAttempts,
                            )
                          : context.read<AddProjectCubit>().submit(
                              name: _nameController.text.trim(),
                              repoUrl: _repoUrlController.text.trim(),
                              repoAccessToken:
                                  _tokenController.text.trim().isEmpty
                                  ? null
                                  : _tokenController.text.trim(),
                            )
                    : null,
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_editing ? 'Save' : 'Add project'),
              ),
            ],
            child: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: Spacing.lg),
                    TextField(
                      controller: _repoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Repository URL',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (!_editing) ...[
                      const SizedBox(height: Spacing.lg),
                      TextField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Repo access token (optional)',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: Spacing.sm),
                      const TokenHelpAccordion(),
                    ],
                    if (_editing) ...[
                      const SizedBox(height: Spacing.lg),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _autoFixFailingChecks,
                        onChanged: (value) =>
                            setState(() => _autoFixFailingChecks = value),
                        title: Text(
                          'Send failing CI checks to the agent automatically',
                          style: AppTypography.body,
                        ),
                        subtitle: Text(
                          'When a task\'s GitHub Actions fail, its agent gets '
                          'the logs and a fix run — without waiting for you.',
                          style: AppTypography.caption,
                        ),
                      ),
                      if (_autoFixFailingChecks) ...[
                        const SizedBox(height: Spacing.sm),
                        Text(
                          'AUTOMATIC ATTEMPTS PER TASK',
                          style: AppTypography.label,
                        ),
                        const SizedBox(height: Spacing.sm),
                        PillSelector<int>(
                          options: const [1, 2, 3, 5],
                          labelBuilder: (n) => '$n',
                          selected: _maxCheckFixAttempts,
                          onChanged: (n) =>
                              setState(() => _maxCheckFixAttempts = n),
                        ),
                      ],
                    ],
                    if (state is AddProjectError) ...[
                      const SizedBox(height: Spacing.md),
                      Text(
                        state.message,
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
