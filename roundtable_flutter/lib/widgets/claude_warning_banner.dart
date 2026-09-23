import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Shown on a machine's card when `Machine.claudeExecutableOk == false` —
/// the daemon's `claude` CLI can't be launched, so every task assigned to
/// this machine will fail (design doc §6.8/§6.2). Reported by
/// `AgentRunnerService._checkClaudeExecutable` via
/// `MachineEndpoint.reportClaudeStatus`, this exists so the failure is
/// visible in the panel instead of only in `journalctl -u agent-runner`,
/// which is easy to miss right after installation.
class ClaudeWarningBanner extends StatefulWidget {
  const ClaudeWarningBanner({super.key, required this.message});

  /// The actionable error description from `Machine.claudeExecutableError`.
  final String message;

  @override
  State<ClaudeWarningBanner> createState() => _ClaudeWarningBannerState();
}

class _ClaudeWarningBannerState extends State<ClaudeWarningBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      'claude CLI cannot run on this machine — tasks will '
                      'fail',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.warning,
                    size: 16,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: Spacing.sm),
                Text(widget.message, style: AppTypography.caption),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
