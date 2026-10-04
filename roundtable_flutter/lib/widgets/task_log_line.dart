import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/log_entry_kind.dart';
import 'code_block.dart';

/// Renders a task's live execution log (design brief "Live execution"
/// artboard) inside a [CodeBlock]: each [TaskLogEntry] gets its own colored
/// line instead of one flat block of text, per the marker that
/// `StreamJsonFormatter` (in `roundtable_agent_runner`) already prefixes
/// every persisted line with.
class TaskLogView extends StatelessWidget {
  const TaskLogView({super.key, required this.entries});

  final List<TaskLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return CodeBlock(
      code: entries.map((e) => e.text).join('\n'),
      expand: true,
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final entry in entries) _TaskLogLine(entry: entry)],
        ),
      ),
    );
  }
}

class _TaskLogLine extends StatelessWidget {
  const _TaskLogLine({required this.entry});

  final TaskLogEntry entry;

  @override
  Widget build(BuildContext context) {
    // `docs/UI-DESIGN.md` §1 forbids emoji as UI glyphs — the kind is
    // shown as a colored ASCII marker instead.
    final text = entry.text;
    final (marker, color, fontStyle) = switch (entry.effectiveKind) {
      LogKind.toolCall => ('●', AppColors.accentSoft, FontStyle.normal),
      LogKind.toolResult || LogKind.runFinished =>
        entry.failed
            ? ('✗', AppColors.red, FontStyle.normal)
            : ('✓', AppColors.live, FontStyle.normal),
      LogKind.thinking => ('', AppColors.text2, FontStyle.italic),
      LogKind.runStarted => ('▶', AppColors.accentSoft, FontStyle.normal),
      LogKind.message => ('', AppColors.text0, FontStyle.normal),
      LogKind.event => ('•', AppColors.accentSoft, FontStyle.normal),
    };

    final style = AppTypography.code.copyWith(
      color: color,
      fontStyle: fontStyle,
    );

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          if (marker.isNotEmpty) TextSpan(text: '$marker  '),
          TextSpan(text: text),
        ],
      ),
    );
  }
}
