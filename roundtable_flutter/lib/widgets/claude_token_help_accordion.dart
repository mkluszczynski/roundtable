import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Always-visible helper text plus an expandable "How do I do this?" for the
/// Claude Code OAuth token field on [AddMachineDialog] — copy lifted from
/// `DESIGN-DOC.md` §6.11. Mirrors [TokenHelpAccordion]'s shape.
class ClaudeTokenHelpAccordion extends StatefulWidget {
  const ClaudeTokenHelpAccordion({super.key});

  @override
  State<ClaudeTokenHelpAccordion> createState() =>
      _ClaudeTokenHelpAccordionState();
}

class _ClaudeTokenHelpAccordionState extends State<ClaudeTokenHelpAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'The OAuth token from `claude setup-token`, billed against '
                'your Claude Pro/Max subscription — required for this '
                "machine's agents to actually run tasks.",
                style: AppTypography.caption,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Hide ▾' : 'How do I do this? ▸'),
            ),
          ],
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. On any machine with the claude CLI and a Pro/Max '
                      'subscription, run: claude setup-token\n'
                      '2. Open the printed URL in a browser and log in\n'
                      '3. Copy the token printed back in the terminal and '
                      'paste it here',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      "The token is tied to one human's subscription, with "
                      "usage limits sized for one person's interactive "
                      'work — several agents sharing it will hit those '
                      'limits sooner than a single developer working by '
                      'hand.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
