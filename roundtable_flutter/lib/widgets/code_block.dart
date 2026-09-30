import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// A monospace code/command block with a copy-to-clipboard chip pinned
/// top-right, per `docs/UI-DESIGN.md` §2. Used for install/uninstall
/// commands, tokens, and as the diff view's chrome.
class CodeBlock extends StatefulWidget {
  const CodeBlock({super.key, required this.code, this.label, this.child});

  /// The text copied to the clipboard, and rendered as-is if [child] is null.
  final String code;
  final String? label;

  /// Optional custom rendering (e.g. colored diff lines) instead of plain
  /// [code] text; [code] is still what gets copied.
  final Widget? child;

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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.codeBg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.massive,
              Spacing.lg,
            ),
            child: DefaultTextStyle.merge(
              style: AppTypography.code,
              child:
                  widget.child ??
                  SelectableText(widget.code, style: AppTypography.code),
            ),
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
