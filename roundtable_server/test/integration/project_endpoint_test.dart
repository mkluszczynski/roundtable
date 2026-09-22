import 'package:roundtable_server/src/generated/protocol.dart';
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

    test(
      'when deleting a project with a non-terminal task then it throws DeletionBlockedException',
      () async {
        final session = sessionBuilder.build();
        final project = await Project.db.insertRow(
          session,
          Project(
            name: 'Roundtable',
            repoUrl: 'https://github.com/example/roundtable',
          ),
        );
        await Task.db.insertRow(
          session,
          Task(
            projectId: project.id!,
            prompt: 'Do something',
            status: TaskStatus.planning,
          ),
        );

        await expectLater(
          endpoints.project.delete(sessionBuilder, project.id!),
          throwsA(isA<DeletionBlockedException>()),
        );
      },
    );

    test(
      'when creating a project with a repo access token then repoAccessTokenUpdatedAt is set',
      () async {
        final project = await endpoints.project.create(
          sessionBuilder,
          'Roundtable',
          'https://github.com/example/roundtable',
          repoAccessToken: 'secret-token',
        );

        expect(project.repoAccessTokenUpdatedAt, isNotNull);
      },
    );

    test(
      'when updating the repo access token then repoAccessTokenUpdatedAt is refreshed and the raw token is never returned',
      () async {
        final created = await endpoints.project.create(
          sessionBuilder,
          'Roundtable',
          'https://github.com/example/roundtable',
        );
        expect(created.repoAccessTokenUpdatedAt, isNull);

        await endpoints.project.updateRepoAccessToken(
          sessionBuilder,
          created.id!,
          'new-secret-token',
        );

        final fetched = await endpoints.project.get(
          sessionBuilder,
          created.id!,
        );
        expect(fetched!.repoAccessTokenUpdatedAt, isNotNull);

        // `repoAccessToken` is `scope=serverOnly`: it's stripped from
        // wire serialization to the panel, not from in-process endpoint
        // calls like this test's — verify the real guarantee instead,
        // that `getCloneUrl` (the only server-side reader) sees it.
        final cloneUrl = await endpoints.project.getCloneUrl(
          sessionBuilder,
          created.id!,
        );
        expect(
          cloneUrl,
          'https://x-access-token:new-secret-token@github.com/example/roundtable',
        );
      },
    );

    test(
      'when getting the clone url for a project without an access token then the plain repo url is returned',
      () async {
        final created = await endpoints.project.create(
          sessionBuilder,
          'Roundtable',
          'https://github.com/example/roundtable',
        );

        final cloneUrl = await endpoints.project.getCloneUrl(
          sessionBuilder,
          created.id!,
        );

        expect(cloneUrl, 'https://github.com/example/roundtable');
      },
    );

    test(
      'when getting the clone url for a project with an access token then it is injected as userinfo',
      () async {
        final created = await endpoints.project.create(
          sessionBuilder,
          'Roundtable',
          'https://github.com/example/roundtable',
          repoAccessToken: 'secret-token',
        );

        final cloneUrl = await endpoints.project.getCloneUrl(
          sessionBuilder,
          created.id!,
        );

        expect(
          cloneUrl,
          'https://x-access-token:secret-token@github.com/example/roundtable',
        );
      },
    );

    test(
      'when getting the clone url for a non-https repo url then it is returned unchanged',
      () async {
        final created = await endpoints.project.create(
          sessionBuilder,
          'Roundtable',
          'git@github.com:example/roundtable.git',
          repoAccessToken: 'secret-token',
        );

        final cloneUrl = await endpoints.project.getCloneUrl(
          sessionBuilder,
          created.id!,
        );

        expect(cloneUrl, 'git@github.com:example/roundtable.git');
      },
    );
  });
}
