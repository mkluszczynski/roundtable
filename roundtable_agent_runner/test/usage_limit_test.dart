import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 10, 4, 23, 30);

  test('recognises usage limit messages', () {
    expect(
      isUsageLimitMessage(
        "You've hit your session limit · resets 12:40am (Europe/Warsaw)",
      ),
      isTrue,
    );
    expect(
      isUsageLimitMessage('Claude AI usage limit reached|1700000000'),
      isTrue,
    );
    expect(isUsageLimitMessage('Error: command not found'), isFalse);
    expect(isUsageLimitMessage(null), isFalse);
  });

  test('a reset time earlier than now is tomorrow, plus a minute', () {
    final at = usageLimitResetAt(
      "You've hit your session limit · resets 12:40am (Europe/Warsaw)",
      now: now,
    ).toLocal();
    expect(at, DateTime(2026, 10, 5, 0, 41));
  });

  test('a later time today and a pm hour', () {
    final at = usageLimitResetAt('resets 11:45pm', now: now).toLocal();
    expect(at, DateTime(2026, 10, 4, 23, 46));
  });

  test('a dated weekly reset', () {
    final at = usageLimitResetAt(
      "You've hit your weekly limit · resets Oct 7, 3pm",
      now: now,
    ).toLocal();
    expect(at, DateTime(2026, 10, 7, 15, 1));
  });

  test('an unreadable time falls back to a short wait', () {
    final at = usageLimitResetAt('usage limit reached', now: now).toLocal();
    expect(at, now.add(usageLimitFallbackWait));
  });

  group('UsageLimitGate', () {
    test('is open until a run hits the limit, then until the reset', () {
      var clock = DateTime.utc(2026, 10, 7, 12);
      final reported = <DateTime>[];
      final gate = UsageLimitGate(now: () => clock, onHit: reported.add);
      expect(gate.limitedUntil, isNull);

      final reset = DateTime.utc(2026, 10, 7, 15);
      gate.hit(reset);
      gate.hit(DateTime.utc(2026, 10, 7, 14)); // an earlier reset is ignored
      expect(gate.limitedUntil, reset);
      expect(reported, [reset]);

      clock = DateTime.utc(2026, 10, 7, 15, 1);
      expect(gate.limitedUntil, isNull);
    });

    test('waits for the reset', () async {
      final gate = UsageLimitGate();
      expect(await gate.wait(), isFalse);

      gate.hit(DateTime.now().add(const Duration(milliseconds: 50)));
      final told = <DateTime>[];
      final stopwatch = Stopwatch()..start();
      expect(await gate.wait(onWaiting: told.add), isTrue);
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
      expect(told, hasLength(1));
    });
  });
}
