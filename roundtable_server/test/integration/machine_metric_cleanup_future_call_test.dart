import 'package:roundtable_server/src/future_calls/machine_metric_cleanup_future_call.dart';
import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given MachineMetricCleanupFutureCall', (sessionBuilder, _) {
    test(
      'when it runs then metrics older than the retention window are deleted',
      () async {
        final session = sessionBuilder.build();
        final machine = await Machine.db.insertRow(
          session,
          Machine(name: 'VPS'),
        );
        MachineMetric metric(Duration age) => MachineMetric(
          machineId: machine.id!,
          cpuPercent: 10,
          memoryUsedMb: 100,
          memoryTotalMb: 1000,
          recordedAt: DateTime.now().toUtc().subtract(age),
        );
        final old = await MachineMetric.db.insertRow(
          session,
          metric(
            MachineMetricCleanupFutureCall.retention +
                const Duration(minutes: 1),
          ),
        );
        final fresh = await MachineMetric.db.insertRow(
          session,
          metric(const Duration(minutes: 1)),
        );

        await MachineMetricCleanupFutureCall().check(session);

        expect(await MachineMetric.db.findById(session, old.id!), isNull);
        expect(await MachineMetric.db.findById(session, fresh.id!), isNotNull);
      },
    );
  });
}
