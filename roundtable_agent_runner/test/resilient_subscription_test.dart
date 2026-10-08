import 'dart:async';

import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  test(
    'resubscribes after the stream errors or closes, until cancelled',
    () async {
      final streams = <StreamController<int>>[];
      final received = <int>[];
      final subscription = ResilientSubscription<int>(
        name: 'watch',
        subscribe: () {
          final controller = StreamController<int>();
          streams.add(controller);
          return controller.stream;
        },
        onData: received.add,
        log: (_) {},
        retryDelay: Duration.zero,
      )..start();

      streams.last.add(1);
      streams.last.addError(Exception('socket closed'));
      await pumpEventQueue();
      streams.last.add(2);
      await streams.last.close();
      await pumpEventQueue();
      streams.last.add(3);
      await pumpEventQueue();

      expect(received, [1, 2, 3]);
      expect(streams, hasLength(3));

      subscription.cancel();
      await streams.last.close();
      await pumpEventQueue();
      expect(streams, hasLength(3), reason: 'no resubscribe after cancel');
    },
  );
}
