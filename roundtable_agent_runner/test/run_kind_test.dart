import 'package:roundtable_agent_runner/roundtable_agent_runner.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:test/test.dart';

Task _queued({bool skipPlanning = false, LogPhase? pausedPhase}) => Task(
  id: 1,
  projectId: 1,
  prompt: 'Fix the login bug',
  status: TaskStatus.queued,
  skipPlanning: skipPlanning,
  pausedPhase: pausedPhase,
);

void main() {
  group('RunKind.queued', () {
    test('a fresh task plans first', () {
      final kind = RunKind.queued(_queued());
      expect(kind, isA<FreshRun>());
      expect(kind.needsPlanning, isTrue);
      expect(kind.phase, LogPhase.planning);
    });

    test('skipPlanning goes straight to execution', () {
      final kind = RunKind.queued(_queued(skipPlanning: true));
      expect(kind.needsPlanning, isFalse);
      expect(kind.phase, LogPhase.execution);
    });

    test('a paused task continues in the phase it was paused in', () {
      final planning = RunKind.queued(
        _queued(skipPlanning: true, pausedPhase: LogPhase.planning),
      );
      expect(planning, isA<PauseResume>());
      expect(planning.needsPlanning, isTrue);

      final feedback = RunKind.queued(_queued(pausedPhase: LogPhase.feedback));
      expect(feedback.needsPlanning, isFalse);
      expect(feedback.phase, LogPhase.feedback);
    });
  });

  test('a feedback resume never plans', () {
    const kind = FeedbackResume('Rename the button');
    expect(kind.needsPlanning, isFalse);
    expect(kind.phase, LogPhase.feedback);
  });

  group('runOutcome', () {
    test('a failure fails the task without an event', () {
      final outcome = runOutcome(
        failureReason: 'boom',
        finishedWithoutCode: false,
      );
      expect(outcome, (status: TaskStatus.failed, event: null));
    });

    test('no code changes finish the task', () {
      final outcome = runOutcome(
        failureReason: null,
        finishedWithoutCode: true,
      );
      expect(outcome.status, TaskStatus.done);
    });

    test('a new PR goes to review', () {
      final outcome = runOutcome(
        failureReason: null,
        finishedWithoutCode: false,
        branchName: 'task-1',
        prUrl: 'https://github.com/acme/app/pull/1',
      );
      expect(outcome.status, TaskStatus.awaitingReview);
      expect(outcome.event, contains('opened pull request'));
    });

    test('new commits on an existing PR', () {
      final outcome = runOutcome(
        failureReason: null,
        finishedWithoutCode: false,
        branchName: 'task-1',
      );
      expect(outcome.event, 'Pushed new commits to task-1');
    });
  });

  test('planning mirrors the task status into the agent status', () {
    expect(
      planningAgentStatus(TaskStatus.planReady),
      AgentStatus.waitingForResponse,
    );
    expect(
      planningAgentStatus(TaskStatus.waitingForAnswer),
      AgentStatus.waitingForResponse,
    );
    expect(planningAgentStatus(TaskStatus.planning), AgentStatus.busy);
    expect(planningAgentStatus(TaskStatus.running), isNull);
  });
}
