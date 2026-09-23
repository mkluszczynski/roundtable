import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../client.dart';
import '../cubits/add_machine_cubit.dart';
import '../repositories/machine_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_modal.dart';
import 'code_block.dart';

/// Two-step machine registration (design doc §6.8): a name form, then the
/// generated one-time token + install command — shown once, no back button
/// once generated. Opened from `machines_screen.dart`.
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
  final _hostInfoController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _hostInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddMachineCubit, AddMachineState>(
      builder: (context, state) {
        if (state is AddMachineRegistered) {
          return _RegisteredStep(
            machineName: state.machine.name,
            token: state.token,
            serverUrl: state.serverUrl,
            scriptUrl: state.scriptUrl,
          );
        }

        final submitting = state is AddMachineSubmitting;
        return AppModal(
          title: 'Add machine',
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: (!submitting && _nameController.text.trim().isNotEmpty)
                  ? () => context.read<AddMachineCubit>().submit(
                      _nameController.text.trim(),
                      hostInfo: _hostInfoController.text.trim().isEmpty
                          ? null
                          : _hostInfoController.text.trim(),
                    )
                  : null,
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register'),
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
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Spacing.lg),
                TextField(
                  controller: _hostInfoController,
                  decoration: const InputDecoration(
                    labelText: 'Host/OS (optional)',
                    hintText: 'e.g. Hetzner · Ubuntu 22.04',
                  ),
                ),
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

class _RegisteredStep extends StatelessWidget {
  const _RegisteredStep({
    required this.machineName,
    required this.token,
    required this.serverUrl,
    required this.scriptUrl,
  });

  final String machineName;
  final String token;
  final String serverUrl;
  final String scriptUrl;

  @override
  Widget build(BuildContext context) {
    final command =
        'curl -fsSL $scriptUrl/install-agent.sh | bash -s -- '
        '--token $token --server $serverUrl';
    return AppModal(
      title: 'Machine registered',
      subtitle: machineName,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Done'),
        ),
      ],
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This token is shown once. Run the following command on the '
              'target machine to install the agent runner:',
              style: AppTypography.body,
            ),
            const SizedBox(height: Spacing.lg),
            CodeBlock(code: command),
          ],
        ),
      ),
    );
  }
}
