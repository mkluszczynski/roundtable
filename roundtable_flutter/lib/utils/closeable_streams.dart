import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Ties long-lived server streams to a Bloc/Cubit's lifetime.
///
/// An `await for` over a Serverpod stream keeps its subscription open after
/// the Bloc/Cubit closes — `close()` doesn't cancel a running loop — so
/// every screen visit would leak a server-side stream. Wrap each stream in
/// [untilClosed]: on `close()` the upstream subscription is cancelled and
/// the wrapped stream completes, which ends the `await for`.
mixin CloseableStreams<S> on BlocBase<S> {
  final List<StreamController<Object?>> _controllers = [];

  Stream<T> untilClosed<T>(Stream<T> source) {
    late final StreamController<T> controller;
    StreamSubscription<T>? subscription;
    controller = StreamController<T>(
      onListen: () {
        subscription = source.listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            _controllers.remove(controller);
            controller.close();
          },
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    _controllers.add(controller);
    return controller.stream;
  }

  /// [untilClosed] for a server stream that must stay live: when it errors
  /// or ends (server restart, lost network, laptop asleep) while this is
  /// open, it's opened again after a backoff of 1 s, doubling up to 30 s.
  /// [onDrop] is told each time it drops; [onReopen] runs before each new
  /// attempt, e.g. to catch up on what was missed meanwhile — a failure
  /// there just means the server is still away.
  Stream<T> keepAlive<T>(
    Stream<T> Function() open, {
    void Function()? onDrop,
    Future<void> Function()? onReopen,
  }) async* {
    var delay = const Duration(seconds: 1);
    for (var attempt = 0; !isClosed; attempt++) {
      if (attempt > 0) {
        try {
          await onReopen?.call();
        } catch (_) {
          // Still unreachable: the stream's own attempt below says so.
        }
      }
      try {
        await for (final event in untilClosed(open())) {
          delay = const Duration(seconds: 1);
          yield event;
        }
      } catch (_) {
        // Dropped with an error: reconnect like after a plain close.
      }
      if (isClosed) return;
      onDrop?.call();
      await Future<void>.delayed(delay);
      delay = delay * 2 > _maxReconnectDelay ? _maxReconnectDelay : delay * 2;
    }
  }

  static const _maxReconnectDelay = Duration(seconds: 30);

  @override
  Future<void> close() async {
    for (final controller in List.of(_controllers)) {
      await controller.close();
    }
    _controllers.clear();
    return super.close();
  }
}
