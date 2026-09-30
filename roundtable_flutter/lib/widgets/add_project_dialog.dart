import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/add_project_cubit.dart';
import '../repositories/project_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import 'app_modal.dart';
import 'token_help_accordion.dart';

/// Name, repo URL, and (create-mode only) an optional repo access token
/// with in-panel help (design doc §6.5.1). Opened from `projects_screen.dart`
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
