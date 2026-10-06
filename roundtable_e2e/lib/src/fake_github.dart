import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A pull request on [FakeGitHub].
class FakePullRequest {
  FakePullRequest({
    required this.number,
    required this.owner,
    required this.repo,
    required this.head,
    required this.base,
    required this.title,
    required this.body,
  });

  final int number;
  final String owner;
  final String repo;
  final String head;
  final String base;
  final String title;
  final String? body;
  bool merged = false;
  bool closed = false;

  /// Bodies of the reviews posted on it, oldest first.
  final reviews = <String>[];
}

/// An inline review comment on [FakeGitHub].
class _FakeComment {
  _FakeComment(this.id, this.prNumber, this.reviewId, this.body);

  final int id;
  final int prNumber;
  final int reviewId;
  final String body;
  bool resolved = false;
}

/// Just enough of GitHub for Roundtable's E2E tests (docs/DEVELOPMENT.md
/// "E2E tests"), served the way GitHub Enterprise is: repos and git over
/// HTTP at the root, the REST API under `/api/v3`, GraphQL at
/// `/api/graphql`. Point the server at it with `ROUNDTABLE_GITHUB_URL`.
///
/// Repos are real bare git repos under [root]: the runner clones and pushes
/// through `git http-backend`, pull request diffs come from `git diff`, and
/// a merge really squashes the branch onto the default one. Any token is
/// accepted. No GitHub Actions run, so CI reports no checks.
class FakeGitHub {
  FakeGitHub._(this._server, this.root);

  final HttpServer _server;

  /// Holds the bare repos, as `<owner>/<repo>`.
  final Directory root;

  final _pulls = <FakePullRequest>[];
  final _comments = <_FakeComment>[];
  var _nextId = 1000;

  /// Starts on a free port of localhost, keeping repos under [root].
  static Future<FakeGitHub> start(Directory root) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final github = FakeGitHub._(server, root);
    server.listen(github._handle);
    return github;
  }

  /// The `ROUNDTABLE_GITHUB_URL` to use, e.g. `http://127.0.0.1:41234`.
  String get url => 'http://127.0.0.1:${_server.port}';

  /// The web URL of [owner]/[repo], as a project's `repoUrl`.
  String repoUrl(String owner, String repo) => '$url/$owner/$repo';

  List<FakePullRequest> get pullRequests => List.unmodifiable(_pulls);

  Future<void> close() => _server.close(force: true);

  /// Creates [owner]/[repo] with [files] committed on `main`.
  Future<void> createRepo(
    String owner,
    String repo,
    Map<String, String> files,
  ) async {
    final bare = _repoDir(owner, repo);
    await bare.create(recursive: true);
    await _git(['init', '--bare', '-b', 'main', bare.path]);
    final work = await Directory.systemTemp.createTemp('fake-github-seed-');
    try {
      await _git(['init', '-b', 'main'], work.path);
      for (final MapEntry(key: path, value: content) in files.entries) {
        final file = File('${work.path}/$path');
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      }
      await _git(['add', '-A'], work.path);
      await _commit(work.path, 'Initial commit');
      await _git(['push', bare.path, 'main'], work.path);
    } finally {
      await work.delete(recursive: true);
    }
  }

  /// The content of [path] on [branch] of [owner]/[repo], or null.
  Future<String?> fileOn(
    String owner,
    String repo,
    String branch,
    String path,
  ) async {
    final result = await Process.run('git', [
      'show',
      '$branch:$path',
    ], workingDirectory: _repoDir(owner, repo).path);
    return result.exitCode == 0 ? result.stdout as String : null;
  }

  Directory _repoDir(String owner, String repo) =>
      Directory('${root.path}/$owner/$repo');

  Future<void> _handle(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (path.startsWith('/api/v3/')) {
        await _rest(request, path.substring('/api/v3'.length));
      } else if (path == '/api/graphql') {
        await _graphql(request);
      } else {
        await _gitHttp(request);
      }
    } catch (e, stack) {
      stderr.writeln(
        'fake GitHub: ${request.method} ${request.uri}: $e\n$stack',
      );
      try {
        request.response.statusCode = 500;
        request.response.write('$e');
      } catch (_) {}
    } finally {
      await request.response.close();
    }
  }

  // ---------------------------------------------------------------- git

  /// Serves `git clone`/`fetch`/`push` through `git http-backend` (CGI).
  /// `/owner/repo.git/...` and `/owner/repo/...` both work.
  Future<void> _gitHttp(HttpRequest request) async {
    final segments = request.uri.pathSegments.toList();
    if (segments.length < 3) {
      request.response.statusCode = 404;
      return;
    }
    if (segments[1].endsWith('.git')) {
      segments[1] = segments[1].substring(0, segments[1].length - 4);
    }
    final process = await Process.start(
      'git',
      ['http-backend'],
      environment: {
        'GIT_PROJECT_ROOT': root.path,
        'GIT_HTTP_EXPORT_ALL': '1',
        'PATH_INFO': '/${segments.join('/')}',
        'QUERY_STRING': request.uri.query,
        'REQUEST_METHOD': request.method,
        'CONTENT_TYPE': request.headers.contentType?.toString() ?? '',
        'HTTP_CONTENT_ENCODING':
            request.headers.value(HttpHeaders.contentEncodingHeader) ?? '',
        'REMOTE_USER': 'x-access-token',
        'REMOTE_ADDR': '127.0.0.1',
        'GIT_CONFIG_COUNT': '1',
        'GIT_CONFIG_KEY_0': 'http.receivepack',
        'GIT_CONFIG_VALUE_0': 'true',
      },
    );
    final stdinDone = request.cast<List<int>>().pipe(process.stdin);
    final output = <int>[];
    final stdoutDone = process.stdout.listen(output.addAll).asFuture<void>();
    final stderrText = process.stderr.transform(utf8.decoder).join();
    await stdinDone;
    await stdoutDone;
    await process.exitCode;
    final errors = await stderrText;
    if (errors.trim().isNotEmpty) stderr.writeln('git http-backend: $errors');

    // CGI output: headers, a blank line, then the body.
    var split = _indexOf(output, const [13, 10, 13, 10]);
    var separator = 4;
    if (split < 0) {
      split = _indexOf(output, const [10, 10]);
      separator = 2;
    }
    final head = latin1.decode(output.sublist(0, split < 0 ? 0 : split));
    final response = request.response;
    for (final line in const LineSplitter().convert(head)) {
      final colon = line.indexOf(':');
      if (colon < 0) continue;
      final name = line.substring(0, colon).trim();
      final value = line.substring(colon + 1).trim();
      if (name.toLowerCase() == 'status') {
        response.statusCode = int.parse(value.split(' ').first);
      } else {
        response.headers.set(name, value);
      }
    }
    response.add(split < 0 ? output : output.sublist(split + separator));
  }

  static int _indexOf(List<int> data, List<int> pattern) {
    outer:
    for (var i = 0; i <= data.length - pattern.length; i++) {
      for (var j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) continue outer;
      }
      return i;
    }
    return -1;
  }

  // ---------------------------------------------------------------- REST

  Future<void> _rest(HttpRequest request, String path) async {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length < 3 || segments[0] != 'repos') {
      return _json(request, 404, {'message': 'Not Found'});
    }
    final owner = segments[1];
    final repo = segments[2];
    if (!await _repoDir(owner, repo).exists()) {
      return _json(request, 404, {'message': 'Not Found'});
    }
    final rest = segments.sublist(3);
    final method = request.method;
    final body = method == 'GET' ? null : await _readJson(request);

    switch (rest) {
      case []:
        return _json(request, 200, {
          'full_name': '$owner/$repo',
          'default_branch': 'main',
        });
      case ['pulls'] when method == 'POST':
        final pr = FakePullRequest(
          number: _pulls.length + 1,
          owner: owner,
          repo: repo,
          head: body!['head'] as String,
          base: body['base'] as String,
          title: body['title'] as String,
          body: body['body'] as String?,
        );
        _pulls.add(pr);
        return _json(request, 201, await _prJson(pr));
      case ['pulls', final number]:
        final pr = _pull(owner, repo, number);
        if (pr == null) return _json(request, 404, {'message': 'Not Found'});
        return _json(request, 200, await _prJson(pr));
      case ['pulls', final number, 'files']:
        final pr = _pull(owner, repo, number);
        if (pr == null) return _json(request, 404, {'message': 'Not Found'});
        return _json(request, 200, await _files(pr));
      case ['pulls', final number, 'reviews'] when method == 'POST':
        final pr = _pull(owner, repo, number);
        if (pr == null) return _json(request, 404, {'message': 'Not Found'});
        final reviewId = _nextId++;
        pr.reviews.add(body!['body'] as String? ?? '');
        for (final c in (body['comments'] as List? ?? const [])) {
          _comments.add(
            _FakeComment(_nextId++, pr.number, reviewId, '${c['body']}'),
          );
        }
        return _json(request, 200, {'id': reviewId});
      case ['pulls', _, 'reviews', final reviewId, 'comments']:
        return _json(request, 200, [
          for (final c in _comments)
            if ('${c.reviewId}' == reviewId) {'id': c.id, 'body': c.body},
        ]);
      case ['pulls', _, 'comments', _, 'replies'] when method == 'POST':
        return _json(request, 201, {'id': _nextId++});
      case ['pulls', final number, 'merge'] when method == 'PUT':
        final pr = _pull(owner, repo, number);
        if (pr == null) return _json(request, 404, {'message': 'Not Found'});
        return _merge(request, pr, body!);
      case ['git', 'ref', 'heads', ...final ref]:
        final sha = await _revParse(owner, repo, ref.join('/'));
        if (sha == null) return _json(request, 404, {'message': 'Not Found'});
        return _json(request, 200, {
          'object': {'sha': sha},
        });
      case ['git', 'trees', final ref]:
        final listed = await _gitIn(owner, repo, [
          'ls-tree',
          '-r',
          '--name-only',
          ref == 'HEAD' ? 'main' : ref,
        ]);
        return _json(request, 200, {
          'tree': [
            for (final p in const LineSplitter().convert(listed))
              {'path': p, 'type': 'blob'},
          ],
        });
      case ['contents', ...final filePath]:
        final ref = request.uri.queryParameters['ref'] ?? 'main';
        final content = await fileOn(owner, repo, ref, filePath.join('/'));
        if (content == null) {
          return _json(request, 404, {'message': 'Not Found'});
        }
        request.response.headers.contentType = ContentType.text;
        request.response.write(content);
        return;
      case ['actions', 'runs']:
        return _json(request, 200, {'total_count': 0, 'workflow_runs': []});
      default:
        return _json(request, 404, {'message': 'Not Found: $path'});
    }
  }

  FakePullRequest? _pull(String owner, String repo, String number) {
    for (final pr in _pulls) {
      if (pr.owner == owner && pr.repo == repo && '${pr.number}' == number) {
        return pr;
      }
    }
    return null;
  }

  Future<Map<String, Object?>> _prJson(FakePullRequest pr) async {
    final headSha = await _revParse(pr.owner, pr.repo, pr.head);
    final conflicts = pr.merged || pr.closed
        ? false
        : !(await _mergesCleanly(pr));
    return {
      'number': pr.number,
      'html_url': '$url/${pr.owner}/${pr.repo}/pull/${pr.number}',
      'title': pr.title,
      'body': pr.body,
      'state': pr.merged || pr.closed ? 'closed' : 'open',
      'merged': pr.merged,
      'mergeable': !conflicts,
      'mergeable_state': conflicts ? 'dirty' : 'clean',
      'head': {'ref': pr.head, 'sha': headSha},
      'base': {'ref': pr.base},
    };
  }

  Future<bool> _mergesCleanly(FakePullRequest pr) async {
    final result = await Process.run('git', [
      'merge-tree',
      '--write-tree',
      pr.base,
      pr.head,
    ], workingDirectory: _repoDir(pr.owner, pr.repo).path);
    return result.exitCode == 0;
  }

  Future<List<Map<String, Object?>>> _files(FakePullRequest pr) async {
    final range = '${pr.base}...${pr.head}';
    final numstat = await _gitIn(pr.owner, pr.repo, [
      'diff',
      '--numstat',
      range,
    ]);
    final statuses = {
      for (final line in const LineSplitter().convert(
        await _gitIn(pr.owner, pr.repo, ['diff', '--name-status', range]),
      ))
        line.split('\t').last: line.split('\t').first,
    };
    final files = <Map<String, Object?>>[];
    for (final line in const LineSplitter().convert(numstat)) {
      final [added, deleted, path] = line.split('\t');
      final diff = await _gitIn(pr.owner, pr.repo, ['diff', range, '--', path]);
      final hunk = diff.indexOf('@@');
      files.add({
        'filename': path,
        'status': switch (statuses[path]) {
          'A' => 'added',
          'D' => 'removed',
          _ => 'modified',
        },
        'additions': int.tryParse(added) ?? 0,
        'deletions': int.tryParse(deleted) ?? 0,
        'patch': hunk < 0 ? null : diff.substring(hunk).trimRight(),
        'contents_url':
            '$url/api/v3/repos/${pr.owner}/${pr.repo}/contents/$path'
            '?ref=${pr.head}',
      });
    }
    return files;
  }

  /// Squashes the PR's branch onto its base, like GitHub's squash merge.
  Future<void> _merge(
    HttpRequest request,
    FakePullRequest pr,
    Map<String, dynamic> body,
  ) async {
    if (pr.merged || pr.closed) {
      return _json(request, 405, {'message': 'Pull Request is not mergeable'});
    }
    final expected = body['sha'] as String?;
    if (expected != null &&
        expected != await _revParse(pr.owner, pr.repo, pr.head)) {
      return _json(request, 409, {'message': 'Head branch was modified'});
    }
    if (!await _mergesCleanly(pr)) {
      return _json(request, 405, {'message': 'Pull Request is not mergeable'});
    }
    final bare = _repoDir(pr.owner, pr.repo).path;
    final work = await Directory.systemTemp.createTemp('fake-github-merge-');
    try {
      await _git(['clone', '-q', '-b', pr.base, bare, work.path]);
      await _git(['fetch', '-q', 'origin', pr.head], work.path);
      await _git(['merge', '--squash', 'FETCH_HEAD'], work.path);
      await _commit(
        work.path,
        (body['commit_title'] as String?) ?? '${pr.title} (#${pr.number})',
      );
      await _git(['push', '-q', 'origin', pr.base], work.path);
    } finally {
      await work.delete(recursive: true);
    }
    pr.merged = true;
    return _json(request, 200, {'merged': true});
  }

  // ------------------------------------------------------------- GraphQL

  /// Review threads of a PR (one per inline comment) and resolving them.
  Future<void> _graphql(HttpRequest request) async {
    final body = await _readJson(request);
    final query = body!['query'] as String;
    final variables = (body['variables'] as Map?) ?? const {};
    if (query.contains('resolveReviewThread')) {
      final id = variables['id'] as String;
      for (final c in _comments) {
        if ('thread-${c.id}' == id) c.resolved = true;
      }
      return _json(request, 200, {
        'data': {
          'resolveReviewThread': {
            'thread': {'isResolved': true},
          },
        },
      });
    }
    final number = variables['number'];
    return _json(request, 200, {
      'data': {
        'repository': {
          'pullRequest': {
            'reviewThreads': {
              'nodes': [
                for (final c in _comments)
                  if (c.prNumber == number)
                    {
                      'id': 'thread-${c.id}',
                      'isResolved': c.resolved,
                      'comments': {
                        'nodes': [
                          {'databaseId': c.id},
                        ],
                      },
                    },
              ],
            },
          },
        },
      },
    });
  }

  // ------------------------------------------------------------- helpers

  Future<Map<String, dynamic>?> _readJson(HttpRequest request) async {
    final text = await utf8.decoder.bind(request).join();
    if (text.trim().isEmpty) return {};
    return jsonDecode(text) as Map<String, dynamic>;
  }

  Future<void> _json(HttpRequest request, int status, Object body) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
  }

  Future<String?> _revParse(String owner, String repo, String ref) async {
    final result = await Process.run('git', [
      'rev-parse',
      '--verify',
      '--quiet',
      ref,
    ], workingDirectory: _repoDir(owner, repo).path);
    return result.exitCode == 0 ? (result.stdout as String).trim() : null;
  }

  Future<String> _gitIn(String owner, String repo, List<String> args) =>
      _git(args, _repoDir(owner, repo).path);

  static Future<void> _commit(String dir, String message) => _git([
    '-c',
    'user.name=Fake GitHub',
    '-c',
    'user.email=fake@github.invalid',
    'commit',
    '-q',
    '-m',
    message,
  ], dir);

  static Future<String> _git(List<String> args, [String? dir]) async {
    final result = await Process.run('git', args, workingDirectory: dir);
    if (result.exitCode != 0) {
      throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
    }
    return result.stdout as String;
  }
}
