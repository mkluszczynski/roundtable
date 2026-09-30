import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../cubits/agent_list_cubit.dart';
import '../cubits/machine_list_cubit.dart';
import '../screens/task_detail_screen.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'kanban_card.dart';

/// One kanban column: title + count badge + task cards, resolving each
/// task's agent/machine name from the ancestor `AgentListCubit`/
/// `MachineListCubit` (present on both the Dashboard and a project's detail
/// screen). The caller decides layout — `Expanded` for the Dashboard's
/// flexible columns, a fixed-width `SizedBox` for a project's horizontally
/// scrolling board.
class KanbanColumnView extends StatelessWidget {
  const KanbanColumnView({super.key, required this.title, required this.tasks});

  final String title;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final agents = switch (context.watch<AgentListCubit>().state) {
      AgentListLoaded(:final agents) => agents,
      _ => const <Agent>[],
    };
    final machines = switch (context.watch<MachineListCubit>().state) {
      MachineListLoaded(:final machines) => machines,
      _ => const <Machine>[],
    };
    Agent? agentFor(int? id) {
      if (id == null) return null;
      for (final agent in agents) {
        if (agent.id == id) return agent;
      }
      return null;
    }

    Machine? machineFor(int machineId) {
      for (final machine in machines) {
        if (machine.id == machineId) return machine;
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title.toUpperCase(), style: AppTypography.label),
            const SizedBox(width: Spacing.xs),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: 1,
                ),
                child: Text('${tasks.length}', style: AppTypography.caption),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: ListView(
            children: [
              for (final task in tasks)
                KanbanCard(
                  task: task,
                  agentName: agentFor(task.agentId)?.name,
                  machineName: agentFor(task.agentId) == null
                      ? null
                      : machineFor(agentFor(task.agentId)!.machineId)?.name,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TaskDetailScreen(initialTaskId: task.id!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
