import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_modal.dart';
import 'code_block.dart';

/// Shown instead of a plain error when the dev tries to delete a [Machine]
/// that's still `online` — the daemon is alive and connected, so we hand
/// them the exact command to shut it down properly (design doc §6.8).
class MachineOnlineDeleteBlockedDialog extends StatelessWidget {
  const MachineOnlineDeleteBlockedDialog({super.key, this.scriptUrl});

  /// Base URL the uninstall script is served from. Null when fetching it
  /// failed, in which case we fall back to the repo-relative command — only
  /// correct if the repo happens to be checked out on the target machine.
  final String? scriptUrl;

  @override
  Widget build(BuildContext context) {
    final scriptUrl = this.scriptUrl;
    final uninstallCommand = scriptUrl == null
        ? 'sudo ./scripts/uninstall-agent.sh'
        : 'curl -fsSL $scriptUrl/uninstall-agent.sh | sudo bash';
    return AppModal(
      title: 'Machine is still online',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.red,
                size: 20,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  'This machine is still running and connected. Run the '
                  'following command on it to uninstall the agent runner:',
                  style: AppTypography.body,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          CodeBlock(code: uninstallCommand),
          const SizedBox(height: Spacing.lg),
          Text(
            "If this machine no longer physically exists, you don't need "
            'to do anything — its status will switch to offline on its own '
            'within ~60s once the heartbeat stops arriving.',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
