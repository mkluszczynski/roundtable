@Timeout(Duration(minutes: 6))
library;

import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_e2e/roundtable_e2e.dart';
import 'package:test/test.dart';

void main() {
  late E2EHarness e2e;

  setUp(() async {
    e2e = await E2EHarness.start(
      scenario: {
        'runs': [
          {
            'files': {'hello.txt': 'Hello from Ana\n'},
            'result': 'Added hello.txt',
          },
        ],
      },
    );
  });

  tearDown(() => e2e.stop());

  test('a task without planning ends with a pull request', () async {
    final seeded = await e2e.seed();
    final task = await e2e.client.task.createTask(
      seeded.project.id!,
      seeded.developer.id!,
      'Add a hello file',
      skipPlanning: true,
    );

    final done = await e2e.waitForStatus(task.id!, TaskStatus.awaitingReview);

    expect(done.prUrl, '${e2e.github.url}/acme/demo/pull/1');
    final pr = e2e.github.pullRequests.single;
    expect(pr.head, 'task-${task.id}');
    expect(
      await e2e.github.fileOn('acme', 'demo', pr.head, 'hello.txt'),
      'Hello from Ana\n',
    );
    expect(e2e.claudeRuns, hasLength(1));
  });
}
