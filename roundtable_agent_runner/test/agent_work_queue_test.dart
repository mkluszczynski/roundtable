import 'dart:async';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  test('runs one piece of work at a time per agent, in order', () async {
    final queue = AgentWorkQueue();
    final events = <String>[];
    final release = Completer<void>();
    final waitingFor = <String>[];

    final first = queue.run(1, 'task #1', () async {
      events.add('start 1');
      await release.future;
      events.add('end 1');
    });
    final second = queue.run(
      1,
      'the review of task #3',
      () async => events.add('start review'),
      onWaiting: waitingFor.add,
    );
    final otherAgent = queue.run(2, 'task #2', () async {
      events.add('start other');
    });

    await otherAgent;
    expect(events, ['start 1', 'start other']);
    expect(waitingFor, ['task #1']);
    expect(queue.currentWork(1), 'task #1');

    release.complete();
    await Future.wait([first, second]);
    expect(events, ['start 1', 'start other', 'end 1', 'start review']);
    expect(queue.currentWork(1), isNull);
  });

  test('a failing piece of work frees the agent', () async {
    final queue = AgentWorkQueue();
    await expectLater(
      queue.run(1, 'task #1', () async => throw StateError('boom')),
      throwsStateError,
    );
    var waited = false;
    expect(
      await queue.run(
        1,
        'task #2',
        () async => 'ran',
        onWaiting: (_) {
          waited = true;
        },
      ),
      'ran',
    );
    expect(waited, isFalse);
  });

  test('drain holds back new work until resume, while running work '
      'finishes', () async {
    final queue = AgentWorkQueue();
    final events = <String>[];
    final release = Completer<void>();
    final waitingFor = <String>[];

    final running = queue.run(1, 'task #1', () async {
      events.add('start 1');
      await release.future;
      events.add('end 1');
    });
    queue.drain();
    expect(queue.isDraining, isTrue);
    expect(queue.isIdle, isFalse);
    expect(queue.currentWorks, ['task #1']);

    final held = queue.run(
      2,
      'task #2',
      () async => events.add('start 2'),
      onWaiting: waitingFor.add,
    );
    await Future<void>.delayed(Duration.zero);
    expect(waitingFor, [AgentWorkQueue.drainLabel]);

    release.complete();
    await running;
    expect(queue.isIdle, isTrue);
    expect(events, ['start 1', 'end 1']);

    queue.resume();
    await held;
    expect(queue.isDraining, isFalse);
    expect(events, ['start 1', 'end 1', 'start 2']);
  });
}
