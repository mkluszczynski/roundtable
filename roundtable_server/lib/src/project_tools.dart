import 'dart:convert';

import 'generated/protocol.dart';

/// A mise tool id: lowercase, optionally with a backend prefix
/// (`aqua:cli/cli`, `npm:prettier`).
final _toolName = RegExp(r'^[a-z0-9][a-z0-9._:/@-]*$');
final _toolVersion = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._+/-]*$');

/// Trims [tools] and rejects invalid names, versions and duplicates, so the
/// runner never passes junk to `mise install`. Throws [InvalidStateException].
List<ProjectTool> validateProjectTools(List<ProjectTool> tools) {
  final seen = <String>{};
  return [
    for (final tool in tools)
      () {
        final name = tool.name.trim().toLowerCase();
        final version = tool.version.trim();
        if (!_toolName.hasMatch(name) || name.length > 100) {
          throw InvalidStateException(
            message: '"${tool.name}" is not a valid tool name',
          );
        }
        if (!_toolVersion.hasMatch(version) || version.length > 50) {
          throw InvalidStateException(
            message: '"${tool.version}" is not a valid version of $name',
          );
        }
        if (!seen.add(name)) {
          throw InvalidStateException(message: '$name is listed twice');
        }
        return ProjectTool(name: name, version: version);
      }(),
  ];
}

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

/// At most this many pubspecs are read to tell Flutter from plain Dart.
const _maxPubspecs = 6;

/// Guesses the toolchains a repo needs from its file list [paths] — reading
/// a few files through [read] (null when missing) for versions. The result
/// is a suggestion the user confirms, never saved on its own.
///
/// A mise config or `.tool-versions` at the root wins: the repo already
/// says exactly what it needs.
Future<List<ProjectTool>> detectProjectTools({
  required List<String> paths,
  required Future<String?> Function(String path) read,
}) async {
  // A Flutter app's platform folders (android/build.gradle, web/…) belong
  // to Flutter, not to a separate Java/Node toolchain.
  final flutterApps = {
    for (final p in paths)
      if (p == 'pubspec.yaml' || p.endsWith('/pubspec.yaml'))
        p.substring(0, p.length - 'pubspec.yaml'.length),
  };
  bool inFlutterPlatformDir(String path) => flutterApps.any(
    (app) =>
        path.startsWith(app) &&
        _flutterPlatformDirs.contains(
          path.substring(app.length).split('/').first,
        ),
  );
  final files = paths
      .where((p) => _isProjectFile(p) && !inFlutterPlatformDir(p))
      .toList();
  final names = {for (final p in files) _basename(p)};
  final rootFiles = files.where((p) => !p.contains('/')).toSet();

  for (final config in ['.mise.toml', 'mise.toml']) {
    if (rootFiles.contains(config)) {
      final tools = _parseMiseToml(await read(config) ?? '');
      if (tools.isNotEmpty) return tools;
    }
  }
  if (rootFiles.contains('.tool-versions')) {
    final tools = _parseToolVersions(await read('.tool-versions') ?? '');
    if (tools.isNotEmpty) return tools;
  }

  final tools = <String, String>{};
  Future<String> versionFrom(String file, String Function(String) parse) async {
    if (!rootFiles.contains(file)) return 'latest';
    final content = (await read(file))?.trim() ?? '';
    final version = content.isEmpty ? '' : parse(content);
    return version.isEmpty ? 'latest' : version;
  }

  // Dart / Flutter: Flutter ships Dart, so it replaces it.
  final pubspecs = files.where((p) => _basename(p) == 'pubspec.yaml');
  if (pubspecs.isNotEmpty) {
    var flutter = false;
    for (final pubspec in pubspecs.take(_maxPubspecs)) {
      if (_dependsOnFlutter(await read(pubspec) ?? '')) {
        flutter = true;
        break;
      }
    }
    if (flutter || rootFiles.contains('.fvmrc')) {
      tools['flutter'] = await versionFrom('.fvmrc', _fvmVersion);
    } else {
      tools['dart'] = 'latest';
    }
  }

  if (names.contains('package.json')) {
    var node = await versionFrom('.nvmrc', _nodeVersion);
    if (node == 'latest') {
      node = await versionFrom('.node-version', _nodeVersion);
    }
    tools['node'] = node == 'latest' ? 'lts' : node;
    final packageManager = rootFiles.contains('package.json')
        ? _packageManager(await read('package.json') ?? '')
        : null;
    if (packageManager != null) {
      tools[packageManager.name] = packageManager.version;
    } else if (names.contains('pnpm-lock.yaml')) {
      tools['pnpm'] = 'latest';
    }
  }

  if (names.contains('go.mod')) {
    final goMod = files.firstWhere((p) => _basename(p) == 'go.mod');
    final match = RegExp(
      r'^go (\d+\.\d+(?:\.\d+)?)',
      multiLine: true,
    ).firstMatch(await read(goMod) ?? '');
    tools['go'] = match?.group(1) ?? 'latest';
  }

  if (names.intersection({
    'pyproject.toml',
    'requirements.txt',
    'setup.py',
    '.python-version',
  }).isNotEmpty) {
    tools['python'] = await versionFrom('.python-version', _firstLine);
  }

  if (names.contains('Cargo.toml')) tools['rust'] = 'latest';

  if (names.contains('Gemfile')) {
    tools['ruby'] = await versionFrom('.ruby-version', _firstLine);
  }

  if (names.intersection({
    'pom.xml',
    'build.gradle',
    'build.gradle.kts',
  }).isNotEmpty) {
    tools['java'] = await versionFrom('.java-version', _firstLine);
  }

  return [
    for (final MapEntry(:key, :value) in tools.entries)
      ProjectTool(name: key, version: value),
  ];
}

bool _isProjectFile(String path) {
  final segments = path.split('/');
  if (segments.length > _maxDepth + 1) return false;
  return !segments
      .take(segments.length - 1)
      .any((dir) => _ignoredDirs.contains(dir));
}

String _basename(String path) => path.substring(path.lastIndexOf('/') + 1);

String _firstLine(String content) =>
    content.split('\n').first.trim().split(RegExp(r'\s')).first;

bool _dependsOnFlutter(String pubspec) =>
    RegExp(r'^\s+sdk:\s*flutter\s*$', multiLine: true).hasMatch(pubspec);

/// `.fvmrc` is JSON (`{"flutter": "3.24.0"}`); a channel isn't a version.
String _fvmVersion(String content) {
  try {
    final version = (jsonDecode(content) as Map<String, dynamic>)['flutter'];
    if (version is String && RegExp(r'^\d').hasMatch(version)) return version;
  } on FormatException {
    // Not JSON — no version.
  }
  return '';
}

/// `.nvmrc`: `v20.11.1`, `20` or an alias like `lts/iron`.
String _nodeVersion(String content) {
  final line = _firstLine(content);
  if (line.startsWith('lts/')) return 'lts';
  final version = line.startsWith('v') ? line.substring(1) : line;
  return RegExp(r'^\d').hasMatch(version) ? version : '';
}

/// `"packageManager": "pnpm@9.1.0+sha512..."` in package.json.
({String name, String version})? _packageManager(String packageJson) {
  try {
    final value =
        (jsonDecode(packageJson) as Map<String, dynamic>)['packageManager'];
    if (value is! String) return null;
    final match = RegExp(
      r'^(pnpm|yarn|bun)@(\d[^+]*)',
    ).firstMatch(value.trim());
    if (match == null) return null;
    return (name: match.group(1)!, version: match.group(2)!);
  } on FormatException {
    return null;
  }
}

/// The `[tools]` table of a mise config: `node = "20"` or
/// `python = ["3.12", "3.11"]` (first one wins).
List<ProjectTool> _parseMiseToml(String content) {
  final tools = <ProjectTool>[];
  var inTools = false;
  for (final raw in content.split('\n')) {
    final line = raw.split('#').first.trim();
    if (line.startsWith('[')) {
      inTools = line == '[tools]';
      continue;
    }
    if (!inTools || !line.contains('=')) continue;
    final name = line
        .substring(0, line.indexOf('='))
        .trim()
        .replaceAll(
          '"',
          '',
        );
    final version = RegExp(
      r'"([^"]+)"',
    ).firstMatch(line.substring(line.indexOf('=')))?.group(1);
    if (name.isNotEmpty && version != null) {
      tools.add(ProjectTool(name: name, version: version));
    }
  }
  return tools;
}

/// `.tool-versions`: `nodejs 20.11.1` per line (asdf names `nodejs`).
List<ProjectTool> _parseToolVersions(String content) => [
  for (final raw in content.split('\n'))
    if (raw.split('#').first.trim().split(RegExp(r'\s+')) case [
      final name,
      final version,
      ...,
    ] when name.isNotEmpty)
      ProjectTool(name: name == 'nodejs' ? 'node' : name, version: version),
];
