/// How long to wait before each retry of a status report that failed.
const defaultRetryDelays = [
  Duration(seconds: 1),
  Duration(seconds: 5),
  Duration(seconds: 15),
];

/// Runs [call], retrying after each of [delays] when it throws. For the
/// final status reports of a run (failed, idle): a server that's briefly
/// unreachable must not leave a task `running` or an agent `busy` for good.
/// Never throws; returns whether [call] eventually succeeded.
Future<bool> retrying(
  String what,
  Future<void> Function() call, {
  required void Function(String message) log,
  List<Duration> delays = defaultRetryDelays,
}) async {
  for (var attempt = 0; ; attempt++) {
    try {
      await call();
      return true;
    } catch (e) {
      if (attempt >= delays.length) {
        log('$what failed, giving up: $e');
        return false;
      }
      log('$what failed, retrying: $e');
      await Future<void>.delayed(delays[attempt]);
    }
  }
}
