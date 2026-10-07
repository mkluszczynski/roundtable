import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/cubits/agent_list_cubit.dart';
import 'package:roundtable_flutter/repositories/agent_repository.dart';
import 'package:roundtable_flutter/widgets/reviewer_select.dart';

Agent _agent(int id, String name) => Agent(
  id: id,
  name: name,
  machineId: 10,
  role: AgentRoleDefinition(id: 2, name: 'backend', prompt: 'p'),
  executionMode: AgentExecutionMode.native,
  status: AgentStatus.idle,
);

class _FakeAgentRepository implements AgentRepository {
  final agents = [_agent(1, 'Ada')];

  @override
  Future<List<Agent>> listAgents() async => [...agents];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<AgentListCubit> _pump(
  WidgetTester tester,
  _FakeAgentRepository repository, {
  int? selected,
}) async {
  final cubit = AgentListCubit(repository);
  await cubit.fetchAgents();
  addTearDown(cubit.close);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: ReviewerSelect(selected: selected, onChanged: (_) {}),
        ),
      ),
    ),
  );
  return cubit;
}

void main() {
  testWidgets('lists an agent added to the shared list after it was built', (
    tester,
  ) async {
    final repository = _FakeAgentRepository();
    final cubit = await _pump(tester, repository);

    await tester.tap(find.byType(ReviewerSelect));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Rex'), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    repository.agents.add(_agent(2, 'Rex'));
    await cubit.fetchAgents();
    // The cubit's stream notifies the widget a frame later.
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ReviewerSelect));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Rex'), findsOneWidget);
  });

  testWidgets('shows the selected agent from the shared list', (tester) async {
    await _pump(tester, _FakeAgentRepository(), selected: 1);

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Loading agents…'), findsNothing);
  });
}
