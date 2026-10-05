import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';

/// A small icon button that copies [text] to the clipboard and shows a
/// check for two seconds.
class CopyIconButton extends StatefulWidget {
  const CopyIconButton({super.key, required this.text, this.tooltip = 'Copy'});

  final String text;
  final String tooltip;

  @override
  State<CopyIconButton> createState() => _CopyIconButtonState();
}

class _CopyIconButtonState extends State<CopyIconButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _copied ? 'Copied' : widget.tooltip,
      visualDensity: VisualDensity.compact,
      iconSize: 16,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: EdgeInsets.zero,
      color: _copied ? AppColors.live : AppColors.text1,
      icon: Icon(_copied ? Icons.check : Icons.copy_outlined),
      onPressed: _copy,
    );
  }
}
