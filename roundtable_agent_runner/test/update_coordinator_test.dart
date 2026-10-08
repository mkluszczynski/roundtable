import 'dart:async';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  late AgentWorkQueue queue;
  late List<String> handedOff;
  late bool canWriteFlag;

  UpdateCoordinator coordinator({String? flagPath = '/run/update'}) =>
      UpdateCoordinator(
        workQueue: queue,
        updateFlagPath: flagPath,
        log: (_) {},
        requestUpdate: (path) {
          if (!canWriteFlag) return false;
          handedOff.add(path);
          return true;
        },
      );

  setUp(() {
    queue = AgentWorkQueue();
    handedOff = [];
    canWriteFlag = true;
  });

  test('an idle runner hands the update off at once, once', () {
    final updates = coordinator();

    updates.onCheckIn(updateRequested: true);
    updates.onCheckIn(updateRequested: true);

    expect(handedOff, ['/run/update']);
  });

  test(
    'a busy runner holds new work and waits for the run to finish',
    () async {
      final run = Completer<void>();
      unawaited(queue.run(1, 'task #5', () => run.future));
      await pumpEventQueue();
      final updates = coordinator();

      updates.onCheckIn(updateRequested: true);
      expect(handedOff, isEmpty);
      expect(queue.isDraining, isTrue);

      run.complete();
      await pumpEventQueue();
      updates.onCheckIn(updateRequested: true);
      expect(handedOff, ['/run/update']);
    },
  );

  test('a withdrawn request lets held work go', () async {
    final run = Completer<void>();
    unawaited(queue.run(1, 'task #5', () => run.future));
    await pumpEventQueue();
    final updates = coordinator();

    updates.onCheckIn(updateRequested: true);
    updates.onCheckIn(updateRequested: false);

    expect(queue.isDraining, isFalse);
    run.complete();
  });

  test("a flag that can't be written lets work go and retries", () {
    canWriteFlag = false;
    final updates = coordinator();

    updates.onCheckIn(updateRequested: true);
    expect(queue.isDraining, isFalse);

    canWriteFlag = true;
    updates.onCheckIn(updateRequested: true);
    expect(handedOff, ['/run/update']);
  });

  test('an install without an updater never holds work', () {
    coordinator(flagPath: null).onCheckIn(updateRequested: true);

    expect(queue.isDraining, isFalse);
    expect(handedOff, isEmpty);
  });
}
