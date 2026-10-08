part of '../task_detail_screen.dart';

class _SectionContent extends StatelessWidget {
  const _SectionContent({
    required this.state,
    required this.section,
    required this.onSectionSelected,
  });

  final TaskDetailLoaded state;
  final TaskSection section;
  final ValueChanged<TaskSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      TaskSection.overview => _Overview(state: state),
      TaskSection.plan => _ReadingColumn(child: _PlanView(state: state)),
      TaskSection.changes => _ChangesView(state: state),
      TaskSection.review => _ReviewView(
        state: state,
        onOpenFile: (path) {
          final file = state.files
              ?.where((f) => f.filename == path)
              .firstOrNull;
          if (file == null) return;
          context.read<TaskDetailBloc>().add(FileSelected(file));
          onSectionSelected(TaskSection.changes);
        },
      ),
      TaskSection.checks => _ReadingColumn(child: _ChecksView(state: state)),
      TaskSection.logs =>
        state.task.isLive
            ? _LiveExecution(state: state)
            : _LogHistory(state: state),
    };
  }
}

class _LogHistory extends StatelessWidget {
  const _LogHistory({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.logs.isEmpty) {
      return Text('No output yet.', style: AppTypography.body);
    }
    return TaskLogTimeline(entries: state.logs);
  }
}

/// What needs the dev's attention for the current status.
class _Overview extends StatelessWidget {
  const _Overview({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final status = state.task.status;
    // The live log uses the full width; prose views get a reading column.
    if (status == TaskStatus.planning || status == TaskStatus.running) {
      return _LiveExecution(state: state);
    }
    return _ReadingColumn(child: _content());
  }

  Widget _content() {
    return switch (state.task.status) {
      TaskStatus.waitingForAnswer => _PendingQuestion(
        key: ValueKey(state.pendingQuestion?.id),
        state: state,
      ),
      TaskStatus.planReady => _PlanReview(state: state),
      TaskStatus.planning || TaskStatus.running => _LiveExecution(state: state),
      // Only reachable for a task that finished without changing code —
      // with a PR, Changes/AI review replace Overview.
      TaskStatus.awaitingReview || TaskStatus.done => _ResultView(state: state),
      TaskStatus.paused => _PausedView(state: state),
      TaskStatus.failed => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.task.failureReason ?? 'This task failed.',
              style: AppTypography.body.copyWith(color: AppColors.red),
            ),
            if (state.task.resultSummary case final result?) ...[
              const SizedBox(height: Spacing.xl),
              Text("AGENT'S LAST REPLY", style: AppTypography.label),
              const SizedBox(height: Spacing.sm),
              AppCard(child: PlanContent(markdown: result)),
            ],
          ],
        ),
      ),
      TaskStatus.draft => Text(
        'Draft — assign an agent to start this task.',
        style: AppTypography.body.copyWith(color: AppColors.text1),
      ),
      TaskStatus.queued || TaskStatus.cloning || TaskStatus.cancelled => Text(
        'No action needed for this task right now.',
        style: AppTypography.caption,
      ),
    };
  }
}

/// A task paused by the Claude usage limit: when it resumes on its own,
/// and a way to resume now (e.g. after raising the plan's limit).
class _PausedView extends StatelessWidget {
  const _PausedView({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    final until = task.pausedUntil;
    final remaining = until?.difference(DateTime.now().toUtc());
    final inText = remaining == null || remaining.isNegative
        ? 'any moment now'
        : remaining.inHours > 0
        ? 'in ${remaining.inHours} h ${remaining.inMinutes % 60} min'
        : 'in ${remaining.inMinutes.clamp(1, 59)} min';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: AppColors.warning),
              const SizedBox(width: Spacing.sm),
              Text(
                'PAUSED — CLAUDE USAGE LIMIT',
                style: AppTypography.label.copyWith(color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  until == null
                      ? 'Resumes automatically when the limit resets'
                      : 'Resumes automatically at ${resumeTimeLabel(until)} '
                            '($inText)',
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  '${state.agent?.name ?? 'The agent'} continues the same '
                  'session from where it stopped — nothing is lost.',
                  style: AppTypography.body.copyWith(color: AppColors.text1),
                ),
                if (task.pauseReason case final reason?) ...[
                  const SizedBox(height: Spacing.md),
                  Text(reason, style: AppTypography.caption),
                ],
                const SizedBox(height: Spacing.lg),
                FilledButton.icon(
                  onPressed: state.submitting
                      ? null
                      : () => context.read<TaskDetailBloc>().add(
                          TaskResumed(task.id!),
                        ),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Resume now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A task that finished without changing code: the agent's reply (e.g. its
/// answer to a question) is the whole outcome.
class _ResultView extends StatelessWidget {
  const _ResultView({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    final result = task.resultSummary;
    // Reopened with a message: the agent is about to resume.
    final continuing = task.status == TaskStatus.awaitingReview;
    final canContinue =
        task.status == TaskStatus.done && task.claudeSessionId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: AppColors.live),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      'FINISHED WITHOUT CODE CHANGES',
                      style: AppTypography.label.copyWith(
                        color: AppColors.live,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'The agent answered or found nothing to change, so there '
                  'is no pull request. Its reply:',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: Spacing.lg),
                AppCard(
                  child: result == null
                      ? Text(
                          'No reply was recorded — see the Logs tab.',
                          style: AppTypography.body,
                        )
                      : PlanContent(markdown: result),
                ),
              ],
            ),
          ),
        ),
        if (continuing) ...[
          const SizedBox(height: Spacing.md),
          Text(
            'Sent — the agent will continue in the same session.',
            style: AppTypography.body.copyWith(color: AppColors.text1),
          ),
        ] else if (canContinue) ...[
          const SizedBox(height: Spacing.md),
          _FeedbackRow(
            hint:
                'Continue the conversation, e.g. "Implement it following '
                'this plan"…',
            submitLabel: 'Continue',
            primarySubmit: true,
            submitting: state.submitting,
            onSubmit: (message) => context.read<TaskDetailBloc>().add(
              TaskContinued(task.id!, message),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChangeStats extends StatelessWidget {
  const _ChangeStats({required this.files});

  final List<DiffFile> files;

  @override
  Widget build(BuildContext context) {
    final additions = files.fold<int>(0, (sum, f) => sum + f.additions);
    final deletions = files.fold<int>(0, (sum, f) => sum + f.deletions);
    return Text.rich(
      TextSpan(
        style: AppTypography.bodyStrong,
        children: [
          TextSpan(
            text:
                '${files.length} file${files.length == 1 ? '' : 's'} changed  ',
          ),
          TextSpan(
            text: '+$additions ',
            style: const TextStyle(color: AppColors.live),
          ),
          TextSpan(
            text: '-$deletions',
            style: const TextStyle(color: AppColors.red),
          ),
        ],
      ),
    );
  }
}
