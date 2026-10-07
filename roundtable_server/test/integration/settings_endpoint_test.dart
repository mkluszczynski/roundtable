import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Settings endpoint', (sessionBuilder, endpoints) {
    group('when a project default changes', () {
      Future<Task> reload(Task task) async =>
          (await Task.db.findById(sessionBuilder.build(), task.id!))!;

      test('then unfinished tasks that inherited it follow, the others '
          'keep theirs', () async {
        var project = await endpoints.project.create(
          sessionBuilder,
          'Roundtable',
          'https://github.com/example/roundtable',
        );
        project = await endpoints.settings.updateProjectTaskDefaults(
          sessionBuilder,
          project.copyWith(autoReview: true),
        );
        Future<Task> create({required bool autoReview}) =>
            endpoints.task.createTask(
              sessionBuilder,
              project.id!,
              null,
              'Fix it',
              skipPlanning: false,
              autoReview: autoReview,
            );
        final inherited = await create(autoReview: true);
        final overridden = await create(autoReview: false);
        var finished = await create(autoReview: true);
        expect(inherited.overriddenOptions, isEmpty);
        expect(overridden.overriddenOptions, ['autoReview']);
        finished = await Task.db.updateRow(
          sessionBuilder.build(),
          finished.copyWith(status: TaskStatus.done),
        );

        project = await endpoints.settings.updateProjectTaskDefaults(
          sessionBuilder,
          project.copyWith(autoReview: false),
        );
        expect((await reload(inherited)).autoReview, isFalse);
        expect((await reload(finished)).autoReview, isTrue);

        await endpoints.settings.updateProjectTaskDefaults(
          sessionBuilder,
          project.copyWith(autoReview: true),
        );
        expect((await reload(inherited)).autoReview, isTrue);
        expect((await reload(overridden)).autoReview, isFalse);
      });

      test('then an option set on the task itself is kept', () async {
        var project = await endpoints.project.create(
          sessionBuilder,
          'Roundtable',
          'https://github.com/example/roundtable',
        );
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          null,
          'Fix it',
          skipPlanning: false,
        );
        final edited = await endpoints.task.updateTaskSettings(
          sessionBuilder,
          task.id!,
          'Fix it',
          autoMerge: true,
        );
        expect(edited.overriddenOptions, ['autoMerge']);

        await endpoints.settings.updateProjectTaskDefaults(
          sessionBuilder,
          project.copyWith(autoMerge: false, autoReview: true),
        );
        final current = await reload(task);
        expect(current.autoMerge, isTrue);
        expect(current.autoReview, isTrue);
      });
    });

    test('when a workspace default changes then unfinished tasks of a '
        'project inheriting it follow', () async {
      final project = await endpoints.project.create(
        sessionBuilder,
        'Roundtable',
        'https://github.com/example/roundtable',
      );
      final task = await endpoints.task.createTask(
        sessionBuilder,
        project.id!,
        null,
        'Fix it',
        skipPlanning: false,
      );
      final workspace = await endpoints.settings.getWorkspace(sessionBuilder);

      await endpoints.settings.updateWorkspace(
        sessionBuilder,
        workspace.copyWith(autoMerge: true),
      );

      final current = await Task.db.findById(sessionBuilder.build(), task.id!);
      expect(current!.autoMerge, isTrue);
    });

    test('when nothing is set then task defaults are off', () async {
      final project = await endpoints.project.create(
        sessionBuilder,
        'Roundtable',
        'https://github.com/example/roundtable',
      );

      final defaults = await endpoints.settings.taskDefaults(
        sessionBuilder,
        project.id!,
      );

      expect(defaults.skipPlanning, isFalse);
    });

    test('when the workspace default is on then a project inherits it, '
        'unless it overrides it', () async {
      final workspace = await endpoints.settings.getWorkspace(sessionBuilder);
      await endpoints.settings.updateWorkspace(
        sessionBuilder,
        workspace.copyWith(skipPlanning: true),
      );
      final project = await endpoints.project.create(
        sessionBuilder,
        'Roundtable',
        'https://github.com/example/roundtable',
      );

      expect(
        (await endpoints.settings.taskDefaults(
          sessionBuilder,
          project.id!,
        )).skipPlanning,
        isTrue,
      );

      await endpoints.settings.updateProjectTaskDefaults(
        sessionBuilder,
        project.copyWith(skipPlanning: false),
      );
      expect(
        (await endpoints.settings.taskDefaults(
          sessionBuilder,
          project.id!,
        )).skipPlanning,
        isFalse,
      );

      // Back to inheriting.
      final reset = await endpoints.settings.updateProjectTaskDefaults(
        sessionBuilder,
        project.copyWith(skipPlanning: null),
      );
      expect(reset.skipPlanning, isNull);
      expect(
        (await endpoints.settings.taskDefaults(
          sessionBuilder,
          project.id!,
        )).skipPlanning,
        isTrue,
      );
    });

    test(
      'when the workspace is read twice then the same row is returned',
      () async {
        final first = await endpoints.settings.getWorkspace(sessionBuilder);
        final second = await endpoints.settings.getWorkspace(sessionBuilder);
        expect(second.id, first.id);
      },
    );
  });
}
