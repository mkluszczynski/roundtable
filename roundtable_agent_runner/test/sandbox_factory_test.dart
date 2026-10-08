import 'dart:io';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  late Directory home;
  late SandboxFactory factory;
  late bool podman;

  setUp(() {
    home = Directory.systemTemp.createTempSync('sandbox_factory_test_');
    // Any executable stands in for claude and podman: only paths matter.
    final fake = File('${home.path}/bin/tool')..createSync(recursive: true);
    podman = true;
    factory = SandboxFactory(
      home: home.path,
      workspaceRoot: '${home.path}/workspace',
      claudeExecutable: fake.path,
      permissionPromptToolCommand: [fake.path],
      hasPodman: () => podman,
    );
  });

  tearDown(() => home.deleteSync(recursive: true));

  ContainerSandbox build() => factory.build((
    projectId: 7,
    name: 'roundtable-task-1',
    worktreePath: '${home.path}/workspace/7/worktrees/1',
    readOnlyDirectories: ['/tmp/mcp'],
    image: null,
  ));

  bool? readOnly(ContainerSandbox sandbox, String path) =>
      sandbox.mounts.where((m) => m.path == path).firstOrNull?.readOnly;

  test("the project's bare repo is read-only — host git runs its config", () {
    final sandbox = build();

    expect(readOnly(sandbox, '${home.path}/workspace/7/repo.git'), isTrue);
    expect(readOnly(sandbox, '${home.path}/workspace/7/worktrees/1'), isFalse);
    expect(readOnly(sandbox, '/tmp/mcp'), isTrue);
    expect(readOnly(sandbox, '${home.path}/bin/tool'), isTrue);
  });

  test('nothing else of the machine is mounted', () {
    final paths = build().mounts.map((m) => m.path).toSet();

    expect(paths, {
      '${home.path}/workspace/7/worktrees/1',
      '${home.path}/workspace/7/repo.git',
      '${home.path}/containers/project-7',
      '${home.path}/.local/share/mise',
      '${home.path}/.pub-cache',
      '${home.path}/bin/tool',
      '/tmp/mcp',
    });
  });

  test("the copied claude login is the owner's only", () {
    File('${home.path}/.claude/.credentials.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"secret": true}');

    build();

    final copy = File(
      '${home.path}/containers/project-7/.claude/.credentials.json',
    );
    expect(copy.readAsStringSync(), '{"secret": true}');
    expect(copy.statSync().modeString(), 'rw-------');
  });

  test('without podman a docker-mode run fails clearly', () {
    podman = false;
    expect(build, throwsA(isA<StateError>()));
  });
}
