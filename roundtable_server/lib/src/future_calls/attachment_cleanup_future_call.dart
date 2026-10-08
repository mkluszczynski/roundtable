import 'package:serverpod/serverpod.dart';

import '../endpoints/task_attachment_endpoint.dart';
import '../generated/protocol.dart';

/// Deletes attachments uploaded but never linked to a task (the dev closed
/// the dialog, or anyone kept uploading) once they're older than [maxAge],
/// files included — otherwise they'd fill the storage for good. Scheduled
/// to run recurringly from `server.dart`.
class AttachmentCleanupFutureCall extends FutureCall {
  /// Long enough for a dev still writing the prompt.
  static const maxAge = Duration(hours: 24);

  Future<void> check(Session session) async {
    final cutoff = DateTime.now().toUtc().subtract(maxAge);
    final orphans = await TaskAttachment.db.find(
      session,
      where: (a) => a.taskId.equals(null) & (a.createdAt < cutoff),
    );
    if (orphans.isEmpty) return;
    await TaskAttachmentEndpoint.deleteStored(session, orphans);
    await TaskAttachment.db.delete(session, orphans);
  }
}
