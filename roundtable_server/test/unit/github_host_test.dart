import 'package:roundtable_server/src/github_host.dart';
import 'package:roundtable_server/src/github_repo_client.dart';
import 'package:test/test.dart';

void main() {
  test('defaults to github.com', () {
    final host = GitHubHost.fromEnvironment({});
    expect(host.web.toString(), 'https://github.com');
    expect(
      host.apiUri('/repos/o/r/pulls', {'per_page': '100'}).toString(),
      'https://api.github.com/repos/o/r/pulls?per_page=100',
    );
    expect(host.graphql.toString(), 'https://api.github.com/graphql');
  });

  test('ROUNDTABLE_GITHUB_URL maps an Enterprise-style host', () {
    final host = GitHubHost.fromEnvironment({
      'ROUNDTABLE_GITHUB_URL': 'http://localhost:9300/',
    });
    expect(host.web.toString(), 'http://localhost:9300');
    expect(
      host.apiUri('/repos/o/r').toString(),
      'http://localhost:9300/api/v3/repos/o/r',
    );
    expect(host.graphql.toString(), 'http://localhost:9300/api/graphql');
    expect(
      host.isApiUri(Uri.parse('http://localhost:9300/api/v3/repos/o/r')),
      isTrue,
    );
    expect(host.isApiUri(Uri.parse('https://api.github.com/repos')), isFalse);
  });

  group('with an Enterprise-style host', () {
    late GitHubHost saved;
    setUp(() {
      saved = gitHubHost;
      gitHubHost = GitHubHost.enterprise('http://localhost:9300');
    });
    tearDown(() => gitHubHost = saved);

    test('repo and PR URLs on it parse, github.com ones do not', () {
      expect(
        parseGitHubRepoUrl('http://localhost:9300/acme/demo.git'),
        (owner: 'acme', repo: 'demo'),
      );
      expect(parseGitHubRepoUrl('https://github.com/acme/demo'), isNull);
      expect(
        GitHubRepoClient().parsePrUrl('http://localhost:9300/acme/demo/pull/3'),
        (owner: 'acme', repo: 'demo', number: '3'),
      );
    });

    test('file contents are only fetched from its API', () async {
      expect(
        () => GitHubRepoClient().getFileContent(
          contentsUrl: 'https://evil.example/api/v3/repos/acme/demo/contents/a',
          token: 't',
          owner: 'acme',
          repo: 'demo',
        ),
        throwsArgumentError,
      );
    });
  });
}
