import 'dart:convert';
import 'dart:io';

import 'package:roundtable_client/roundtable_client.dart';

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
    this.fetchProject,
    this.sandboxFor,
  });

  static Future<List<TaskImage>> _noAttachments(int taskId) async => const [];

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
  final Future<void> Function(
    int reviewId,
    String summary,
    List<ReviewCommentDraft> comments,
  )
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
      await completeReview(reviewId, findings.summary, findings.comments);
      log('review $reviewId: done with ${findings.comments.length} comment(s)');
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
/// [imagePaths] are the images attached to the task's prompt.
String buildReviewPrompt({
  required String rolePrompt,
  required String taskPrompt,
  required String baseSha,
  List<String> imagePaths = const [],
}) =>
    '''
$rolePrompt You are reviewing another agent's change. Do not modify any files.

The change was made for this task:
<task>
$taskPrompt
</task>
${_attachedImagesSection(imagePaths)}
Inspect it with `git diff $baseSha...HEAD` and read surrounding code as needed. Look for bugs, missed requirements, security problems, and clear maintainability issues. Skip pure style preferences.

End your reply with exactly one fenced ```json block of this shape:
{"summary": "<one paragraph verdict>", "comments": [{"path": "<repo-relative path>", "line": <line number in the new file, or null>, "severity": "blocker" | "issue" | "nit", "body": "<what is wrong and how to fix it>"}]}
Use an empty comments list if the change is good.''';

String _attachedImagesSection(List<String> imagePaths) {
  if (imagePaths.isEmpty) return '';
  final list = imagePaths.map((p) => '- $p').join('\n');
  return '\nThe developer attached ${imagePaths.length} image(s) to this task '
      '(screenshots or mockups). They are part of the requirements: open '
      'each one with the Read tool before reviewing the change:\n$list\n';
}

/// Parses the reviewer's final reply: the last fenced ```json block (or the
/// whole text, if it's bare JSON). Returns `null` if no valid block is found.
({String summary, List<ReviewCommentDraft> comments})? parseReviewOutput(
  String text,
) {
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
  return (summary: summary, comments: drafts);
}
