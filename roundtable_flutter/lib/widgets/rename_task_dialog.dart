import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_modal.dart';

/// Edits a task's title. Pops the new title — empty to clear it, so the
/// board falls back to the prompt — or null when cancelled.
class RenameTaskDialog extends StatefulWidget {
  const RenameTaskDialog({super.key, required this.taskId, this.title});

  final int taskId;
  final String? title;

  @override
  State<RenameTaskDialog> createState() => _RenameTaskDialogState();
}

class _RenameTaskDialogState extends State<RenameTaskDialog> {
  late final _controller = TextEditingController(text: widget.title ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.edit_outlined,
      title: 'Rename task',
      subtitle: 'Task #${widget.taskId}',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Title'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Leave empty to show the prompt instead.',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
