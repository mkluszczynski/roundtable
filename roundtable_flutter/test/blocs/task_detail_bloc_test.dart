import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/blocs/task_detail_bloc.dart';
import 'package:roundtable_flutter/repositories/agent_repository.dart';
import 'package:roundtable_flutter/repositories/machine_repository.dart';
import 'package:roundtable_flutter/repositories/project_repository.dart';
import 'package:roundtable_flutter/repositories/task_repository.dart';

Task _task(TaskStatus status, {String? title}) => Task(
  id: 1,
  projectId: 1,
  prompt: 'Fix the login bug',
  status: status,
  title: title,
);

class _FakeTaskRepository implements TaskRepository {
  final tasks = StreamController<Task>();
  Object? failWith;
  final calls = <String>[];

  Future<Task> _call(String name) async {
    calls.add(name);
    if (failWith case final error?) throw error;
    return _task(TaskStatus.running);
  }

  @override
  Stream<Task> watchTask(int taskId) => tasks.stream;

  @override
  Stream<TaskLogEntry> watchLogs(int taskId) => const Stream.empty();

  @override
  Stream<CodeReview> watchReviews(int taskId) => const Stream.empty();

  @override
  Stream<PrChecks> watchChecks(int taskId) => const Stream.empty();

  @override
  Future<List<TaskFeedback>> listFeedback(int taskId) async => const [];

  @override
  Future<Task> approvePlan(int taskId) => _call('approvePlan');

  @override
  Future<Task> retryTask(int taskId) => _call('retryTask');

  @override
  Future<Task> setTitle(int taskId, String? title) => _call('setTitle');

  @override
  Future<void> deleteTask(int taskId) => _call('deleteTask');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProjectRepository implements ProjectRepository {
  @override
  Future<Project?> getProject(int id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAgentRepository implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMachineRepository implements MachineRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeTaskRepository repository;
  late TaskDetailBloc bloc;

  /// Subscribes the bloc and waits for the first [TaskDetailLoaded].
  Future<TaskDetailLoaded> load(TaskStatus status) async {
    bloc.add(const TaskDetailSubscribed(1));
    repository.tasks.add(_task(status));
    return await bloc.stream.firstWhere((s) => s is TaskDetailLoaded)
        as TaskDetailLoaded;
  }

  /// The next state matching [test], after the bloc processes the event.
  Future<TaskDetailLoaded> next(bool Function(TaskDetailLoaded s) test) async =>
      await bloc.stream.firstWhere((s) => s is TaskDetailLoaded && test(s))
          as TaskDetailLoaded;

  setUp(() {
    repository = _FakeTaskRepository();
    bloc = TaskDetailBloc(
      repository,
      projectRepository: _FakeProjectRepository(),
      agentRepository: _FakeAgentRepository(),
      machineRepository: _FakeMachineRepository(),
    );
  });

  tearDown(() => bloc.close());

  test(
    'an action shows progress until watchTask delivers the result',
    () async {
      await load(TaskStatus.planReady);

      bloc.add(const PlanApproved(1));
      await next((s) => s.submitting);
      expect(repository.calls, ['approvePlan']);

      repository.tasks.add(_task(TaskStatus.running));
      final done = await next((s) => s.task.status == TaskStatus.running);
      expect(done.submitting, isFalse);
    },
  );

  test('a failed action keeps the task on screen with the error', () async {
    await load(TaskStatus.failed);
    repository.failWith = Exception('machine offline');

    bloc.add(const TaskRetried(1));
    final failed = await next((s) => s.actionError != null);

    expect(failed.submitting, isFalse);
    expect(failed.task.status, TaskStatus.failed);
    expect(failed.actionError, contains('machine offline'));
  });

  test('the next action clears the previous error', () async {
    await load(TaskStatus.failed);
    repository.failWith = Exception('machine offline');
    bloc.add(const TaskRetried(1));
    await next((s) => s.actionError != null);

    repository.failWith = null;
    bloc.add(const TaskRetried(1));
    final retrying = await next((s) => s.submitting);

    expect(retrying.actionError, isNull);
  });

  test('renaming does not show progress', () async {
    await load(TaskStatus.running);
    final states = <TaskDetailState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const TaskRenamed(1, 'Login fix'));
    await pumpEventQueue();
    await sub.cancel();

    expect(repository.calls, ['setTitle']);
    expect(
      states.whereType<TaskDetailLoaded>().any((s) => s.submitting),
      false,
    );
  });

  test('deleting the task ends in TaskDetailDeleted', () async {
    await load(TaskStatus.done);

    bloc.add(const TaskDeleteRequested(1));

    await expectLater(bloc.stream, emitsThrough(isA<TaskDetailDeleted>()));
  });

  test('a failed load is an error state', () async {
    bloc.add(const TaskDetailSubscribed(1));
    repository.tasks.addError(Exception('not found'));

    await expectLater(bloc.stream, emitsThrough(isA<TaskDetailError>()));
  });
}
