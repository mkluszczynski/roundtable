import 'generated/protocol.dart';
import 'project_tools/repo_snapshot.dart';
import 'project_tools/tool_detectors.dart';
import 'project_tools/version_parsers.dart';

/// A mise tool id: lowercase, optionally with a backend prefix
/// (`aqua:cli/cli`, `npm:prettier`) — or `pub:<package>`, a Dart CLI the
/// runner activates itself (mise has no pub backend).
final _toolName = RegExp(r'^[a-z0-9][a-z0-9._:/@-]*$');
final _toolVersion = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._+/-]*$');

/// Trims [tools] and rejects invalid names, versions and duplicates, so the
/// runner never passes junk to `mise install`. Throws [InvalidStateException].
List<ProjectTool> validateProjectTools(List<ProjectTool> tools) {
  final seen = <String>{};
  final valid = [
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
  // `pub:` packages are activated with `dart pub global activate`.
  final pub = valid.where((t) => t.name.startsWith('pub:'));
  if (pub.isNotEmpty && !seen.contains('dart') && !seen.contains('flutter')) {
    throw InvalidStateException(
      message:
          '${pub.first.name} needs dart or flutter in the tools — it is '
          'installed with dart pub global activate',
    );
  }
  return valid;
}

/// Config files that list the tools outright, in priority order.
const _explicitConfigs = [
  ExplicitToolConfig('.mise.toml', parseMiseToml),
  ExplicitToolConfig('mise.toml', parseMiseToml),
  ExplicitToolConfig('.tool-versions', parseToolVersions),
];

/// One detector per ecosystem; the result keeps this order.
const _detectors = <ToolDetector>[
  DartDetector(),
  NodeDetector(),
  GoDetector(),
  ManifestDetector(
    'python',
    {'pyproject.toml', 'requirements.txt', 'setup.py', '.python-version'},
    versionFile: '.python-version',
  ),
  ManifestDetector('rust', {'Cargo.toml'}),
  ManifestDetector('ruby', {'Gemfile'}, versionFile: '.ruby-version'),
  ManifestDetector(
    'java',
    {'pom.xml', 'build.gradle', 'build.gradle.kts'},
    versionFile: '.java-version',
  ),
];

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
  final repo = RepoSnapshot.from(paths: paths, read: read);
  for (final config in _explicitConfigs) {
    final tools = await config.read(repo);
    if (tools.isNotEmpty) return tools;
  }
  final tools = <String, String>{
    for (final detector in _detectors) ...await detector.detect(repo),
  };
  return [
    for (final MapEntry(:key, :value) in tools.entries)
      ProjectTool(name: key, version: value),
  ];
}
