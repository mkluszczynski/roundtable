import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:roundtable_client/roundtable_client.dart';

/// A project's toolchains, ready for a task: the environment `claude` runs
/// with (its `PATH` puts them first) and what got installed.
typedef PreparedToolchain = ({
  Map<String, String> environment,
  List<String> tools,
});

/// Installs a project's toolchains ([Project.tools]) with mise
/// (https://mise.jdx.dev) before a task runs — docs/FLOWS.md §7.
///
/// Everything lives under [home] (the runner's `$HOME`), so no sudo is
/// needed: the mise binary in `.local/bin`, the installs in mise's data dir
/// (shared by every project and kept across tasks, so only a new tool or
/// version downloads anything), and one config per project under
/// `.config/roundtable/toolchains/` — never in the worktree, so the pull
/// request stays clean. mise always runs from [home], so a repo's own
/// `.mise.toml` is neither read nor needs trusting.
class ToolchainInstaller {
  ToolchainInstaller({
    required this.home,
    this.downloadMise = _downloadMise,
    this.runProcess = Process.run,
  });

  final String home;

  /// Downloads the mise binary to the given path — swapped in tests.
  final Future<void> Function(String path) downloadMise;

  final Future<ProcessResult> Function(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  })
  runProcess;

  /// Serializes installs: two tasks starting at once mustn't download the
  /// same SDK twice.
  Future<void> _queue = Future.value();

  String get misePath => '$home/.local/bin/mise';

  /// Makes [tools] available and returns the environment to run `claude`
  /// with. [onInstalling] is called with the tools that have to be
  /// downloaded first (e.g. `flutter 3.24.0`), before the slow part —
  /// never when everything is cached. Throws [ToolchainException].
  Future<PreparedToolchain> prepare({
    required int projectId,
    required List<ProjectTool> tools,
    void Function(List<String> missing)? onInstalling,
  }) {
    final result = _queue.then((_) => _prepare(projectId, tools, onInstalling));
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<PreparedToolchain> _prepare(
    int projectId,
    List<ProjectTool> tools,
    void Function(List<String> missing)? onInstalling,
  ) async {
    await _ensureMise();
    final configDir = Directory('$home/.config/roundtable/toolchains');
    await configDir.create(recursive: true);
    final config = File('${configDir.path}/project-$projectId.toml');
    await config.writeAsString(miseConfig(tools));
    final env = _miseEnv(config.path);

    final missing = await _mise(['ls', '--missing', '--json'], env);
    final toInstall = missingTools(missing);
    if (toInstall.isNotEmpty) {
      onInstalling?.call(toInstall);
      await _mise(['install'], env);
    }

    final vars = jsonDecode(await _mise(['env', '--json'], env)) as Map;
    final environment = {
      for (final MapEntry(:key, :value) in vars.entries) '$key': '$value',
    };

    final pubTools = [
      for (final t in tools)
        if (t.name.startsWith(pubPrefix)) t,
    ];
    if (pubTools.isNotEmpty) {
      await _activatePubTools(pubTools, environment, onInstalling);
    }

    return (
      environment: environment,
      tools: [for (final t in tools) '${t.name} ${t.version}'],
    );
  }

  /// Activates `pub:` tools with `dart pub global activate` — the `dart`
  /// from the project's toolchain — into a pub cache under [home], and puts
  /// its `bin` first on [environment]'s PATH. Skips packages already active
  /// at the wanted version (any version for `latest`).
  Future<void> _activatePubTools(
    List<ProjectTool> tools,
    Map<String, String> environment,
    void Function(List<String> missing)? onInstalling,
  ) async {
    final path = environment['PATH'] ?? Platform.environment['PATH'] ?? '';
    final dart = _which('dart', path);
    if (dart == null) {
      throw ToolchainException(
        '${tools.first.name} needs dart — add dart or flutter to the tools',
      );
    }
    final pubCache = '$home/.pub-cache';
    final env = {...environment, 'HOME': home, 'PUB_CACHE': pubCache};

    final listed = await runProcess(dart, [
      'pub',
      'global',
      'list',
    ], environment: env);
    final active = activePubPackages('${listed.stdout}');
    final toActivate = [
      for (final t in tools)
        if (!pubToolActive(t, active)) t,
    ];
    if (toActivate.isNotEmpty) {
      onInstalling?.call([
        for (final t in toActivate) '${t.name} ${t.version}',
      ]);
      for (final tool in toActivate) {
        final package = tool.name.substring(pubPrefix.length);
        final result = await runProcess(dart, [
          'pub',
          'global',
          'activate',
          package,
          if (tool.version != 'latest') tool.version,
        ], environment: env);
        if (result.exitCode != 0) {
          throw ToolchainException(
            'dart pub global activate $package failed: '
            '${lastLines('${result.stderr}\n${result.stdout}')}',
          );
        }
      }
    }

    environment
      ..['PUB_CACHE'] = pubCache
      ..['PATH'] = '$pubCache/bin:$path';
  }

  String? _which(String name, String path) {
    for (final dir in path.split(':')) {
      if (dir.isEmpty) continue;
      if (File('$dir/$name').existsSync()) return '$dir/$name';
    }
    return null;
  }

  Map<String, String> _miseEnv(String configPath) => {
    // [home] decides where everything lives, even if the runner's own
    // `$HOME` or XDG dirs point elsewhere (tests, a desktop session).
    'HOME': home,
    'MISE_DATA_DIR': '$home/.local/share/mise',
    'MISE_CACHE_DIR': '$home/.cache/mise',
    'MISE_STATE_DIR': '$home/.local/state/mise',
    'MISE_CONFIG_DIR': '$home/.config/mise',
    'MISE_GLOBAL_CONFIG_FILE': configPath,
    'MISE_YES': '1',
  };

  Directory get _configDir => Directory('$home/.config/roundtable/toolchains');

  /// Frees disk space: forgets project configs unused for [keepUnused]
  /// (each run rewrites its project's config, so the file's mtime is its
  /// last use), then uninstalls every mise version no remaining config
  /// resolves to — older `latest`s, versions a project moved off, tools of
  /// deleted projects. Runs between installs, never during one. Returns
  /// the removed `tool version`s. `pub:` packages are small and stay.
  Future<List<String>> prune({Duration keepUnused = const Duration(days: 30)}) {
    final result = _queue.then((_) => _prune(keepUnused));
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<List<String>> _prune(Duration keepUnused) async {
    if (!await File(misePath).exists() || !await _configDir.exists()) {
      return const [];
    }
    final cutoff = DateTime.now().subtract(keepUnused);
    final configs = <File>[];
    await for (final entry in _configDir.list()) {
      if (entry is! File || !entry.path.endsWith('.toml')) continue;
      if ((await entry.lastModified()).isBefore(cutoff)) {
        await entry.delete();
      } else {
        configs.add(entry);
      }
    }

    final wanted = <String>{};
    for (final config in configs) {
      wanted.addAll(
        installedVersions(
          await _mise(['ls', '--current', '--json'], _miseEnv(config.path)),
        ),
      );
    }
    // Lists every install without a project's config getting in the way.
    final empty = File('$home/.config/roundtable/no-tools.toml');
    await empty.writeAsString('');
    final installed = installedVersions(
      await _mise(['ls', '--installed', '--json'], _miseEnv(empty.path)),
    );
    final stale = installed.difference(wanted).toList()..sort();
    if (stale.isNotEmpty) {
      await _mise([
        'uninstall',
        for (final v in stale) v.replaceFirst(' ', '@'),
      ], _miseEnv(empty.path));
    }
    return stale;
  }

  Future<void> _ensureMise() async {
    if (await File(misePath).exists()) return;
    await Directory('$home/.local/bin').create(recursive: true);
    final partial = '$misePath.download';
    try {
      await downloadMise(partial);
      await runProcess('chmod', ['755', partial]);
      await File(partial).rename(misePath);
    } catch (e) {
      throw ToolchainException("couldn't download mise: $e");
    }
  }

  Future<String> _mise(List<String> args, Map<String, String> env) async {
    final result = await runProcess(
      misePath,
      args,
      workingDirectory: home,
      environment: env,
    );
    if (result.exitCode != 0) {
      throw ToolchainException(
        'mise ${args.first} failed: ${lastLines('${result.stderr}')}',
      );
    }
    return '${result.stdout}';
  }
}

class ToolchainException implements Exception {
  ToolchainException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The mise config for [tools] — names and versions are validated by the
/// server (`validateProjectTools`), quoted here anyway.
/// `pub:` tools aren't mise's — they're activated separately.
String miseConfig(List<ProjectTool> tools) => [
  '# Written by the Roundtable agent runner — edit tools in the panel.',
  '[tools]',
  for (final t in tools)
    if (!t.name.startsWith(pubPrefix)) '"${t.name}" = "${t.version}"',
].join('\n');

/// The prefix of a Dart CLI package in [Project.tools], e.g.
/// `pub:serverpod_cli`.
const pubPrefix = 'pub:';

/// `dart pub global list` → package → version (`serverpod_cli 4.0.3`).
Map<String, String> activePubPackages(String output) => {
  for (final line in output.split('\n'))
    if (line.trim().split(RegExp(r'\s+')) case [final name, final version, ...])
      name: version,
};

bool pubToolActive(ProjectTool tool, Map<String, String> active) {
  final version = active[tool.name.substring(pubPrefix.length)];
  return version != null &&
      (tool.version == 'latest' || version == tool.version);
}

/// `mise ls --json` → the `tool version`s it lists as installed.
Set<String> installedVersions(String json) {
  if (json.trim().isEmpty) return const {};
  final decoded = jsonDecode(json);
  if (decoded is! Map) return const {};
  return {
    for (final MapEntry(:key, :value) in decoded.entries)
      for (final install in value as List)
        if ((install as Map)['installed'] != false &&
            install['version'] != null)
          '$key ${install['version']}',
  };
}

/// `mise ls --missing --json` → `["flutter 3.47.6", …]` (resolved versions).
List<String> missingTools(String json) {
  if (json.trim().isEmpty) return const [];
  final decoded = jsonDecode(json);
  if (decoded is! Map) return const [];
  return [
    for (final MapEntry(:key, :value) in decoded.entries)
      for (final install in value as List)
        '$key ${(install as Map)['version'] ?? install['requested_version']}',
  ];
}

/// The last few lines of a failing command's output, for an error message.
String lastLines(String output, {int count = 5}) {
  final lines = output.trim().split('\n');
  return lines
      .sublist((lines.length - count).clamp(0, lines.length))
      .join('\n');
}

/// Downloads the latest mise release for this machine's architecture.
Future<void> _downloadMise(String path) async {
  final arch = switch (Abi.current()) {
    Abi.linuxArm64 => 'arm64',
    Abi.linuxX64 => 'x64',
    final abi => throw ToolchainException('no mise build for $abi'),
  };
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('https://mise.jdx.dev/mise-latest-linux-$arch'),
    );
    final response = await request.close();
    if (response.statusCode != 200) {
      throw ToolchainException('download returned ${response.statusCode}');
    }
    await response.pipe(File(path).openWrite());
  } finally {
    client.close();
  }
}
