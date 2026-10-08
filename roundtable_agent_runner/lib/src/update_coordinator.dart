import 'agent_work_queue.dart';
import 'runner_update.dart';

/// Applies a runner update the panel requested (docs/FLOWS.md §2). The
/// update restarts this service, which would kill the `claude` runs in
/// progress, so it waits for them: new work is held back
/// ([AgentWorkQueue.drain]) and the update is handed off to the root-side
/// updater once no agent is busy. Held work is let go if the request is
/// withdrawn or can't be handed off.
class UpdateCoordinator {
  UpdateCoordinator({
    required this.workQueue,
    required this.updateFlagPath,
    required this.log,
    this._requestUpdate = requestRunnerUpdate,
  });

  final AgentWorkQueue workQueue;

  /// The file the root-side updater watches; null for an install that
  /// predates in-panel updates.
  final String? updateFlagPath;
  final void Function(String message) log;
  final bool Function(String flagPath) _requestUpdate;

  var _handedOff = false;

  /// Called on every check-in with whether an update is requested.
  void onCheckIn({required bool updateRequested}) {
    if (!updateRequested) {
      if (workQueue.isDraining && !_handedOff) {
        log('update no longer requested, resuming work');
        workQueue.resume();
      }
      return;
    }
    if (_handedOff) return;
    final flagPath = updateFlagPath;
    if (flagPath == null) {
      log(
        'update requested, but this install has no updater — re-run '
        'scripts/install-agent.sh once to enable in-panel updates',
      );
      // Logged once per process; nothing to wait for.
      _handedOff = true;
      return;
    }
    workQueue.drain();
    if (!workQueue.isIdle) {
      log(
        'update requested, waiting for ${workQueue.currentWorks.join(', ')} '
        'to finish',
      );
      return;
    }
    // Once per process: the updater restarts this service, so the next
    // process reports the new version and the server clears the request.
    if (!_requestUpdate(flagPath)) {
      log('update requested, but could not write $flagPath');
      workQueue.resume();
      return;
    }
    log('update requested, handed off to agent-runner-update');
    _handedOff = true;
  }
}
