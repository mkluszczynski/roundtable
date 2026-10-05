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
