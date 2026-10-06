import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  test('runArgs mounts paths in place and passes env vars by name', () {
    final sandbox = ContainerSandbox(
      image: 'img',
      name: 'roundtable-task-3',
      workingDirectory: '/w/1/task-3',
      mounts: [
        (path: '/w/1/task-3', readOnly: false),
        (path: '/usr/bin/claude', readOnly: true),
        (path: '/w/1/task-3', readOnly: false),
      ],
      home: '/h/project-1',
      claudePath: '/usr/bin/claude',
    );

    final args = sandbox.runArgs(
      '/usr/bin/claude',
      ['-p', 'hi'],
      environment: ['PATH', 'CLAUDE_CODE_OAUTH_TOKEN'],
    );

    expect(args, containsAllInOrder(['run', '--rm', '--userns=keep-id']));
    expect(
      args.where((a) => a == '/w/1/task-3:/w/1/task-3'),
      hasLength(1),
      reason: 'duplicate mounts collapse',
    );
    expect(args, contains('/usr/bin/claude:/usr/bin/claude:ro'));
    expect(args, contains('CLAUDE_CODE_OAUTH_TOKEN'));
    expect(args.join(' '), isNot(contains('CLAUDE_CODE_OAUTH_TOKEN=')));
    expect(args.sublist(args.indexOf('img')), [
      'img',
      '/usr/bin/claude',
      '-p',
      'hi',
    ]);
  });

  test('containerServerUrl rewrites only loopback hosts', () {
    expect(
      containerServerUrl('http://localhost:8080/'),
      'http://host.containers.internal:8080/',
    );
    expect(
      containerServerUrl('http://127.0.0.1:8080/'),
      'http://host.containers.internal:8080/',
    );
    expect(
      containerServerUrl('https://rt.example.com/'),
      'https://rt.example.com/',
    );
  });

  test('describeContainerFailure explains a uid mapping failure', () {
    expect(
      describeContainerFailure('newuidmap: write to uid_map failed'),
      contains('Re-run install-agent.sh with --docker'),
    );
    expect(describeContainerFailure('boom'), 'boom');
  });
}
