import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'generated/protocol.dart';

/// Fetches a task's changed files and file contents from the GitHub REST API
/// on the panel's behalf (docs/FLOWS.md §4) — `repoAccessToken` never reaches
/// the panel, only the already-parsed result does.
class GitHubRepoClient {
  GitHubRepoClient({http.Client? httpClient, Duration timeout = _timeout})
    : _http = _TimeoutClient(httpClient ?? http.Client(), timeout);

  static const _timeout = Duration(seconds: 30);

  /// Pages read at most per Actions listing (100 items each).
  static const _maxPages = 10;
  static const _etagCacheLimit = 1000;

  final http.Client _http;

  /// The last 200 response (ETag and body) of each URL the CI checks poll,
  /// so the next request can be conditional: a `304 Not Modified` doesn't
  /// count against the token's rate limit.
  final _etagCache = <Uri, ({String etag, String body})>{};

  /// Fetches the list of changed files for the pull request at [prUrl]
  /// (`https://github.com/{owner}/{repo}/pull/{number}`), authenticating
  /// with [token].
  Future<List<DiffFile>> getChangedFiles({
    required String prUrl,
    required String token,
  }) async {
    final (:owner, :repo, :number) = parsePrUrl(prUrl);

    await _waitForPrToCatchUp(owner, repo, number, token);

    final response = await _http.get(
      Uri.https('api.github.com', '/repos/$owner/$repo/pulls/$number/files', {
        'per_page': '100',
      }),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw GitHubException(
        message: 'Failed to fetch changed files for $owner/$repo#$number',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(
          (file) => DiffFile(
            filename: file['filename'] as String,
            status: file['status'] as String,
            additions: file['additions'] as int,
            deletions: file['deletions'] as int,
            patch: file['patch'] as String?,
            contentsUrl: file['contents_url'] as String,
          ),
        )
        .toList();
  }

  /// Fetches the raw content of the file at [contentsUrl], authenticating
  /// with [token]. [contentsUrl] must point at `api.github.com` under
  /// `/repos/$owner/$repo/...` — it's a call parameter supplied by the panel,
  /// so this guard is required to make sure [token] is never sent to a
  /// client-influenced host.
  Future<String> getFileContent({
    required String contentsUrl,
    required String token,
    required String owner,
    required String repo,
  }) async {
    final uri = Uri.tryParse(contentsUrl);
    final expectedPathPrefix = '/repos/$owner/$repo/';
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'api.github.com' ||
        !uri.path.startsWith(expectedPathPrefix)) {
      throw ArgumentError.value(
        contentsUrl,
        'contentsUrl',
        'must be an https://api.github.com$expectedPathPrefix... URL',
      );
    }

    final response = await _http.get(
      uri,
      headers: {..._headers(token), 'Accept': 'application/vnd.github.raw'},
    );
    if (response.statusCode != 200) {
      throw GitHubException(
        message: 'Failed to fetch file content from $contentsUrl',
        statusCode: response.statusCode,
      );
    }

    return response.body;
  }

  /// Posts [comments] as one `COMMENT` review on the pull request at
  /// [prUrl], with [summary] as its body. GitHub rejects the whole review if
  /// any inline comment targets a line outside the diff, so only comments on
  /// a line [getChangedFiles] reports as commentable go inline — the rest are
  /// folded into the review body. Returns the review id and, per index into
  /// [comments], the inline comment id GitHub assigned (absent if folded).
  Future<({int reviewId, Map<int, int> commentIds})> createReview({
    required String prUrl,
    required String token,
    required String summary,
    required List<ReviewComment> comments,
  }) async {
    final (:owner, :repo, :number) = parsePrUrl(prUrl);
    final files = await getChangedFiles(prUrl: prUrl, token: token);
    final commentable = {
      for (final file in files) file.filename: commentableLines(file.patch),
    };

    final inline = <int>[];
    final folded = StringBuffer();
    for (var i = 0; i < comments.length; i++) {
      final comment = comments[i];
      final line = comment.line;
      if (line != null &&
          (commentable[comment.path]?.contains(line) ?? false)) {
        inline.add(i);
      } else {
        folded.write(
          '\n\n**${comment.path}${line == null ? '' : ':$line'}** '
          '(${comment.severity.name}): ${comment.body}',
        );
      }
    }

    final response = await _http.post(
      Uri.https('api.github.com', '/repos/$owner/$repo/pulls/$number/reviews'),
      headers: _headers(token),
      body: jsonEncode({
        'event': 'COMMENT',
        'body': '$summary$folded',
        'comments': [
          for (final i in inline)
            {
              'path': comments[i].path,
              'line': comments[i].line,
              'side': 'RIGHT',
              'body': '**${comments[i].severity.name}**: ${comments[i].body}',
            },
        ],
      }),
    );
    if (response.statusCode != 200) {
      throw GitHubException(
        message: 'Failed to create a review on $owner/$repo#$number',
        statusCode: response.statusCode,
      );
    }
    final reviewId =
        (jsonDecode(response.body) as Map<String, dynamic>)['id'] as int;

    // The create response doesn't carry the comments; they come back in the
    // order they were sent.
    final commentsResponse = await _http.get(
      Uri.https(
        'api.github.com',
        '/repos/$owner/$repo/pulls/$number/reviews/$reviewId/comments',
        {'per_page': '100'},
      ),
      headers: _headers(token),
    );
    final commentIds = <int, int>{};
    if (commentsResponse.statusCode == 200) {
      final created = (jsonDecode(commentsResponse.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (var j = 0; j < created.length && j < inline.length; j++) {
        commentIds[inline[j]] = created[j]['id'] as int;
      }
    }
    return (reviewId: reviewId, commentIds: commentIds);
  }

  /// Resolves the review thread containing the inline comment
  /// [githubCommentId] on the pull request at [prUrl]. Threads can only be
  /// resolved through the GraphQL API; if that fails (e.g. a token without
  /// GraphQL access), replies to the comment instead.
  Future<void> resolveThread({
    required String prUrl,
    required String token,
    required int githubCommentId,
  }) async {
    final (:owner, :repo, :number) = parsePrUrl(prUrl);
    try {
      final threads = await _graphql(
        token,
        r'''
        query($owner: String!, $repo: String!, $number: Int!) {
          repository(owner: $owner, name: $repo) {
            pullRequest(number: $number) {
              reviewThreads(first: 100) {
                nodes { id isResolved comments(first: 1) { nodes { databaseId } } }
              }
            }
          }
        }
      ''',
        {'owner': owner, 'repo': repo, 'number': int.parse(number)},
      );
      final nodes =
          (((threads['repository'] as Map<String, dynamic>)['pullRequest']
                      as Map<String, dynamic>)['reviewThreads']
                  as Map<String, dynamic>)['nodes']
              as List<dynamic>;
      for (final node in nodes.cast<Map<String, dynamic>>()) {
        final first =
            ((node['comments'] as Map<String, dynamic>)['nodes']
                    as List<dynamic>)
                .cast<Map<String, dynamic>>();
        if (first.isEmpty || first.first['databaseId'] != githubCommentId) {
          continue;
        }
        if (node['isResolved'] == true) return;
        await _graphql(
          token,
          r'''
          mutation($id: ID!) {
            resolveReviewThread(input: {threadId: $id}) { thread { id } }
          }
        ''',
          {'id': node['id']},
        );
        return;
      }
    } on GitHubException {
      // Fall through to the reply below.
    }

    final reply = await _http.post(
      Uri.https(
        'api.github.com',
        '/repos/$owner/$repo/pulls/$number/comments/$githubCommentId/replies',
      ),
      headers: _headers(token),
      body: jsonEncode({'body': 'Resolved in Roundtable.'}),
    );
    if (reply.statusCode != 201) {
      throw GitHubException(
        message:
            'Failed to resolve comment $githubCommentId on $owner/$repo#$number',
        statusCode: reply.statusCode,
      );
    }
  }

  /// Squash-merges the pull request at [prUrl]. With [sha], GitHub only
  /// merges if that's still the PR's head — so a commit pushed after the
  /// checks were read can't slip in. Throws a [GitHubException] when GitHub
  /// refuses (conflicts, failing required checks, head changed under us,
  /// ...).
  Future<void> mergePullRequest({
    required String prUrl,
    required String token,
    String? commitTitle,
    String? sha,
  }) async {
    final (:owner, :repo, :number) = parsePrUrl(prUrl);
    final response = await _http.put(
      Uri.https('api.github.com', '/repos/$owner/$repo/pulls/$number/merge'),
      headers: _headers(token),
      body: jsonEncode({
        'merge_method': 'squash',
        'commit_title': ?commitTitle,
        'sha': ?sha,
      }),
    );
    if (response.statusCode != 200) {
      var reason = response.body;
      try {
        reason =
            (jsonDecode(response.body) as Map<String, dynamic>)['message']
                as String;
      } catch (_) {}
      throw GitHubException(
        message: 'GitHub refused to merge $owner/$repo#$number: $reason',
        statusCode: response.statusCode,
      );
    }
  }

  /// Reads whether the pull request at [prUrl] conflicts with its base
  /// branch. GitHub computes `mergeable` lazily (null until ready), so this
  /// polls briefly; `hasConflicts` stays null if it's still unknown.
  Future<({bool? hasConflicts, String baseRef})> getMergeability({
    required String prUrl,
    required String token,
    int attempts = 5,
  }) async {
    final (:owner, :repo, :number) = parsePrUrl(prUrl);
    String? baseRef;
    for (var i = 0; i < attempts; i++) {
      final response = await _http.get(
        Uri.https('api.github.com', '/repos/$owner/$repo/pulls/$number'),
        headers: _headers(token),
      );
      if (response.statusCode != 200) {
        throw GitHubException(
          message: 'Failed to fetch $owner/$repo#$number',
          statusCode: response.statusCode,
        );
      }
      final pr = jsonDecode(response.body) as Map<String, dynamic>;
      baseRef = (pr['base'] as Map<String, dynamic>)['ref'] as String;
      final mergeable = pr['mergeable'] as bool?;
      if (mergeable != null) {
        return (
          hasConflicts: !mergeable && pr['mergeable_state'] == 'dirty',
          baseRef: baseRef,
        );
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return (hasConflicts: null, baseRef: baseRef!);
  }

  /// Reads the head commit and state (`open`/`closed`) of the pull request
  /// at [prUrl].
  Future<({String sha, bool open})> getPrHead({
    required String prUrl,
    required String token,
  }) async {
    final (:owner, :repo, :number) = parsePrUrl(prUrl);
    final response = await _conditionalGet(
      Uri.https('api.github.com', '/repos/$owner/$repo/pulls/$number'),
      token,
    );
    if (response.statusCode != 200) {
      throw GitHubException(
        message: 'Failed to fetch $owner/$repo#$number',
        statusCode: response.statusCode,
      );
    }
    final pr = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      sha: (pr['head'] as Map<String, dynamic>)['sha'] as String,
      open: pr['state'] == 'open',
    );
  }

  /// Lists the GitHub Actions workflow runs for commit [headSha] of the
  /// repository [owner]/[repo] (any event — `push` and `pull_request` alike).
  Future<List<WorkflowRunInfo>> listWorkflowRuns({
    required String owner,
    required String repo,
    required String headSha,
    required String token,
  }) async {
    final runs = await _listAllPages(
      (page) =>
          Uri.https('api.github.com', '/repos/$owner/$repo/actions/runs', {
            'head_sha': headSha,
            'per_page': '100',
            'page': '$page',
          }),
      token,
      itemsKey: 'workflow_runs',
      errorMessage: 'Failed to list workflow runs for $owner/$repo@$headSha',
    );
    return [
      for (final run in runs)
        if (run['head_sha'] == headSha)
          WorkflowRunInfo(
            id: run['id'] as int,
            name: (run['name'] as String?) ?? 'Workflow',
            status: run['status'] as String,
            conclusion: run['conclusion'] as String?,
            runAttempt: (run['run_attempt'] as int?) ?? 1,
          ),
    ];
  }

  /// Lists the jobs of the latest attempt of workflow run [runId] — all of
  /// them, a big matrix can span several pages.
  Future<List<WorkflowJobInfo>> listRunJobs({
    required String owner,
    required String repo,
    required int runId,
    required String token,
  }) async {
    final jobs = await _listAllPages(
      (page) => Uri.https(
        'api.github.com',
        '/repos/$owner/$repo/actions/runs/$runId/jobs',
        {'filter': 'latest', 'per_page': '100', 'page': '$page'},
      ),
      token,
      itemsKey: 'jobs',
      errorMessage:
          'Failed to list the jobs of workflow run $runId in $owner/$repo',
    );
    return [
      for (final job in jobs)
        WorkflowJobInfo(
          id: job['id'] as int,
          name: job['name'] as String,
          status: job['status'] as String,
          conclusion: job['conclusion'] as String?,
          htmlUrl: job['html_url'] as String?,
          startedAt: DateTime.tryParse((job['started_at'] as String?) ?? ''),
          completedAt: DateTime.tryParse(
            (job['completed_at'] as String?) ?? '',
          ),
          failedStep: _firstFailedStep(job['steps']),
        ),
    ];
  }

  /// Reads every page of an Actions listing (`{total_count, <itemsKey>: [...]}`)
  /// until `total_count` items arrived or a page comes back short.
  Future<List<Map<String, dynamic>>> _listAllPages(
    Uri Function(int page) pageUri,
    String token, {
    required String itemsKey,
    required String errorMessage,
  }) async {
    final items = <Map<String, dynamic>>[];
    for (var page = 1; page <= _maxPages; page++) {
      final response = await _conditionalGet(pageUri(page), token);
      if (response.statusCode != 200) {
        throw GitHubException(
          message: _actionsErrorMessage(errorMessage, response.statusCode),
          statusCode: response.statusCode,
        );
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final pageItems = (decoded[itemsKey] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      items.addAll(pageItems);
      final total = decoded['total_count'] as int?;
      if (pageItems.length < 100 || (total != null && items.length >= total)) {
        break;
      }
    }
    return items;
  }

  /// GETs [uri], conditionally when an earlier response's ETag is cached —
  /// a 304 is answered from the cache as a 200.
  Future<({int statusCode, String body})> _conditionalGet(
    Uri uri,
    String token,
  ) async {
    final cached = _etagCache[uri];
    final response = await _http.get(
      uri,
      headers: {
        ..._headers(token),
        if (cached != null) 'If-None-Match': cached.etag,
      },
    );
    if (response.statusCode == 304 && cached != null) {
      return (statusCode: 200, body: cached.body);
    }
    final etag = response.headers['etag'];
    _etagCache.remove(uri);
    if (response.statusCode == 200 && etag != null) {
      if (_etagCache.length >= _etagCacheLimit) {
        _etagCache.remove(_etagCache.keys.first);
      }
      _etagCache[uri] = (etag: etag, body: response.body);
    }
    return (statusCode: response.statusCode, body: response.body);
  }

  /// Fetches the log of Actions job [jobId] and returns the part worth
  /// showing an agent: up to [maxLines] lines ending a little after the last
  /// `##[error]` line (or the log's tail when there's none), without
  /// GitHub's timestamps.
  Future<String> getJobLogTail({
    required String owner,
    required String repo,
    required int jobId,
    required String token,
    int maxLines = 150,
  }) async {
    // GitHub answers with a redirect to a short-lived blob URL. Follow it by
    // hand, so the token is never sent to the blob host.
    final request =
        http.Request(
            'GET',
            Uri.https(
              'api.github.com',
              '/repos/$owner/$repo/actions/jobs/$jobId/logs',
            ),
          )
          ..headers.addAll(_headers(token))
          ..followRedirects = false;
    var response = await http.Response.fromStream(await _http.send(request));
    final location = response.headers['location'];
    if (response.statusCode >= 300 &&
        response.statusCode < 400 &&
        location != null) {
      response = await _http.get(
        Uri.parse(location),
        headers: {'User-Agent': 'roundtable-server'},
      );
    }
    if (response.statusCode != 200) {
      throw GitHubException(
        message: _actionsErrorMessage(
          'Failed to fetch the log of job $jobId in $owner/$repo',
          response.statusCode,
        ),
        statusCode: response.statusCode,
      );
    }
    return extractLogTail(response.body, maxLines: maxLines);
  }

  /// A GitHub error message, pointing at the token's missing "Actions: read"
  /// permission when GitHub denies access.
  static String _actionsErrorMessage(String message, int statusCode) =>
      statusCode == 403 || statusCode == 404
      ? '$message — make sure the project\'s token has the '
            '"Actions: read" permission'
      : message;

  static String? _firstFailedStep(Object? steps) {
    if (steps is! List) return null;
    for (final step in steps.cast<Map<String, dynamic>>()) {
      final conclusion = step['conclusion'];
      if (conclusion == 'failure' || conclusion == 'timed_out') {
        return step['name'] as String?;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _graphql(
    String token,
    String query,
    Map<String, dynamic> variables,
  ) async {
    final response = await _http.post(
      Uri.https('api.github.com', '/graphql'),
      headers: _headers(token),
      body: jsonEncode({'query': query, 'variables': variables}),
    );
    final decoded = response.statusCode == 200
        ? jsonDecode(response.body) as Map<String, dynamic>
        : null;
    if (decoded == null || decoded['errors'] != null) {
      throw GitHubException(
        message: 'GitHub GraphQL request failed',
        statusCode: response.statusCode,
      );
    }
    return decoded['data'] as Map<String, dynamic>;
  }

  /// GitHub updates a PR's head (and its `/files` diff) asynchronously after
  /// a push, so right after the daemon pushes a feedback iteration the diff
  /// can still be the previous one. Waits (briefly) until the PR head matches
  /// the branch tip. Best effort: gives up silently after [attempts].
  Future<void> _waitForPrToCatchUp(
    String owner,
    String repo,
    String number,
    String token, {
    int attempts = 10,
  }) async {
    for (var i = 0; i < attempts; i++) {
      final prResponse = await _http.get(
        Uri.https('api.github.com', '/repos/$owner/$repo/pulls/$number'),
        headers: _headers(token),
      );
      if (prResponse.statusCode != 200) return;
      final head =
          (jsonDecode(prResponse.body) as Map<String, dynamic>)['head']
              as Map<String, dynamic>;
      final ref = head['ref'] as String;
      final prSha = head['sha'] as String;

      final refResponse = await _http.get(
        Uri.https('api.github.com', '/repos/$owner/$repo/git/ref/heads/$ref'),
        headers: _headers(token),
      );
      if (refResponse.statusCode != 200) return;
      final branchSha =
          ((jsonDecode(refResponse.body) as Map<String, dynamic>)['object']
                  as Map<String, dynamic>)['sha']
              as String;
      if (branchSha == prSha) return;

      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'roundtable-server',
  };

  /// Parses [prUrl] (`https://github.com/{owner}/{repo}/pull/{number}`) into
  /// its `owner`, `repo` and `number` parts.
  ({String owner, String repo, String number}) parsePrUrl(String prUrl) {
    final uri = Uri.tryParse(prUrl);
    if (uri == null || uri.scheme != 'https' || uri.host != 'github.com') {
      throw ArgumentError.value(
        prUrl,
        'prUrl',
        'must be an https://github.com/... URL',
      );
    }

    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.length < 4 || segments[2] != 'pull') {
      throw ArgumentError.value(
        prUrl,
        'prUrl',
        'must be an https://github.com/{owner}/{repo}/pull/{number} URL',
      );
    }

    return (owner: segments[0], repo: segments[1], number: segments[3]);
  }
}

/// The new-file (`RIGHT` side) line numbers that a unified diff [patch]
/// shows — added and context lines — which are the only lines GitHub
/// accepts an inline review comment on. Empty for a binary file.
Set<int> commentableLines(String? patch) {
  final lines = <int>{};
  if (patch == null) return lines;
  final hunkHeader = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@');
  int? next;
  for (final line in patch.split('\n')) {
    final header = hunkHeader.firstMatch(line);
    if (header != null) {
      next = int.parse(header.group(1)!);
      continue;
    }
    if (next == null || line.startsWith('-') || line.startsWith('\\')) {
      continue;
    }
    lines.add(next++);
  }
  return lines;
}

/// One GitHub Actions workflow run, as [GitHubRepoClient.listWorkflowRuns]
/// returns it.
class WorkflowRunInfo {
  const WorkflowRunInfo({
    required this.id,
    required this.name,
    required this.status,
    required this.conclusion,
    required this.runAttempt,
  });

  final int id;
  final String name;
  final String status;
  final String? conclusion;
  final int runAttempt;
}

/// One job of a workflow run, as [GitHubRepoClient.listRunJobs] returns it.
class WorkflowJobInfo {
  const WorkflowJobInfo({
    required this.id,
    required this.name,
    required this.status,
    required this.conclusion,
    required this.htmlUrl,
    required this.startedAt,
    required this.completedAt,
    required this.failedStep,
  });

  final int id;
  final String name;
  final String status;
  final String? conclusion;
  final String? htmlUrl;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? failedStep;
}

final _logTimestamp = RegExp(r'^\d{4}-\d\d-\d\dT[\d:.]+Z ');

/// The part of a GitHub Actions job [log] that explains a failure: up to
/// [maxLines] lines ending a few lines after the last `##[error]` line, or
/// the log's last [maxLines] lines when there's no error marker. Strips the
/// timestamp GitHub prefixes every line with.
String extractLogTail(String log, {int maxLines = 150}) {
  final lines = [
    for (final line in const LineSplitter().convert(log))
      line.replaceFirst(_logTimestamp, ''),
  ];
  final lastError = lines.lastIndexWhere((l) => l.contains('##[error]'));
  final end = lastError == -1
      ? lines.length
      : (lastError + 5).clamp(0, lines.length);
  final start = (end - maxLines).clamp(0, end);
  return lines.sublist(start, end).join('\n');
}

/// Shared instance used by the endpoints. Tests replace it with one backed
/// by a `MockClient` to avoid hitting GitHub.
GitHubRepoClient gitHubRepoClient = GitHubRepoClient();

/// Fails any GitHub request that takes longer than [_timeout] with a
/// [GitHubException], so a hung API call can't hang the panel request
/// waiting on it.
class _TimeoutClient extends http.BaseClient {
  _TimeoutClient(this._inner, this._timeout);

  final http.Client _inner;
  final Duration _timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _inner
      .send(request)
      .timeout(
        _timeout,
        onTimeout: () => throw GitHubException(
          message:
              'GitHub did not respond within ${_timeout.inSeconds}s '
              '(${request.method} ${request.url.path})',
          statusCode: 504,
        ),
      );

  @override
  void close() => _inner.close();
}
