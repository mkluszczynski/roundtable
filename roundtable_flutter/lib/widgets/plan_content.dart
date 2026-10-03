import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Renders an AI agent's plan — markdown text — as formatted prose instead
/// of raw markdown source, styled with the app's design tokens.
class PlanContent extends StatelessWidget {
  const PlanContent({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: markdown,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: AppTypography.body,
        pPadding: const EdgeInsets.only(bottom: Spacing.md),
        h1: AppTypography.cardTitle,
        h1Padding: const EdgeInsets.only(bottom: Spacing.sm),
        h2: AppTypography.bodyStrong.copyWith(fontSize: 16),
        h2Padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.sm),
        h3: AppTypography.bodyStrong,
        h3Padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.sm),
        strong: AppTypography.bodyStrong,
        em: AppTypography.body.copyWith(fontStyle: FontStyle.italic),
        del: AppTypography.body.copyWith(
          decoration: TextDecoration.lineThrough,
        ),
        a: AppTypography.body.copyWith(
          color: AppColors.accentSoft,
          decoration: TextDecoration.underline,
        ),
        listBullet: AppTypography.body,
        listIndent: Spacing.xl,
        code: AppTypography.code.copyWith(backgroundColor: AppColors.codeBg),
        codeblockPadding: const EdgeInsets.all(Spacing.lg),
        codeblockDecoration: BoxDecoration(
          color: AppColors.codeBg,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: AppTypography.body.copyWith(color: AppColors.text1),
        blockquotePadding: const EdgeInsets.only(left: Spacing.lg),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.border, width: 2)),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
      ),
    );
  }
}
