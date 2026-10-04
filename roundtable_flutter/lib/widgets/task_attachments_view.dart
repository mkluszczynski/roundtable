import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../repositories/attachment_repository.dart';
import '../theme/spacing.dart';
import 'attachment_thumbnail.dart';

/// Thumbnails of the images attached to task [taskId]'s prompt; renders
/// nothing when there are none.
class TaskAttachmentsView extends StatefulWidget {
  const TaskAttachmentsView({super.key, required this.taskId});

  final int taskId;

  @override
  State<TaskAttachmentsView> createState() => _TaskAttachmentsViewState();
}

class _TaskAttachmentsViewState extends State<TaskAttachmentsView> {
  final _repository = AttachmentRepository(client);
  List<TaskAttachment> _attachments = const [];
  final _bytes = <int, Uint8List>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final attachments = await _repository.list(widget.taskId);
      if (!mounted) return;
      setState(() => _attachments = attachments);
      for (final a in attachments) {
        final bytes = await _repository.download(a.id!);
        if (!mounted) return;
        setState(() => _bytes[a.id!] = bytes);
      }
    } catch (_) {
      // Attachments are supplementary; the prompt text still shows.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_attachments.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.sm,
        children: [
          for (final a in _attachments)
            AttachmentThumbnail(
              name: a.fileName,
              bytes: _bytes[a.id],
              size: 64,
            ),
        ],
      ),
    );
  }
}
