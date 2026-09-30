import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
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
      code: entries.map((e) => e.content).join('\n'),
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
    final content = entry.content;
    // `docs/UI-DESIGN.md` §1 forbids emoji as UI glyphs — the raw pictographic
    // markers `StreamJsonFormatter` prefixes onto persisted content (🔧 ✅ ❌
    // 🤔) are swapped here for a colored ASCII marker; `✓`/`✗` are already
    // plain glyphs and are kept as-is.
    String marker = '';
    Color color = AppColors.text0;
    FontStyle fontStyle = FontStyle.normal;
    String text = content;

    if (content.startsWith('🔧 ')) {
      marker = '●';
      color = AppColors.accentSoft;
      text = content.substring('🔧 '.length);
    } else if (content.startsWith('✅')) {
      marker = '✓';
      color = AppColors.live;
      text = content.substring('✅'.length).trimLeft();
    } else if (content.startsWith('✓ ')) {
      marker = '✓';
      color = AppColors.live;
      text = content.substring('✓ '.length);
    } else if (content.startsWith('❌')) {
      marker = '✗';
      color = AppColors.red;
      text = content.substring('❌'.length).trimLeft();
    } else if (content.startsWith('✗ ')) {
      marker = '✗';
      color = AppColors.red;
      text = content.substring('✗ '.length);
    } else if (content.startsWith('🤔 ')) {
      color = AppColors.text2;
      fontStyle = FontStyle.italic;
      text = content.substring('🤔 '.length);
    }

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
