import 'package:flutter/material.dart';

import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Shows the shared modal shell from `docs/UI-DESIGN.md` §2: centered card,
/// 480-560px wide, header (title/subtitle + ghost close), scrollable [child],
/// and a right-aligned [actions] footer. Every dialog in this app should use
/// this instead of a raw `AlertDialog`.
Future<T?> showAppModal<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget child,
  List<Widget> actions = const [],
  IconData? icon,
  AppModalTone tone = AppModalTone.normal,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => AppModal(
      title: title,
      subtitle: subtitle,
      actions: actions,
      icon: icon,
      tone: tone,
      child: child,
    ),
  );
}

/// [AppModalTone.danger] tints the header icon red, for destructive
/// confirmations.
enum AppModalTone { normal, danger }

class AppModal extends StatelessWidget {
  const AppModal({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions = const [],
    this.icon,
    this.tone = AppModalTone.normal,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  /// Shown in a tinted tile left of the title.
  final IconData? icon;
  final AppModalTone tone;

  @override
  Widget build(BuildContext context) {
    final compact = LayoutSize.of(context).isCompact;
    return Dialog(
      backgroundColor: AppColors.bg1,
      // Phones: close to the edges, so the form gets the width.
      insetPadding: compact
          ? const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.xxxl,
            )
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, minWidth: compact ? 0 : 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.huge,
                Spacing.xxl,
                Spacing.xl,
                Spacing.xl,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    _HeaderIcon(icon: icon!, tone: tone),
                    const SizedBox(width: Spacing.lg),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.cardTitle),
                        if (subtitle != null) ...[
                          const SizedBox(height: Spacing.xs),
                          Text(subtitle!, style: AppTypography.caption),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, color: AppColors.text1),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.huge,
                  0,
                  Spacing.huge,
                  Spacing.xxl,
                ),
                child: child,
              ),
            ),
            if (actions.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bg0.withValues(alpha: 0.35),
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.huge,
                  vertical: Spacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: Spacing.sm),
                      actions[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.tone});

  final IconData icon;
  final AppModalTone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone == AppModalTone.danger
        ? AppColors.red
        : AppColors.accentSoft;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
