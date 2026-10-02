import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Whether a machine's agent-runner is current with the binaries the server
/// serves — derived from `Machine.runnerVersion`/`updateRequestedAt` and
/// `MachineEndpoint.latestRunnerVersion` by [runnerUpdateStatus].
enum RunnerUpdateStatus {
  upToDate,
  available,
  updating,

  /// The daemon predates in-panel updates and must be reinstalled once.
  unsupported,
}

RunnerUpdateStatus runnerUpdateStatus({
  required String? installedVersion,
  required String? latestVersion,
  required DateTime? updateRequestedAt,
}) {
  if (updateRequestedAt != null) return RunnerUpdateStatus.updating;
  if (latestVersion == null || installedVersion == latestVersion) {
    return RunnerUpdateStatus.upToDate;
  }
  if (installedVersion == null) return RunnerUpdateStatus.unsupported;
  return RunnerUpdateStatus.available;
}

/// Shown on a machine's card when its agent-runner is out of date, with an
/// "Update" action that asks the daemon to re-download itself from the
/// server and restart (see `MachineEndpoint.requestRunnerUpdate`). Renders
/// nothing when [status] is [RunnerUpdateStatus.upToDate].
class RunnerUpdateBanner extends StatelessWidget {
  const RunnerUpdateBanner({
    super.key,
    required this.status,
    required this.onUpdate,
  });

  final RunnerUpdateStatus status;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final (message, icon) = switch (status) {
      RunnerUpdateStatus.upToDate => (null, null),
      RunnerUpdateStatus.available => (
        'Agent runner update available',
        Icons.system_update_alt,
      ),
      RunnerUpdateStatus.updating => (
        'Updating agent runner…',
        Icons.sync,
      ),
      RunnerUpdateStatus.unsupported => (
        'Agent runner is outdated — reinstall it once to enable in-panel '
            'updates',
        Icons.info_outline,
      ),
    };
    if (message == null) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentSoft, size: 16),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.caption.copyWith(
                  color: AppColors.accentSoft,
                ),
              ),
            ),
            if (status == RunnerUpdateStatus.available)
              TextButton(onPressed: onUpdate, child: const Text('Update')),
          ],
        ),
      ),
    );
  }
}
