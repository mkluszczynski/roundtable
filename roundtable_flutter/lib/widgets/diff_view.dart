import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import 'code_block.dart';

/// Renders a unified diff `patch` (design doc §6.7) inside a [CodeBlock],
/// per `docs/UI-DESIGN.md` §2: a fixed 16px marker column (`+`/`-`/blank)
/// then the line text, additions/deletions tinted, no diffing algorithm of
/// our own — GitHub has already computed the diff.
class DiffView extends StatelessWidget {
  const DiffView({super.key, required this.patch});

  final String patch;

  @override
  Widget build(BuildContext context) {
    final lines = patch.split('\n');

    return CodeBlock(
      code: patch,
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final line in lines) _DiffLine(line: line)],
        ),
      ),
    );
  }
}

class _DiffLine extends StatelessWidget {
  const _DiffLine({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    final isAddition = line.startsWith('+') && !line.startsWith('+++');
    final isDeletion = line.startsWith('-') && !line.startsWith('---');
    final marker = isAddition
        ? '+'
        : isDeletion
        ? '-'
        : '';

    Color? background;
    Color textColor = AppColors.text1;
    if (isAddition) {
      background = AppColors.live.withValues(alpha: 0.10);
      textColor = AppColors.diffAddedText;
    } else if (isDeletion) {
      background = AppColors.red.withValues(alpha: 0.10);
      textColor = AppColors.diffRemovedText;
    } else if (line.startsWith('@@')) {
      textColor = AppColors.accentSoft;
    }

    final content = line.isEmpty
        ? line
        : (isAddition || isDeletion)
        ? line.substring(1)
        : line;

    return DecoratedBox(
      decoration: BoxDecoration(color: background),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Text(
              marker,
              style: AppTypography.code.copyWith(color: AppColors.text2),
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: AppTypography.code.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
