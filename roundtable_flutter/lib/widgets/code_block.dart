import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// A monospace code/command block with a copy-to-clipboard chip pinned
/// top-right, per `docs/UI-DESIGN.md` §2. Used for install/uninstall
/// commands, tokens, and as the diff view's chrome.
class CodeBlock extends StatefulWidget {
  const CodeBlock({
    super.key,
    required this.code,
    this.label,
    this.child,
    this.expand = false,
  });

  /// The text copied to the clipboard, and rendered as-is if [child] is null.
  final String code;
  final String? label;

  /// Optional custom rendering (e.g. colored diff lines) instead of plain
  /// [code] text; [code] is still what gets copied.
  final Widget? child;

  /// When true, the block fills the bounded space given by its parent (e.g.
  /// an [Expanded]) instead of shrinking to [child]'s intrinsic size, and
  /// scrolls [child] internally if it overflows. Requires a parent that
  /// supplies bounded constraints.
  final bool expand;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = DefaultTextStyle.merge(
      style: AppTypography.code,
      child:
          widget.child ?? SelectableText(widget.code, style: AppTypography.code),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.codeBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: widget.expand ? StackFit.expand : StackFit.loose,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.massive,
              Spacing.lg,
            ),
            child: widget.expand
                ? SingleChildScrollView(reverse: true, child: content)
                : content,
          ),
          Positioned(
            top: Spacing.sm,
            right: Spacing.sm,
            child: _CopyChip(copied: _copied, onTap: _copy),
          ),
        ],
      ),
    );
  }
}

class _CopyChip extends StatelessWidget {
  const _CopyChip({required this.copied, required this.onTap});

  final bool copied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg2,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Icon(
            copied ? Icons.check : Icons.copy,
            size: 14,
            color: copied ? AppColors.live : AppColors.text1,
          ),
        ),
      ),
    );
  }
}
