import 'dart:async';

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
}
