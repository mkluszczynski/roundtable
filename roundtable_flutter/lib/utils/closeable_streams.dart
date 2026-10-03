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
          onDone: controller.close,
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    _controllers.add(controller);
    return controller.stream;
  }

  @override
  Future<void> close() async {
    for (final controller in _controllers) {
      await controller.close();
    }
    _controllers.clear();
    return super.close();
  }
}
