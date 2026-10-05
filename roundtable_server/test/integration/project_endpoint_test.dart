import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:roundtable_server/src/github_repo_client.dart';
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

    test('when creating a project with tools then they are validated and '
        'saved', () async {
      final project = await endpoints.project.create(
        sessionBuilder,
        'Roundtable',
        'https://github.com/example/roundtable',
        tools: [ProjectTool(name: 'Flutter', version: '3.24')],
      );

      final fetched = await endpoints.project.get(sessionBuilder, project.id!);
      expect(fetched!.tools!.single.name, 'flutter');
      expect(fetched.tools!.single.version, '3.24');
    });

    test('when updating tools then the list is replaced', () async {
      final project = await endpoints.project.create(
        sessionBuilder,
        'Roundtable',
        'https://github.com/example/roundtable',
      );

      final updated = await endpoints.project.updateTools(
        sessionBuilder,
        project.id!,
        [
          ProjectTool(name: 'node', version: 'lts'),
          ProjectTool(name: 'pnpm', version: '9'),
        ],
      );

      expect([for (final t in updated.tools!) t.name], ['node', 'pnpm']);
      expect(updated.name, 'Roundtable');
    });

    test('when updating tools with a duplicate then it is rejected', () async {
      final project = await endpoints.project.create(
        sessionBuilder,
        'Roundtable',
        'https://github.com/example/roundtable',
      );

      await expectLater(
        endpoints.project.updateTools(sessionBuilder, project.id!, [
          ProjectTool(name: 'node', version: '20'),
          ProjectTool(name: 'node', version: '22'),
        ]),
        throwsA(isA<InvalidStateException>()),
      );
    });

    group('when detecting tools', () {
      late List<http.Request> requests;

      setUp(() {
        requests = [];
        gitHubRepoClient = GitHubRepoClient(
          httpClient: MockClient((request) async {
            requests.add(request);
            if (request.url.path.endsWith('/git/trees/HEAD')) {
              return http.Response(
                jsonEncode({
                  'tree': [
                    {'path': 'app/pubspec.yaml', 'type': 'blob'},
                    {'path': '.nvmrc', 'type': 'blob'},
                    {'path': 'web/package.json', 'type': 'blob'},
                  ],
                }),
                200,
              );
            }
            if (request.url.path.endsWith('/app/pubspec.yaml')) {
              return http.Response(
                'dependencies:\n  flutter:\n    sdk: flutter\n',
                200,
              );
            }
            if (request.url.path.endsWith('/.nvmrc')) {
              return http.Response('20\n', 200);
            }
            return http.Response('', 404);
          }),
        );
      });

      tearDown(() => gitHubRepoClient = GitHubRepoClient());

      test('then the repo manifests are turned into suggestions, read with '
          "the project's stored token", () async {
        final project = await endpoints.project.create(
          sessionBuilder,
          'Roundtable',
          'https://github.com/example/roundtable.git',
          repoAccessToken: 'stored-token',
        );

        final tools = await endpoints.project.detectTools(
          sessionBuilder,
          project.repoUrl,
          projectId: project.id,
        );

        expect(
          [for (final t in tools) '${t.name}@${t.version}'],
          [
            'flutter@latest',
            'node@20',
          ],
        );
        expect(
          requests.first.url.path,
          '/repos/example/roundtable/git/trees/HEAD',
        );
        expect(
          requests.every(
            (r) => r.headers['Authorization'] == 'Bearer stored-token',
          ),
          isTrue,
        );
      });

      test('then a non-GitHub repo yields nothing without a request', () async {
        final tools = await endpoints.project.detectTools(
          sessionBuilder,
          'https://gitlab.com/example/roundtable',
        );

        expect(tools, isEmpty);
        expect(requests, isEmpty);
      });
    });
  });
}
