import 'package:roundtable_client/roundtable_client.dart';

extension TaskStatusLabel on TaskStatus {
  String get label => switch (this) {
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
  };
}
