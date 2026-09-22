import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/agent_list_cubit.dart';
import '../cubits/create_task_cubit.dart';
import '../cubits/project_list_cubit.dart';
import '../repositories/agent_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_modal.dart';
import 'pill_selector.dart';

class CreateTaskDialog extends StatelessWidget {
  const CreateTaskDialog({super.key, this.initialProjectId});

  /// When set (opened from `project_detail_screen.dart`'s "New task"), the
  /// project is fixed and its `PillSelector` is hidden — same pattern as
  /// `AddAgentDialog`'s scoped machine.
  final int? initialProjectId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ProjectListCubit(ProjectRepository(client))..fetchProjects(),
        ),
        BlocProvider(
          create: (_) => AgentListCubit(AgentRepository(client))..fetchAgents(),
        ),
        BlocProvider(create: (_) => CreateTaskCubit(TaskRepository(client))),
      ],
      child: _CreateTaskDialogContent(initialProjectId: initialProjectId),
    );
  }
}

class _CreateTaskDialogContent extends StatefulWidget {
  const _CreateTaskDialogContent({this.initialProjectId});

  final int? initialProjectId;

  @override
  State<_CreateTaskDialogContent> createState() =>
      _CreateTaskDialogContentState();
}

class _CreateTaskDialogContentState extends State<_CreateTaskDialogContent> {
  final _promptController = TextEditingController();
  late int? _projectId = widget.initialProjectId;
  int? _agentId;
  bool _skipPlanning = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _projectId != null &&
      _agentId != null &&
      _promptController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateTaskCubit, CreateTaskState>(
      listener: (context, state) {
        if (state is CreateTaskSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created')),
          );
        }
      },
      child: AppModal(
        title: 'New task',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          BlocBuilder<CreateTaskCubit, CreateTaskState>(
            builder: (context, state) {
              final submitting = state is CreateTaskSubmitting;
              return FilledButton(
                onPressed: (_canSubmit && !submitting)
                    ? () => context.read<CreateTaskCubit>().submit(
                        projectId: _projectId!,
                        agentId: _agentId!,
                        prompt: _promptController.text.trim(),
                        skipPlanning: _skipPlanning,
                      )
                    : null,
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              );
            },
          ),
        ],
        child: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.initialProjectId == null) ...[
                  Text('Project', style: AppTypography.label),
                  const SizedBox(height: Spacing.sm),
                  BlocBuilder<ProjectListCubit, ProjectListState>(
                    builder: (context, state) {
                      final projects = switch (state) {
                        ProjectListLoaded(:final projects) => projects,
                        _ => <Project>[],
                      };
                      return PillSelector<int>(
                        options: [for (final p in projects) p.id!],
                        labelBuilder: (id) =>
                            projects.firstWhere((p) => p.id == id).name,
                        selected: _projectId,
                        onChanged: (id) => setState(() => _projectId = id),
                      );
                    },
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
                Text('Agent', style: AppTypography.label),
                const SizedBox(height: Spacing.sm),
                BlocBuilder<AgentListCubit, AgentListState>(
                  builder: (context, state) {
                    final agents = switch (state) {
                      AgentListLoaded(:final agents) => agents,
                      _ => <Agent>[],
                    };
                    return PillSelector<int>(
                      options: [for (final a in agents) a.id!],
                      labelBuilder: (id) =>
                          agents.firstWhere((a) => a.id == id).name,
                      selected: _agentId,
                      onChanged: (id) => setState(() => _agentId = id),
                    );
                  },
                ),
                const SizedBox(height: Spacing.lg),
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: 'Prompt',
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 6,
                  onChanged: (_) => setState(() {}),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _skipPlanning,
                  activeColor: AppColors.accent,
                  title: const Text('Skip planning'),
                  subtitle: const Text(
                    'Go straight to execution — saves usage on trivial tasks',
                  ),
                  onChanged: (value) =>
                      setState(() => _skipPlanning = value ?? false),
                ),
                BlocBuilder<CreateTaskCubit, CreateTaskState>(
                  builder: (context, state) {
                    if (state is CreateTaskError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: Spacing.md),
                        child: Text(
                          state.message,
                          style: const TextStyle(color: AppColors.red),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
