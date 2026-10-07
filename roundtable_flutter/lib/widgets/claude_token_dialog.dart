import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../cubits/machine_list_cubit.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/error_message.dart';
import '../utils/relative_time.dart';
import 'app_modal.dart';
import 'claude_token_help_accordion.dart';

/// Sets the Claude Code OAuth token [machine]'s daemon runs `claude` with
/// (docs/FLOWS.md §1). The daemon picks it up at its next check-in; the
/// panel can never read it back.
class ClaudeTokenDialog extends StatefulWidget {
  const ClaudeTokenDialog({super.key, required this.machine});

  final Machine machine;

  @override
  State<ClaudeTokenDialog> createState() => _ClaudeTokenDialogState();
}

class _ClaudeTokenDialogState extends State<ClaudeTokenDialog> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<MachineListCubit>().setClaudeToken(
        widget.machine.id!,
        _controller.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
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
    final canSave = !_saving && _controller.text.trim().isNotEmpty;
    return AppModal(
      icon: Icons.key_outlined,
      title: 'Claude token',
      subtitle: widget.machine.name,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSave ? _save : null,
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
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agents on this machine run Claude Code with this token. It '
              'replaces the one from the install and reaches the machine '
              'within about 20 seconds. Runs already in progress keep the '
              'old one.',
              style: AppTypography.body,
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Claude Code OAuth token',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => canSave ? _save() : null,
            ),
            const SizedBox(height: Spacing.sm),
            const ClaudeTokenHelpAccordion(),
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

/// The machine's Claude credentials, with the action to set a token:
/// a warning when it has none, the token on its way, or when it was set.
class ClaudeAuthStatus extends StatelessWidget {
  const ClaudeAuthStatus({
    super.key,
    required this.machine,
    this.compact = false,
  });

  final Machine machine;

  /// On a machine card: only shown when something needs attention.
  final bool compact;

  static bool needsAttention(Machine machine) =>
      machine.claudeAuthSource == ClaudeAuthSource.none ||
      machine.claudeTokenRequestedAt != null;

  @override
  Widget build(BuildContext context) {
    if (compact && !needsAttention(machine)) return const SizedBox.shrink();
    final (icon, color, text) = switch (machine) {
      Machine(claudeTokenRequestedAt: != null) => (
        Icons.schedule,
        AppColors.text1,
        'New Claude token sent — the machine applies it at its next '
            'check-in',
      ),
      Machine(claudeAuthSource: ClaudeAuthSource.none) => (
        Icons.key_off_outlined,
        AppColors.warning,
        'No Claude token — tasks on this machine will fail',
      ),
      Machine(claudeAuthSource: ClaudeAuthSource.panel) => (
        Icons.check_circle_outline,
        AppColors.live,
        machine.claudeTokenSetAt == null
            ? 'Token set in the panel'
            : 'Token set in the panel '
                  '${relativeTime(machine.claudeTokenSetAt!, words: true)}',
      ),
      Machine(claudeAuthSource: ClaudeAuthSource.install) => (
        Icons.check_circle_outline,
        AppColors.live,
        'Token from the install',
      ),
      Machine(claudeAuthSource: ClaudeAuthSource.login) => (
        Icons.check_circle_outline,
        AppColors.live,
        'Signed in with claude login',
      ),
      _ => (Icons.help_outline, AppColors.text2, 'Not reported yet'),
    };
    // The daemon only picks a token up while online, and only if its
    // runner knows how to — runners that do also report claudeAuthSource.
    final blocked = machine.status != MachineStatus.online
        ? 'Available while the machine is online'
        : machine.claudeAuthSource == null
        ? 'Update the runner to set a token here'
        : null;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(color: color),
          ),
        ),
        if (blocked != null)
          Tooltip(
            message: blocked,
            child: const TextButton(onPressed: null, child: Text('Set token')),
          )
        else
          TextButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<MachineListCubit>(),
                child: ClaudeTokenDialog(machine: machine),
              ),
            ),
            child: Text(
              machine.claudeAuthSource == ClaudeAuthSource.none
                  ? 'Set token'
                  : 'Replace',
            ),
          ),
      ],
    );
  }
}
