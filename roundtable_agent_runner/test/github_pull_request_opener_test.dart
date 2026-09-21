import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubPullRequestOpener', () {
    const cloneUrl =
        'https://x-access-token:secret-token@github.com/acme/widgets.git';

    test('looks up the default branch then opens a PR onto it', () async {
      final requests = <http.Request>[];
      final opener = GitHubPullRequestOpener(
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/repos/acme/widgets') {
            return http.Response(jsonEncode({'default_branch': 'main'}), 200);
          }
          if (request.url.path == '/repos/acme/widgets/pulls') {
            return http.Response(
              jsonEncode({
                'html_url': 'https://github.com/acme/widgets/pull/7',
              }),
              201,
            );
          }
          return http.Response('not found', 404);
        }),
      );

      final prUrl = await opener.open(
        cloneUrl: cloneUrl,
        branchName: 'task-42',
        title: 'Do the thing',
        body: 'Details',
      );

      expect(prUrl, 'https://github.com/acme/widgets/pull/7');
      expect(requests, hasLength(2));
      expect(requests[0].headers['Authorization'], 'Bearer secret-token');
      expect(requests[1].method, 'POST');
      final sentBody = jsonDecode(requests[1].body) as Map<String, dynamic>;
      expect(sentBody, {
        'title': 'Do the thing',
        'head': 'task-42',
        'base': 'main',
        'body': 'Details',
      });
    });

    test('throws GitHubApiException on a non-2xx PR creation response', () {
      final opener = GitHubPullRequestOpener(
        httpClient: MockClient((request) async {
          if (request.url.path == '/repos/acme/widgets') {
            return http.Response(jsonEncode({'default_branch': 'main'}), 200);
          }
          return http.Response('bad credentials', 401);
        }),
      );

      expect(
        () => opener.open(
          cloneUrl: cloneUrl,
          branchName: 'task-42',
          title: 'Do the thing',
        ),
        throwsA(isA<GitHubApiException>()),
      );
    });

    test('throws GitHubApiException when the default-branch lookup fails', () {
      final opener = GitHubPullRequestOpener(
        httpClient: MockClient((request) async {
          return http.Response('not found', 404);
        }),
      );

      expect(
        () => opener.open(
          cloneUrl: cloneUrl,
          branchName: 'task-42',
          title: 'Do the thing',
        ),
        throwsA(isA<GitHubApiException>()),
      );
    });

    test('rejects a clone URL with no embedded token', () {
      final opener = GitHubPullRequestOpener(
        httpClient: MockClient((request) async => http.Response('', 500)),
      );

      expect(
        () => opener.open(
          cloneUrl: 'https://github.com/acme/widgets.git',
          branchName: 'task-42',
          title: 'Do the thing',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a non-GitHub clone URL', () {
      final opener = GitHubPullRequestOpener(
        httpClient: MockClient((request) async => http.Response('', 500)),
      );

      expect(
        () => opener.open(
          cloneUrl: 'https://x-access-token:t@gitlab.com/acme/widgets.git',
          branchName: 'task-42',
          title: 'Do the thing',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
