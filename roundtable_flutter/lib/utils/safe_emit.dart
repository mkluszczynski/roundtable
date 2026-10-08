import 'package:flutter_bloc/flutter_bloc.dart';

/// Drops states emitted after the Cubit closed. A request started from a
/// dialog can finish after the dialog (and its Cubit) is gone; a plain
/// `emit` would then throw "Cannot emit new states after calling close".
mixin SafeEmit<S> on BlocBase<S> {
  @override
  void emit(S state) {
    if (isClosed) return;
    super.emit(state);
  }
}
