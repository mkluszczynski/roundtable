import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Project endpoint', (sessionBuilder, endpoints) {
    test(
      'when creating a project then it is persisted with the given fields',
      () async {
        final project = await endpoints.project.create(
          sessionBuilder,
          'Roundtable',
          'https://github.com/example/roundtable',
        );

        expect(project.id, isNotNull);
        expect(project.name, 'Roundtable');
        expect(project.repoUrl, 'https://github.com/example/roundtable');
      },
    );

    test('when getting a project by id then it is returned', () async {
      final created = await endpoints.project.create(
        sessionBuilder,
        'Roundtable',
        'https://github.com/example/roundtable',
      );

      final fetched = await endpoints.project.get(sessionBuilder, created.id!);

      expect(fetched, isNotNull);
      expect(fetched!.id, created.id);
    });

    test(
      'when listing projects then all created projects are included',
      () async {
        final first = await endpoints.project.create(
          sessionBuilder,
          'Roundtable',
          'https://github.com/example/roundtable',
        );
        final second = await endpoints.project.create(
          sessionBuilder,
          'Other',
          'https://github.com/example/other',
        );

        final projects = await endpoints.project.list(sessionBuilder);

        expect(projects.map((p) => p.id), containsAll([first.id, second.id]));
      },
    );

    test('when updating a project then the change is persisted', () async {
      final created = await endpoints.project.create(
        sessionBuilder,
        'Roundtable',
        'https://github.com/example/roundtable',
      );

      await endpoints.project.update(
        sessionBuilder,
        created.copyWith(name: 'Renamed'),
      );

      final fetched = await endpoints.project.get(sessionBuilder, created.id!);
      expect(fetched!.name, 'Renamed');
    });

    test('when deleting a project then it can no longer be fetched', () async {
      final created = await endpoints.project.create(
        sessionBuilder,
        'Roundtable',
        'https://github.com/example/roundtable',
      );

      await endpoints.project.delete(sessionBuilder, created.id!);

      final fetched = await endpoints.project.get(sessionBuilder, created.id!);
      expect(fetched, isNull);
    });
  });
}
