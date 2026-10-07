import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/utils/task_timeline.dart';

final _t0 = DateTime.utc(2026, 10, 7, 12);
DateTime _at(int minutes) => _t0.add(Duration(minutes: minutes));

TaskLogEntry _entry(
  String runId,
  LogPhase phase,
  LogKind kind,
  int minute, {
  String content = '',
  String? toolName,
  String? toolUseId,
  bool? isError,
}) => TaskLogEntry(
  taskId: 1,
  runId: runId,
  phase: phase,
  kind: kind,
  content: content,
  toolName: toolName,
  toolUseId: toolUseId,
  isError: isError,
  createdAt: _at(minute),
);

List<TaskLogEntry> _run(
  String id,
  LogPhase phase,
  int start,
  int? end, {
  List<TaskLogEntry> body = const [],
}) => [
  _entry(id, phase, LogKind.runStarted, start, content: 'Ana started'),
  ...body,
  if (end != null) _entry(id, phase, LogKind.runFinished, end),
];

Task _task(TaskStatus status) => Task(
  id: 1,
  projectId: 1,
  prompt: 'Add divide',
  status: status,
  createdAt: _t0,
  lastProgressAt: _at(60),
  finishedAt: status == TaskStatus.done ? _at(60) : null,
  prUrl: 'https://github.com/acme/demo/pull/1',
);

void main() {
  test('a whole task: planning with one revision, implementing, a review '
      'asking for changes, the fix, an approving review, merged', () {
    final steps = buildTaskTimeline(
      task: _task(TaskStatus.done),
      logs: [
        ..._run(
          'r1',
          LogPhase.planning,
          1,
          20,
          body: [
            for (final (i, (minute, answer)) in [
              (3, 'Revise: use Polish'),
              (6, 'User has approved your plan'),
            ].indexed) ...[
              _entry(
                'r1',
                LogPhase.planning,
                LogKind.toolCall,
                minute - 1,
                toolName: 'ExitPlanMode',
                toolUseId: 'p$i',
              ),
              _entry(
                'r1',
                LogPhase.planning,
                LogKind.toolResult,
                minute,
                content: answer,
                toolUseId: 'p$i',
                isError: i == 0,
              ),
            ],
          ],
        ),
        ..._run('r2', LogPhase.feedback, 31, 35),
      ],
      reviews: [
        CodeReview(
          id: 1,
          taskId: 1,
          status: CodeReviewStatus.completed,
          verdict: CodeReviewVerdict.changesRequested,
          createdAt: _at(21),
          finishedAt: _at(25),
        ),
        CodeReview(
          id: 2,
          taskId: 1,
          status: CodeReviewStatus.completed,
          verdict: CodeReviewVerdict.approve,
          createdAt: _at(36),
          finishedAt: _at(40),
        ),
      ],
      feedback: [
        TaskFeedback(
          taskId: 1,
          message: '1. divide.dart:1 [blocker] Guard b == 0',
          phase: TaskFeedbackPhase.review,
          kind: TaskFeedbackKind.reviewComments,
          createdAt: _at(30),
        ),
      ],
    );

    expect(
      [for (final s in steps) (s.label, s.detail)],
      [
        ('Created', null),
        ('Planning', 'Plan approved · 1 revision'),
        ('Implementing', null),
        ('AI review #1', 'Changes requested'),
        ('Fixing review comments', null),
        ('AI review #2', 'Approved'),
        ('Merged', null),
      ],
    );
    expect(steps[2].endedAt, _at(20));
    expect(steps[2].link, TimelineLink.log);
    expect(steps[3].link, TimelineLink.review);
  });

  test('the running step pulses and fix runs are named by their feedback', () {
    final steps = buildTaskTimeline(
      task: _task(TaskStatus.running),
      logs: [
        ..._run('r1', LogPhase.execution, 1, 10),
        ..._run('r2', LogPhase.feedback, 12, 14),
        ..._run('r3', LogPhase.feedback, 16, null),
      ],
      reviews: const [],
      feedback: [
        TaskFeedback(
          taskId: 1,
          message: 'CI failed',
          phase: TaskFeedbackPhase.review,
          kind: TaskFeedbackKind.checks,
          createdAt: _at(11),
        ),
        TaskFeedback(
          taskId: 1,
          message: 'Resolve conflicts',
          phase: TaskFeedbackPhase.review,
          kind: TaskFeedbackKind.conflicts,
          createdAt: _at(15),
        ),
      ],
    );

    expect(steps.map((s) => s.label), [
      'Created',
      'Implementing',
      'Fixing CI',
      'Resolving conflicts',
    ]);
    expect(steps.last.state, TimelineStepState.running);
    expect(steps[1].state, TimelineStepState.done);
  });
}
