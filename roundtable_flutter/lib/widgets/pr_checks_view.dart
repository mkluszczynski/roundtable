import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/pr_checks.dart';
import 'status_pill.dart';

/// A task PR's GitHub Actions checks (docs/FLOWS.md §4 "CI checks"): the
/// jobs grouped by workflow, with the failing ones selectable and sent to
/// the agent — with an optional note — as one fix run. Pure data and
/// callbacks, so the task detail screen owns the state.
class PrChecksView extends StatelessWidget {
  const PrChecksView({
    super.key,
    required this.checks,
    this.selectedJobIds = const {},
    this.canSendToAgent = false,
    this.agentWorking = false,
    this.busy = false,
    this.error,
    this.onRefresh,
    this.onToggleJob,
    this.onSendToAgent,
    this.onOpenUrl,
  });

  /// Null while the first snapshot is loading.
  final PrChecks? checks;

  /// Failing jobs ticked for "send to agent"; none ticked sends all of them.
  final Set<int> selectedJobIds;

  /// The task is in review and nothing else is in flight, so failures can
  /// be sent to the agent.
  final bool canSendToAgent;

  /// The agent is running a fix run: the checks shown are about to go stale.
  final bool agentWorking;
  final bool busy;

  /// Why the last refresh/send failed.
  final String? error;
  final VoidCallback? onRefresh;
  final ValueChanged<int>? onToggleJob;

  /// Sends the selected (or all) failing jobs with the dev's note.
  final ValueChanged<String>? onSendToAgent;
  final ValueChanged<String>? onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final checks = this.checks;
    final runs = checks?.runs ?? const <PrCheckRun>[];
    final failing = runs.where(isFailedCheckRun).toList();
    final selectable = canSendToAgent && !busy;
    final sendCount = selectedJobIds.isEmpty
        ? failing.length
        : selectedJobIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('CI checks', style: AppTypography.cardTitle),
            const SizedBox(width: Spacing.md),
            if (checks != null)
              StatusPill.fromAppearance(
                checkStateAppearance(checks.state),
                label: checkStateLabel(checks.state),
              ),
            if (checks?.headSha != null) ...[
              const SizedBox(width: Spacing.md),
              Text(
                checks!.headSha!.substring(
                  0,
                  checks.headSha!.length < 7 ? checks.headSha!.length : 7,
                ),
                style: AppTypography.code.copyWith(color: AppColors.text1),
              ),
            ],
            const Spacer(),
            if (onRefresh != null)
              OutlinedButton.icon(
                onPressed: busy ? null : onRefresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        if (agentWorking) ...[
          _Banner(
            icon: Icons.hourglass_top,
            color: AppColors.warning,
            text:
                'The agent is working — the checks restart once it pushes '
                'its changes.',
          ),
          const SizedBox(height: Spacing.md),
        ],
        if (checks?.error != null) ...[
          _Banner(
            icon: Icons.lock_outline,
            color: AppColors.warning,
            text:
                'The CI checks can\'t be read: ${checks!.error}. Merging is '
                'left to GitHub\'s branch protection.',
          ),
          const SizedBox(height: Spacing.md),
        ],
        if (error != null) ...[
          Text(
            error!,
            style: AppTypography.body.copyWith(color: AppColors.red),
          ),
          const SizedBox(height: Spacing.md),
        ],
        Expanded(
          child: checks == null
              ? const Center(child: CircularProgressIndicator())
              : runs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xxl),
                  child: Text(
                    switch (checks.state) {
                      PrCheckState.pending =>
                        'Waiting for the workflows to start on the latest '
                            'commit…',
                      _ when checks.error != null =>
                        'Give the project token "Actions: Read" to see the '
                            'checks here.',
                      _ =>
                        checks.headSha == null
                            ? 'The checks haven\'t been read from GitHub yet.'
                            : 'No GitHub Actions workflow ran on the latest '
                                  'commit.',
                    },
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(color: AppColors.text1),
                  ),
                )
              : ListView(
                  children: [
                    for (final group in _groupByWorkflow(runs)) ...[
                      // Readable on wide screens, like the review view.
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: _WorkflowCard(
                            name: group.first.workflowName,
                            jobs: group,
                            selectedJobIds: selectedJobIds,
                            onToggleJob: selectable ? onToggleJob : null,
                            onOpenUrl: onOpenUrl,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                    ],
                  ],
                ),
        ),
        if (canSendToAgent && failing.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          _FixComposer(
            busy: busy,
            label: 'Send $sendCount to agent',
            onSend: onSendToAgent,
          ),
        ],
      ],
    );
  }

  /// One list per workflow run, in the order the server stored them.
  static List<List<PrCheckRun>> _groupByWorkflow(List<PrCheckRun> runs) {
    final groups = <int, List<PrCheckRun>>{};
    for (final run in runs) {
      (groups[run.workflowRunId] ??= []).add(run);
    }
    return groups.values.toList();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Text(text, style: AppTypography.body)),
        ],
      ),
    );
  }
}

/// One workflow run: its jobs under the workflow's name, or — with a
/// single job — just that job, with the workflow's name beside it when
/// it differs (`test` in `Tests`).
class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({
    required this.name,
    required this.jobs,
    required this.selectedJobIds,
    required this.onToggleJob,
    required this.onOpenUrl,
  });

  final String name;
  final List<PrCheckRun> jobs;
  final Set<int> selectedJobIds;
  final ValueChanged<int>? onToggleJob;
  final ValueChanged<String>? onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final showHeader = jobs.length > 1;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.md,
                Spacing.lg,
                Spacing.xs,
              ),
              child: Text(name.toUpperCase(), style: AppTypography.label),
            ),
          for (final (i, job) in jobs.indexed) ...[
            if (i > 0) Divider(height: 1, color: AppColors.border),
            _JobRow(
              job: job,
              selected: selectedJobIds.contains(job.jobId),
              onToggle: onToggleJob != null && isFailedCheckRun(job)
                  ? () => onToggleJob!(job.jobId)
                  : null,
              onOpenUrl: onOpenUrl,
              workflowName:
                  !showHeader && job.jobName.toLowerCase() != name.toLowerCase()
                  ? name
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

/// One job: its outcome as an icon and a word, the failed step, how long
/// it took. The whole row opens the job on GitHub.
class _JobRow extends StatefulWidget {
  const _JobRow({
    required this.job,
    required this.selected,
    required this.onToggle,
    required this.onOpenUrl,
    this.workflowName,
  });

  final PrCheckRun job;
  final bool selected;
  final VoidCallback? onToggle;
  final ValueChanged<String>? onOpenUrl;

  /// Shown beside the job's name for a single-job workflow without a header.
  final String? workflowName;

  @override
  State<_JobRow> createState() => _JobRowState();
}

class _JobRowState extends State<_JobRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final appearance = checkRunAppearance(job);
    final url = job.htmlUrl;
    final onOpenUrl = widget.onOpenUrl;
    final open = url != null && onOpenUrl != null ? () => onOpenUrl(url) : null;
    final duration = _duration(job);
    final failed = isFailedCheckRun(job);
    return MouseRegion(
      cursor: open != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: Container(
          color: _hovered && open != null ? AppColors.bg2 : null,
          padding: EdgeInsets.fromLTRB(
            widget.onToggle != null ? Spacing.xs : Spacing.lg,
            Spacing.md,
            Spacing.sm,
            Spacing.md,
          ),
          child: Row(
            children: [
              if (widget.onToggle != null)
                Tooltip(
                  message: 'Select to send to the agent',
                  child: Checkbox(
                    value: widget.selected,
                    onChanged: (_) => widget.onToggle!(),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              _OutcomeIcon(job: job, color: appearance.color),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: job.jobName,
                        style: AppTypography.bodyStrong,
                        children: [
                          if (widget.workflowName != null)
                            TextSpan(
                              text: '  ${widget.workflowName}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.text2,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (failed && job.failedStep != null)
                      Text(
                        'Failed at "${job.failedStep}"',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.red,
                        ),
                      ),
                  ],
                ),
              ),
              if (duration != null) ...[
                Text(
                  duration,
                  style: AppTypography.code.copyWith(color: AppColors.text1),
                ),
                const SizedBox(width: Spacing.lg),
              ],
              SizedBox(
                width: 72,
                child: Text(
                  outcomeLabel(job),
                  style: AppTypography.caption.copyWith(
                    color: appearance.color,
                  ),
                ),
              ),
              if (open != null)
                IconButton(
                  tooltip: 'Open on GitHub',
                  onPressed: open,
                  icon: const Icon(Icons.open_in_new, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _duration(PrCheckRun job) {
    final start = job.startedAt;
    final end = job.completedAt;
    if (start == null || end == null) return null;
    final elapsed = end.difference(start);
    if (elapsed.inMinutes == 0) return '${elapsed.inSeconds}s';
    return '${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s';
  }
}

/// A job's outcome in one word: Passed, Failed, Running…
String outcomeLabel(PrCheckRun job) {
  if (job.status != 'completed') {
    return job.status == 'in_progress' ? 'Running' : 'Queued';
  }
  return switch (job.conclusion) {
    'success' => 'Passed',
    'skipped' => 'Skipped',
    'neutral' => 'Neutral',
    'cancelled' => 'Cancelled',
    'timed_out' => 'Timed out',
    _ => 'Failed',
  };
}

class _OutcomeIcon extends StatelessWidget {
  const _OutcomeIcon({required this.job, required this.color});

  final PrCheckRun job;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (job.status != 'completed') {
      return SizedBox(
        width: 18,
        height: 18,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      );
    }
    final icon = switch (job.conclusion) {
      'success' => Icons.check_circle,
      'skipped' || 'neutral' => Icons.remove_circle_outline,
      _ => Icons.cancel,
    };
    return Icon(icon, size: 18, color: color);
  }
}

/// The note and "send to agent" action under the failing jobs.
class _FixComposer extends StatefulWidget {
  const _FixComposer({
    required this.busy,
    required this.label,
    required this.onSend,
  });

  final bool busy;
  final String label;
  final ValueChanged<String>? onSend;

  @override
  State<_FixComposer> createState() => _FixComposerState();
}

class _FixComposerState extends State<_FixComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSend = widget.onSend;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xs,
        Spacing.sm,
        Spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !widget.busy,
              minLines: 1,
              maxLines: 4,
              style: AppTypography.body,
              decoration: const InputDecoration(
                hintText: 'Optional note for the agent…',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: widget.busy || onSend == null
                ? null
                : () {
                    onSend(_controller.text.trim());
                    _controller.clear();
                  },
            icon: const Icon(Icons.build_outlined, size: 14),
            label: Text(widget.label),
          ),
        ],
      ),
    );
  }
}
