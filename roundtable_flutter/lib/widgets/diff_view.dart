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
          children: [for (final line in lines) _classifyPatchLine(line)],
        ),
      ),
    );
  }
}

/// Renders the whole (post-change) file content with the diff reconciled
/// in: added/removed lines highlighted at their real position, like
/// GitHub's "view file" expanded-diff mode. [fileContent] is the new/head
/// version of the file (per `contents_url`); removed lines don't exist in
/// it, so they're spliced back in from [patch].
class FullFileDiffView extends StatelessWidget {
  const FullFileDiffView({
    super.key,
    required this.patch,
    required this.fileContent,
  });

  final String patch;
  final String fileContent;

  @override
  Widget build(BuildContext context) {
    final merged = mergeFullFileDiff(patch: patch, fileContent: fileContent);

    return CodeBlock(
      code: fileContent,
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in merged)
              _DiffLineRow(kind: line.kind, text: line.text),
          ],
        ),
      ),
    );
  }
}

enum DiffLineKind { hunkHeader, context, added, removed }

/// A single reconciled line of a [FullFileDiffView]: unchanged context
/// from the full file, or an added/removed line spliced in from the patch.
class MergedDiffLine {
  const MergedDiffLine(this.kind, this.text);

  final DiffLineKind kind;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is MergedDiffLine && other.kind == kind && other.text == text;

  @override
  int get hashCode => Object.hash(kind, text);

  @override
  String toString() => 'MergedDiffLine($kind, $text)';
}

final _hunkHeaderPattern = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@');

/// Reconciles [patch]'s hunks into [fileContent] (the new/head version of
/// the file), producing one [MergedDiffLine] per line of the resulting
/// "whole file with changes highlighted" view — the same reconciliation
/// GitHub's web UI does when expanding a diff to the full file: context and
/// added lines line up with [fileContent] by the hunk's new-side line
/// number, removed lines (absent from [fileContent]) are spliced in at the
/// point they occur in the patch without advancing that line number.
List<MergedDiffLine> mergeFullFileDiff({
  required String patch,
  required String fileContent,
}) {
  final fileLines = fileContent.split('\n');
  final patchLines = patch.split('\n');
  final result = <MergedDiffLine>[];

  // 0-indexed position in fileLines, i.e. (new-file line number - 1).
  var cursor = 0;

  void copyContextUpTo(int newLineNumExclusiveEnd) {
    while (cursor < newLineNumExclusiveEnd - 1 && cursor < fileLines.length) {
      result.add(MergedDiffLine(DiffLineKind.context, fileLines[cursor]));
      cursor++;
    }
  }

  var i = 0;
  while (i < patchLines.length) {
    final match = _hunkHeaderPattern.firstMatch(patchLines[i]);
    if (match == null) {
      i++;
      continue;
    }
    final newStart = int.parse(match.group(1)!);
    copyContextUpTo(newStart);
    i++;

    while (i < patchLines.length && !patchLines[i].startsWith('@@')) {
      final line = patchLines[i];
      if (line.isEmpty || line.startsWith(r'\')) {
        i++;
        continue;
      }
      switch (line[0]) {
        case ' ':
          result.add(
            MergedDiffLine(
              DiffLineKind.context,
              cursor < fileLines.length ? fileLines[cursor] : line.substring(1),
            ),
          );
          cursor++;
        case '+':
          result.add(MergedDiffLine(DiffLineKind.added, line.substring(1)));
          cursor++;
        case '-':
          result.add(MergedDiffLine(DiffLineKind.removed, line.substring(1)));
        default:
          break;
      }
      i++;
    }
  }

  while (cursor < fileLines.length) {
    result.add(MergedDiffLine(DiffLineKind.context, fileLines[cursor]));
    cursor++;
  }

  return result;
}

DiffLineKind _kindOfPatchLine(String line) {
  if (line.startsWith('@@')) return DiffLineKind.hunkHeader;
  if (line.startsWith('+') && !line.startsWith('+++')) {
    return DiffLineKind.added;
  }
  if (line.startsWith('-') && !line.startsWith('---')) {
    return DiffLineKind.removed;
  }
  return DiffLineKind.context;
}

Widget _classifyPatchLine(String line) {
  final kind = _kindOfPatchLine(line);
  final text = line.isEmpty
      ? line
      : (kind == DiffLineKind.added || kind == DiffLineKind.removed)
      ? line.substring(1)
      : line;
  return _DiffLineRow(kind: kind, text: text);
}

class _DiffLineRow extends StatelessWidget {
  const _DiffLineRow({required this.kind, required this.text});

  final DiffLineKind kind;
  final String text;

  @override
  Widget build(BuildContext context) {
    final marker = switch (kind) {
      DiffLineKind.added => '+',
      DiffLineKind.removed => '-',
      DiffLineKind.context || DiffLineKind.hunkHeader => '',
    };

    Color? background;
    var textColor = AppColors.text1;
    switch (kind) {
      case DiffLineKind.added:
        background = AppColors.live.withValues(alpha: 0.10);
        textColor = AppColors.diffAddedText;
      case DiffLineKind.removed:
        background = AppColors.red.withValues(alpha: 0.10);
        textColor = AppColors.diffRemovedText;
      case DiffLineKind.hunkHeader:
        textColor = AppColors.accentSoft;
      case DiffLineKind.context:
        break;
    }

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
              text,
              style: AppTypography.code.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
