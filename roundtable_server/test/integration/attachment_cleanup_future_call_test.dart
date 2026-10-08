import 'dart:typed_data';

import 'package:roundtable_server/src/endpoints/task_attachment_endpoint.dart';
import 'package:roundtable_server/src/future_calls/attachment_cleanup_future_call.dart';
import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

ByteData _png() => ByteData.sublistView(
  Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2]),
);

void main() {
  withServerpod('Given AttachmentCleanupFutureCall', (
    sessionBuilder,
    endpoints,
  ) {
    Future<TaskAttachment> uploaded({required Duration age}) async {
      final attachment = await endpoints.taskAttachment.upload(
        sessionBuilder,
        'shot.png',
        _png(),
      );
      return TaskAttachment.db.updateRow(
        sessionBuilder.build(),
        attachment.copyWith(
          createdAt: DateTime.now().toUtc().subtract(age),
        ),
      );
    }

    Future<bool> stored(TaskAttachment a) =>
        sessionBuilder.build().storage.fileExists(
          storageId: TaskAttachmentEndpoint.storageId,
          path: a.storagePath,
        );

    test('an old attachment never linked to a task is deleted, file and '
        'all; a recent one stays', () async {
      final old = await uploaded(
        age: AttachmentCleanupFutureCall.maxAge + const Duration(hours: 1),
      );
      final recent = await uploaded(age: const Duration(minutes: 5));

      await AttachmentCleanupFutureCall().check(sessionBuilder.build());

      final session = sessionBuilder.build();
      expect(await TaskAttachment.db.findById(session, old.id!), isNull);
      expect(await stored(old), isFalse);
      expect(await TaskAttachment.db.findById(session, recent.id!), isNotNull);
      expect(await stored(recent), isTrue);
    });

    test('an old attachment of a task stays', () async {
      final project = await Project.db.insertRow(
        sessionBuilder.build(),
        Project(name: 'Roundtable', repoUrl: 'https://github.com/example/r'),
      );
      final old = await uploaded(
        age: AttachmentCleanupFutureCall.maxAge + const Duration(hours: 1),
      );
      await endpoints.task.createTask(
        sessionBuilder,
        project.id!,
        null,
        'Fix this',
        skipPlanning: false,
        attachmentIds: [old.id!],
      );

      await AttachmentCleanupFutureCall().check(sessionBuilder.build());

      expect(
        await TaskAttachment.db.findById(sessionBuilder.build(), old.id!),
        isNotNull,
      );
    });
  });
}
