import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'tag_chip.dart';

/// The tools a machine's daemon found on its PATH (`Machine.toolchain`,
/// "name: version output"), as chips like `dart 3.13.3`.
class ToolchainChips extends StatelessWidget {
  const ToolchainChips({super.key, required this.toolchain});

  final List<String>? toolchain;

  static final _version = RegExp(r'\d+(\.\d+)+');

  /// "dart: Dart SDK version: 3.13.3 (stable)…" → "dart 3.13.3".
  static String label(String entry) {
    final split = entry.indexOf(':');
    if (split < 0) return entry;
    final name = entry.substring(0, split);
    final version = _version.firstMatch(entry.substring(split + 1))?.group(0);
    return version == null ? name : '$name $version';
  }

  @override
  Widget build(BuildContext context) {
    final toolchain = this.toolchain;
    if (toolchain == null) {
      return Text(
        'Not reported — update the runner to detect tools.',
        style: AppTypography.caption,
      );
    }
    if (toolchain.isEmpty) {
      return Text(
        'No build tools found on the runner\'s PATH.',
        style: AppTypography.caption,
      );
    }
    return Wrap(
      spacing: Spacing.xs,
      runSpacing: Spacing.xs,
      children: [
        for (final entry in toolchain)
          Tooltip(message: entry, child: TagChip(label(entry))),
      ],
    );
  }
}
