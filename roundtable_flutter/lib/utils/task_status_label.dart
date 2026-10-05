import 'package:roundtable_client/roundtable_client.dart';

extension TaskStatusLabel on TaskStatus {
  String get label => switch (this) {
    TaskStatus.draft => 'draft',
    TaskStatus.queued => 'queued',
    TaskStatus.cloning => 'cloning',
    TaskStatus.planning => 'planning',
    TaskStatus.waitingForAnswer => 'waiting for answer',
    TaskStatus.planReady => 'plan ready',
    TaskStatus.running => 'running',
    TaskStatus.awaitingReview => 'awaiting review',
    TaskStatus.done => 'done',
    TaskStatus.failed => 'failed',
    TaskStatus.cancelled => 'cancelled',
    TaskStatus.paused => 'paused',
  };
}

/// "00:40" — when a paused task resumes, in local time.
String resumeTimeLabel(DateTime at) {
  final local = at.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
