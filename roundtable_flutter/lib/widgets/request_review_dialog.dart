import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../blocs/task_detail_bloc.dart';
import 'agent_picker.dart';
import 'app_modal.dart';

/// Picks an idle agent to review a task's PR. Shown via `showDialog` with a
/// `BlocProvider.value` wrapping the caller's `TaskDetailBloc`, like
/// `ReassignAgentDialog`.
class RequestReviewDialog extends StatefulWidget {
  const RequestReviewDialog({super.key, required this.taskId});

  final int taskId;

  @override
  State<RequestReviewDialog> createState() => _RequestReviewDialogState();
}

class _RequestReviewDialogState extends State<RequestReviewDialog> {
  int? _agentId;

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.rate_review_outlined,
      title: 'Request AI review',
      subtitle:
          'The reviewer reads the PR diff and leaves comments here and on '
          'GitHub. It does not change any code.',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _agentId == null
              ? null
              : () {
                  context.read<TaskDetailBloc>().add(
                    ReviewRequested(widget.taskId, _agentId!),
                  );
                  Navigator.of(context).pop();
                },
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text('Start review'),
        ),
      ],
      child: AgentPicker(
        selected: _agentId,
        onChanged: (id) => setState(() => _agentId = id),
        // A review runs right away, so only a free agent on a live machine
        // can take it.
        unavailableReason: (agent, machine) {
          if (machine?.status == MachineStatus.offline) {
            return 'Machine offline';
          }
          if (agent.status != AgentStatus.idle) return 'Busy with another task';
          return null;
        },
      ),
    );
  }
}
