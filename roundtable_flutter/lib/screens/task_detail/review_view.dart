part of '../task_detail_screen.dart';

/// The AI code review on its own: verdict, every comment to triage, and
/// sending the picked ones back to the agent.
class _ReviewView extends StatelessWidget {
  const _ReviewView({required this.state, required this.onOpenFile});

  final TaskDetailLoaded state;

  /// Jumps to a comment's file in the Changes view.
  final ValueChanged<String> onOpenFile;

  @override
  Widget build(BuildContext context) {
    final latestReview = state.latestReview;
    final reviewActive = state.reviewActive;
    final comments = state.reviewComments.reversed.toList();
    final editable = state.inReview && !reviewActive;
    final canOpenFiles = state.files != null;
    final openIds = {
      for (final c in comments)
        if (c.state == ReviewCommentState.open) c.id!,
    };
    final selected = state.selectedCommentIds;
    final bloc = context.read<TaskDetailBloc>();

    return _ReadingColumn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('AI code review', style: AppTypography.cardTitle),
              ),
              if (state.inReview)
                OutlinedButton.icon(
                  onPressed: reviewActive || state.reviewBusy
                      ? null
                      : () => _openRequestReviewDialog(context, state.task),
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: Text(
                    state.reviews.isEmpty
                        ? 'Request AI review'
                        : 'Review again',
                  ),
                ),
            ],
          ),
          if (state.task.isLive && state.sentToFixCommentCount > 0) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              'The agent is fixing the comments sent to it — read-only until '
              "it's back in review.",
              style: AppTypography.caption,
            ),
          ],
          const SizedBox(height: Spacing.lg),
          Expanded(
            child: ListView(
              children: [
                if (latestReview != null) ...[
                  _VerdictCard(
                    review: latestReview,
                    number: state.reviews.length,
                  ),
                  const SizedBox(height: Spacing.md),
                  _ReviewerLog(
                    key: ValueKey(latestReview.id),
                    review: latestReview,
                    logs: state.logs,
                  ),
                  const SizedBox(height: Spacing.xl),
                ],
                if (state.reviewError != null) ...[
                  Text(
                    state.reviewError!,
                    style: AppTypography.body.copyWith(color: AppColors.red),
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
                if (comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.xxl),
                    child: Text(
                      latestReview == null
                          ? 'No AI review yet — request one to get comments '
                                'on this PR.'
                          : reviewActive
                          ? 'Review in progress…'
                          : 'The review left no comments.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.text1,
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Text(
                        'COMMENTS · ${openIds.length} OPEN OF '
                        '${comments.length}',
                        style: AppTypography.label,
                      ),
                      const Spacer(),
                      if (editable && openIds.isNotEmpty)
                        TextButton(
                          onPressed: () => bloc.add(
                            CommentsSelectionSet(
                              selected.containsAll(openIds) ? {} : openIds,
                            ),
                          ),
                          child: Text(
                            selected.containsAll(openIds)
                                ? 'Clear selection'
                                : 'Select all open',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  for (final comment in comments) ...[
                    _commentCard(
                      context,
                      state,
                      comment,
                      editable: editable,
                      onOpenLocation: canOpenFiles
                          ? () => onOpenFile(comment.path)
                          : null,
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                ],
              ],
            ),
          ),
          if (state.inReview) ...[
            const SizedBox(height: Spacing.md),
            if (selected.isNotEmpty) ...[
              _SelectionBar(
                count: selected.length,
                onClear: () => bloc.add(const CommentsSelectionSet({})),
              ),
              const SizedBox(height: Spacing.sm),
            ],
            _IterationFeedbackRow(state: state),
          ],
        ],
      ),
    );
  }
}

/// The PR's GitHub Actions checks, with failures sendable to the agent.
class _ChecksView extends StatelessWidget {
  const _ChecksView({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TaskDetailBloc>();
    final taskId = state.task.id!;
    return PrChecksView(
      checks: state.checks,
      selectedJobIds: state.selectedCheckJobIds,
      canSendToAgent:
          state.inReview && !state.reviewActive && !state.submitting,
      agentWorking: state.task.status == TaskStatus.running,
      busy: state.checksBusy || state.reviewBusy,
      error: state.checksError,
      onRefresh: state.inReview
          ? () => bloc.add(ChecksRefreshRequested(taskId))
          : null,
      onToggleJob: (jobId) => bloc.add(CheckJobSelectionToggled(jobId)),
      onSendToAgent: (note) => bloc.add(FailingChecksSentToFix(taskId, note)),
      onOpenUrl: (url) =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );
  }
}

/// Centers prose-heavy views (plan, question, result, AI review) in a
/// column narrow enough to read on wide screens.
class _ReadingColumn extends StatelessWidget {
  const _ReadingColumn({required this.child});

  static const maxWidth = 960.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// The latest review's status and the reviewer's overall verdict.
class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.review, required this.number});

  final CodeReview review;

  /// 1-based: the how-many-th review of this task.
  final int number;

  @override
  Widget build(BuildContext context) {
    final pausedUntil = review.status == CodeReviewStatus.queued
        ? review.pausedUntil
        : null;
    final (color, label, pulsing) = switch (review.status) {
      CodeReviewStatus.queued when pausedUntil != null => (
        AppColors.warning,
        'Paused',
        false,
      ),
      CodeReviewStatus.queued => (AppColors.text2, 'Queued', false),
      CodeReviewStatus.running => (AppColors.live, 'Reviewing…', true),
      CodeReviewStatus.completed => switch (review.verdict) {
        CodeReviewVerdict.approve => (AppColors.live, 'Approved', false),
        CodeReviewVerdict.changesRequested => (
          AppColors.warning,
          'Changes requested',
          false,
        ),
        null => (AppColors.accentSoft, 'Completed', false),
      },
      CodeReviewStatus.failed => (AppColors.red, 'Failed', false),
    };
    final failed = review.status == CodeReviewStatus.failed;
    final detail = failed ? review.failureReason : review.summary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('VERDICT', style: AppTypography.label),
              const SizedBox(width: Spacing.md),
              StatusPill(color: color, label: label, pulsing: pulsing),
              const Spacer(),
              Text(
                'Review #$number · ${relativeTime(review.createdAt)}',
                style: AppTypography.caption,
              ),
            ],
          ),
          if (pausedUntil != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              'Usage limit — the review resumes at '
              '${resumeTimeLabel(pausedUntil)}',
              style: AppTypography.body.copyWith(color: AppColors.warning),
            ),
          ],
          if (detail != null) ...[
            const SizedBox(height: Spacing.md),
            failed
                ? Text(
                    detail,
                    style: AppTypography.body.copyWith(color: AppColors.red),
                  )
                : PlanContent(markdown: detail),
          ],
        ],
      ),
    );
  }
}

/// The reviewer's own log for [review] — what it looked at and said —
/// collapsed under the verdict.
class _ReviewerLog extends StatefulWidget {
  const _ReviewerLog({super.key, required this.review, required this.logs});

  final CodeReview review;
  final List<TaskLogEntry> logs;

  @override
  State<_ReviewerLog> createState() => _ReviewerLogState();
}

class _ReviewerLogState extends State<_ReviewerLog> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final reviewRuns = buildLogTimeline(
      widget.logs,
    ).where((r) => r.isReview).toList();
    // Structured runs carry their review; older logs only allow "the
    // latest review run" for the latest review.
    final run =
        reviewRuns.where((r) => r.reviewId == widget.review.id).lastOrNull ??
        (reviewRuns.every((r) => r.reviewId == null)
            ? reviewRuns.lastOrNull
            : null);
    if (run == null) return const SizedBox.shrink();
    final active =
        widget.review.status == CodeReviewStatus.queued ||
        widget.review.status == CodeReviewStatus.running;
    return LogRunView(
      run: run,
      running: active,
      expanded: _expanded,
      onToggle: (open) => setState(() => _expanded = open),
    );
  }
}

/// Shown while comments are selected: what the composer below will send.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.count, required this.onClear});

  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xs,
        Spacing.xs,
        Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.checklist, size: 16, color: AppColors.accentSoft),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              '$count comment${count == 1 ? '' : 's'} selected — they will be '
              'sent to the agent to fix, with your optional note.',
              style: AppTypography.body,
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

/// Sends the agent another iteration: the comments selected for fixing (with
/// an optional note), or free-form feedback when none are selected.
class _IterationFeedbackRow extends StatelessWidget {
  const _IterationFeedbackRow({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final selectedCount = state.selectedCommentIds.length;
    return _FeedbackRow(
      hint: selectedCount == 0
          ? 'Leave feedback for another iteration…'
          : 'Optional note to send with the selected comments…',
      submitting: state.submitting || state.reviewBusy || state.reviewActive,
      submitLabel: selectedCount == 0
          ? 'Send feedback'
          : 'Send $selectedCount to agent',
      // Sending selected comments is the main action of the review view.
      primarySubmit: selectedCount > 0,
      allowEmpty: selectedCount > 0,
      onSubmit: (message) => context.read<TaskDetailBloc>().add(
        selectedCount == 0
            ? ReviewFeedbackSubmitted(state.task.id!, message)
            : CommentsSentToFix(state.task.id!, message),
      ),
    );
  }
}

Widget _commentCard(
  BuildContext context,
  TaskDetailLoaded state,
  ReviewComment comment, {
  required bool editable,
  bool showLocation = true,
  VoidCallback? onOpenLocation,
}) {
  final bloc = context.read<TaskDetailBloc>();
  return ReviewCommentCard(
    comment: comment,
    showLocation: showLocation,
    selected: state.selectedCommentIds.contains(comment.id),
    onToggleSelected: editable
        ? () => bloc.add(CommentSelectionToggled(comment.id!))
        : null,
    onStateChanged: editable
        ? (s) => bloc.add(CommentStateChanged(comment.id!, s))
        : null,
    onOpenLocation: onOpenLocation,
  );
}
