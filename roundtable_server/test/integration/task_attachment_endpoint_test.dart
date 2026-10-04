import 'dart:typed_data';

import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

ByteData _png() => ByteData.sublistView(
  Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2]),
);

void main() {
  withServerpod('Given TaskAttachment endpoint', (sessionBuilder, endpoints) {
    Future<Project> createProject() => Project.db.insertRow(
      sessionBuilder.build(),
      Project(name: 'Roundtable', repoUrl: 'https://github.com/example/r'),
    );

    test('an uploaded image is linked on task creation and readable', () async {
      final project = await createProject();
      final uploaded = await endpoints.taskAttachment.upload(
        sessionBuilder,
        '../../shot.png',
        _png(),
      );
      expect(uploaded.taskId, isNull);
      expect(uploaded.mimeType, 'image/png');
      expect(uploaded.fileName, 'shot.png');

      final task = await endpoints.task.createTask(
        sessionBuilder,
        project.id!,
        null,
        'Fix this',
        skipPlanning: false,
        attachmentIds: [uploaded.id!],
      );

      final listed = await endpoints.taskAttachment.list(
        sessionBuilder,
        task.id!,
      );
      expect(listed.map((a) => a.id), [uploaded.id]);

      final bytes = await endpoints.taskAttachment.download(
        sessionBuilder,
        uploaded.id!,
      );
      expect(bytes.lengthInBytes, 10);
    });

    test('a file that is not an image is rejected', () async {
      expect(
        () => endpoints.taskAttachment.upload(
          sessionBuilder,
          'evil.png',
          ByteData.sublistView(Uint8List.fromList('#!/bin/sh'.codeUnits)),
        ),
        throwsA(isA<InvalidStateException>()),
      );
    });

    test('deleting the task removes its attachments', () async {
      final project = await createProject();
      final uploaded = await endpoints.taskAttachment.upload(
        sessionBuilder,
        'a.png',
        _png(),
      );
      final task = await endpoints.task.createTask(
        sessionBuilder,
        project.id!,
        null,
        'Draft',
        skipPlanning: false,
        attachmentIds: [uploaded.id!],
      );

      await endpoints.task.deleteTask(sessionBuilder, task.id!);

      expect(
        await TaskAttachment.db.findById(sessionBuilder.build(), uploaded.id!),
        isNull,
      );
    });
  });
}
