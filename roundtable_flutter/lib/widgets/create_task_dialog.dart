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

class CreateTaskDialog extends StatelessWidget {
  const CreateTaskDialog({super.key});

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
      child: const _CreateTaskDialogContent(),
    );
  }
}

class _CreateTaskDialogContent extends StatefulWidget {
  const _CreateTaskDialogContent();

  @override
  State<_CreateTaskDialogContent> createState() =>
      _CreateTaskDialogContentState();
}

class _CreateTaskDialogContentState extends State<_CreateTaskDialogContent> {
  final _promptController = TextEditingController();
  int? _projectId;
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
      child: AlertDialog(
        title: const Text('New task'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocBuilder<ProjectListCubit, ProjectListState>(
                  builder: (context, state) {
                    final projects = switch (state) {
                      ProjectListLoaded(:final projects) => projects,
                      _ => <Project>[],
                    };
                    return DropdownButtonFormField<int>(
                      initialValue: _projectId,
                      decoration: const InputDecoration(labelText: 'Project'),
                      items: [
                        for (final project in projects)
                          DropdownMenuItem(
                            value: project.id,
                            child: Text(project.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _projectId = value),
                    );
                  },
                ),
                const SizedBox(height: 12),
                BlocBuilder<AgentListCubit, AgentListState>(
                  builder: (context, state) {
                    final agents = switch (state) {
                      AgentListLoaded(:final agents) => agents,
                      _ => <Agent>[],
                    };
                    return DropdownButtonFormField<int>(
                      initialValue: _agentId,
                      decoration: const InputDecoration(labelText: 'Agent'),
                      items: [
                        for (final agent in agents)
                          DropdownMenuItem(
                            value: agent.id,
                            child: Text(agent.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _agentId = value),
                    );
                  },
                ),
                const SizedBox(height: 12),
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
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          state.message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
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
      ),
    );
  }
}
