import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Settings endpoint', (sessionBuilder, endpoints) {
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

    group('a task created with the default options', () {
      late Project project;

      setUp(() async {
        project = await endpoints.project.create(
          sessionBuilder,
          'Roundtable',
          'https://github.com/example/roundtable',
        );
        project = await endpoints.settings.updateProjectTaskDefaults(
          sessionBuilder,
          project.copyWith(autoReview: true, skipPlanning: true),
        );
      });

      Future<Task> createTask({bool followDefaults = true}) =>
          endpoints.task.createTask(
            sessionBuilder,
            project.id!,
            null,
            'Do something',
            skipPlanning: false,
            followDefaults: followDefaults,
          );

      Future<Task> reload(Task task) async =>
          (await Task.db.findById(sessionBuilder.build(), task.id!))!;

      Future<Task> setStatus(Task task, TaskStatus status) => Task.db.updateRow(
        sessionBuilder.build(),
        task.copyWith(status: status),
      );

      test('takes the project defaults, whatever options are sent', () async {
        final task = await endpoints.task.createTask(
          sessionBuilder,
          project.id!,
          null,
          'Do something',
          skipPlanning: false,
          autoReview: false,
          followDefaults: true,
        );

        expect(task.followsDefaults, isTrue);
        expect(task.autoReview, isTrue);
        expect(task.skipPlanning, isTrue);
      });

      test(
        'when the project turns an option off then the task follows',
        () async {
          final task = await createTask();

          await endpoints.settings.updateProjectTaskDefaults(
            sessionBuilder,
            project.copyWith(autoReview: false),
          );

          expect((await reload(task)).autoReview, isFalse);
        },
      );

      test('when the workspace default changes then a task of a project '
          'inheriting it follows', () async {
        final task = await createTask();
        final workspace = await endpoints.settings.getWorkspace(sessionBuilder);

        await endpoints.settings.updateWorkspace(
          sessionBuilder,
          workspace.copyWith(autoMerge: true),
        );

        expect((await reload(task)).autoMerge, isTrue);
      });

      test('when created with its own options then it keeps them', () async {
        final task = await createTask(followDefaults: false);

        await endpoints.settings.updateProjectTaskDefaults(
          sessionBuilder,
          project.copyWith(autoReview: false, autoMerge: true),
        );

        final stored = await reload(task);
        expect(stored.followsDefaults, isFalse);
        expect(stored.autoReview, isFalse);
        expect(stored.autoMerge, isFalse);
      });

      test('when the dev edits an option on the task then it stops '
          'following the defaults', () async {
        final task = await createTask();

        // Editing only the prompt keeps it following.
        final renamed = await endpoints.task.updateTaskSettings(
          sessionBuilder,
          task.id!,
          'Do something else',
          skipPlanning: task.skipPlanning,
          autoReview: task.autoReview,
          reviewerAgentId: task.reviewerAgentId,
        );
        expect(renamed.followsDefaults, isTrue);

        final edited = await endpoints.task.updateTaskSettings(
          sessionBuilder,
          task.id!,
          'Do something else',
          autoMerge: true,
        );
        expect(edited.followsDefaults, isFalse);

        await endpoints.settings.updateProjectTaskDefaults(
          sessionBuilder,
          project.copyWith(autoReview: false),
        );
        expect((await reload(task)).autoReview, isTrue);
      });

      test('when it is done then it keeps its options', () async {
        final task = await setStatus(await createTask(), TaskStatus.done);

        await endpoints.settings.updateProjectTaskDefaults(
          sessionBuilder,
          project.copyWith(autoReview: false),
        );

        expect((await reload(task)).autoReview, isTrue);
      });

      test('when a run is under way then only the automation options '
          'follow', () async {
        final task = await setStatus(await createTask(), TaskStatus.running);

        await endpoints.settings.updateProjectTaskDefaults(
          sessionBuilder,
          project.copyWith(autoReview: false, skipPlanning: false),
        );

        final stored = await reload(task);
        expect(stored.autoReview, isFalse);
        expect(stored.skipPlanning, isTrue);
        expect(stored.status, TaskStatus.running);
      });
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
