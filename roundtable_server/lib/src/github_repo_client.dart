import 'dart:convert';

import 'package:http/http.dart' as http;

import 'generated/protocol.dart';

/// Thrown when the GitHub REST API responds with a non-2xx status.
class GitHubApiException implements Exception {
  GitHubApiException(
    this.message, {
    required this.statusCode,
    required this.body,
  });

  final String message;
  final int statusCode;
  final String body;

  @override
  String toString() => '$message (HTTP $statusCode): $body';
}

/// Fetches a task's changed files and file contents from the GitHub REST API
/// on the panel's behalf (design doc §6.7) — `repoAccessToken` never reaches
/// the panel, only the already-parsed result does.
class GitHubRepoClient {
  GitHubRepoClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

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
      throw GitHubApiException(
        'Failed to fetch changed files for $owner/$repo#$number',
        statusCode: response.statusCode,
        body: response.body,
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
      throw GitHubApiException(
        'Failed to fetch file content from $contentsUrl',
        statusCode: response.statusCode,
        body: response.body,
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
      throw GitHubApiException(
        'Failed to create a review on $owner/$repo#$number',
        statusCode: response.statusCode,
        body: response.body,
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
    } on GitHubApiException {
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
      throw GitHubApiException(
        'Failed to resolve comment $githubCommentId on $owner/$repo#$number',
        statusCode: reply.statusCode,
        body: reply.body,
      );
    }
  }

  /// Squash-merges the pull request at [prUrl]. Throws a
  /// [GitHubApiException] when GitHub refuses (conflicts, failing required
  /// checks, head changed under us, ...).
  Future<void> mergePullRequest({
    required String prUrl,
    required String token,
    String? commitTitle,
  }) async {
    final (:owner, :repo, :number) = parsePrUrl(prUrl);
    final response = await _http.put(
      Uri.https('api.github.com', '/repos/$owner/$repo/pulls/$number/merge'),
      headers: _headers(token),
      body: jsonEncode({
        'merge_method': 'squash',
        'commit_title': ?commitTitle,
      }),
    );
    if (response.statusCode != 200) {
      var reason = response.body;
      try {
        reason =
            (jsonDecode(response.body) as Map<String, dynamic>)['message']
                as String;
      } catch (_) {}
      throw GitHubApiException(
        'GitHub refused to merge $owner/$repo#$number: $reason',
        statusCode: response.statusCode,
        body: response.body,
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
        throw GitHubApiException(
          'Failed to fetch $owner/$repo#$number',
          statusCode: response.statusCode,
          body: response.body,
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
      throw GitHubApiException(
        'GitHub GraphQL request failed',
        statusCode: response.statusCode,
        body: response.body,
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

/// Shared instance used by the endpoints. Tests replace it with one backed
/// by a `MockClient` to avoid hitting GitHub.
GitHubRepoClient gitHubRepoClient = GitHubRepoClient();
