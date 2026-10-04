import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_modal.dart';

/// A square preview of an attached image, with an optional remove button
/// and an uploading/error overlay. Tapping opens it full size.
class AttachmentThumbnail extends StatelessWidget {
  const AttachmentThumbnail({
    super.key,
    required this.name,
    required this.bytes,
    this.size = 72,
    this.uploading = false,
    this.error,
    this.onRemove,
  });

  final String name;

  /// Null while the image is still loading.
  final Uint8List? bytes;
  final double size;
  final bool uploading;
  final String? error;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final bytes = this.bytes;
    return Tooltip(
      message: error ?? name,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: Material(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: bytes == null ? null : () => _preview(context, bytes),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: error != null ? AppColors.red : AppColors.border,
                      ),
                    ),
                    child: bytes == null
                        ? const Center(
                            child: SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Image.memory(bytes, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            if (uploading || error != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg0.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: error != null
                        ? const Icon(
                            Icons.error_outline,
                            color: AppColors.red,
                            size: 20,
                          )
                        : const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                  ),
                ),
              ),
            if (onRemove != null)
              Positioned(
                top: 2,
                right: 2,
                child: Material(
                  color: AppColors.bg0.withValues(alpha: 0.75),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: AppColors.text0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _preview(BuildContext context, Uint8List bytes) {
    showAppModal<void>(
      context,
      icon: Icons.image_outlined,
      title: name,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 640),
        child: InteractiveViewer(
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Caption under an attachment strip, e.g. "2 images · paste or attach".
Widget attachmentHint(String text) => Padding(
  padding: const EdgeInsets.only(top: Spacing.xs),
  child: Text(text, style: AppTypography.caption),
);
