import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/error_message.dart';
import 'app_modal.dart';
import 'task_options_form.dart';

const _promptEditableStatuses = {
  TaskStatus.draft,
  TaskStatus.queued,
  TaskStatus.failed,
  TaskStatus.cancelled,
};

/// Mirrors the server's `updateTaskSettings` guard: the prompt and skip
/// planning only matter when a run starts — before the first one, or
/// before a retry. A task queued to resume a paused run continues its
/// session instead, so they're locked then too.
bool canEditPrompt(Task task) =>
    _promptEditableStatuses.contains(task.status) &&
    !(task.status == TaskStatus.queued && task.pausedPhase != null);

/// Edits a task's prompt and advanced options. [onSave] sends them to the
/// server; the dialog closes once it succeeds and shows its error otherwise
/// (e.g. the task started in the meantime). The task view gets the change
/// through `watchTask`, like any other.
class EditTaskDialog extends StatefulWidget {
  const EditTaskDialog({super.key, required this.task, required this.onSave});

  final Task task;
  final Future<void> Function(String prompt, TaskOptions options) onSave;

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late final _promptController = TextEditingController(
    text: widget.task.prompt,
  );
  late final _initialOptions = TaskOptions.fromTask(widget.task);
  late TaskOptions _options = _initialOptions;
  bool _saving = false;
  String? _error;

  bool get _promptEditable => canEditPrompt(widget.task);

  bool get _changed =>
      _promptController.text.trim() != widget.task.prompt ||
      _options != _initialOptions;

  bool get _canSave =>
      !_saving && _changed && _promptController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_promptController.text.trim(), _options);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.tune,
      title: 'Edit task',
      subtitle: 'Task #${widget.task.id}',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
      child: SizedBox(
        width: 496,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PROMPT', style: AppTypography.label),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: _promptController,
                enabled: _promptEditable,
                decoration: const InputDecoration(alignLabelWithHint: true),
                minLines: 4,
                maxLines: 8,
                onChanged: (_) => setState(() {}),
              ),
              if (!_promptEditable) ...[
                const SizedBox(height: Spacing.xs),
                Text(
                  'The prompt can\'t change once the agent has started — '
                  'send it feedback instead.',
                  style: AppTypography.caption,
                ),
              ],
              const SizedBox(height: Spacing.xl),
              Text('ADVANCED', style: AppTypography.label),
              TaskOptionsForm(
                options: _options,
                planningEditable: _promptEditable,
                onChanged: (options) => setState(() => _options = options),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.md),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
