import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Deletes [MachineMetric] rows older than [retention]. The daemon reports a
/// sample every few seconds per machine and the panel only ever shows the
/// latest one, so without this the table grows without bound. Scheduled to
/// run recurringly from `server.dart`.
class MachineMetricCleanupFutureCall extends FutureCall {
  static const retention = Duration(hours: 1);

  Future<void> check(Session session) async {
    final cutoff = DateTime.now().toUtc().subtract(retention);
    await MachineMetric.db.deleteWhere(
      session,
      where: (t) => t.recordedAt < cutoff,
    );
  }
}
