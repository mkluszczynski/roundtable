import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/cubits/dashboard_cubit.dart';

Task _task(TaskStatus status) =>
    Task(id: 1, projectId: 1, prompt: 'Fix the login bug', status: status);

void main() {
  test('counts working tasks, tasks waiting on the dev, busy agents and '
      'online machines', () {
    final stats = DashboardStats.from(
      tasks: [
        _task(TaskStatus.cloning),
        _task(TaskStatus.running),
        _task(TaskStatus.planReady),
        _task(TaskStatus.awaitingReview),
        // Failed needs attention but isn't waiting on the dev.
        _task(TaskStatus.failed),
        _task(TaskStatus.done),
      ],
      agents: [
        Agent(id: 1, machineId: 1, name: 'Ana', status: AgentStatus.busy),
        Agent(id: 2, machineId: 1, name: 'Rex', status: AgentStatus.idle),
      ],
      machines: [
        Machine(name: 'VPS', status: MachineStatus.online),
        Machine(name: 'Laptop', status: MachineStatus.offline),
      ],
    );

    expect(stats.running, 2);
    expect(stats.waiting, 2);
    expect((stats.busyAgents, stats.agents), (1, 2));
    expect((stats.onlineMachines, stats.machines), (1, 2));
  });
}
