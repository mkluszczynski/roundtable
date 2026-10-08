import '../generated/protocol.dart';
import 'repo_snapshot.dart';
import 'version_parsers.dart';

/// A config file in which the repo already says exactly which tools it
/// needs. When one is found, detection is skipped.
class ExplicitToolConfig {
  const ExplicitToolConfig(this.file, this.parse);

  final String file;
  final List<ProjectTool> Function(String content) parse;

  /// The tools listed in the root [file], or an empty list.
  Future<List<ProjectTool>> read(RepoSnapshot repo) async =>
      repo.hasAtRoot(file) ? parse(await repo.read(file)) : const [];
}

/// Guesses one ecosystem's toolchains (name → version) from a repo.
abstract interface class ToolDetector {
  Future<Map<String, String>> detect(RepoSnapshot repo);
}

/// Dart or Flutter (Flutter ships Dart, so it replaces it), plus the
/// Serverpod CLI matched to the framework version, so the generated code is
/// what the repo expects.
class DartDetector implements ToolDetector {
  const DartDetector();

  /// At most this many pubspecs are read.
  static const _maxPubspecs = 8;

  @override
  Future<Map<String, String>> detect(RepoSnapshot repo) async {
    final pubspecs = [
      for (final path in repo.filesNamed('pubspec.yaml').take(_maxPubspecs))
        await repo.read(path),
    ];
    if (pubspecs.isEmpty) return const {};
    final serverpod = pubspecs.map(serverpodVersion).nonNulls.firstOrNull;
    return {
      if (pubspecs.any(dependsOnFlutter) || repo.hasAtRoot('.fvmrc'))
        'flutter': await repo.versionFrom('.fvmrc', fvmVersion)
      else
        'dart': 'latest',
      'pub:serverpod_cli': ?serverpod,
    };
  }
}

/// Node from `.nvmrc` / `.node-version` (`lts` otherwise), and the package
/// manager from package.json's `packageManager` or a pnpm lockfile.
class NodeDetector implements ToolDetector {
  const NodeDetector();

  @override
  Future<Map<String, String>> detect(RepoSnapshot repo) async {
    if (!repo.has('package.json')) return const {};
    var node = await repo.versionFrom('.nvmrc', nodeVersion);
    if (node == 'latest') {
      node = await repo.versionFrom('.node-version', nodeVersion);
    }
    final manager = repo.hasAtRoot('package.json')
        ? packageManager(await repo.read('package.json'))
        : null;
    return {
      'node': node == 'latest' ? 'lts' : node,
      if (manager != null)
        manager.name: manager.version
      else if (repo.has('pnpm-lock.yaml'))
        'pnpm': 'latest',
    };
  }
}

/// Go at the version of the first go.mod's `go` directive.
class GoDetector implements ToolDetector {
  const GoDetector();

  @override
  Future<Map<String, String>> detect(RepoSnapshot repo) async {
    final goMod = repo.filesNamed('go.mod').firstOrNull;
    if (goMod == null) return const {};
    return {'go': goVersion(await repo.read(goMod)) ?? 'latest'};
  }
}

/// A toolchain needed whenever one of [manifests] is in the repo, pinned by
/// the first line of an optional root [versionFile].
class ManifestDetector implements ToolDetector {
  const ManifestDetector(this.tool, this.manifests, {this.versionFile});

  final String tool;
  final Set<String> manifests;
  final String? versionFile;

  @override
  Future<Map<String, String>> detect(RepoSnapshot repo) async {
    if (!repo.hasAny(manifests)) return const {};
    final file = versionFile;
    return {
      tool: file == null ? 'latest' : await repo.versionFrom(file, firstLine),
    };
  }
}
