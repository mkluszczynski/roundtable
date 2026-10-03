import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' show Node, highlight;

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'code_block.dart';

/// Renders a unified diff `patch` (docs/FLOWS.md §4) inside a [CodeBlock],
/// per `docs/UI-DESIGN.md` §2: a fixed 16px marker column (`+`/`-`/blank)
/// then the line text, additions/deletions tinted. [language] (a
/// `highlight` package language id, see `utils/code_language.dart`) adds
/// per-token syntax colors on top of that tint; `null` falls back to plain
/// text, no diffing algorithm of our own — GitHub has already computed it.
///
/// [annotations] are shown right below the diff line that carries the given
/// new-file line number (e.g. review comments on that line).
class DiffView extends StatelessWidget {
  const DiffView({
    super.key,
    required this.patch,
    this.language,
    this.annotations = const {},
  });

  final String patch;
  final String? language;
  final Map<int, Widget> annotations;

  @override
  Widget build(BuildContext context) {
    final lines = _classifyPatchLines(patch);
    final rendered = _highlightDiffLines(lines, language);

    final children = <Widget>[];
    for (var idx = 0; idx < lines.length; idx++) {
      children.add(_DiffLineRow(line: rendered[idx]));
      final lineNumber = lines[idx].newLineNumber;
      final annotation = lineNumber == null ? null : annotations[lineNumber];
      if (annotation != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SelectionContainer.disabled(child: annotation),
          ),
        );
      }
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

/// Renders the whole (post-change) file content with the diff reconciled
/// in: added/removed lines highlighted at their real position, like
/// GitHub's "view file" expanded-diff mode. [fileContent] is the new/head
/// version of the file (per `contents_url`); removed lines don't exist in
/// it, so they're spliced back in from [patch]. See [DiffView] for
/// [language]/[annotations].
class FullFileDiffView extends StatelessWidget {
  const FullFileDiffView({
    super.key,
    required this.patch,
    required this.fileContent,
    this.language,
    this.annotations = const {},
  });

  final String patch;
  final String fileContent;
  final String? language;
  final Map<int, Widget> annotations;

  @override
  Widget build(BuildContext context) {
    List<MergedDiffLine> merged;
    try {
      merged = mergeFullFileDiff(patch: patch, fileContent: fileContent);
    } catch (_) {
      // The patch and the fetched file content disagree (e.g. the file
      // changed again after the diff was computed) — fall back to the
      // file as-is rather than risk silently misaligned highlighting.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Text(
              "This file has changed since the diff was computed — showing "
              "it without highlighting.",
              style: AppTypography.body.copyWith(color: AppColors.warning),
            ),
          ),
          CodeBlock(code: fileContent),
        ],
      );
    }

    final rendered = _highlightDiffLines(merged, language);
    final children = <Widget>[];
    for (var idx = 0; idx < merged.length; idx++) {
      children.add(_DiffLineRow(line: rendered[idx]));
      final lineNumber = merged[idx].newLineNumber;
      final annotation = lineNumber == null ? null : annotations[lineNumber];
      if (annotation != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SelectionContainer.disabled(child: annotation),
          ),
        );
      }
    }

    return CodeBlock(
      code: fileContent,
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// Thrown by [mergeFullFileDiff] when the fetched file content doesn't
/// agree with what the patch expects — e.g. it was fetched separately and
/// is now stale, or the file changed again after the diff was computed —
/// so reconciling them further would silently mislabel lines.
class DiffReconciliationException implements Exception {
  DiffReconciliationException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum DiffLineKind { hunkHeader, context, added, removed }

/// A single line of a diff/full-file view: unchanged context, or an
/// added/removed line. Used both for a raw patch line ([DiffView]) and a
/// [mergeFullFileDiff] result ([FullFileDiffView]).
///
/// [newLineNumber] is the new-file (post-change) line number this line
/// corresponds to — `null` for removed lines (absent from the new file)
/// and hunk headers — used to place [DiffView.annotations]/
/// [FullFileDiffView.annotations]. It's excluded from equality/hashing
/// (and so from tests that compare [MergedDiffLine] values), since it's a
/// rendering detail, not part of a line's identity.
class MergedDiffLine {
  const MergedDiffLine(this.kind, this.text, {this.newLineNumber});

  final DiffLineKind kind;
  final String text;
  final int? newLineNumber;

  @override
  bool operator ==(Object other) =>
      other is MergedDiffLine && other.kind == kind && other.text == text;

  @override
  int get hashCode => Object.hash(kind, text);

  @override
  String toString() => 'MergedDiffLine($kind, $text, line: $newLineNumber)';
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
      result.add(
        MergedDiffLine(
          DiffLineKind.context,
          fileLines[cursor],
          newLineNumber: cursor + 1,
        ),
      );
      cursor++;
    }
    if (cursor != newLineNumExclusiveEnd - 1) {
      throw DiffReconciliationException(
        'Full file content has fewer lines than the diff expects.',
      );
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
          {
            final text = line.substring(1);
            if (cursor >= fileLines.length || fileLines[cursor] != text) {
              throw DiffReconciliationException(
                'Full file content no longer matches the diff at line '
                '${cursor + 1}.',
              );
            }
            result.add(
              MergedDiffLine(
                DiffLineKind.context,
                text,
                newLineNumber: cursor + 1,
              ),
            );
            cursor++;
          }
          break;
        case '+':
          {
            final text = line.substring(1);
            if (cursor >= fileLines.length || fileLines[cursor] != text) {
              throw DiffReconciliationException(
                'Full file content no longer matches the diff at line '
                '${cursor + 1}.',
              );
            }
            result.add(
              MergedDiffLine(
                DiffLineKind.added,
                text,
                newLineNumber: cursor + 1,
              ),
            );
            cursor++;
          }
          break;
        case '-':
          result.add(MergedDiffLine(DiffLineKind.removed, line.substring(1)));
          break;
        default:
          break;
      }
      i++;
    }
  }

  while (cursor < fileLines.length) {
    result.add(
      MergedDiffLine(
        DiffLineKind.context,
        fileLines[cursor],
        newLineNumber: cursor + 1,
      ),
    );
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

/// Classifies every line of [patch] and, for context/added lines once a
/// hunk has started, tags them with their new-file line number — the same
/// "new-file line the diff shows" tracking a standalone `_diffNewLines`
/// helper used to do, folded in here so [DiffView] can place
/// [DiffView.annotations] directly off [MergedDiffLine].
List<MergedDiffLine> _classifyPatchLines(String patch) {
  final result = <MergedDiffLine>[];
  int? newLine;
  for (final line in patch.split('\n')) {
    final header = _hunkHeaderPattern.firstMatch(line);
    if (header != null) {
      newLine = int.parse(header.group(1)!);
      result.add(_classifyPatchLine(line));
      continue;
    }

    final classified = _classifyPatchLine(line);
    final noNewlineMarker = line.startsWith(r'\');
    if (classified.kind == DiffLineKind.removed ||
        noNewlineMarker ||
        newLine == null) {
      result.add(classified);
      continue;
    }

    result.add(
      MergedDiffLine(classified.kind, classified.text, newLineNumber: newLine),
    );
    newLine++;
  }
  return result;
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
    return [
      for (final l in lines) _RenderLine(l.kind, [_Token(null, l.text)]),
    ];
  }

  try {
    final newText = lines
        .where(
          (l) =>
              l.kind != DiffLineKind.removed &&
              l.kind != DiffLineKind.hunkHeader,
        )
        .map((l) => l.text)
        .join('\n');
    final oldText = lines
        .where(
          (l) =>
              l.kind != DiffLineKind.added && l.kind != DiffLineKind.hunkHeader,
        )
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
          break;
        case DiffLineKind.context:
          result.add(_RenderLine(line.kind, newTokenLines[newIdx]));
          newIdx++;
          oldIdx++;
          break;
        case DiffLineKind.added:
          result.add(_RenderLine(line.kind, newTokenLines[newIdx]));
          newIdx++;
          break;
        case DiffLineKind.removed:
          result.add(_RenderLine(line.kind, oldTokenLines[oldIdx]));
          oldIdx++;
          break;
      }
    }
    return result;
  } catch (_) {
    return [
      for (final l in lines) _RenderLine(l.kind, [_Token(null, l.text)]),
    ];
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
        break;
      case DiffLineKind.removed:
        background = AppColors.red.withValues(alpha: 0.10);
        break;
      case DiffLineKind.context:
      case DiffLineKind.hunkHeader:
        break;
    }

    final defaultStyle = AppTypography.code.copyWith(
      color: _defaultTextColor(),
    );

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
