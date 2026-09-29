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
