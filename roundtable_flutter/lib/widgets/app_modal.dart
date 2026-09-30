import 'package:flutter/material.dart';

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
      child: child,
    ),
  );
}

class AppModal extends StatelessWidget {
  const AppModal({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderStrong),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, minWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.huge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    icon: const Icon(Icons.close, color: AppColors.text1),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xl),
              Flexible(child: child),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: Spacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: Spacing.sm),
                      actions[i],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
