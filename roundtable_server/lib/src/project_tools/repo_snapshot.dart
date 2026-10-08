/// Directories that hold dependencies or build output, never the project's
/// own manifests.
const _ignoredDirs = {
  'node_modules',
  '.dart_tool',
  'build',
  'vendor',
  '.git',
  'dist',
  'target',
  '.venv',
  'venv',
};

/// The per-platform folders `flutter create` generates next to pubspec.yaml.
/// They belong to Flutter, not to a separate Java/Node toolchain.
const _flutterPlatformDirs = {
  'android',
  'ios',
  'macos',
  'linux',
  'windows',
  'web',
};

/// Manifests deeper than this are examples or fixtures, not the project.
const _maxDepth = 3;

/// The files of a repo that say something about its toolchains, with a way
/// to read them. Built once and handed to every [ToolDetector].
class RepoSnapshot {
  RepoSnapshot._(this.files, this._read)
    : names = {for (final p in files) basename(p)},
      rootFiles = files.where((p) => !p.contains('/')).toSet();

  /// Keeps the project's own files from [paths]: no dependency or build
  /// dirs, nothing too deep, no Flutter platform folders.
  factory RepoSnapshot.from({
    required List<String> paths,
    required Future<String?> Function(String path) read,
  }) {
    final flutterApps = {
      for (final p in paths)
        if (basename(p) == 'pubspec.yaml')
          p.substring(0, p.length - 'pubspec.yaml'.length),
    };
    bool inFlutterPlatformDir(String path) => flutterApps.any(
      (app) =>
          path.startsWith(app) &&
          _flutterPlatformDirs.contains(
            path.substring(app.length).split('/').first,
          ),
    );
    return RepoSnapshot._(
      paths
          .where((p) => _isProjectFile(p) && !inFlutterPlatformDir(p))
          .toList(),
      read,
    );
  }

  final List<String> files;

  /// Basenames of [files], at any depth.
  final Set<String> names;

  /// [files] at the repo root.
  final Set<String> rootFiles;

  final Future<String?> Function(String path) _read;

  bool has(String name) => names.contains(name);

  bool hasAny(Set<String> manifests) =>
      names.intersection(manifests).isNotEmpty;

  bool hasAtRoot(String name) => rootFiles.contains(name);

  Iterable<String> filesNamed(String name) =>
      files.where((p) => basename(p) == name);

  /// The file's content, or '' when it is missing.
  Future<String> read(String path) async => await _read(path) ?? '';

  /// The version [parse] finds in the root [file], or `latest` when the file
  /// is missing, empty or holds no version.
  Future<String> versionFrom(String file, String Function(String) parse) async {
    if (!hasAtRoot(file)) return 'latest';
    final content = (await read(file)).trim();
    final version = content.isEmpty ? '' : parse(content);
    return version.isEmpty ? 'latest' : version;
  }
}

String basename(String path) => path.substring(path.lastIndexOf('/') + 1);

bool _isProjectFile(String path) {
  final segments = path.split('/');
  if (segments.length > _maxDepth + 1) return false;
  return !segments
      .take(segments.length - 1)
      .any((dir) => _ignoredDirs.contains(dir));
}
