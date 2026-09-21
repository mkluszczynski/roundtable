import 'dart:convert';

import 'package:http/http.dart' as http;

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

/// Opens a GitHub pull request for a task's pushed branch (design doc §6.1
/// step 7, §6.5), using the GitHub REST API directly rather than the `gh`
/// CLI or an octokit-style SDK — only two endpoints are needed.
class GitHubPullRequestOpener {
  GitHubPullRequestOpener({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Parses [cloneUrl] (as returned by `ProjectEndpoint.getCloneUrl`) for the
  /// embedded token and the `owner/repo`, looks up the repository's default
  /// branch, opens a PR from [branchName] onto it, and returns the PR's
  /// `html_url`.
  ///
  /// Throws [ArgumentError] if [cloneUrl] has no embedded token or isn't an
  /// `https://github.com/...` URL, or [GitHubApiException] on any non-2xx
  /// GitHub API response.
  Future<String> open({
    required String cloneUrl,
    required String branchName,
    required String title,
    String? body,
  }) async {
    final (:owner, :repo, :token) = _parseCloneUrl(cloneUrl);

    final defaultBranch = await _getDefaultBranch(
      owner: owner,
      repo: repo,
      token: token,
    );

    final response = await _http.post(
      Uri.https('api.github.com', '/repos/$owner/$repo/pulls'),
      headers: _headers(token),
      body: jsonEncode({
        'title': title,
        'head': branchName,
        'base': defaultBranch,
        if (body != null) 'body': body,
      }),
    );
    if (response.statusCode != 201) {
      throw GitHubApiException(
        'Failed to open pull request for $owner/$repo',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['html_url'] as String;
  }

  Future<String> _getDefaultBranch({
    required String owner,
    required String repo,
    required String token,
  }) async {
    final response = await _http.get(
      Uri.https('api.github.com', '/repos/$owner/$repo'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw GitHubApiException(
        'Failed to look up default branch for $owner/$repo',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['default_branch'] as String;
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'roundtable-agent-runner',
  };

  ({String owner, String repo, String token}) _parseCloneUrl(String cloneUrl) {
    final uri = Uri.tryParse(cloneUrl);
    if (uri == null || uri.scheme != 'https' || uri.host != 'github.com') {
      throw ArgumentError.value(
        cloneUrl,
        'cloneUrl',
        'must be an https://github.com/... URL',
      );
    }
    if (uri.userInfo.isEmpty || !uri.userInfo.contains(':')) {
      throw ArgumentError.value(
        cloneUrl,
        'cloneUrl',
        'has no embedded access token — cannot authenticate to the GitHub API',
      );
    }

    final token = uri.userInfo.substring(uri.userInfo.indexOf(':') + 1);
    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.length < 2) {
      throw ArgumentError.value(
        cloneUrl,
        'cloneUrl',
        'must contain an owner and a repo path segment',
      );
    }

    final owner = segments[0];
    var repo = segments[1];
    if (repo.endsWith('.git')) {
      repo = repo.substring(0, repo.length - '.git'.length);
    }

    return (owner: owner, repo: repo, token: token);
  }
}
