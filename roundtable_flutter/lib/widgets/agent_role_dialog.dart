import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../repositories/agent_role_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/error_message.dart';
import 'app_modal.dart';

/// Creates a role, or edits [existing]. Pops the saved role.
class AgentRoleDialog extends StatefulWidget {
  const AgentRoleDialog({super.key, this.existing});

  final AgentRoleDefinition? existing;

  @override
  State<AgentRoleDialog> createState() => _AgentRoleDialogState();
}

class _AgentRoleDialogState extends State<AgentRoleDialog> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _description = TextEditingController(
    text: widget.existing?.description,
  );
  late final _prompt = TextEditingController(
    text: widget.existing?.prompt ?? 'You are {name}, ',
  );
  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  bool get _canSave =>
      !_saving &&
      _name.text.trim().isNotEmpty &&
      _prompt.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final repository = AgentRoleRepository(client);
    final role = (widget.existing ?? AgentRoleDefinition(name: '', prompt: ''))
        .copyWith(
          name: _name.text,
          description: _description.text,
          prompt: _prompt.text,
        );
    try {
      final saved = _editing
          ? await repository.updateRole(role)
          : await repository.createRole(role);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = errorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.badge_outlined,
      title: _editing ? 'Edit role' : 'New role',
      subtitle:
          'The prompt opens every task and review an agent with this role '
          'gets. Changes apply from the next run.',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: Text(_editing ? 'Save' : 'Add role'),
        ),
      ],
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: !_editing,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. backend, reviewer, mobile',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description — optional',
                hintText: 'One line shown when picking a role',
              ),
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _prompt,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                alignLabelWithHint: true,
              ),
              minLines: 4,
              maxLines: 10,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              '{name} becomes the agent\'s name, e.g. "You are {name}, the '
              'backend specialist."',
              style: AppTypography.caption,
            ),
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
