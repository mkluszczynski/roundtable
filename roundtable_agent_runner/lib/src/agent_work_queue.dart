import 'dart:async';

/// One piece of work at a time per agent: a task run or a code review
/// (docs/FLOWS.md §5). Shared by `TaskDispatcher` and `ReviewDispatcher`, so
/// an agent never runs two `claude` processes at once — work for a busy
/// agent waits its turn, first come first served. An agent that should do
/// more in parallel is a second agent.
class AgentWorkQueue {
  final _tails = <int, Future<void>>{};
  final _current = <int, String>{};

  /// Completes when [resume] lifts a [drain]; null while not draining.
  Completer<void>? _drained;

  /// What [agentId] is doing right now (`task #12`, `review of task #4`), or
  /// null when it's free.
  String? currentWork(int agentId) => _current[agentId];

  /// What every busy agent is doing right now, e.g. for a log line.
  Iterable<String> get currentWorks => _current.values;

  /// Whether no agent is doing any work right now. Work held back by
  /// [drain] doesn't count.
  bool get isIdle => _current.isEmpty;

  /// Whether [drain] is holding back new work.
  bool get isDraining => _drained != null;

  /// Holds back work that hasn't started yet until [resume], so the work
  /// already running can finish and leave the daemon idle for an update
  /// (docs/FLOWS.md §2). Held work waits with [onWaiting] called with
  /// [drainLabel].
  void drain() => _drained ??= Completer<void>();

  /// Lets the work held back by [drain] start.
  void resume() {
    _drained?.complete();
    _drained = null;
  }

  /// What work held back by [drain] is told it waits for.
  static const drainLabel = 'an agent runner update';

  /// Runs [body] once [agentId] is free. [onWaiting] is called first, with
  /// what the agent is busy with, if [body] has to wait. [label] describes
  /// this work to later callers' [onWaiting].
  Future<T> run<T>(
    int agentId,
    String label,
    Future<T> Function() body, {
    void Function(String busyWith)? onWaiting,
  }) async {
    final previous = _tails[agentId];
    final done = Completer<void>();
    _tails[agentId] = done.future;
    if (previous != null) {
      final busyWith = _current[agentId];
      if (busyWith != null) onWaiting?.call(busyWith);
      await previous;
    }
    for (var drained = _drained; drained != null; drained = _drained) {
      onWaiting?.call(drainLabel);
      await drained.future;
    }
    _current[agentId] = label;
    try {
      return await body();
    } finally {
      _current.remove(agentId);
      done.complete();
      if (identical(_tails[agentId], done.future)) _tails.remove(agentId);
    }
  }
}
