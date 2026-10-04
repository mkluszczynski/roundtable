import '../generated/protocol.dart';
import '../task_lifecycle.dart';
import 'package:serverpod/serverpod.dart';

/// Resumes tasks paused by a Claude usage limit once their `pausedUntil`
/// has passed. Scheduled to run recurringly from `server.dart`.
class PausedTaskResumeFutureCall extends FutureCall {
  Future<void> check(Session session) async {
    final due = await Task.db.find(
      session,
      where: (t) =>
          t.status.equals(TaskStatus.paused) &
          (t.pausedUntil <= DateTime.now().toUtc()),
    );
    for (final task in due) {
      await resumePausedTask(session, task);
    }
  }
}
