import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/blocs/task_detail_bloc.dart';

Task _task(
  TaskStatus status, {
  String? prUrl,
  String? branchName,
  String? currentPlan,
  PrCheckState checkState = PrCheckState.none,
}) => Task(
  id: 1,
  projectId: 1,
  prompt: 'Fix the login bug',
  status: status,
  prUrl: prUrl,
  branchName: branchName,
  currentPlan: currentPlan,
  checkState: checkState,
);

TaskDetailLoaded _state(Task task, {bool conflicts = false}) =>
    TaskDetailLoaded(
      task: task,
      mergeStatus: conflicts
          ? PrMergeStatus(hasConflicts: true, baseBranch: 'main')
          : null,
    );

const _pr = 'https://github.com/acme/app/pull/1';

void main() {
  group('availableActions', () {
    test('a task in review with green checks can be accepted', () {
      final state = _state(
        _task(
          TaskStatus.awaitingReview,
          prUrl: _pr,
          checkState: PrCheckState.success,
        ),
      );
      expect(state.availableActions, [TaskAction.accept, TaskAction.cancel]);
    });

    test('failing checks offer a fix and a merge anyway', () {
      final state = _state(
        _task(
          TaskStatus.awaitingReview,
          prUrl: _pr,
          checkState: PrCheckState.failure,
        ),
      );
      expect(state.availableActions, [
        TaskAction.fixChecks,
        TaskAction.accept,
        TaskAction.mergeAnyway,
        TaskAction.cancel,
      ]);
    });

    test('pending checks block the merge but need no fix', () {
      final state = _state(
        _task(
          TaskStatus.awaitingReview,
          prUrl: _pr,
          checkState: PrCheckState.pending,
        ),
      );
      expect(state.mergeBlockedByChecks, isNotNull);
      expect(state.availableActions, [
        TaskAction.accept,
        TaskAction.mergeAnyway,
        TaskAction.cancel,
      ]);
    });

    test('conflicts replace every merge action', () {
      final state = _state(
        _task(
          TaskStatus.awaitingReview,
          prUrl: _pr,
          checkState: PrCheckState.failure,
        ),
        conflicts: true,
      );
      expect(state.availableActions, [
        TaskAction.resolveConflicts,
        TaskAction.cancel,
      ]);
    });

    test('a failed task can be retried or deleted', () {
      expect(_state(_task(TaskStatus.failed)).availableActions, [
        TaskAction.retry,
        TaskAction.delete,
      ]);
    });

    test('a done task offers a follow-up', () {
      expect(_state(_task(TaskStatus.done)).availableActions, [
        TaskAction.followUp,
        TaskAction.delete,
      ]);
    });

    test('a running task can only be cancelled', () {
      expect(_state(_task(TaskStatus.running)).availableActions, [
        TaskAction.cancel,
      ]);
    });
  });

  group('sections', () {
    test('a live task opens on its log and has no overview', () {
      final state = _state(_task(TaskStatus.running));
      expect(state.task.defaultSection, TaskSection.logs);
      expect(state.availableSections, {TaskSection.logs});
    });

    test('a done task with a PR opens on its changes', () {
      final state = _state(_task(TaskStatus.done, prUrl: _pr));
      expect(state.task.defaultSection, TaskSection.changes);
      expect(state.availableSections, {
        TaskSection.changes,
        TaskSection.review,
        TaskSection.checks,
        TaskSection.logs,
      });
    });

    test('a done task without code changes shows its result in overview', () {
      final state = _state(_task(TaskStatus.done));
      expect(state.task.defaultSection, TaskSection.overview);
      expect(state.availableSections, {TaskSection.overview, TaskSection.logs});
    });

    test('the plan tab is hidden while the plan awaits approval', () {
      final plan = 'Do it';
      expect(
        _state(
          _task(TaskStatus.planReady, currentPlan: plan),
        ).availableSections,
        isNot(contains(TaskSection.plan)),
      );
      expect(
        _state(_task(TaskStatus.running, currentPlan: plan)).availableSections,
        contains(TaskSection.plan),
      );
    });
  });
}
