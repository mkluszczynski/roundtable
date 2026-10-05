import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../github_repo_client.dart';
import '../task_review_support.dart';

/// AI code review of a task's PR: a reviewer agent leaves comments, the dev
/// triages them and sends the ones worth fixing back to the task's agent.
class CodeReviewEndpoint extends Endpoint {
  /// Queues a review of [taskId]'s PR by [agentId]. The reviewer's daemon
  /// picks it up via [watchAssignedReviews].
  Future<CodeReview> requestReview(
    Session session,
    int taskId,
    int agentId,
  ) async {
    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw NotFoundException(message: 'Task $taskId not found');
    }
    if (task.status != TaskStatus.awaitingReview || task.prUrl == null) {
      throw InvalidStateException(
        message: 'Task $taskId has no PR awaiting review',
      );
    }
    await requireNoActiveReview(session, taskId);
    var agent = await Agent.db.findById(session, agentId);
    if (agent == null) {
      throw NotFoundException(message: 'Agent $agentId not found');
    }
    if (agent.status != AgentStatus.idle) {
      throw InvalidStateException(message: '${agent.name} is busy');
    }

    return queueCodeReview(session, task, agent);
  }

  /// Streams reviews assigned to agents hosted on [machineId], for the
  /// daemon. Replays the queued ones on subscribe, like
  /// `TaskEndpoint.watchAssignedTasks`.
  Stream<CodeReview> watchAssignedReviews(
    Session session,
    int machineId,
  ) async* {
    var agentIds = (await Agent.db.find(
      session,
      where: (t) => t.machineId.equals(machineId),
    )).map((agent) => agent.id!).toSet();

    var pending = await CodeReview.db.find(
      session,
      where: (r) =>
          r.reviewerAgentId.inSet(agentIds) &
          r.status.equals(CodeReviewStatus.queued),
      orderBy: (r) => r.createdAt,
    );
    for (var review in pending) {
      yield review;
    }

    var updates = session.messages.createStream<CodeReview>(
      reviewChannelForMachine(machineId),
    );
    await for (var review in updates) {
      yield review;
    }
  }

  /// Called by the daemon when it starts [reviewId]: flips it to `running`
  /// and its reviewer to `busy`. Returns the task under review, which the
  /// daemon needs for the branch and original prompt.
  Future<Task> startReview(Session session, int reviewId) async {
    var review = await _requireReview(session, reviewId);
    if (review.status != CodeReviewStatus.queued) {
      throw InvalidStateException(
        message: 'Code review $reviewId is already ${review.status.name}',
      );
    }
    var task = await Task.db.findById(session, review.taskId);
    if (task == null) {
      throw NotFoundException(message: 'Task ${review.taskId} not found');
    }

    await CodeReview.db.updateRow(
      session,
      review.copyWith(status: CodeReviewStatus.running),
      columns: (r) => [r.status],
    );
    await _setReviewerStatus(session, review, AgentStatus.busy);
    await postReviewChanged(session, reviewId);
    return task;
  }

  /// Stores the reviewer's findings and mirrors them to the PR as a GitHub
  /// review. Mirroring is best effort: on failure the comments still live in
  /// Roundtable, just without `githubCommentId`.
  Future<CodeReview> completeReview(
    Session session,
    int reviewId,
    String summary,
    List<ReviewCommentDraft> drafts,
  ) async {
    var review = await _requireReview(session, reviewId);
    var comments = await ReviewComment.db.insert(session, [
      for (var draft in drafts)
        ReviewComment(
          reviewId: reviewId,
          path: draft.path,
          line: draft.line,
          body: draft.body,
          severity: draft.severity,
        ),
    ]);

    int? githubReviewId;
    try {
      final context = await repoContextFor(session, review.taskId);
      final mirrored = await gitHubRepoClient.createReview(
        prUrl: context.prUrl,
        token: context.token,
        summary: '🤖 Roundtable AI review\n\n$summary',
        comments: comments,
      );
      githubReviewId = mirrored.reviewId;
      var withIds = [
        for (final MapEntry(key: i, value: id) in mirrored.commentIds.entries)
          comments[i].copyWith(githubCommentId: id),
      ];
      if (withIds.isNotEmpty) {
        await ReviewComment.db.update(
          session,
          withIds,
          columns: (c) => [c.githubCommentId],
        );
      }
    } catch (e) {
      session.log(
        'Mirroring code review $reviewId to GitHub failed: $e',
        level: LogLevel.warning,
      );
    }

    await CodeReview.db.updateRow(
      session,
      review.copyWith(
        status: CodeReviewStatus.completed,
        summary: summary,
        githubReviewId: githubReviewId,
        finishedAt: DateTime.now().toUtc(),
      ),
    );
    await _setReviewerStatus(session, review, AgentStatus.idle);
    final posted = await postReviewChanged(session, reviewId);
    await autoFixReviewIfEnabled(session, review.taskId, comments);
    return posted;
  }

  /// Called by the daemon when the review run couldn't produce findings.
  Future<CodeReview> failReview(
    Session session,
    int reviewId,
    String reason,
  ) async {
    var review = await _requireReview(session, reviewId);
    await CodeReview.db.updateRow(
      session,
      review.copyWith(
        status: CodeReviewStatus.failed,
        failureReason: reason,
        finishedAt: DateTime.now().toUtc(),
      ),
    );
    await _setReviewerStatus(session, review, AgentStatus.idle);
    return postReviewChanged(session, reviewId);
  }

  /// Streams [taskId]'s reviews, each with its comments, for the panel.
  /// Replays them all on subscribe, then yields a review again whenever it
  /// or one of its comments changes — merge by id.
  Stream<CodeReview> watchReviews(Session session, int taskId) async* {
    var updates = session.messages.createStream<CodeReview>(
      channelForTaskReviews(taskId),
    );
    var existing = await CodeReview.db.find(
      session,
      where: (r) => r.taskId.equals(taskId),
      orderBy: (r) => r.createdAt,
      include: CodeReview.include(
        comments: ReviewComment.includeList(orderBy: (c) => c.id),
      ),
    );
    for (var review in existing) {
      yield review;
    }
    await for (var review in updates) {
      yield review;
    }
  }

  /// Triage by hand: dismiss, reopen, or resolve a comment. Resolving also
  /// resolves its mirrored GitHub thread.
  Future<ReviewComment> setCommentState(
    Session session,
    int commentId,
    ReviewCommentState state,
  ) async {
    if (state == ReviewCommentState.sentToFix) {
      throw InvalidStateException(
        message: 'Use sendCommentsToFix to send a comment to the agent',
      );
    }
    var comment = await ReviewComment.db.findById(session, commentId);
    if (comment == null) {
      throw NotFoundException(message: 'Review comment $commentId not found');
    }
    comment = await ReviewComment.db.updateRow(
      session,
      comment.copyWith(state: state),
      columns: (c) => [c.state],
    );
    var review = await _requireReview(session, comment.reviewId);
    if (state == ReviewCommentState.resolved) {
      var task = await Task.db.findById(session, review.taskId);
      if (task != null) {
        await resolveGitHubThreads(session, task, [comment]);
      }
    }
    await postReviewChanged(session, review.id!);
    return comment;
  }

  /// Sends [commentIds] — plus an optional [note] from the dev — to
  /// [taskId]'s agent as one review-feedback iteration. They're marked
  /// `sentToFix`, then `resolved` once that run finishes
  /// (`TaskEndpoint.update`).
  Future<TaskFeedback> sendCommentsToFix(
    Session session,
    int taskId,
    List<int> commentIds,
    String? note,
  ) async {
    var task = await Task.db.findById(session, taskId);
    if (task == null) {
      throw NotFoundException(message: 'Task $taskId not found');
    }
    await requireNoActiveReview(session, taskId);
    var reviewIds = (await CodeReview.db.find(
      session,
      where: (r) => r.taskId.equals(taskId),
    )).map((r) => r.id!).toSet();
    var comments = await ReviewComment.db.find(
      session,
      where: (c) =>
          c.id.inSet(commentIds.toSet()) & c.reviewId.inSet(reviewIds),
      orderBy: (c) => c.id,
    );
    return sendCommentsToAgent(session, task, comments, note);
  }

  Future<CodeReview> _requireReview(Session session, int reviewId) async {
    var review = await CodeReview.db.findById(session, reviewId);
    if (review == null) {
      throw NotFoundException(message: 'Code review $reviewId not found');
    }
    return review;
  }

  Future<void> _setReviewerStatus(
    Session session,
    CodeReview review,
    AgentStatus status,
  ) async {
    var agentId = review.reviewerAgentId;
    if (agentId == null) return;
    var agent = await Agent.db.findById(session, agentId);
    if (agent == null) return;
    await Agent.db.updateRow(
      session,
      agent.copyWith(status: status),
      columns: (a) => [a.status],
    );
  }
}
