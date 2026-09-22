import 'package:flutter/material.dart';

import '../client.dart';
import '../repositories/project_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import 'app_modal.dart';
import 'token_help_accordion.dart';

/// Sets a project's repo access token (design doc §6.5.1) — a single write
/// call, so this manages its own local submitting/error state rather than a
/// full cubit. Opened from `project_detail_screen.dart`'s "Update token".
class UpdateTokenDialog extends StatefulWidget {
  const UpdateTokenDialog({super.key, required this.projectId});

  final int projectId;

  @override
  State<UpdateTokenDialog> createState() => _UpdateTokenDialogState();
}

class _UpdateTokenDialogState extends State<UpdateTokenDialog> {
  final _tokenController = TextEditingController();
  final _repository = ProjectRepository(client);
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.updateRepoAccessToken(
        widget.projectId,
        _tokenController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _tokenController.text.trim().isNotEmpty;
    return AppModal(
      title: 'Update token',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (canSubmit && !_submitting) ? _submit : null,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update token'),
        ),
      ],
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'New repo access token',
              ),
              obscureText: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Spacing.sm),
            const TokenHelpAccordion(),
            if (_error != null) ...[
              const SizedBox(height: Spacing.md),
              Text(_error!, style: const TextStyle(color: AppColors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
