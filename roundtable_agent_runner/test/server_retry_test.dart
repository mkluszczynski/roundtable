import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  const noDelay = [Duration.zero, Duration.zero];

  test('retries until the call succeeds', () async {
    var calls = 0;
    final logs = <String>[];

    final ok = await retrying(
      'reporting',
      () async {
        if (++calls < 3) throw Exception('server down');
      },
      log: logs.add,
      delays: noDelay,
    );

    expect(ok, isTrue);
    expect(calls, 3);
    expect(logs, everyElement(contains('retrying')));
  });

  test('gives up after the last delay without throwing', () async {
    var calls = 0;
    final logs = <String>[];

    final ok = await retrying(
      'reporting',
      () async {
        calls++;
        throw Exception('server down');
      },
      log: logs.add,
      delays: noDelay,
    );

    expect(ok, isFalse);
    expect(calls, 3);
    expect(logs.last, contains('giving up'));
  });
}
