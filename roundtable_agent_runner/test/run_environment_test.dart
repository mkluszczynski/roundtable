import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:test/test.dart';

Agent _agent(AgentExecutionMode mode) => Agent(
  id: 1,
  machineId: 1,
  name: 'Ana',
  status: AgentStatus.idle,
  executionMode: mode,
);

void main() {
  late List<ContainerRequest> requests;
  late List<String> events;

  RunEnvironments environments({bool hasPodman = true}) => RunEnvironments(
    executorFactory: ClaudeCodeExecutor.new,
    log: (_) {},
    environmentPrompt: ({container = false}) =>
        container ? 'You are in a container.' : 'You are on a laptop.',
    sandboxFor: hasPodman
        ? (request) {
            requests.add(request);
            return ContainerSandbox(
              image: 'img',
              name: request.name,
              workingDirectory: request.worktreePath,
              mounts: const [],
              home: '/h',
              claudePath: '/usr/bin/claude',
            );
          }
        : null,
  );

  Future<RunEnvironment> prepare(
    RunEnvironments environments,
    AgentExecutionMode mode,
  ) => environments.prepare(
    agent: _agent(mode),
    label: 'task 1',
    projectId: 7,
    containerName: 'roundtable-task-1',
    worktreePath: '/w/7/worktrees/1',
    readOnlyDirectories: ['/tmp/mcp'],
    append: (item) => events.add(item.content),
  );

  setUp(() {
    requests = [];
    events = [];
  });

  test('a native agent runs on the machine', () async {
    final env = await prepare(environments(), AgentExecutionMode.native);

    expect(env.inContainer, isFalse);
    expect(requests, isEmpty);
    expect(
      env.systemPrompt(['Name the task.']),
      'You are on a laptop.\n\n'
      'Name the task.',
    );
    expect(env.describeFailure('boom'), 'boom');
  });

  test(
    'a docker-mode agent gets its container with the read-only dirs',
    () async {
      final env = await prepare(environments(), AgentExecutionMode.docker);

      expect(env.inContainer, isTrue);
      expect(requests.single.name, 'roundtable-task-1');
      expect(requests.single.readOnlyDirectories, ['/tmp/mcp']);
      expect(env.systemPrompt(), 'You are in a container.');
      expect(events, ['Running in a container (img)']);
    },
  );

  test('a docker-mode agent on a machine without podman fails clearly', () {
    expect(
      prepare(environments(hasPodman: false), AgentExecutionMode.docker),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('no container runtime'),
        ),
      ),
    );
  });
}
