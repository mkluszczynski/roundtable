part of 'review_dispatcher.dart';

/// One code review, from the read-only worktree to the uploaded findings
/// (docs/FLOWS.md §5), in steps. Holds what the steps share and the
/// resources [_cleanUp] releases.
class _ReviewRun {
  _ReviewRun(this._d, this.reviewId, this.task, this.agentId);

  final ReviewDispatcher _d;
  final int reviewId;
  final Task task;
  final int agentId;

  String get projectId => '${task.projectId}';
  late final String _runId = newRunId('review-$reviewId');
  final _formatter = StreamJsonFormatter();

  Directory? _attachmentDir;
  RunEnvironment? _environment;

  void _log(String message) => _d.log('review $reviewId: $message');

  void _append(LogItem item) {
    // The verdict JSON is shown as cards in the panel, not as text.
    final shown = item.kind == LogKind.message
        ? item.copyWith(content: stripReviewJson(item.content))
        : item;
    if (shown.content.isEmpty) return;
    _d
        .appendLog(
          logEntryFor(
            shown,
            taskId: task.id!,
            runId: _runId,
            phase: LogPhase.review,
            reviewId: reviewId,
          ),
        )
        .catchError((Object e) => _log('appendLog failed: $e'));
  }

  /// Runs the review; returns true when the usage limit cut it short and it
  /// went back to `queued`.
  Future<bool> execute() async {
    final branch = task.branchName;
    if (branch == null) {
      await _d._fail(reviewId, 'Task ${task.id} has no pushed branch.');
      return false;
    }
    try {
      final agent = await _d.fetchAgent(agentId);
      final worktree = await _prepareWorktree(branch);
      final imagePaths = await _writeAttachments();
      _append(
        LogItem(
          kind: LogKind.runStarted,
          content: '${agent.name} started a code review',
        ),
      );
      final environment = _environment = await _d._environments.prepare(
        agent: agent,
        label: 'review $reviewId',
        projectId: task.projectId,
        containerName: 'roundtable-review-$reviewId',
        worktreePath: worktree.path,
        readOnlyDirectories: [?_attachmentDir?.path],
        append: _append,
        // On the host the reviewer can't run anything, so it needs none.
        installToolchain: agent.executionMode == AgentExecutionMode.docker,
      );
      final result = await _runClaude(agent, environment, worktree, imagePaths);
      return await _report(result, environment);
    } catch (e) {
      _log('failed: $e');
      await _d._fail(
        reviewId,
        e is ProcessException ? describeClaudeLaunchFailure(e) : '$e',
      );
      return false;
    } finally {
      await _cleanUp();
    }
  }

  Future<({String path, String baseSha})> _prepareWorktree(
    String branch,
  ) async {
    final cloneUrl = await _d.getCloneUrl(task.projectId);
    await _d.worktreeManager.ensureProjectCloned(
      projectId: projectId,
      cloneUrl: cloneUrl,
    );
    final worktree = await _d.worktreeManager.createReviewWorktree(
      projectId: projectId,
      reviewId: '$reviewId',
      branch: branch,
      fetchUrl: cloneUrl,
    );
    _log('reviewing $branch at ${worktree.path}');
    return worktree;
  }

  /// The task's attached images, part of the requirements the reviewer
  /// checks the change against.
  Future<List<String>> _writeAttachments() async {
    final images = await _d.fetchAttachments(task.id!);
    if (images.isEmpty) return const [];
    final dir = _attachmentDir = await Directory.systemTemp.createTemp(
      'roundtable-review-$reviewId-',
    );
    _log('${images.length} attached image(s)');
    return writeTaskImages(dir, images);
  }

  Future<ClaudeCodeExecutionResult> _runClaude(
    Agent agent,
    RunEnvironment environment,
    ({String path, String baseSha}) worktree,
    List<String> imagePaths,
  ) async {
    final previous = await _d.fetchPreviousComments(reviewId);
    return environment.executor.runReview(
      prompt: buildReviewPrompt(
        rolePrompt: buildRolePrompt(agent),
        taskPrompt: task.prompt,
        baseSha: worktree.baseSha,
        imagePaths: imagePaths,
        previousComments: previous,
        canRunChecks: environment.inContainer,
      ),
      workingDirectory: worktree.path,
      environment: environment.environment,
      // Only in a disposable container: on the host, Bash could reach any
      // file the runner's user can.
      allowBash: environment.inContainer,
      oauthToken: _d.oauthToken?.call(),
      model: agent.defaultModel,
      effort: agent.defaultEffort?.name,
      additionalDirectories: [?_attachmentDir?.path],
      appendSystemPrompt: environment.systemPrompt(),
      onLine: (line) => _formatter.feedEntries(line).forEach(_append),
    );
  }

  /// Uploads the findings, or requeues/fails the review. Returns true when
  /// it went back to `queued` for the usage limit.
  Future<bool> _report(
    ClaudeCodeExecutionResult result,
    RunEnvironment environment,
  ) async {
    final requeue = _d.requeueReview;
    if (!result.success &&
        requeue != null &&
        isUsageLimitMessage(result.errorSummary)) {
      final until = usageLimitResetAt(result.errorSummary!);
      _d.usageLimit.hit(until);
      _log('usage limit, queued again until $until');
      _append(
        LogItem(
          kind: LogKind.event,
          content:
              'Stopped by the Claude usage limit — the review runs again '
              'at ${localClock(until)}',
        ),
      );
      await requeue(reviewId, until, result.errorSummary!);
      return true;
    }
    if (!result.success) {
      await _d._fail(
        reviewId,
        environment.describeFailure(result.errorSummary) ?? 'Review run failed',
      );
      return false;
    }
    final findings = parseReviewOutput(result.resultText ?? '');
    if (findings == null) {
      await _d._fail(
        reviewId,
        'The reviewer did not end with the expected JSON block.',
      );
      return false;
    }
    await _d.completeReview(reviewId, findings);
    _log(
      'done with ${findings.comments.length} comment(s), '
      '${findings.checks.length} earlier one(s) checked',
    );
    return false;
  }

  Future<void> _cleanUp() async {
    await _environment?.dispose();
    try {
      await _d.worktreeManager.removeReviewWorktree(
        projectId: projectId,
        reviewId: '$reviewId',
        onError: (e) => _log('worktree cleanup: $e'),
      );
    } catch (e) {
      _log('could not remove worktree: $e');
    }
    try {
      await _attachmentDir?.delete(recursive: true);
    } catch (e) {
      _log('could not remove attached images: $e');
    }
  }
}
