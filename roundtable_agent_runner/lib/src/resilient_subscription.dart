import 'dart:async';

/// A subscription to a server stream that resubscribes after [retryDelay]
/// whenever the stream errors or closes (e.g. a transient WebSocket
/// hiccup). Without it, one dropped stream would silently and permanently
/// stop the daemon from picking up work, while its heartbeat kept it
/// looking "online".
class ResilientSubscription<T> {
  ResilientSubscription({
    required this.name,
    required this.subscribe,
    required this.onData,
    required this.log,
    this.retryDelay = const Duration(seconds: 5),
  });

  /// The stream's name in the log, e.g. `watchAssignedTasks`.
  final String name;
  final Stream<T> Function() subscribe;
  final void Function(T event) onData;
  final void Function(String message) log;
  final Duration retryDelay;

  StreamSubscription<T>? _subscription;
  Timer? _retry;
  var _cancelled = false;

  void start() {
    if (_cancelled) return;
    _subscription = subscribe().listen(
      onData,
      onError: (Object error) {
        log('$name stream error: $error — resubscribing');
        _scheduleRetry();
      },
      onDone: () {
        if (_cancelled) return;
        log('$name stream closed unexpectedly — resubscribing');
        _scheduleRetry();
      },
    );
  }

  void _scheduleRetry() {
    if (_cancelled) return;
    _retry?.cancel();
    _subscription?.cancel();
    _retry = Timer(retryDelay, start);
  }

  void cancel() {
    _cancelled = true;
    _retry?.cancel();
    _subscription?.cancel();
  }
}
