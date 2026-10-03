import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import 'code_block.dart';

/// Renders a unified diff `patch` (design doc §6.7) inside a [CodeBlock],
/// per `docs/UI-DESIGN.md` §2: a fixed 16px marker column (`+`/`-`/blank)
/// then the line text, additions/deletions tinted, no diffing algorithm of
/// our own — GitHub has already computed the diff.
///
/// [annotations] are shown right below the diff line that carries the given
/// new-file line number (e.g. review comments on that line).
class DiffView extends StatelessWidget {
  const DiffView({super.key, required this.patch, this.annotations = const {}});

  final String patch;
  final Map<int, Widget> annotations;

  @override
  Widget build(BuildContext context) {
    final lines = patch.split('\n');
    final hunkHeader = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)');

    final children = <Widget>[];
    int? newLine;
    for (final line in lines) {
      children.add(_DiffLine(line: line));
      final header = hunkHeader.firstMatch(line);
      if (header != null) {
        newLine = int.parse(header.group(1)!);
        continue;
      }
      if (newLine == null || line.startsWith('-') || line.startsWith('\\')) {
        continue;
      }
      final annotation = annotations[newLine];
      if (annotation != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SelectionContainer.disabled(child: annotation),
          ),
        );
      }
      newLine++;
    }

    return CodeBlock(
      code: patch,
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
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
