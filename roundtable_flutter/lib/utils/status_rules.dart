import 'package:roundtable_client/roundtable_client.dart';

extension TaskPauseRules on Task {
  /// A review waiting for the Claude usage limit to reset, on a task in
  /// review (`pausedPhase` review).
  bool get isReviewPaused =>
      status == TaskStatus.awaitingReview && pausedPhase == LogPhase.review;

  /// When a run (or a review) paused by the usage limit resumes; null when
  /// nothing is paused.
  DateTime? get pausedUntilNow =>
      status == TaskStatus.paused || isReviewPaused ? pausedUntil : null;
}

extension MachineRules on Machine {
  bool get isOnline => status == MachineStatus.online;
}
