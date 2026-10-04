import 'dart:math';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Images attached to a task's prompt. The panel uploads them while the dev
/// writes the prompt ([upload]) and links them on `TaskEndpoint.createTask`;
/// the panel and the agent runner read them back by id.
class TaskAttachmentEndpoint extends Endpoint {
  static const storageId = 'private';
  static const maxBytes = 5 * 1024 * 1024;
  static const maxPerTask = 6;

  /// Stores [bytes] and returns the not-yet-linked attachment. The type is
  /// sniffed from the bytes rather than trusted from the client, and the
  /// storage path is generated here.
  Future<TaskAttachment> upload(
    Session session,
    String fileName,
    ByteData bytes,
  ) async {
    if (bytes.lengthInBytes == 0) {
      throw InvalidStateException(message: 'The image is empty.');
    }
    if (bytes.lengthInBytes > maxBytes) {
      throw InvalidStateException(
        message: 'Images can be at most ${maxBytes ~/ (1024 * 1024)} MB.',
      );
    }
    final type = imageTypeOf(
      bytes.buffer.asUint8List(
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      ),
    );
    if (type == null) {
      throw InvalidStateException(
        message: 'Only PNG, JPEG, GIF and WebP images can be attached.',
      );
    }

    final path = 'task-attachments/${_randomId()}.${type.extension}';
    await session.storage.storeFile(
      storageId: storageId,
      path: path,
      byteData: bytes,
    );
    return TaskAttachment.db.insertRow(
      session,
      TaskAttachment(
        storagePath: path,
        fileName: _safeFileName(fileName, type.extension),
        mimeType: type.mimeType,
        sizeBytes: bytes.lengthInBytes,
      ),
    );
  }

  /// The attachments of [taskId], oldest first.
  Future<List<TaskAttachment>> list(Session session, int taskId) {
    return TaskAttachment.db.find(
      session,
      where: (a) => a.taskId.equals(taskId),
      orderBy: (a) => a.id,
    );
  }

  /// The image bytes of attachment [id].
  Future<ByteData> download(Session session, int id) async {
    final attachment = await TaskAttachment.db.findById(session, id);
    if (attachment == null) {
      throw NotFoundException(message: 'Attachment $id not found');
    }
    return session.storage.retrieveFile(
      storageId: storageId,
      path: attachment.storagePath,
    );
  }

  /// Removes an attachment that isn't linked to a task yet — the dev took
  /// it out of the prompt before creating the task.
  Future<void> discard(Session session, int id) async {
    final attachment = await TaskAttachment.db.findById(session, id);
    if (attachment == null || attachment.taskId != null) return;
    await deleteStored(session, [attachment]);
    await TaskAttachment.db.deleteRow(session, attachment);
  }

  /// Links the uploaded [ids] to [taskId]. Ignores ids that don't exist or
  /// already belong to a task.
  static Future<void> link(Session session, int taskId, List<int> ids) async {
    if (ids.isEmpty) return;
    if (ids.length > maxPerTask) {
      throw InvalidStateException(
        message: 'A task can have at most $maxPerTask images.',
      );
    }
    final pending = await TaskAttachment.db.find(
      session,
      where: (a) => a.id.inSet(ids.toSet()) & a.taskId.equals(null),
    );
    await TaskAttachment.db.update(
      session,
      [for (final a in pending) a.copyWith(taskId: taskId)],
      columns: (a) => [a.taskId],
    );
  }

  /// Deletes the stored files of [attachments] (their rows cascade with the
  /// task, the files don't).
  static Future<void> deleteStored(
    Session session,
    List<TaskAttachment> attachments,
  ) async {
    for (final a in attachments) {
      await session.storage.deleteFile(
        storageId: storageId,
        path: a.storagePath,
      );
    }
  }

  static final _random = Random.secure();

  /// 128 random bits as hex — unguessable storage key.
  static String _randomId() => List.generate(
    16,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  static String _safeFileName(String name, String extension) {
    final base = name
        .split(RegExp(r'[\\/]'))
        .last
        .replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_')
        .trim();
    if (base.isEmpty) return 'image.$extension';
    return base.length > 100 ? base.substring(base.length - 100) : base;
  }
}

/// An accepted image type, recognised by its magic bytes.
typedef ImageType = ({String mimeType, String extension});

ImageType? imageTypeOf(Uint8List b) {
  bool starts(List<int> sig, [int offset = 0]) {
    if (b.length < offset + sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (b[offset + i] != sig[i]) return false;
    }
    return true;
  }

  if (starts([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return (mimeType: 'image/png', extension: 'png');
  }
  if (starts([0xFF, 0xD8, 0xFF])) {
    return (mimeType: 'image/jpeg', extension: 'jpg');
  }
  if (starts([0x47, 0x49, 0x46, 0x38])) {
    return (mimeType: 'image/gif', extension: 'gif');
  }
  if (starts([0x52, 0x49, 0x46, 0x46]) && starts([0x57, 0x45, 0x42, 0x50], 8)) {
    return (mimeType: 'image/webp', extension: 'webp');
  }
  return null;
}
