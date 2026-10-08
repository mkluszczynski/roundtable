import '../utils/status_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../cubits/dashboard_cubit.dart';
import '../screens/machine_detail_screen.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/relative_time.dart';
import 'agent_row.dart';
import 'app_card.dart';
import 'machine_metrics.dart';
import 'status_pill.dart';

/// A machine card for the dashboard's machines panel: status, live CPU/RAM
/// and the agents hosted on it with what each is working on. An offline
/// machine collapses to a single line. Tapping opens the machine.
class MachineSummaryCard extends StatelessWidget {
  const MachineSummaryCard({
    super.key,
    required this.machine,
    this.agents = const [],
  });

  final Machine machine;
  final List<Agent> agents;

  @override
  Widget build(BuildContext context) {
    final online = machine.isOnline;
    final dashboard = context.watch<DashboardCubit>().state;
    final lastSeen = machine.lastSeenAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Opacity(
        opacity: online ? 1 : 0.6,
        child: AppCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MachineDetailScreen(machineId: machine.id!),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusDot.fromAppearance(
                    machineStatusAppearance(machine.status),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      machine.name,
                      style: AppTypography.bodyStrong,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!online)
                    Text(
                      lastSeen == null
                          ? 'offline'
                          : 'seen ${relativeTime(lastSeen)}',
                      style: AppTypography.caption,
                    )
                  else
                    Text(
                      '${agents.length} agent${agents.length == 1 ? '' : 's'}',
                      style: AppTypography.caption,
                    ),
                ],
              ),
              if (online) ...[
                const SizedBox(height: Spacing.md),
                MachineMetrics(machineId: machine.id!),
                if (agents.isNotEmpty) ...[
                  const SizedBox(height: Spacing.md),
                  Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: Spacing.sm),
                  for (final agent in agents)
                    AgentRow(
                      agent: agent,
                      showDetails: false,
                      currentTask: dashboard is DashboardLoaded
                          ? dashboard.currentTaskFor(agent.id!)
                          : null,
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
