import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Always-visible helper text plus an expandable "How do I do this?" for the
/// repo access token field — copy lifted verbatim from `DESIGN-DOC.md`
/// §6.5.1, the one source of text for both the panel and (eventually) the
/// README.
class TokenHelpAccordion extends StatefulWidget {
  const TokenHelpAccordion({super.key});

  @override
  State<TokenHelpAccordion> createState() => _TokenHelpAccordionState();
}

class _TokenHelpAccordionState extends State<TokenHelpAccordion> {
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
                'A fine-grained token with Contents: Read and write '
                'permission, scoped to this repository.',
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
                      '1. GitHub → profile → Settings → Developer settings '
                      '→ Personal access tokens → Fine-grained tokens\n'
                      '2. Generate new token — pick the Resource owner '
                      '(yourself, or the organization if the repo lives '
                      'there)\n'
                      '3. Repository access → Only select repositories → '
                      'pick this one repo\n'
                      '4. Permissions → Contents: Read and write (add Pull '
                      'requests: Write if the agent should open PRs itself)\n'
                      '5. Generate token and paste it here — GitHub only '
                      'shows it once',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      'If the repo belongs to an organization, pick it as '
                      "the Resource owner. Don't see it in the list? Ask an "
                      'admin to enable fine-grained tokens in the '
                      "organization's settings — the token may also require "
                      'their approval.',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      'The token will expire after at most 366 days — '
                      "it's worth setting yourself a reminder to renew it.",
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: Spacing.md),
                    SelectableText(
                      'https://github.com/settings/personal-access-tokens/new',
                      style: AppTypography.code.copyWith(
                        color: AppColors.accentSoft,
                      ),
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
