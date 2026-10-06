import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Shown on a machine while its Claude account is rate limited
/// (`Machine.usageLimitedUntil` in the future): the runner starts no new
/// task or review there until the reset (docs/FLOWS.md §4). Renders nothing
/// otherwise.
class UsageLimitNote extends StatelessWidget {
  const UsageLimitNote({super.key, required this.until, this.now});

  final DateTime? until;

  /// The current time, for tests.
  final DateTime? now;

  /// Whether [until] is still ahead, i.e. the note shows.
  static bool isActive(DateTime? until, {DateTime? now}) =>
      until != null && until.isAfter(now ?? DateTime.now());

  @override
  Widget build(BuildContext context) {
    final until = this.until;
    if (until == null || !isActive(until, now: now)) {
      return const SizedBox.shrink();
    }
    final local = until.toLocal();
    final at =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return Tooltip(
      message:
          "This machine's Claude account hit its usage limit. New tasks "
          'and reviews wait until it resets; interrupted ones resume then.',
      child: Row(
        children: [
          const Icon(Icons.hourglass_top, size: 14, color: AppColors.warning),
          const SizedBox(width: Spacing.xs),
          Flexible(
            child: Text(
              'Usage limit until $at',
              style: AppTypography.caption.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
