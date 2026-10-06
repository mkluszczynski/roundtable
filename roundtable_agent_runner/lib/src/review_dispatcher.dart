import 'dart:convert';
import 'dart:io';

import 'package:roundtable_client/roundtable_client.dart';

import 'agent_work_queue.dart';
import 'claude_code_executor.dart';
import 'container_sandbox.dart';
import 'role_prompts.dart';
import 'log_entries.dart';
import 'stream_json_formatter.dart';
import 'task_images.dart';
import 'worktree_manager.dart';

/// Runs an assigned [CodeReview]: checks the task's branch out read-only,
/// asks Claude Code to review the diff, and uploads its findings.
///
/// Server-facing dependencies are plain functions, like [TaskDispatcher].
class ReviewDispatcher {
  ReviewDispatcher({
    required this.worktreeManager,
    required this.executorFactory,
    required this.oauthToken,
    required this.getCloneUrl,
    required this.fetchAgent,
    required this.startReview,
    required this.completeReview,
    required this.failReview,
    required this.appendLog,
    required this.log,
    this.environmentPrompt,
    this.fetchAttachments = _noAttachments,
    this.fetchPreviousComments = _noPreviousComments,
    this.fetchProject,
    this.sandboxFor,
    AgentWorkQueue? workQueue,
  }) : workQueue = workQueue ?? AgentWorkQueue();

  /// One piece of work at a time per agent, shared with `TaskDispatcher`: a
  /// review by a busy agent stays `queued` here until it's free.
  final AgentWorkQueue workQueue;

  static Future<List<TaskImage>> _noAttachments(int taskId) async => const [];
  static Future<List<ReviewComment>> _noPreviousComments(int reviewId) async =>
      const [];

  /// The comments of earlier reviews of the same task, for the reviewer to
  /// check — bound to `client.codeReview.previousComments` in production.
  final Future<List<ReviewComment>> Function(int reviewId)
  fetchPreviousComments;

  /// The images attached to the task's prompt — part of the requirements the
  /// reviewer checks the change against. Bound to `client.taskAttachment` in
  /// production.
  final Future<List<TaskImage>> Function(int taskId) fetchAttachments;

  /// Describes this machine to the reviewer (`--append-system-prompt`) —
  /// see `buildEnvironmentPrompt`. Null when not yet known.
  final String? Function({bool container})? environmentPrompt;

  /// The project under review — its `dockerImage` for a docker-mode
  /// reviewer.
  final Future<Project?> Function(int projectId)? fetchProject;

  /// Builds the container a docker-mode reviewer runs in, like
  /// `TaskDispatcher.sandboxFor`: only the review worktree, the project's
  /// git data and the attached images are visible, never the machine's
  /// other files. Null when the machine has no container runtime.
  final ContainerSandbox Function(ContainerRequest request)? sandboxFor;

  final WorktreeManager worktreeManager;
  final ClaudeCodeExecutor Function() executorFactory;
  final String? oauthToken;
  final Future<String> Function(int projectId) getCloneUrl;
  final Future<Agent> Function(int agentId) fetchAgent;

  /// Bound to `client.codeReview.startReview`; returns the task under review.
  final Future<Task> Function(int reviewId) startReview;
  final Future<void> Function(int reviewId, ReviewFindings findings)
  completeReview;
  final Future<void> Function(int reviewId, String reason) failReview;

  /// Persists one structured log entry. Bound to
  /// `client.task.appendLogEntry` in production.
  final Future<void> Function(TaskLogEntry entry) appendLog;
  final void Function(String message) log;

  Future<void> handle(CodeReview review) async {
    final reviewId = review.id!;
    final agentId = review.reviewerAgentId;
    if (review.status != CodeReviewStatus.queued || agentId == null) {
      log('review $reviewId: not queued (status=${review.status}), skipping');
      return;
    }
    await workQueue.run(
      agentId,
      'the review of task #${review.taskId}',
      () => _handle(review, reviewId, agentId),
      onWaiting: (busyWith) {
        log('review $reviewId: reviewer $agentId is busy with $busyWith');
        appendLog(
          TaskLogEntry(
            taskId: review.taskId,
            content: 'Review waiting — the reviewer is busy with $busyWith',
            source: LogSource.system,
            kind: LogKind.event,
          ),
        ).catchError(
          (Object e) => log('review $reviewId: appendLog failed: $e'),
        );
      },
    );
  }

  Future<void> _handle(CodeReview review, int reviewId, int agentId) async {
    final Task task;
    try {
      task = await startReview(reviewId);
    } catch (e) {
      // Another subscription (e.g. a replay after reconnect) won the race.
      log('review $reviewId: could not start: $e');
      return;
    }
    final branch = task.branchName;
    if (branch == null) {
      await failReview(reviewId, 'Task ${task.id} has no pushed branch.');
      return;
    }

    final projectId = '${task.projectId}';
    Directory? attachmentDir;
    ContainerSandbox? sandbox;
    try {
      final agent = await fetchAgent(agentId);
      final cloneUrl = await getCloneUrl(task.projectId);
      await worktreeManager.ensureProjectCloned(
        projectId: projectId,
        cloneUrl: cloneUrl,
      );
      final worktree = await worktreeManager.createReviewWorktree(
        projectId: projectId,
        reviewId: '$reviewId',
        branch: branch,
        fetchUrl: cloneUrl,
      );
      log('review $reviewId: reviewing $branch at ${worktree.path}');

      var imagePaths = const <String>[];
      final images = await fetchAttachments(task.id!);
      if (images.isNotEmpty) {
        attachmentDir = await Directory.systemTemp.createTemp(
          'roundtable-review-$reviewId-',
        );
        imagePaths = await writeTaskImages(attachmentDir, images);
        log('review $reviewId: ${images.length} attached image(s)');
      }

      final runId = newRunId('review-$reviewId');
      void append(LogItem item) {
        // The verdict JSON is shown as cards in the panel, not as text.
        final shown = item.kind == LogKind.message
            ? item.copyWith(content: stripReviewJson(item.content))
            : item;
        if (shown.content.isEmpty) return;
        appendLog(
          logEntryFor(
            shown,
            taskId: task.id!,
            runId: runId,
            phase: LogPhase.review,
            reviewId: reviewId,
          ),
        ).catchError(
          (Object e) => log('review $reviewId: appendLog failed: $e'),
        );
      }

      append(
        LogItem(
          kind: LogKind.runStarted,
          content: '${agent.name} started a code review',
        ),
      );

      final inContainer = agent.executionMode == AgentExecutionMode.docker;
      if (inContainer) {
        final build = sandboxFor;
        if (build == null) {
          throw StateError(
            '${agent.name} runs in docker mode, but this machine has no '
            'container runtime — install podman (install-agent.sh --docker) '
            'or switch the agent to native',
          );
        }
        final project = await fetchProject?.call(task.projectId);
        sandbox = build((
          projectId: task.projectId,
          name: 'roundtable-review-$reviewId',
          worktreePath: worktree.path,
          readOnlyDirectories: [?attachmentDir?.path],
          image: project?.dockerImage,
        ));
        append(
          LogItem(
            kind: LogKind.event,
            content: 'Running in a container (${sandbox.image})',
          ),
        );
      }

      final previous = await fetchPreviousComments(reviewId);

      final formatter = StreamJsonFormatter();
      final executor = sandbox == null
          ? executorFactory()
          : executorFactory().inContainer(sandbox);
      final result = await executor.runReview(
        prompt: buildReviewPrompt(
          rolePrompt: buildRolePrompt(agent),
          taskPrompt: task.prompt,
          baseSha: worktree.baseSha,
          imagePaths: imagePaths,
          previousComments: previous,
        ),
        workingDirectory: worktree.path,
        oauthToken: oauthToken,
        model: agent.defaultModel,
        effort: agent.defaultEffort?.name,
        additionalDirectories: [?attachmentDir?.path],
        appendSystemPrompt: environmentPrompt?.call(container: inContainer),
        onLine: (line) => formatter.feedEntries(line).forEach(append),
      );

      if (!result.success) {
        await failReview(
          reviewId,
          (sandbox != null
                  ? describeContainerFailure(result.errorSummary)
                  : result.errorSummary) ??
              'Review run failed',
        );
        return;
      }
      final findings = parseReviewOutput(result.resultText ?? '');
      if (findings == null) {
        await failReview(
          reviewId,
          'The reviewer did not end with the expected JSON block.',
        );
        return;
      }
      await completeReview(reviewId, findings);
      log(
        'review $reviewId: done with ${findings.comments.length} comment(s), '
        '${findings.checks.length} earlier one(s) checked',
      );
    } catch (e) {
      log('review $reviewId: failed: $e');
      await failReview(
        reviewId,
        e is ProcessException ? describeClaudeLaunchFailure(e) : '$e',
      );
    } finally {
      await sandbox?.remove();
      try {
        await worktreeManager.removeReviewWorktree(
          projectId: projectId,
          reviewId: '$reviewId',
        );
      } catch (e) {
        log('review $reviewId: could not remove worktree: $e');
      }
      try {
        await attachmentDir?.delete(recursive: true);
      } catch (e) {
        log('review $reviewId: could not remove attached images: $e');
      }
    }
  }
}

/// The instructions given to the reviewer agent. The working tree is the
/// task's branch; [baseSha] is where it forked off the default branch.
/// [imagePaths] are the images attached to the task's prompt;
/// [previousComments] are earlier reviews' comments, to check and not repeat.
String buildReviewPrompt({
  required String rolePrompt,
  required String taskPrompt,
  required String baseSha,
  List<String> imagePaths = const [],
  List<ReviewComment> previousComments = const [],
}) =>
    '''
$rolePrompt You are reviewing another agent's change. Do not modify any files.

The change was made for this task:
<task>
$taskPrompt
</task>
${_attachedImagesSection(imagePaths)}${_previousCommentsSection(previousComments)}
Before reviewing, read the repo's conventions if these files exist: AGENTS.md, CLAUDE.md, CONTRIBUTING.md (at the root and next to the changed code). Judge the change against them.

Inspect it with `git diff $baseSha...HEAD` and read surrounding code as needed. Look for bugs, missed requirements, security problems, broken conventions, and clear maintainability issues. Skip pure style preferences.

Scope: comment on code the change adds or modifies. Raise untouched code only when the change breaks it.

Severity:
- blocker: a bug, data loss, a security problem, or a requirement of the task that isn't met. The change must not be merged as is.
- issue: a real problem worth fixing before merging (missing error handling or test, a broken convention, a maintainability trap).
- nit: cosmetic or optional; never blocks merging.
When unsure between two severities, pick the lower one.

Each comment names the problem and how to fix it, concretely enough for another agent to act on without asking.

End your reply with exactly one fenced ```json block of this shape:
{"verdict": "approve" | "changes_requested", "summary": "<one paragraph verdict>", "comments": [{"path": "<repo-relative path>", "line": <line number in the new file, or null>, "severity": "blocker" | "issue" | "nit", "body": "<what is wrong and how to fix it>"}]${previousComments.isEmpty ? '' : ', "previous": [{"id": <earlier comment id>, "fixed": true | false, "note": "<if not fixed: what is still wrong, else null>"}]'}}
Use "changes_requested" exactly when a blocker or issue remains (new or earlier and not fixed), else "approve". Use an empty comments list if the change is good.''';

/// Earlier reviews' comments with their state: the reviewer checks each one
/// that wasn't dismissed and reports it under `previous`, never repeating
/// it among the new comments.
String _previousCommentsSection(List<ReviewComment> comments) {
  if (comments.isEmpty) return '';
  String state(ReviewComment c) => switch (c.state) {
    ReviewCommentState.open => 'still open',
    ReviewCommentState.sentToFix ||
    ReviewCommentState.resolved => 'the agent was asked to fix it',
    ReviewCommentState.dismissed => 'dismissed by the developer',
    ReviewCommentState.superseded => 'superseded',
  };
  final list = comments
      .map((c) {
        final location = c.line == null ? c.path : '${c.path}:${c.line}';
        return '- id ${c.id} · $location · ${c.severity.name} · ${state(c)}\n'
            '  ${c.body.replaceAll('\n', '\n  ')}';
      })
      .join('\n');
  return '''
This change was reviewed before. Earlier comments:
$list

For every earlier comment that wasn't dismissed, check the current code and report it under "previous": fixed or not, with a note on what is still wrong. Don't repeat earlier comments among the new ones, and don't raise again what the developer dismissed. New comments are only for problems not listed above.
''';
}

String _attachedImagesSection(List<String> imagePaths) {
  if (imagePaths.isEmpty) return '';
  final list = imagePaths.map((p) => '- $p').join('\n');
  return '\nThe developer attached ${imagePaths.length} image(s) to this task '
      '(screenshots or mockups). They are part of the requirements: open '
      'each one with the Read tool before reviewing the change:\n$list\n';
}

/// Parses the reviewer's final reply: the last fenced ```json block (or the
/// whole text, if it's bare JSON). Returns `null` if no valid block is found.
/// What the reviewer's final reply ([parseReviewOutput]) holds. [verdict]
/// is null when the reviewer didn't give a valid one.
typedef ReviewFindings = ({
  String summary,
  List<ReviewCommentDraft> comments,
  List<ReviewCommentCheck> checks,
  CodeReviewVerdict? verdict,
});

ReviewFindings? parseReviewOutput(String text) {
  final blocks = RegExp(
    r'```json\s*\n([\s\S]*?)\n\s*```',
  ).allMatches(text).toList();
  final raw = blocks.isEmpty ? text.trim() : blocks.last.group(1)!;

  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  final summary = decoded['summary'];
  final comments = decoded['comments'];
  if (summary is! String || comments is! List) return null;

  final drafts = <ReviewCommentDraft>[];
  for (final c in comments) {
    if (c is! Map<String, dynamic>) continue;
    final path = c['path'];
    final body = c['body'];
    if (path is! String || body is! String || path.isEmpty) continue;
    final line = c['line'];
    drafts.add(
      ReviewCommentDraft(
        path: path,
        line: line is int && line > 0 ? line : null,
        body: body,
        severity: ReviewCommentSeverity.values.firstWhere(
          (s) => s.name == c['severity'],
          orElse: () => ReviewCommentSeverity.issue,
        ),
      ),
    );
  }
  final checks = <ReviewCommentCheck>[];
  if (decoded['previous'] case final List previous) {
    for (final p in previous) {
      if (p is! Map<String, dynamic>) continue;
      final id = p['id'];
      final fixed = p['fixed'];
      if (id is! int || fixed is! bool) continue;
      final note = p['note'];
      checks.add(
        ReviewCommentCheck(
          commentId: id,
          fixed: fixed,
          note: note is String && note.trim().isNotEmpty ? note : null,
        ),
      );
    }
  }
  final verdict = switch (decoded['verdict']) {
    'approve' => CodeReviewVerdict.approve,
    'changes_requested' ||
    'changesRequested' => CodeReviewVerdict.changesRequested,
    _ => null,
  };
  return (summary: summary, comments: drafts, checks: checks, verdict: verdict);
}
