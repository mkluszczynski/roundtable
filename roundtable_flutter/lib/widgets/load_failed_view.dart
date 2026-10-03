import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Shown by a detail screen instead of an endless spinner when its record
/// couldn't be loaded (fetch error) or no longer exists. Offers going back
/// and, when [onRetry] is given, retrying.
class LoadFailedView extends StatelessWidget {
  const LoadFailedView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 32, color: AppColors.text2),
              const SizedBox(height: Spacing.lg),
              Text(title, style: AppTypography.cardTitle),
              const SizedBox(height: Spacing.sm),
              Text(
                message,
                style: AppTypography.body.copyWith(color: AppColors.text1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xxl),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Back'),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: Spacing.md),
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
