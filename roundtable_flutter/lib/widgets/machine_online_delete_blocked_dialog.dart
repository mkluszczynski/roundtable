import 'package:flutter/material.dart';

/// Shown instead of a plain error when the dev tries to delete a [Machine]
/// that's still `online` — the daemon is alive and connected, so we hand
/// them the exact command to shut it down properly (design doc §6.8).
class MachineOnlineDeleteBlockedDialog extends StatelessWidget {
  const MachineOnlineDeleteBlockedDialog({super.key});

  static const uninstallCommand = 'sudo ./scripts/uninstall-agent.sh';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Machine is still online'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This machine is still running and connected. Run the '
            'following command on it to uninstall the agent runner:',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const SelectableText(
              uninstallCommand,
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "If this machine no longer physically exists, you don't need "
            'to do anything — its status will switch to offline on its own '
            'within ~60s once the heartbeat stops arriving.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
