import 'package:flutter/material.dart';

/// Renders a unified diff `patch` (design doc §6.7) by splitting it into
/// lines and coloring each by its leading character — no diffing algorithm
/// of our own, GitHub has already computed the diff.
class DiffView extends StatelessWidget {
  const DiffView({super.key, required this.patch});

  final String patch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = patch.split('\n');

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Text(
              line,
              style: TextStyle(
                fontFamily: 'monospace',
                color: _colorFor(line, theme),
              ),
            ),
        ],
      ),
    );
  }

  Color? _colorFor(String line, ThemeData theme) {
    if (line.startsWith('+++') || line.startsWith('---')) {
      return theme.colorScheme.onSurfaceVariant;
    }
    if (line.startsWith('+')) {
      return Colors.green.shade700;
    }
    if (line.startsWith('-')) {
      return Colors.red.shade700;
    }
    if (line.startsWith('@@')) {
      return theme.colorScheme.primary;
    }
    return null;
  }
}
