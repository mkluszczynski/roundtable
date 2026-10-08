import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/cubits/dashboard_cubit.dart';
import 'package:roundtable_flutter/repositories/task_repository.dart';

Task _task(int id) =>
    Task(id: id, projectId: 1, prompt: 'Task $id', status: TaskStatus.queued);

class _FakeTaskRepository implements TaskRepository {
  final taskStreams = <StreamController<Task>>[];
  Set<int> existing = {};

  @override
  Stream<Task> watchAllTasks() {
    final controller = StreamController<Task>();
    taskStreams.add(controller);
    return controller.stream;
  }

  @override
  Stream<TaskDeleted> watchTaskDeletions() => const Stream.empty();

  @override
  Future<List<Task>> findTasks(List<int> taskIds) async => [
    for (final id in taskIds)
      if (existing.contains(id)) _task(id),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a dropped stream keeps the board, says so, reconnects and drops '
      'tasks deleted meanwhile', () async {
    final repository = _FakeTaskRepository();
    final cubit = DashboardCubit(repository);
    await cubit.subscribe();
    await pumpEventQueue();

    repository.taskStreams.last
      ..add(_task(1))
      ..add(_task(2));
    await pumpEventQueue();

    // The server restarts; task 2 is deleted while the panel is away.
    repository.existing = {1};
    await repository.taskStreams.last.close();
    await pumpEventQueue();

    final dropped = cubit.state as DashboardLoaded;
    expect(dropped.reconnecting, isTrue);
    expect(dropped.tasks.keys, {1, 2}, reason: 'the last known board stays');

    // Back after the 1 s backoff.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final back = cubit.state as DashboardLoaded;
    expect(back.reconnecting, isFalse);
    expect(back.tasks.keys, {1});
    expect(repository.taskStreams, hasLength(2));

    await cubit.close();
  });

  test('an erroring stream reconnects too, without an error screen', () async {
    final repository = _FakeTaskRepository();
    final cubit = DashboardCubit(repository);
    await cubit.subscribe();
    await pumpEventQueue();

    repository.taskStreams.last.addError(Exception('connection lost'));
    await pumpEventQueue();

    expect(cubit.state, isA<DashboardLoaded>());
    expect((cubit.state as DashboardLoaded).reconnecting, isTrue);
    await cubit.close();
  });
}
