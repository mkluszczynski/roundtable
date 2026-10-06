import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:roundtable_client/roundtable_client.dart';

import 'fake_github.dart';

/// One fake claude run, see [E2EHarness.claudeRuns].
typedef ClaudeRun = ({List<String> args, String cwd, int start, int? end});

/// Runs Roundtable end to end for one test (docs/DEVELOPMENT.md "E2E
/// tests"): the real server (its own embedded Postgres, fresh every time)
/// and the real agent runner as processes, a [FakeGitHub] with the repo
/// `acme/demo`, and the scripted fake `claude` playing the agents.
///
/// Drive it through [client], like the panel does.
class E2EHarness {
  E2EHarness._(this._temp, this.github, this.client, this._processes);

  final Directory _temp;
  final FakeGitHub github;
  final Client client;
  final List<Process> _processes;

  /// The machine the runner registered as.
  late final Machine machine;

  static const owner = 'acme';
  static const repo = 'demo';

  /// Starts everything. [scenario] is the fake claude's script (see
  /// `bin/fake_claude.dart`); [files] seed `acme/demo` on `main`.
  static Future<E2EHarness> start({
    required Map<String, Object?> scenario,
    Map<String, String> files = const {'README.md': '# Demo\n'},
  }) async {
    final binaries = await _build();
    final temp = await Directory.systemTemp.createTemp('roundtable_e2e_');
    final github = await FakeGitHub.start(Directory('${temp.path}/github'));
    await github.createRepo(owner, repo, files);
    final scenarioFile = File('${temp.path}/scenario.json')
      ..writeAsStringSync(jsonEncode(scenario));

    final processes = <Process>[];
    try {
      final apiPort = await _freePort();
      final server = await _startLogged(
        'server',
        'dart',
        ['run', 'bin/main.dart', '--mode', 'test'],
        workingDirectory: '${_repoRoot.path}/roundtable_server',
        environment: {
          'ROUNDTABLE_GITHUB_URL': github.url,
          'SERVERPOD_API_SERVER_PORT': '$apiPort',
          'SERVERPOD_API_SERVER_PUBLIC_PORT': '$apiPort',
          'SERVERPOD_INSIGHTS_SERVER_PORT': '${await _freePort()}',
          'SERVERPOD_WEB_SERVER_PORT': '${await _freePort()}',
          'SERVERPOD_DATABASE_DATA_PATH': '${temp.path}/pgdata',
          'SERVERPOD_DATABASE_PORT': '${await _freePort()}',
          'SERVERPOD_DATABASE_PASSWORD': 'e2e',
          'SERVERPOD_PASSWORD_database': 'e2e',
          'SERVERPOD_PASSWORD_emailSecretHashPepper': 'e2e-pepper',
          'SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper': 'e2e-pepper',
          'SERVERPOD_PASSWORD_serviceSecret': 'e2e-service-secret',
          'SERVERPOD_APPLY_MIGRATIONS': 'true',
          'SERVERPOD_REDIS_ENABLED': 'false',
          'SERVERPOD_SESSION_PERSISTENT_LOG_ENABLED': 'false',
          'SERVERPOD_SESSION_CONSOLE_LOG_ENABLED': 'false',
        },
      );
      processes.add(server);

      final serverUrl = 'http://localhost:$apiPort/';
      final client = Client(serverUrl);
      await _until('the server to start', const Duration(minutes: 3), () async {
        try {
          await client.machine.list();
          return true;
        } catch (_) {
          return false;
        }
      });

      final registration = await client.machine.register('E2E machine');
      final runner = await _startLogged(
        'runner',
        binaries.runner,
        const [],
        workingDirectory: temp.path,
        environment: {
          'REGISTRATION_TOKEN': registration.token,
          'SERVER_URL': serverUrl,
          'CLAUDE_EXECUTABLE': binaries.fakeClaude,
          'CLAUDE_CODE_OAUTH_TOKEN': 'fake',
          'WORKSPACE_ROOT': '${temp.path}/workspace',
          'PERMISSION_PROMPT_TOOL_PATH': binaries.permissionTool,
          'HOME': '${temp.path}/home',
          'FAKE_CLAUDE_SCENARIO': scenarioFile.path,
          'FAKE_CLAUDE_STATE': '${temp.path}/fake-claude',
        },
      );
      processes.add(runner);

      final harness = E2EHarness._(temp, github, client, processes);
      harness.machine = await harness.waitFor(
        'the machine to come online',
        () async => (await client.machine.list())
            .where(
              (m) =>
                  m.id == registration.machine.id &&
                  m.status == MachineStatus.online,
            )
            .firstOrNull,
      );
      return harness;
    } catch (_) {
      for (final p in processes) {
        p.kill();
      }
      await github.close();
      rethrow;
    }
  }

  /// Creates project `acme/demo` (with a token, so PRs and reviews work)
  /// and two agents on [machine].
  Future<({Project project, Agent developer, Agent reviewer})> seed() async {
    final project = await client.project.create(
      'Demo',
      github.repoUrl(owner, repo),
      repoAccessToken: 'fake-token',
    );
    final developer = await client.agent.create(
      'Ana',
      machine.id!,
      roleId: await _roleId('developer'),
    );
    final reviewer = await client.agent.create(
      'Rex',
      machine.id!,
      roleId: await _roleId('reviewer'),
    );
    return (project: project, developer: developer, reviewer: reviewer);
  }

  Future<int> _roleId(String hint) async {
    final roles = await client.agentRole.list();
    return (roles
                .where((r) => r.name.toLowerCase().contains(hint))
                .firstOrNull ??
            roles.first)
        .id!;
  }

  /// The task's current row.
  Future<Task> task(int id) async => (await client.task.findTasks([id])).single;

  /// Polls [check] until it returns non-null, failing after [timeout].
  Future<T> waitFor<T extends Object>(
    String what,
    Future<T?> Function() check, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    T? value;
    await _until(what, timeout, () async {
      value = await check();
      return value != null;
    });
    return value!;
  }

  /// Waits until task [id] is in [status], failing early if it fails.
  Future<Task> waitForStatus(
    int id,
    TaskStatus status, {
    Duration timeout = const Duration(seconds: 90),
  }) => waitFor('task $id to be ${status.name}', () async {
    final current = await task(id);
    if (current.status == TaskStatus.failed && status != TaskStatus.failed) {
      throw StateError('task $id failed: ${current.failureReason}');
    }
    return current.status == status ? current : null;
  }, timeout: timeout);

  /// Every fake claude run so far (not its `--version` checks): args,
  /// working directory, and when it started and ended (ms since epoch;
  /// `end` is null while it's still running).
  List<ClaudeRun> get claudeRuns {
    final dir = '${_temp.path}/fake-claude';
    List<Map<String, dynamic>> read(String name) {
      final file = File('$dir/$name');
      if (!file.existsSync()) return const [];
      return [
        for (final line in file.readAsLinesSync())
          if (line.trim().isNotEmpty) jsonDecode(line) as Map<String, dynamic>,
      ];
    }

    final ends = {for (final e in read('ends.jsonl')) e['pid']: e['end']};
    return [
      for (final run in read('invocations.jsonl'))
        (
          args: (run['args'] as List).cast<String>(),
          cwd: run['cwd'] as String,
          start: run['start'] as int,
          end: ends[run['pid']] as int?,
        ),
    ];
  }

  /// Task [taskId]'s code reviews with their comments, oldest first.
  Future<List<CodeReview>> reviews(int taskId) async {
    final byId = <int, CodeReview>{};
    final subscription = client.codeReview
        .watchReviews(taskId)
        .listen((r) => byId[r.id!] = r);
    // The stream replays every review on subscribe.
    await Future<void>.delayed(const Duration(seconds: 2));
    await subscription.cancel();
    return byId.values.toList()..sort((a, b) => a.id!.compareTo(b.id!));
  }

  Future<void> stop() async {
    client.close();
    for (final p in _processes.reversed) {
      p.kill();
      await p.exitCode.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          p.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    }
    await github.close();
    if (Platform.environment['E2E_KEEP'] != null) {
      stderr.writeln('E2E_KEEP: left ${_temp.path}');
      return;
    }
    try {
      await _temp.delete(recursive: true);
    } catch (_) {}
  }

  // ------------------------------------------------------------ plumbing

  static Directory get _repoRoot {
    var dir = Directory.current.absolute;
    while (!File('${dir.path}/roundtable_server/pubspec.yaml').existsSync()) {
      final parent = dir.parent;
      if (parent.path == dir.path) {
        throw StateError('Run the E2E tests from inside the repo');
      }
      dir = parent;
    }
    return dir;
  }

  static Future<({String runner, String permissionTool, String fakeClaude})>?
  _built;

  /// Compiles the runner, its permission prompt tool and the fake claude
  /// once per test run, like the binaries a machine installs.
  static Future<({String runner, String permissionTool, String fakeClaude})>
  _build() => _built ??= () async {
    final out = Directory(
      '${_repoRoot.path}/roundtable_e2e/.dart_tool/e2e_bin',
    );
    await out.create(recursive: true);
    Future<String> compile(String package, String entry, String name) async {
      final target = '${out.path}/$name';
      final result = await Process.run('dart', [
        'compile',
        'exe',
        entry,
        '-o',
        target,
      ], workingDirectory: '${_repoRoot.path}/$package');
      if (result.exitCode != 0) {
        throw StateError('compiling $entry failed:\n${result.stderr}');
      }
      return target;
    }

    final compiled = await Future.wait([
      compile(
        'roundtable_agent_runner',
        'bin/roundtable_agent_runner.dart',
        'agent_runner',
      ),
      compile(
        'roundtable_agent_runner',
        'bin/permission_prompt_tool.dart',
        'permission_prompt_tool',
      ),
      compile('roundtable_e2e', 'bin/fake_claude.dart', 'fake_claude'),
    ]);
    return (
      runner: compiled[0],
      permissionTool: compiled[1],
      fakeClaude: compiled[2],
    );
  }();

  /// Starts a process, echoing its output with a [label] prefix when
  /// `E2E_VERBOSE` is set (and always keeping the tail for failures).
  static Future<Process> _startLogged(
    String label,
    String executable,
    List<String> args, {
    required String workingDirectory,
    required Map<String, String> environment,
  }) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
    );
    final verbose = Platform.environment['E2E_VERBOSE'] != null;
    for (final stream in [process.stdout, process.stderr]) {
      stream.transform(utf8.decoder).transform(const LineSplitter()).listen((
        line,
      ) {
        if (verbose) stderr.writeln('[$label] $line');
      });
    }
    return process;
  }

  static Future<int> _freePort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  static Future<void> _until(
    String what,
    Duration timeout,
    Future<bool> Function() check,
  ) async {
    final deadline = DateTime.now().add(timeout);
    while (!await check()) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('Timed out waiting for $what', timeout);
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }
}
