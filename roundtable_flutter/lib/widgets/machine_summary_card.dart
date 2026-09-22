import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/machine_metric_cubit.dart';
import '../repositories/machine_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/relative_time.dart';
import 'app_card.dart';
import 'metric_bar.dart';
import 'status_pill.dart';

/// A machine card for the dashboard's machines panel: status + live CPU/RAM
/// bars + the agents hosted on it, per `docs/UI-DESIGN.md`/the design brief.
class MachineSummaryCard extends StatelessWidget {
  const MachineSummaryCard({
    super.key,
    required this.machine,
    this.agents = const [],
  });

  final Machine machine;
  final List<Agent> agents;

  String _offlineCaption() {
    final lastSeen = machine.lastSeenAt;
    if (lastSeen == null) return 'Offline';
    return 'Offline — last seen ${relativeTime(lastSeen)}';
  }

  @override
  Widget build(BuildContext context) {
    final online = machine.status == MachineStatus.online;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusDot.fromAppearance(
                  machineStatusAppearance(machine.status),
                ),
                const SizedBox(width: Spacing.sm),
                Text(machine.name, style: AppTypography.bodyStrong),
                const Spacer(),
                if (!online)
                  Text(
                    _offlineCaption(),
                    style: AppTypography.caption.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            if (online) ...[
              const SizedBox(height: Spacing.md),
              BlocProvider(
                create: (_) =>
                    MachineMetricCubit(MachineRepository(client), machine.id!),
                child: BlocBuilder<MachineMetricCubit, MachineMetricState>(
                  builder: (context, state) => switch (state) {
                    MachineMetricInitial() => const SizedBox.shrink(),
                    MachineMetricLoaded(:final metric) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MetricBar(
                          label: 'CPU',
                          fraction: metric.cpuPercent / 100,
                          valueLabel:
                              '${metric.cpuPercent.toStringAsFixed(0)}%',
                        ),
                        const SizedBox(height: Spacing.xs),
                        MetricBar(
                          label: 'RAM',
                          fraction: metric.memoryTotalMb == 0
                              ? 0
                              : metric.memoryUsedMb / metric.memoryTotalMb,
                          valueLabel:
                              '${(metric.memoryUsedMb / 1024).toStringAsFixed(1)}G',
                        ),
                      ],
                    ),
                  },
                ),
              ),
            ],
            if (agents.isNotEmpty) ...[
              const SizedBox(height: Spacing.md),
              Divider(height: 1, color: AppColors.border),
              const SizedBox(height: Spacing.sm),
              for (final agent in agents)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      StatusDot.fromAppearance(
                        agentStatusAppearance(agent.status),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(agent.name, style: AppTypography.body),
                      const Spacer(),
                      Text(agent.role.name, style: AppTypography.caption),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
