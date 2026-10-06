import 'dart:io';

/// Where GitHub lives: github.com by default, or a GitHub Enterprise-style
/// host set by `ROUNDTABLE_GITHUB_URL` (repos at `<url>/owner/repo`, the
/// REST API at `<url>/api/v3`, GraphQL at `<url>/api/graphql`). The E2E
/// tests point it at a fake GitHub (docs/DEVELOPMENT.md "E2E tests").
class GitHubHost {
  GitHubHost._({required this.web, required this.api, required this.graphql});

  /// github.com.
  factory GitHubHost.cloud() => GitHubHost._(
    web: Uri.parse('https://github.com'),
    api: Uri.parse('https://api.github.com'),
    graphql: Uri.parse('https://api.github.com/graphql'),
  );

  /// A GitHub Enterprise-style host at [baseUrl].
  factory GitHubHost.enterprise(String baseUrl) {
    final base = Uri.parse(baseUrl.replaceFirst(RegExp(r'/+$'), ''));
    return GitHubHost._(
      web: base,
      api: base.replace(path: '${base.path}/api/v3'),
      graphql: base.replace(path: '${base.path}/api/graphql'),
    );
  }

  /// [GitHubHost.enterprise] when `ROUNDTABLE_GITHUB_URL` is set, else
  /// [GitHubHost.cloud].
  factory GitHubHost.fromEnvironment([Map<String, String>? environment]) {
    final url = (environment ?? Platform.environment)['ROUNDTABLE_GITHUB_URL'];
    return url == null || url.trim().isEmpty
        ? GitHubHost.cloud()
        : GitHubHost.enterprise(url.trim());
  }

  /// Where repos and pull requests live (`<web>/owner/repo/pull/1`).
  final Uri web;
  final Uri api;
  final Uri graphql;

  /// A REST API URL: [path] starts with `/` (`/repos/o/r/pulls`).
  Uri apiUri(String path, [Map<String, String>? query]) => api.replace(
    path: '${api.path}$path',
    queryParameters: query == null || query.isEmpty ? null : query,
  );

  /// Whether [uri] is on the repos host ([web]).
  bool isWebUri(Uri uri) => _sameOrigin(uri, web);

  /// The path segments of [uri] below [web] (`[owner, repo, pull, 1]`),
  /// or null when [uri] isn't on the repos host.
  List<String>? webSegments(Uri uri) {
    if (!isWebUri(uri)) return null;
    final base = web.pathSegments.where((s) => s.isNotEmpty).toList();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < base.length) return null;
    for (var i = 0; i < base.length; i++) {
      if (segments[i] != base[i]) return null;
    }
    return segments.sublist(base.length);
  }

  /// Whether [uri] is on the REST API host, under its path ([api]).
  bool isApiUri(Uri uri) =>
      _sameOrigin(uri, api) && uri.path.startsWith(api.path);

  /// The path of an API [uri] below [api] (`/repos/o/r/...`).
  String apiPath(Uri uri) => uri.path.substring(api.path.length);

  static bool _sameOrigin(Uri a, Uri b) =>
      a.scheme == b.scheme && a.host == b.host && a.port == b.port;
}

/// The GitHub host every server-side GitHub call goes to. Replaced by tests.
GitHubHost gitHubHost = GitHubHost.fromEnvironment();
