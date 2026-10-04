import 'dart:typed_data';

import 'package:roundtable_client/roundtable_client.dart';

/// Images attached to a task's prompt (`TaskAttachmentEndpoint`).
class AttachmentRepository {
  AttachmentRepository(this._client);

  final Client _client;

  Future<TaskAttachment> upload(String fileName, Uint8List bytes) =>
      _client.taskAttachment.upload(fileName, ByteData.sublistView(bytes));

  Future<List<TaskAttachment>> list(int taskId) =>
      _client.taskAttachment.list(taskId);

  Future<Uint8List> download(int id) async {
    final data = await _client.taskAttachment.download(id);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<void> discard(int id) => _client.taskAttachment.discard(id);
}
