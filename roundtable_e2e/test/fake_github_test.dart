import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:roundtable_e2e/roundtable_e2e.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late FakeGitHub github;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('fake_github_test_');
    github = await FakeGitHub.start(Directory('${temp.path}/repos'));
    await github.createRepo('acme', 'demo', {'README.md': 'hello\n'});
  });

  tearDown(() async {
    await github.close();
    await temp.delete(recursive: true);
  });

  Future<String> git(List<String> args, String dir) async {
    final result = await Process.run('git', [
      '-c',
      'user.name=T',
      '-c',
      'user.email=t@t',
      ...args,
    ], workingDirectory: dir);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    return result.stdout as String;
  }

  Future<Map<String, dynamic>> api(
    String method,
    String path, [
    Object? body,
  ]) async {
    final uri = Uri.parse('${github.url}/api/v3$path');
    final headers = {'Authorization': 'Bearer t'};
    final response = switch (method) {
      'POST' => await http.post(uri, headers: headers, body: jsonEncode(body)),
      'PUT' => await http.put(uri, headers: headers, body: jsonEncode(body)),
      _ => await http.get(uri, headers: headers),
    };
    final decoded = jsonDecode(response.body);
    return {'status': response.statusCode, 'body': decoded};
  }

  test(
    'clone, push a branch, open a PR, diff it and squash-merge it',
    () async {
      final work = '${temp.path}/work';
      final cloneUrl =
          'http://x-access-token:t@${github.url.substring(7)}/acme/demo.git';
      await git(['clone', '-q', cloneUrl, work], temp.path);
      expect(File('$work/README.md').readAsStringSync(), 'hello\n');

      await git(['checkout', '-q', '-b', 'task-1'], work);
      File('$work/README.md').writeAsStringSync('hello\nworld\n');
      File('$work/new.txt').writeAsStringSync('new\n');
      await git(['add', '-A'], work);
      await git(['commit', '-q', '-m', 'change'], work);
      await git(['push', '-q', 'origin', 'task-1'], work);

      final repo = await api('GET', '/repos/acme/demo');
      expect(repo['body']['default_branch'], 'main');

      final created = await api('POST', '/repos/acme/demo/pulls', {
        'title': 'Change',
        'head': 'task-1',
        'base': 'main',
      });
      expect(created['status'], 201);
      expect(created['body']['html_url'], '${github.url}/acme/demo/pull/1');

      final files = await api('GET', '/repos/acme/demo/pulls/1/files');
      final byName = {for (final f in files['body'] as List) f['filename']: f};
      expect(byName['README.md']['status'], 'modified');
      expect(byName['README.md']['patch'], contains('+world'));
      expect(byName['new.txt']['status'], 'added');

      final pr = await api('GET', '/repos/acme/demo/pulls/1');
      expect(pr['body']['mergeable'], isTrue);
      expect(pr['body']['state'], 'open');

      final merged = await api('PUT', '/repos/acme/demo/pulls/1/merge', {
        'merge_method': 'squash',
      });
      expect(merged['status'], 200);
      expect(
        await github.fileOn('acme', 'demo', 'main', 'README.md'),
        'hello\nworld\n',
      );
      expect(
        (await api('GET', '/repos/acme/demo/pulls/1'))['body']['state'],
        'closed',
      );
    },
  );

  test('reviews keep their inline comments, threads can be resolved', () async {
    final work = '${temp.path}/work';
    await git(['clone', '-q', '${github.url}/acme/demo', work], temp.path);
    await git(['checkout', '-q', '-b', 'b'], work);
    File('$work/a.txt').writeAsStringSync('a\n');
    await git(['add', '-A'], work);
    await git(['commit', '-q', '-m', 'a'], work);
    await git(['push', '-q', 'origin', 'b'], work);
    await api('POST', '/repos/acme/demo/pulls', {
      'title': 'A',
      'head': 'b',
      'base': 'main',
    });

    final review = await api('POST', '/repos/acme/demo/pulls/1/reviews', {
      'event': 'COMMENT',
      'body': 'Summary',
      'comments': [
        {'path': 'a.txt', 'line': 1, 'side': 'RIGHT', 'body': 'Hmm'},
      ],
    });
    final reviewId = review['body']['id'];
    final comments = await http.get(
      Uri.parse(
        '${github.url}/api/v3/repos/acme/demo/pulls/1/reviews/$reviewId/comments',
      ),
    );
    final commentId = (jsonDecode(comments.body) as List).single['id'];

    final threads = await http.post(
      Uri.parse('${github.url}/api/graphql'),
      body: jsonEncode({
        'query': 'query { reviewThreads }',
        'variables': {'owner': 'acme', 'repo': 'demo', 'number': 1},
      }),
    );
    final node =
        (jsonDecode(
                  threads.body,
                )['data']['repository']['pullRequest']['reviewThreads']['nodes']
                as List)
            .single;
    expect(node['comments']['nodes'].single['databaseId'], commentId);
    expect(node['isResolved'], isFalse);
    expect(github.pullRequests.single.reviews, ['Summary']);
  });
}
