import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:roundtable_server/src/github_repo_client.dart';
import 'package:test/test.dart';

void main() {
  test('when GitHub does not respond in time then a GitHubException with '
      'status 504 is thrown', () async {
    final hanging = Completer<http.Response>();
    final client = GitHubRepoClient(
      httpClient: MockClient((_) => hanging.future),
      timeout: const Duration(milliseconds: 50),
    );

    await expectLater(
      client.mergePullRequest(
        prUrl: 'https://github.com/example/rt/pull/1',
        token: 'secret',
      ),
      throwsA(
        isA<GitHubException>().having((e) => e.statusCode, 'statusCode', 504),
      ),
    );
  });

  group('parseGitHubRepoUrl', () {
    test('accepts repo URLs with and without .git', () {
      expect(parseGitHubRepoUrl('https://github.com/a/b'), (
        owner: 'a',
        repo: 'b',
      ));
      expect(parseGitHubRepoUrl('https://github.com/a/b.git/'), (
        owner: 'a',
        repo: 'b',
      ));
    });

    test('rejects other hosts and incomplete paths', () {
      expect(parseGitHubRepoUrl('https://gitlab.com/a/b'), isNull);
      expect(parseGitHubRepoUrl('https://github.com/a'), isNull);
    });
  });

  test('listRepoFiles keeps blobs and works without a token', () async {
    late http.Request seen;
    final client = GitHubRepoClient(
      httpClient: MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode({
            'tree': [
              {'path': 'app', 'type': 'tree'},
              {'path': 'app/pubspec.yaml', 'type': 'blob'},
            ],
          }),
          200,
        );
      }),
    );

    expect(await client.listRepoFiles(owner: 'a', repo: 'b'), [
      'app/pubspec.yaml',
    ]);
    expect(seen.url.path, '/repos/a/b/git/trees/HEAD');
    expect(seen.headers.containsKey('Authorization'), isFalse);
  });

  test('getRepoFile returns null for a missing file', () async {
    final client = GitHubRepoClient(
      httpClient: MockClient((_) async => http.Response('', 404)),
    );
    expect(
      await client.getRepoFile(owner: 'a', repo: 'b', path: '.nvmrc'),
      isNull,
    );
  });
}
