import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/add_agent_cubit.dart';
import '../repositories/agent_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'agent_avatar.dart';
import 'app_modal.dart';
import 'pill_selector.dart';
import 'tag_chip.dart';

const _presetModels = [
  'claude-haiku-4-5',
  'claude-sonnet-5',
  'claude-opus-4-7',
];

/// Name, role, model, effort, and execution mode (`docker` disabled —
/// schema-ready but not implemented). Opened from `machines_screen.dart`,
/// scoped to [machineId]/[machineName] — the design brief shows this dialog
/// as "on \<machine\>", not a machine picker. With [existingAgent] it edits
/// that agent instead (execution mode is then fixed).
class AddAgentDialog extends StatelessWidget {
  const AddAgentDialog({
    super.key,
    required this.machineId,
    required this.machineName,
    this.existingAgent,
  });

  final int machineId;
  final String machineName;
  final Agent? existingAgent;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddAgentCubit(AgentRepository(client)),
      child: _AddAgentDialogContent(
        machineId: machineId,
        machineName: machineName,
        existingAgent: existingAgent,
      ),
    );
  }
}

class _AddAgentDialogContent extends StatefulWidget {
  const _AddAgentDialogContent({
    required this.machineId,
    required this.machineName,
    this.existingAgent,
  });

  final int machineId;
  final String machineName;
  final Agent? existingAgent;

  @override
  State<_AddAgentDialogContent> createState() => _AddAgentDialogContentState();
}

class _AddAgentDialogContentState extends State<_AddAgentDialogContent> {
  late final _nameController = TextEditingController(
    text: widget.existingAgent?.name,
  );
  late AgentRole _role = widget.existingAgent?.role ?? AgentRole.generalist;
  late String? _model = widget.existingAgent?.defaultModel;
  late AgentEffort? _effort = widget.existingAgent?.defaultEffort;
  late AgentExecutionMode _executionMode =
      widget.existingAgent?.executionMode ?? AgentExecutionMode.native;

  bool get _editing => widget.existingAgent != null;

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
            icon: Icons.smart_toy_outlined,
            title: _editing ? 'Edit agent' : 'Add agent',
            subtitle: 'on ${widget.machineName}',
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: (_canSubmit && !submitting)
                    ? () => _editing
                          ? context.read<AddAgentCubit>().update(
                              existing: widget.existingAgent!,
                              name: _nameController.text.trim(),
                              role: _role,
                              defaultModel: _model,
                              defaultEffort: _effort,
                            )
                          : context.read<AddAgentCubit>().submit(
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
                    : Text(_editing ? 'Save' : 'Add agent'),
              ),
            ],
            child: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AgentPreview(
                      name: _nameController.text.trim(),
                      role: _role,
                      model: _model,
                      effort: _effort,
                    ),
                    const SizedBox(height: Spacing.xl),
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
                      options: [
                        null,
                        ..._presetModels,
                        // Keep a custom model set elsewhere selectable.
                        if (_model != null && !_presetModels.contains(_model))
                          _model,
                      ],
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
                      disabledOptions: _editing
                          ? AgentExecutionMode.values
                                .where((m) => m != _executionMode)
                                .toSet()
                          : const {AgentExecutionMode.docker},
                      disabledHint: _editing ? "Can't change" : 'Coming soon',
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

/// How the agent will look in pickers, updated as the form changes.
class _AgentPreview extends StatelessWidget {
  const _AgentPreview({
    required this.name,
    required this.role,
    required this.model,
    required this.effort,
  });

  final String name;
  final AgentRole role;
  final String? model;
  final AgentEffort? effort;

  @override
  Widget build(BuildContext context) {
    final displayName = name.isEmpty ? 'New agent' : name;
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.16),
            AppColors.bg2,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: 36,
            child: FittedBox(child: AgentAvatar(name: displayName)),
          ),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTypography.cardTitle.copyWith(
                    color: name.isEmpty ? AppColors.text2 : AppColors.text0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text('${role.name} specialist', style: AppTypography.caption),
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.xs,
                  runSpacing: Spacing.xs,
                  children: [
                    TagChip(model ?? 'default model'),
                    TagChip('effort: ${effort?.name ?? 'default'}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
