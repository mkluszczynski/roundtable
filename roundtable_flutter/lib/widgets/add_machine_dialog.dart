import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/add_machine_cubit.dart';
import '../repositories/machine_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_modal.dart';
import 'claude_token_help_accordion.dart';
import 'code_block.dart';

/// Two-step machine setup (docs/FLOWS.md §1): a form, then the install
/// command with a one-time token. The machine is created by the install
/// script, not here — the second step waits for it to show up. Opened from
/// `machines_screen.dart`.
class AddMachineDialog extends StatelessWidget {
  const AddMachineDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddMachineCubit(MachineRepository(client)),
      child: const _AddMachineDialogContent(),
    );
  }
}

class _AddMachineDialogContent extends StatefulWidget {
  const _AddMachineDialogContent();

  @override
  State<_AddMachineDialogContent> createState() =>
      _AddMachineDialogContentState();
}

class _AddMachineDialogContentState extends State<_AddMachineDialogContent> {
  final _nameController = TextEditingController();
  final _claudeTokenController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _claudeTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddMachineCubit, AddMachineState>(
      builder: (context, state) {
        if (state is AddMachineCommandReady) {
          return _InstallStep(
            command: state.command,
            machine: state.machine,
            claudeToken: _claudeTokenController.text.trim(),
          );
        }

        final submitting = state is AddMachineSubmitting;
        final canSubmit = !submitting;
        return AppModal(
          icon: Icons.dns_outlined,

          title: 'Add machine',
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: canSubmit
                  ? () => context.read<AddMachineCubit>().submit(
                      _nameController.text.trim(),
                    )
                  : null,
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Get install command'),
            ),
          ],
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name (optional)',
                    hintText: "Defaults to the machine's hostname",
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'The machine appears once the install command has run on '
                  'it. Its OS version is detected automatically.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: Spacing.lg),
                TextField(
                  controller: _claudeTokenController,
                  decoration: const InputDecoration(
                    labelText: 'Claude Code OAuth token (optional)',
                    hintText: 'Or set it on the machine once it shows up',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: Spacing.sm),
                const ClaudeTokenHelpAccordion(),
                if (state is AddMachineError) ...[
                  const SizedBox(height: Spacing.md),
                  Text(
                    state.message,
                    style: const TextStyle(color: AppColors.red),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InstallStep extends StatefulWidget {
  const _InstallStep({
    required this.command,
    required this.machine,
    required this.claudeToken,
  });

  final MachineInstallCommand command;

  /// The machine the command created, once install-agent.sh has run it.
  final Machine? machine;

  /// Claude Code OAuth token entered in the form step — never sent to the
  /// server (docs/ARCHITECTURE.md), only folded into the install command below.
  final String claudeToken;

  @override
  State<_InstallStep> createState() => _InstallStepState();
}

class _InstallStepState extends State<_InstallStep> {
  /// Adds `--docker`: installs rootless Podman for docker-mode agents.
  bool _docker = false;

  @override
  Widget build(BuildContext context) {
    final _InstallStep(:command, :machine, :claudeToken) = widget;
    final scriptUrl = command.scriptUrl;
    final installCommand =
        'curl -fsSL $scriptUrl/install-agent.sh | sudo bash -s -- '
        '--enroll ${command.enrollmentToken} --server ${command.serverUrl} '
        '--script-url $scriptUrl'
        "${claudeToken.isEmpty ? '' : " --claude-token '$claudeToken'"}"
        "${_docker ? ' --docker' : ''}";
    final expires = command.expiresAt.toLocal();
    final expiresAt =
        '${expires.hour.toString().padLeft(2, '0')}:'
        '${expires.minute.toString().padLeft(2, '0')}';
    return AppModal(
      icon: machine == null ? Icons.terminal : Icons.check_circle_outline,
      title: machine == null ? 'Install the runner' : 'Machine added',
      subtitle: machine?.name,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(machine == null ? 'Close' : 'Done'),
        ),
      ],
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Run this command on the target machine. It works once and '
              'expires at $expiresAt.',
              style: AppTypography.body,
            ),
            const SizedBox(height: Spacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _docker,
              activeThumbColor: AppColors.accent,
              onChanged: (v) => setState(() => _docker = v),
              title: Text('With docker mode', style: AppTypography.bodyStrong),
              subtitle: Text(
                'Installs rootless Podman, so agents set to docker run their '
                'tasks in a container that sees only their worktree.',
                style: AppTypography.caption,
              ),
            ),
            const SizedBox(height: Spacing.md),
            CodeBlock(code: installCommand),
            const SizedBox(height: Spacing.lg),
            if (machine == null)
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Waiting for the machine to finish installing…',
                    style: AppTypography.caption,
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.live,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      '${machine.name} is installed. Add agents to it from '
                      'the Machines screen.',
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
