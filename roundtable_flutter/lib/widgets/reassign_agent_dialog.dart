import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../blocs/task_detail_bloc.dart';
import '../client.dart';
import '../cubits/agent_list_cubit.dart';
import '../repositories/agent_repository.dart';
import 'app_modal.dart';
import 'pill_selector.dart';

/// Lets the dev assign or reassign a task's agent — either giving an
/// agent-less task one (its previous agent was deleted, its `Agent` relation
/// is `onDelete=Cascade`ing to no agent left) or moving a backlog/review
/// task to a different agent (design doc §5). Shown via `showDialog` with a
/// `BlocProvider.value` wrapping the caller's `TaskDetailBloc`, since
/// `showDialog` uses the root navigator and wouldn't otherwise see it.
class ReassignAgentDialog extends StatefulWidget {
  const ReassignAgentDialog({
    super.key,
    required this.taskId,
    this.currentAgentId,
  });

  final int taskId;
  final int? currentAgentId;

  @override
  State<ReassignAgentDialog> createState() => _ReassignAgentDialogState();
}

class _ReassignAgentDialogState extends State<ReassignAgentDialog> {
  late int? _agentId = widget.currentAgentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AgentListCubit(AgentRepository(client))..fetchAgents(),
      child: AppModal(
        title: widget.currentAgentId == null
            ? 'Assign agent'
            : 'Reassign agent',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          BlocBuilder<TaskDetailBloc, TaskDetailState>(
            builder: (context, state) {
              final submitting = state is TaskDetailLoaded && state.submitting;
              final agentId = _agentId;
              return FilledButton(
                onPressed: (agentId != null && !submitting)
                    ? () {
                        context.read<TaskDetailBloc>().add(
                          AgentReassigned(widget.taskId, agentId),
                        );
                        Navigator.of(context).pop();
                      }
                    : null,
                child: const Text('Assign'),
              );
            },
          ),
        ],
        child: SizedBox(
          width: 420,
          child: BlocBuilder<AgentListCubit, AgentListState>(
            builder: (context, state) {
              final agents = switch (state) {
                AgentListLoaded(:final agents) => agents,
                _ => <Agent>[],
              };
              return PillSelector<int>(
                options: [for (final a in agents) a.id!],
                labelBuilder: (id) => agents.firstWhere((a) => a.id == id).name,
                selected: _agentId,
                onChanged: (id) => setState(() => _agentId = id),
              );
            },
          ),
        ),
      ),
    );
  }
}
