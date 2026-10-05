import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/widgets/agent_picker.dart';

Machine _machine(int id, String name, MachineStatus status) => Machine(
  id: id,
  name: name,
  status: status,
);

Agent _agent(int id, String name, int machineId, {AgentStatus? status}) =>
    Agent(
      id: id,
      name: name,
      machineId: machineId,
      role: AgentRoleDefinition(id: 2, name: 'backend', prompt: 'p'),
      executionMode: AgentExecutionMode.native,
      status: status ?? AgentStatus.idle,
    );

Future<List<int?>> _pump(
  WidgetTester tester, {
  bool allowNone = false,
  AgentAvailability? unavailableReason,
}) async {
  final picks = <int?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AgentPickerList(
          agents: [
            _agent(1, 'Ada', 10),
            _agent(2, 'Bob', 20, status: AgentStatus.busy),
          ],
          machines: [
            _machine(10, 'vps', MachineStatus.online),
            _machine(20, 'laptop', MachineStatus.offline),
          ],
          selected: 1,
          onChanged: picks.add,
          allowNone: allowNone,
          currentAgentId: 1,
          unavailableReason: unavailableReason,
        ),
      ),
    ),
  );
  return picks;
}

void main() {
  testWidgets('groups agents under their machine with details', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('VPS'), findsOneWidget);
    expect(find.text('LAPTOP'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('backend specialist'), findsNWidgets(2));
    expect(find.text('current'), findsOneWidget);
    expect(find.text('Machine offline — the task will wait'), findsOneWidget);
  });

  testWidgets('tapping an agent picks it', (tester) async {
    final picks = await _pump(tester);
    await tester.tap(find.text('Bob'));
    expect(picks, [2]);
  });

  testWidgets('an unavailable agent shows why and cannot be picked', (
    tester,
  ) async {
    final picks = await _pump(
      tester,
      unavailableReason: (agent, _) =>
          agent.status == AgentStatus.busy ? 'Busy' : null,
    );
    expect(find.text('Busy'), findsOneWidget);
    await tester.tap(find.text('Bob'));
    expect(picks, isEmpty);
  });

  testWidgets('offers a "none" option when allowed', (tester) async {
    final picks = await _pump(tester, allowNone: true);
    await tester.tap(find.text('None (draft)'));
    expect(picks, [null]);
  });
}
