import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/add_agent_cubit.dart';
import '../repositories/agent_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_modal.dart';
import 'pill_selector.dart';

const _presetModels = [
  'claude-haiku-4-5',
  'claude-sonnet-5',
  'claude-opus-4-7',
];

/// Name, role, model, effort, and execution mode (`docker` disabled —
/// schema-ready but not implemented, design doc §6.10). Opened from
/// `machines_screen.dart`, scoped to [machineId]/[machineName] — the design
/// brief shows this dialog as "on \<machine\>", not a machine picker.
class AddAgentDialog extends StatelessWidget {
  const AddAgentDialog({
    super.key,
    required this.machineId,
    required this.machineName,
  });

  final int machineId;
  final String machineName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddAgentCubit(AgentRepository(client)),
      child: _AddAgentDialogContent(
        machineId: machineId,
        machineName: machineName,
      ),
    );
  }
}

class _AddAgentDialogContent extends StatefulWidget {
  const _AddAgentDialogContent({
    required this.machineId,
    required this.machineName,
  });

  final int machineId;
  final String machineName;

  @override
  State<_AddAgentDialogContent> createState() => _AddAgentDialogContentState();
}

class _AddAgentDialogContentState extends State<_AddAgentDialogContent> {
  final _nameController = TextEditingController();
  AgentRole _role = AgentRole.generalist;
  String? _model;
  AgentEffort? _effort;
  AgentExecutionMode _executionMode = AgentExecutionMode.native;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddAgentCubit, AddAgentState>(
      listener: (context, state) {
        if (state is AddAgentSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      child: BlocBuilder<AddAgentCubit, AddAgentState>(
        builder: (context, state) {
          final submitting = state is AddAgentSubmitting;
          return AppModal(
            title: 'Add agent',
            subtitle: 'on ${widget.machineName}',
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: (_canSubmit && !submitting)
                    ? () => context.read<AddAgentCubit>().submit(
                        name: _nameController.text.trim(),
                        machineId: widget.machineId,
                        role: _role,
                        defaultModel: _model,
                        defaultEffort: _effort,
                      )
                    : null,
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add agent'),
              ),
            ],
            child: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: Spacing.lg),
                    Text(
                      'Role — a prompt prefix, not a permission',
                      style: AppTypography.label,
                    ),
                    const SizedBox(height: Spacing.sm),
                    PillSelector<AgentRole>(
                      options: AgentRole.values,
                      labelBuilder: (role) => role.name,
                      selected: _role,
                      onChanged: (role) => setState(() => _role = role),
                    ),
                    const SizedBox(height: Spacing.lg),
                    Text(
                      'Default model — optional',
                      style: AppTypography.label,
                    ),
                    const SizedBox(height: Spacing.sm),
                    PillSelector<String?>(
                      options: [null, ..._presetModels],
                      labelBuilder: (model) => model ?? 'Use default',
                      selected: _model,
                      onChanged: (model) => setState(() => _model = model),
                    ),
                    const SizedBox(height: Spacing.lg),
                    Text(
                      'Default effort — optional',
                      style: AppTypography.label,
                    ),
                    const SizedBox(height: Spacing.sm),
                    PillSelector<AgentEffort?>(
                      options: [null, ...AgentEffort.values],
                      labelBuilder: (effort) => effort?.name ?? 'default',
                      selected: _effort,
                      onChanged: (effort) => setState(() => _effort = effort),
                    ),
                    const SizedBox(height: Spacing.lg),
                    Text('Execution mode', style: AppTypography.label),
                    const SizedBox(height: Spacing.sm),
                    PillSelector<AgentExecutionMode>(
                      options: AgentExecutionMode.values,
                      labelBuilder: (mode) => mode.name,
                      selected: _executionMode,
                      onChanged: (mode) =>
                          setState(() => _executionMode = mode),
                      disabledOptions: const {AgentExecutionMode.docker},
                      disabledHint: 'Coming soon',
                    ),
                    if (state is AddAgentError) ...[
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
