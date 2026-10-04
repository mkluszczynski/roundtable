import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/task_detail_bloc.dart';
import 'agent_picker.dart';
import 'app_modal.dart';

/// Lets the dev assign or reassign a task's agent — either giving an
/// agent-less task one (its previous agent was deleted, its `Agent` relation
/// is `onDelete=Cascade`ing to no agent left) or moving a backlog/review
/// task to a different agent (docs/ARCHITECTURE.md). Shown via `showDialog`
/// with a
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
    final current = widget.currentAgentId;
    return AppModal(
      icon: current == null ? Icons.person_add_alt_1 : Icons.swap_horiz,
      title: current == null ? 'Assign agent' : 'Reassign agent',
      subtitle: current == null
          ? 'Pick who works on Task #${widget.taskId}. It starts right away.'
          : 'Move Task #${widget.taskId} to another agent.',
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
              onPressed: (agentId != null && agentId != current && !submitting)
                  ? () {
                      context.read<TaskDetailBloc>().add(
                        AgentReassigned(widget.taskId, agentId),
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
              child: Text(current == null ? 'Assign' : 'Reassign'),
            );
          },
        ),
      ],
      child: AgentPicker(
        selected: _agentId,
        currentAgentId: current,
        onChanged: (id) => setState(() => _agentId = id),
      ),
    );
  }
}
