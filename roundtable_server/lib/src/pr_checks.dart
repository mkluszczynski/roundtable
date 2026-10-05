import 'package:serverpod/serverpod.dart';

import 'endpoints/task_endpoint.dart';
import 'generated/protocol.dart';
import 'github_repo_client.dart';
import 'task_review_support.dart';

/// GitHub Actions checks on a task's PR (docs/FLOWS.md §4 "CI checks"):
/// mirrored into [PrCheckRun] rows and `Task.checkState` by [syncChecks],
/// which `PrChecksFutureCall` runs for every task in review — every 30 s
/// while the checks are pending, every [settledPollInterval] once they
/// settled. Kept out of the endpoint classes so none of it is exposed as an
/// RPC.

/// Channel the panel's `TaskEndpoint.watchChecks` listens on.
String channelForTaskChecks(int taskId) => 'task-$taskId-checks';

/// How long a new head commit without any workflow run counts as "CI hasn't
/// started yet" (pending) rather than "this repo has no CI" (mergeable).
const noCiGracePeriod = Duration(minutes: 2);

/// How often settled checks (success/failure/none) are polled — only a
/// manual push or a re-run on GitHub can change them, and the agent's own
/// pushes are synced right away by `TaskEndpoint.update`.
const settledPollInterval = Duration(minutes: 5);

/// When each task's checks were last synced. In memory on purpose: losing it
/// on a restart only means one early poll.
final _lastSyncedAt = <int, DateTime>{};

/// Forgets when tasks were last synced, so the next poll syncs them all.
/// For tests.
void resetChecksPollSchedule() => _lastSyncedAt.clear();

/// Whether `PrChecksFutureCall` should sync [task] now.
bool shouldPollChecks(Task task, {DateTime? now}) {
  if (task.checkState == PrCheckState.pending) return true;
  final last = _lastSyncedAt[task.id];
  if (last == null) return true;
  final current = now ?? DateTime.now().toUtc();
  return current.difference(last) >= settledPollInterval;
}

/// Prompt budget for the failing jobs' logs [sendFailingChecksToFix] sends.
const _maxPromptLogChars = 20000;

const _passingConclusions = {'success', 'skipped', 'neutral'};

/// Whether [run] finished without passing.
bool isFailedCheck(PrCheckRun run) =>
    run.status == 'completed' &&
    run.conclusion != null &&
    !_passingConclusions.contains(run.conclusion);

/// Whether [run] hasn't finished yet.
bool isPendingCheck(PrCheckRun run) => run.status != 'completed';

/// The aggregated state of [runs] (the jobs of one head commit).
/// [hasUnstartedRuns] is true when a workflow run has no jobs yet; with no
/// runs at all, a commit first seen at [headSeenAt] is `pending` for
/// [noCiGracePeriod] before it counts as `none`.
PrCheckState aggregateCheckState(
  List<PrCheckRun> runs, {
  bool hasUnstartedRuns = false,
  DateTime? headSeenAt,
  DateTime? now,
}) {
  if (runs.any(isFailedCheck)) return PrCheckState.failure;
  if (hasUnstartedRuns || runs.any(isPendingCheck)) {
    return PrCheckState.pending;
  }
  if (runs.isNotEmpty) return PrCheckState.success;
  final current = now ?? DateTime.now().toUtc();
  if (headSeenAt != null && current.difference(headSeenAt) < noCiGracePeriod) {
    return PrCheckState.pending;
  }
  return PrCheckState.none;
}

/// Why `acceptTask` must not merge [task] yet given its current checks
/// [runs], or null when the checks allow it. [fixRunQueued]: a fix run was
/// sent to the agent but hasn't run yet, so the PR is about to change.
String? mergeBlockedReason(
  Task task,
  List<PrCheckRun> runs, {
  bool fixRunQueued = false,
}) {
  if (fixRunQueued) {
    return 'A fix run is queued for the agent — wait for its push before '
        'merging.';
  }
  switch (task.checkState) {
    case PrCheckState.success:
    case PrCheckState.none:
      return null;
    case PrCheckState.failure:
      final failed = runs.where(isFailedCheck).length;
      return 'CI checks are failing ($failed failed) — fix them, send them '
          'to the agent, or merge anyway.';
    case PrCheckState.pending:
      final pending = runs.where(isPendingCheck).length;
      if (pending == 0) {
        return 'Waiting for CI to start on the latest commit '
            '(${shortSha(task.prHeadSha)}) — try again in a moment.';
      }
      return 'CI checks are still running ($pending pending) — wait for them '
          'before merging.';
  }
}

/// The first 7 characters of [sha], like GitHub shows it.
String shortSha(String? sha) =>
    sha == null ? '?' : sha.substring(0, sha.length < 7 ? sha.length : 7);

/// The [PrChecks] snapshot of [task] the panel renders.
Future<PrChecks> loadChecks(Session session, Task task) async {
  final runs = await PrCheckRun.db.find(
    session,
    where: (r) => r.taskId.equals(task.id!),
    orderBy: (r) => r.id,
  );
  return PrChecks(
    taskId: task.id!,
    headSha: task.prHeadSha,
    state: task.checkState,
    error: task.checkError,
    runs: runs,
  );
}

/// Whether review feedback was sent to [task]'s agent that its daemon hasn't
/// picked up yet — the same "newer than `finishedAt`" rule the daemon's
/// `TaskDispatcher` uses to tell a pending resume from a consumed one.
Future<bool> hasQueuedFixRun(
  Session session,
  Task task, {
  Transaction? transaction,
}) async {
  if (task.status != TaskStatus.awaitingReview) return false;
  final finishedAt = task.finishedAt;
  final queued = await TaskFeedback.db.count(
    session,
    where: (f) {
      final review =
          f.taskId.equals(task.id!) & f.phase.equals(TaskFeedbackPhase.review);
      return finishedAt == null ? review : review & (f.createdAt > finishedAt);
    },
    transaction: transaction,
  );
  return queued > 0;
}

/// Reads [task]'s PR head and its GitHub Actions jobs, stores them as
/// [PrCheckRun] rows and `Task.checkState`, and notifies the panel of any
/// change. A new head commit (a fix run's push, a manual push) replaces the
/// previous commit's checks. Logs a timeline event when the checks fail or
/// pass, and sends a failure to the agent when the task's auto-fix is on.
/// Returns the task as stored afterwards.
///
/// Throws when the task has no PR or token, or when GitHub fails — see
/// [syncChecksQuietly] for the best-effort variant.
Future<Task> syncChecks(
  Session session,
  Task task, {
  ({String prUrl, String token})? context,
}) async {
  final taskId = task.id!;
  context ??= await repoContextFor(session, taskId);
  final github = gitHubRepoClient;
  final head = await github.getPrHead(
    prUrl: context.prUrl,
    token: context.token,
  );
  // A PR merged or closed on GitHub keeps its last known checks.
  if (!head.open) return task;
  final (:owner, :repo, number: _) = github.parsePrUrl(context.prUrl);

  final now = DateTime.now().toUtc();
  final previousSha = task.prHeadSha;
  final newCommit = head.sha != previousSha;
  final headSeenAt = newCommit ? now : task.prHeadSeenAt;

  final stored = await PrCheckRun.db.find(
    session,
    where: (r) => r.taskId.equals(taskId),
    orderBy: (r) => r.id,
  );
  final cachedForSha = newCommit ? const <PrCheckRun>[] : stored;

  var fresh = <PrCheckRun>[];
  var hasUnstartedRuns = false;
  String? checkError;
  try {
    (fresh, hasUnstartedRuns) = await _fetchJobs(
      github,
      taskId: taskId,
      owner: owner,
      repo: repo,
      headSha: head.sha,
      token: context.token,
      cachedForSha: cachedForSha,
    );
  } on GitHubException catch (e) {
    if (e.statusCode != 403 && e.statusCode != 404) rethrow;
    // Typically a token created before CI checks existed, without "Actions:
    // Read". Report the checks as unknown rather than blocking the PR —
    // GitHub's own branch protection still applies to the merge.
    session.log(
      'Cannot read the CI checks of task $taskId: ${e.message}',
      level: LogLevel.warning,
    );
    checkError = e.message;
  }

  final fixRunQueued = await hasQueuedFixRun(session, task);
  final state = checkError != null
      ? PrCheckState.none
      // The agent is about to push a fix: whatever the current commit's
      // checks say is stale, and must neither unblock the merge nor offer
      // sending the same failure again.
      : fixRunQueued
      ? PrCheckState.pending
      : aggregateCheckState(
          fresh,
          hasUnstartedRuns: hasUnstartedRuns,
          headSeenAt: headSeenAt,
          now: now,
        );
  _lastSyncedAt[taskId] = now;

  var runs = stored;
  final runsChanged = newCommit || _signature(stored) != _signature(fresh);
  if (runsChanged) {
    runs = await session.db.transaction((transaction) async {
      await PrCheckRun.db.deleteWhere(
        session,
        where: (r) => r.taskId.equals(taskId),
        transaction: transaction,
      );
      return fresh.isEmpty
          ? <PrCheckRun>[]
          : await PrCheckRun.db.insert(
              session,
              fresh,
              transaction: transaction,
            );
    });
  }

  final previousState = task.checkState;
  final fixAttempts = state == PrCheckState.success ? 0 : task.checkFixAttempts;
  var updated = task;
  final taskChanged =
      newCommit ||
      state != previousState ||
      checkError != task.checkError ||
      fixAttempts != task.checkFixAttempts;
  if (taskChanged) {
    // Only these columns: the daemon and the panel write the task's other
    // fields concurrently.
    updated = await Task.db.updateRow(
      session,
      task.copyWith(
        prHeadSha: head.sha,
        prHeadSeenAt: headSeenAt,
        checkState: state,
        checkError: checkError,
        checkFixAttempts: fixAttempts,
      ),
      columns: (t) => [
        t.prHeadSha,
        t.prHeadSeenAt,
        t.checkState,
        t.checkError,
        t.checkFixAttempts,
      ],
    );
    await session.messages.postMessage(
      TaskEndpoint.channelForTask(taskId),
      updated,
    );
    await session.messages.postMessage(
      TaskEndpoint.channelForAllTasks(),
      updated,
    );
  }
  if (runsChanged || taskChanged) {
    await session.messages.postMessage(
      channelForTaskChecks(taskId),
      PrChecks(
        taskId: taskId,
        headSha: updated.prHeadSha,
        state: updated.checkState,
        error: updated.checkError,
        runs: runs,
      ),
    );
  }

  if (newCommit && previousSha != null) {
    await logTaskEvent(
      session,
      taskId,
      'New commit ${shortSha(head.sha)} — CI checks restarted',
    );
  }
  if (state != previousState) {
    if (state == PrCheckState.failure) {
      final failed = runs
          .where(isFailedCheck)
          .map((r) => '${r.workflowName} / ${r.jobName}')
          .join(', ');
      await logTaskEvent(session, taskId, 'CI failed: $failed');
    } else if (state == PrCheckState.success) {
      await logTaskEvent(
        session,
        taskId,
        'CI passed (${runs.length} ${runs.length == 1 ? 'job' : 'jobs'})',
      );
    }
  }

  if (state == PrCheckState.failure && !runs.any(isPendingCheck)) {
    await _autoFix(session, updated);
  }
  return updated;
}

/// The Actions jobs of commit [headSha], and whether a workflow run has no
/// jobs yet. Reuses [cachedForSha]'s jobs of runs that already finished.
Future<(List<PrCheckRun>, bool)> _fetchJobs(
  GitHubRepoClient github, {
  required int taskId,
  required String owner,
  required String repo,
  required String headSha,
  required String token,
  required List<PrCheckRun> cachedForSha,
}) async {
  final workflowRuns =
      await github.listWorkflowRuns(
          owner: owner,
          repo: repo,
          headSha: headSha,
          token: token,
        )
        ..sort((a, b) => a.id.compareTo(b.id));

  final fresh = <PrCheckRun>[];
  var hasUnstartedRuns = false;
  for (final run in workflowRuns) {
    // A finished run's jobs don't change until it's re-run (which bumps
    // its attempt) — reuse them instead of asking GitHub again.
    final cached = cachedForSha
        .where(
          (r) => r.workflowRunId == run.id && r.runAttempt == run.runAttempt,
        )
        .toList();
    if (run.status == 'completed' &&
        cached.isNotEmpty &&
        !cached.any(isPendingCheck)) {
      fresh.addAll(cached.map((r) => r.copyWith(id: null)));
      continue;
    }

    final jobs = await github.listRunJobs(
      owner: owner,
      repo: repo,
      runId: run.id,
      token: token,
    );
    if (jobs.isEmpty) {
      if (run.status != 'completed') {
        hasUnstartedRuns = true;
      } else if (run.conclusion != null &&
          !_passingConclusions.contains(run.conclusion)) {
        // A run that failed before any job started (e.g. an invalid
        // workflow file) still has to fail the checks.
        fresh.add(
          PrCheckRun(
            taskId: taskId,
            headSha: headSha,
            workflowRunId: run.id,
            runAttempt: run.runAttempt,
            workflowName: run.name,
            jobId: -run.id,
            jobName: run.name,
            status: run.status,
            conclusion: run.conclusion,
          ),
        );
      }
      continue;
    }
    for (final job in jobs) {
      fresh.add(
        PrCheckRun(
          taskId: taskId,
          headSha: headSha,
          workflowRunId: run.id,
          runAttempt: run.runAttempt,
          workflowName: run.name,
          jobId: job.id,
          jobName: job.name,
          status: job.status,
          conclusion: job.conclusion,
          failedStep: job.failedStep,
          htmlUrl: job.htmlUrl,
          startedAt: job.startedAt,
          completedAt: job.completedAt,
        ),
      );
    }
  }

  return (fresh, hasUnstartedRuns);
}

/// [syncChecks] for callers that must not fail on it (the future call, the
/// daemon's status update): skips a task without a PR or a project token
/// and logs GitHub errors instead of throwing.
Future<void> syncChecksQuietly(Session session, Task task) async {
  final prUrl = task.prUrl;
  if (prUrl == null) return;
  final project = await Project.db.findById(session, task.projectId);
  final token = project?.repoAccessToken;
  if (token == null || token.isEmpty) return;
  try {
    await syncChecks(session, task, context: (prUrl: prUrl, token: token));
  } catch (e) {
    session.log(
      'Syncing CI checks for task ${task.id} failed: $e',
      level: LogLevel.warning,
    );
  }
}

/// Sends [task]'s failing checks (all of them, or just [jobIds]) to its
/// agent as a fix run — the same `--resume` path as review feedback — with
/// each job's log tail in the prompt and the dev's optional [note]. Refused
/// while another fix run is still queued; with [oncePerCommit] (auto-fix)
/// also when this commit's failure was already sent. Both are re-checked in
/// a serializable transaction, so concurrent syncs can't send twice.
Future<TaskFeedback> sendFailingChecksToFix(
  Session session,
  Task task, {
  List<int>? jobIds,
  String? note,
  bool oncePerCommit = false,
}) async {
  final taskId = task.id!;
  if (task.status != TaskStatus.awaitingReview) {
    throw InvalidStateException(
      message: 'Task $taskId is not awaiting review (${task.status.name})',
    );
  }
  await requireNoActiveReview(session, taskId);
  if (await hasQueuedFixRun(session, task)) {
    throw InvalidStateException(
      message: 'A fix run is already queued for task $taskId',
    );
  }
  final headSha = task.prHeadSha;
  final failing = headSha == null
      ? const <PrCheckRun>[]
      : (await PrCheckRun.db.find(
              session,
              where: (r) => r.taskId.equals(taskId) & r.headSha.equals(headSha),
              orderBy: (r) => r.id,
            ))
            .where(isFailedCheck)
            .where(
              (r) => jobIds == null || jobIds.contains(r.jobId),
            )
            .toList();
  if (failing.isEmpty) {
    throw InvalidStateException(
      message: 'Task $taskId has no failing CI checks to fix',
    );
  }

  final context = await repoContextFor(session, taskId);
  final (:owner, :repo, number: _) = gitHubRepoClient.parsePrUrl(
    context.prUrl,
  );
  final failures = <({PrCheckRun run, String? log})>[];
  for (final run in failing) {
    String? log;
    if (run.jobId > 0) {
      try {
        log = await gitHubRepoClient.getJobLogTail(
          owner: owner,
          repo: repo,
          jobId: run.jobId,
          token: context.token,
        );
      } catch (e) {
        session.log(
          'Fetching the log of job ${run.jobId} failed: $e',
          level: LogLevel.warning,
        );
      }
    }
    failures.add((run: run, log: log));
  }

  return queueReviewFeedback(
    session,
    task,
    checkFixPrompt(headSha: headSha!, failures: failures, note: note),
    transactionSettings: const TransactionSettings(
      isolationLevel: IsolationLevel.serializable,
    ),
    alsoWrite: (transaction) async {
      final current = await Task.db.findById(
        session,
        taskId,
        transaction: transaction,
      );
      if (current == null) {
        throw NotFoundException(message: 'Task $taskId not found');
      }
      if (oncePerCommit && current.checkFixSentForSha == headSha) {
        throw InvalidStateException(
          message:
              'The failing checks of ${shortSha(headSha)} were already '
              'sent to the agent',
        );
      }
      // The feedback inserted by this transaction is one; any other one
      // newer than the last run means a concurrent send got there first.
      final queued = await TaskFeedback.db.count(
        session,
        where: (f) {
          final review =
              f.taskId.equals(taskId) &
              f.phase.equals(TaskFeedbackPhase.review);
          final finishedAt = current.finishedAt;
          return finishedAt == null
              ? review
              : review & (f.createdAt > finishedAt);
        },
        transaction: transaction,
      );
      if (queued > 1) {
        throw InvalidStateException(
          message: 'A fix run is already queued for task $taskId',
        );
      }
      await Task.db.updateRow(
        session,
        current.copyWith(
          checkFixAttempts: current.checkFixAttempts + 1,
          checkFixSentForSha: headSha,
        ),
        columns: (t) => [t.checkFixAttempts, t.checkFixSentForSha],
        transaction: transaction,
      );
    },
  );
}

/// The fix-run prompt [sendFailingChecksToFix] sends for the [failures] on
/// commit [headSha].
String checkFixPrompt({
  required String headSha,
  required List<({PrCheckRun run, String? log})> failures,
  String? note,
}) {
  final buffer = StringBuffer(
    'The GitHub Actions checks on this PR failed for commit '
    '${shortSha(headSha)}:\n',
  );
  final logBudget = failures.isEmpty
      ? _maxPromptLogChars
      : _maxPromptLogChars ~/ failures.length;
  for (final (:run, :log) in failures) {
    buffer.write(
      '\n### ${run.workflowName} / ${run.jobName} — ${run.conclusion}',
    );
    final step = run.failedStep;
    if (step != null) buffer.write(' at step "$step"');
    buffer.writeln();
    final url = run.htmlUrl;
    if (url != null) buffer.writeln(url);
    if (log == null || log.isEmpty) {
      buffer.writeln('(log unavailable — check the workflow definition)');
    } else {
      final trimmed = log.length > logBudget
          ? '…\n${log.substring(log.length - logBudget)}'
          : log;
      buffer
        ..writeln('````')
        ..writeln(trimmed)
        ..writeln('````');
    }
  }
  buffer.write(
    '\nReproduce each failure locally with the same command the workflow '
    'runs (see `.github/workflows/`), fix its cause — don\'t skip, disable '
    'or delete tests or checks — make sure the tests, analyzer and linter '
    'pass, then commit and push the branch.',
  );
  final trimmedNote = note?.trim();
  if (trimmedNote != null && trimmedNote.isNotEmpty) {
    buffer.write('\n\nNote from the developer: $trimmedNote');
  }
  return buffer.toString();
}

/// Sends [task]'s failing checks to its agent when its auto-fix is on, the
/// attempt cap isn't reached and this commit wasn't sent already.
Future<void> _autoFix(Session session, Task task) async {
  if (task.status != TaskStatus.awaitingReview ||
      task.prHeadSha == null ||
      task.checkFixSentForSha == task.prHeadSha ||
      !task.autoFixFailingChecks ||
      task.checkFixAttempts >= task.maxCheckFixAttempts) {
    return;
  }
  try {
    await sendFailingChecksToFix(session, task, oncePerCommit: true);
    await logTaskEvent(
      session,
      task.id!,
      'Failing CI checks sent to the agent automatically '
      '(attempt ${task.checkFixAttempts + 1} of '
      '${task.maxCheckFixAttempts})',
    );
  } on InvalidStateException catch (e) {
    // E.g. a code review in progress — the next sync tries again.
    session.log(
      'Not auto-fixing CI checks for task ${task.id}: ${e.message}',
      level: LogLevel.info,
    );
  } catch (e) {
    // E.g. a serialization failure because a concurrent sync sent it.
    session.log(
      'Auto-fixing CI checks for task ${task.id} failed: $e',
      level: LogLevel.warning,
    );
  }
}

/// Identifies what the panel shows of [runs], to tell whether a sync
/// changed anything.
String _signature(List<PrCheckRun> runs) => [
  for (final r in runs)
    '${r.workflowRunId}/${r.runAttempt}/${r.jobId}/${r.status}/'
        '${r.conclusion}/${r.failedStep}',
].join(',');
