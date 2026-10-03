import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/widgets/machine_metrics.dart';

void main() {
  testWidgets('formats CPU as percent and RAM in GiB', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MachineMetricBars(
            metric: MachineMetric(
              machineId: 1,
              cpuPercent: 42.4,
              memoryUsedMb: 3072,
              memoryTotalMb: 8192,
            ),
          ),
        ),
      ),
    );

    expect(find.text('42%'), findsOneWidget);
    expect(find.text('3.0G'), findsOneWidget);
  });

  testWidgets('a zero memory total does not divide by zero', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MachineMetricBars(
            metric: MachineMetric(
              machineId: 1,
              cpuPercent: 0,
              memoryUsedMb: 0,
              memoryTotalMb: 0,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
