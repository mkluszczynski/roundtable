import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

/// One compiled entrypoint of the sibling `roundtable_agent_runner` package.
enum AgentRunnerBinary {
  agentRunner('bin/roundtable_agent_runner.dart', 'roundtable-agent-runner'),
  permissionPromptTool(
    'bin/permission_prompt_tool.dart',
    'roundtable-permission-prompt-tool',
  );

  const AgentRunnerBinary(this.targetScript, this.packagedFileName);

  /// The `bin/*.dart` entrypoint in the agent-runner package.
  final String targetScript;

  /// File name of the prebuilt copy the Dockerfile bakes into
  /// `web/static/bin/`.
  final String packagedFileName;

  String get targetName => targetScript.split('/').last.replaceAll('.dart', '');
}

/// Resolves the agent-runner binaries served to `install-agent.sh` and the
/// root-side updater it installs (design doc §6.8), and the version string a
/// daemon compares itself against.
///
/// Prefers the prebuilt copies in `web/static/bin/`. In development, where
/// the agent-runner package is source, each binary is compiled with
/// `dart build cli` into a per-target subdirectory of that package's
/// `build/` directory (`dart build cli` wipes its whole `--output` directory
/// on every invocation), and recompiled whenever any of its sources — the
/// agent-runner package, or the generated `roundtable_client` it depends
/// on — is newer than the cached binary. So a runner fix reaches machines
/// on their next update without manually deleting the cache.
class AgentRunnerBinaries {
  AgentRunnerBinaries._();

  static final instance = AgentRunnerBinaries._();

  final _builds = <AgentRunnerBinary, Future<File?>>{};

  /// Returns the up-to-date binary for [binary], building it first if
  /// needed, or null if it can't be found or built.
  Future<File?> resolve(AgentRunnerBinary binary) {
    // Concurrent callers share one in-flight resolution, so they don't race
    // two `dart build cli` runs into the same output directory.
    // Block body: `remove` returns this very future, and `whenComplete`
    // would wait on a returned future — i.e. on itself, forever.
    return _builds[binary] ??= _resolve(binary).whenComplete(() {
      _builds.remove(binary);
    });
  }

  /// The version of the binaries currently being served — see
  /// [agentRunnerVersion]. Null if either can't be resolved.
  Future<String?> version() async {
    final runner = await resolve(AgentRunnerBinary.agentRunner);
    final tool = await resolve(AgentRunnerBinary.permissionPromptTool);
    if (runner == null || tool == null) return null;
    return agentRunnerVersion(runner, tool);
  }

  Future<File?> _resolve(AgentRunnerBinary binary) async {
    final packaged = File(
      Uri(path: 'web/static/bin/${binary.packagedFileName}').toFilePath(),
    );
    if (packaged.existsSync()) return packaged;

    final agentRunnerDir = Directory(
      Uri(path: '../roundtable_agent_runner').toFilePath(),
    );
    if (!agentRunnerDir.existsSync()) return null;

    final name = binary.targetName;
    final built = File(
      Uri(
        path: '../roundtable_agent_runner/build/$name/bundle/bin/$name',
      ).toFilePath(),
    );
    if (built.existsSync() &&
        !_newestSourceChange().isAfter(built.lastModifiedSync())) {
      return built;
    }

    stdout.writeln(
      'Building $name binary (missing, or its sources changed)...',
    );
    final result = await Process.run('dart', [
      'build',
      'cli',
      '--target',
      binary.targetScript,
      '--output',
      'build/$name',
    ], workingDirectory: agentRunnerDir.path);
    if (result.exitCode != 0) {
      stderr.writeln(
        'Failed to build $name binary, it will 404 until this is fixed:\n'
        '${result.stderr}',
      );
      return null;
    }
    return built.existsSync() ? built : null;
  }

  /// The newest modification time among the sources a dev-mode binary is
  /// compiled from.
  DateTime _newestSourceChange() {
    var newest = DateTime.fromMillisecondsSinceEpoch(0);
    void consider(FileSystemEntity entity) {
      if (entity is! File) return;
      final modified = entity.lastModifiedSync();
      if (modified.isAfter(newest)) newest = modified;
    }

    for (final dir in [
      '../roundtable_agent_runner/bin',
      '../roundtable_agent_runner/lib',
      '../roundtable_client/lib',
    ]) {
      final directory = Directory(Uri(path: dir).toFilePath());
      if (!directory.existsSync()) continue;
      directory.listSync(recursive: true).forEach(consider);
    }
    for (final file in [
      '../roundtable_agent_runner/pubspec.yaml',
      '../pubspec.lock',
    ]) {
      final f = File(Uri(path: file).toFilePath());
      if (f.existsSync()) consider(f);
    }
    return newest;
  }
}

/// Version string of an agent-runner install: short content hashes of the
/// daemon binary and the permission-prompt-tool binary. The daemon computes
/// the same string over its own installed files and reports it on every
/// heartbeat, so the panel can tell a machine is out of date without either
/// side tracking release numbers.
String agentRunnerVersion(File runner, File permissionPromptTool) =>
    '${_shortHash(runner)}-${_shortHash(permissionPromptTool)}';

String _shortHash(File file) =>
    sha256.convert(file.readAsBytesSync()).toString().substring(0, 12);

/// Serves the current build of [binary], rebuilding it first if its sources
/// changed (see [AgentRunnerBinaries]).
class AgentRunnerBinaryRoute extends Route {
  AgentRunnerBinaryRoute(this.binary) : super(methods: {Method.get});

  final AgentRunnerBinary binary;

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final file = await AgentRunnerBinaries.instance.resolve(binary);
    if (file == null) {
      return Response.notFound(
        body: Body.fromString('${binary.targetName} binary is unavailable'),
      );
    }
    return Response.ok(
      body: Body.fromData(
        await file.readAsBytes(),
        mimeType: MimeType.octetStream,
      ),
    );
  }
}
