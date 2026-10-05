import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/cubits/dashboard_cubit.dart';
import 'package:roundtable_flutter/widgets/agent_row.dart';

Agent _agent({AgentStatus status = AgentStatus.busy}) => Agent(
  id: 1,
  name: 'Ada',
  machineId: 1,
  role: AgentRoleDefinition(id: 4, name: 'fullstack', prompt: 'p'),
  executionMode: AgentExecutionMode.native,
  status: status,
);

Task _task(int id, TaskStatus status, {int? agentId = 1}) => Task(
  id: id,
  projectId: 1,
  agentId: agentId,
  prompt: 'Task $id\nmore detail',
  status: status,
);

void main() {
  testWidgets('shows status and links the current task', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgentRow(
            agent: _agent(),
            currentTask: _task(21, TaskStatus.running),
          ),
        ),
      ),
    );

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('busy'), findsOneWidget);
    expect(find.text('#21'), findsOneWidget);
    expect(find.text('Task 21'), findsOneWidget);
    expect(find.text('fullstack'), findsOneWidget);
  });

  testWidgets('compact mode hides role and chips', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgentRow(
            agent: _agent(status: AgentStatus.idle),
            showDetails: false,
          ),
        ),
      ),
    );

    expect(find.text('idle'), findsOneWidget);
    expect(find.text('fullstack'), findsNothing);
    expect(find.textContaining('effort'), findsNothing);
  });

  test('currentTaskFor ignores finished, review and other agents', () {
    final state = DashboardLoaded({
      1: _task(1, TaskStatus.done),
      2: _task(2, TaskStatus.awaitingReview),
      3: _task(3, TaskStatus.running, agentId: 2),
      4: _task(4, TaskStatus.planning),
    });
    expect(state.currentTaskFor(1)?.id, 4);
    expect(state.currentTaskFor(3), isNull);
  });
}
