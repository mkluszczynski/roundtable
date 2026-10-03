import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../blocs/task_detail_bloc.dart';
import '../client.dart';
import '../cubits/agent_list_cubit.dart';
import '../repositories/agent_repository.dart';
import '../theme/typography.dart';
import 'app_modal.dart';
import 'pill_selector.dart';

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
    return BlocProvider(
      create: (_) => AgentListCubit(AgentRepository(client))..fetchAgents(),
      child: AppModal(
        title: 'Request AI review',
        subtitle:
            'The reviewer reads the PR diff and leaves comments here and on '
            'GitHub. It does not change any code.',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _agentId == null
                ? null
                : () {
                    context.read<TaskDetailBloc>().add(
                      ReviewRequested(widget.taskId, _agentId!),
                    );
                    Navigator.of(context).pop();
                  },
            child: const Text('Start review'),
          ),
        ],
        child: SizedBox(
          width: 420,
          child: BlocBuilder<AgentListCubit, AgentListState>(
            builder: (context, state) {
              final agents = switch (state) {
                AgentListLoaded(:final agents) =>
                  agents.where((a) => a.status == AgentStatus.idle).toList(),
                _ => <Agent>[],
              };
              if (state is AgentListLoaded && agents.isEmpty) {
                return Text(
                  'No idle agents right now.',
                  style: AppTypography.body,
                );
              }
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
