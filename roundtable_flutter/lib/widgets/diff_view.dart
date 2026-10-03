import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' show Node, highlight;

import '../theme/colors.dart';
import '../theme/typography.dart';
import 'code_block.dart';

/// Renders a unified diff `patch` (design doc §6.7) inside a [CodeBlock],
/// per `docs/UI-DESIGN.md` §2: a fixed 16px marker column (`+`/`-`/blank)
/// then the line text, additions/deletions tinted. [language] (a
/// `highlight` package language id, see `utils/code_language.dart`) adds
/// per-token syntax colors on top of that tint; `null` falls back to plain
/// text, no diffing algorithm of our own — GitHub has already computed it.
class DiffView extends StatelessWidget {
  const DiffView({super.key, required this.patch, this.language});

  final String patch;
  final String? language;

  @override
  Widget build(BuildContext context) {
    final lines = [for (final line in patch.split('\n')) _classifyPatchLine(line)];
    final rendered = _highlightDiffLines(lines, language);

    return CodeBlock(
      code: patch,
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final line in rendered) _DiffLineRow(line: line)],
        ),
      ),
    );
  }
}

/// Renders the whole (post-change) file content with the diff reconciled
/// in: added/removed lines highlighted at their real position, like
/// GitHub's "view file" expanded-diff mode. [fileContent] is the new/head
/// version of the file (per `contents_url`); removed lines don't exist in
/// it, so they're spliced back in from [patch]. See [DiffView] for
/// [language].
class FullFileDiffView extends StatelessWidget {
  const FullFileDiffView({
    super.key,
    required this.patch,
    required this.fileContent,
    this.language,
  });

  final String patch;
  final String fileContent;
  final String? language;

  @override
  Widget build(BuildContext context) {
    final merged = mergeFullFileDiff(patch: patch, fileContent: fileContent);
    final rendered = _highlightDiffLines(merged, language);

    return CodeBlock(
      code: fileContent,
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final line in rendered) _DiffLineRow(line: line)],
        ),
      ),
    );
  }
}

enum DiffLineKind { hunkHeader, context, added, removed }

/// A single line of a diff/full-file view: unchanged context, or an
/// added/removed line. Used both for a raw patch line ([DiffView]) and a
/// [mergeFullFileDiff] result ([FullFileDiffView]).
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

MergedDiffLine _classifyPatchLine(String line) {
  final kind = _kindOfPatchLine(line);
  final text = line.isEmpty
      ? line
      : (kind == DiffLineKind.added || kind == DiffLineKind.removed)
      ? line.substring(1)
      : line;
  return MergedDiffLine(kind, text);
}

/// A run of text sharing one `highlight` package scope (`className`, e.g.
/// `'keyword'`/`'string'`/`'comment'`) — `null` when unstyled or when
/// [language] tokenization wasn't attempted/available.
class _Token {
  const _Token(this.className, this.text);

  final String? className;
  final String text;
}

class _RenderLine {
  const _RenderLine(this.kind, this.tokens);

  final DiffLineKind kind;
  final List<_Token> tokens;
}

/// Splits [lines] into their new-side (context+added) and old-side
/// (context+removed) text, tokenizes each with [language] separately —
/// mirroring how GitHub highlights a diff by tokenizing the old and new
/// file independently then merging — and reassembles one [_RenderLine] per
/// input line. Falls back to a single unstyled token per line if
/// [language] is `null` or tokenization fails for any reason.
List<_RenderLine> _highlightDiffLines(
  List<MergedDiffLine> lines,
  String? language,
) {
  if (language == null) {
    return [for (final l in lines) _RenderLine(l.kind, [_Token(null, l.text)])];
  }

  try {
    final newText = lines
        .where((l) => l.kind != DiffLineKind.removed && l.kind != DiffLineKind.hunkHeader)
        .map((l) => l.text)
        .join('\n');
    final oldText = lines
        .where((l) => l.kind != DiffLineKind.added && l.kind != DiffLineKind.hunkHeader)
        .map((l) => l.text)
        .join('\n');

    final newTokenLines = _tokenizeLines(newText, language);
    final oldTokenLines = _tokenizeLines(oldText, language);

    var newIdx = 0;
    var oldIdx = 0;
    final result = <_RenderLine>[];
    for (final line in lines) {
      switch (line.kind) {
        case DiffLineKind.hunkHeader:
          result.add(_RenderLine(line.kind, [_Token(null, line.text)]));
        case DiffLineKind.context:
          result.add(_RenderLine(line.kind, newTokenLines[newIdx]));
          newIdx++;
          oldIdx++;
        case DiffLineKind.added:
          result.add(_RenderLine(line.kind, newTokenLines[newIdx]));
          newIdx++;
        case DiffLineKind.removed:
          result.add(_RenderLine(line.kind, oldTokenLines[oldIdx]));
          oldIdx++;
      }
    }
    return result;
  } catch (_) {
    return [for (final l in lines) _RenderLine(l.kind, [_Token(null, l.text)])];
  }
}

/// Tokenizes [text] with the `highlight` package and splits the flattened
/// result back into one token list per line, so it lines up 1:1 with
/// `text.split('\n')`.
List<List<_Token>> _tokenizeLines(String text, String language) {
  final result = highlight.parse(text, language: language);

  final tokens = <_Token>[];
  void flatten(Node node, String? inheritedClassName) {
    final className = node.className ?? inheritedClassName;
    final value = node.value;
    final children = node.children;
    if (value != null) {
      tokens.add(_Token(className, value));
    } else if (children != null) {
      for (final child in children) {
        flatten(child, className);
      }
    }
  }

  for (final node in result.nodes ?? const []) {
    flatten(node, null);
  }

  final lines = <List<_Token>>[[]];
  for (final token in tokens) {
    final parts = token.text.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        lines.last.add(_Token(token.className, parts[i]));
      }
      if (i != parts.length - 1) {
        lines.add(<_Token>[]);
      }
    }
  }
  return lines;
}

/// Syntax color/weight for a `highlight` package scope name, picked from
/// `AppColors`' syntax roles; `null` leaves the line's default color
/// ([_DiffLineRow._defaultTextColor]) untouched.
TextStyle? _syntaxStyle(String? className) {
  switch (className) {
    case 'keyword':
    case 'built_in':
    case 'type':
    case 'literal':
      return const TextStyle(color: AppColors.accentSoft);
    case 'string':
    case 'symbol':
    case 'regexp':
      return const TextStyle(color: AppColors.codeString);
    case 'number':
      return const TextStyle(color: AppColors.warning);
    case 'comment':
    case 'quote':
    case 'doctag':
      return const TextStyle(
        color: AppColors.text2,
        fontStyle: FontStyle.italic,
      );
    case 'title':
    case 'section':
    case 'name':
    case 'selector-tag':
    case 'tag':
      return const TextStyle(color: AppColors.codeFunction);
    case 'attr':
    case 'attribute':
    case 'variable':
    case 'params':
      return const TextStyle(color: AppColors.text0);
    case 'strong':
      return const TextStyle(fontWeight: FontWeight.bold);
    case 'emphasis':
      return const TextStyle(fontStyle: FontStyle.italic);
    default:
      return null;
  }
}

class _DiffLineRow extends StatelessWidget {
  const _DiffLineRow({required this.line});

  final _RenderLine line;

  Color _defaultTextColor() => switch (line.kind) {
    DiffLineKind.added => AppColors.diffAddedText,
    DiffLineKind.removed => AppColors.diffRemovedText,
    DiffLineKind.hunkHeader => AppColors.accentSoft,
    DiffLineKind.context => AppColors.text1,
  };

  @override
  Widget build(BuildContext context) {
    final marker = switch (line.kind) {
      DiffLineKind.added => '+',
      DiffLineKind.removed => '-',
      DiffLineKind.context || DiffLineKind.hunkHeader => '',
    };

    Color? background;
    switch (line.kind) {
      case DiffLineKind.added:
        background = AppColors.live.withValues(alpha: 0.10);
      case DiffLineKind.removed:
        background = AppColors.red.withValues(alpha: 0.10);
      case DiffLineKind.context:
      case DiffLineKind.hunkHeader:
        break;
    }

    final defaultStyle = AppTypography.code.copyWith(color: _defaultTextColor());

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
            child: Text.rich(
              TextSpan(
                children: [
                  for (final token in line.tokens)
                    TextSpan(
                      text: token.text,
                      style: defaultStyle.merge(_syntaxStyle(token.className)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
