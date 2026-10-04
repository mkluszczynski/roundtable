import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/log_entry_kind.dart';
import '../utils/log_timeline.dart';
import 'pill_selector.dart';
import 'plan_content.dart';
import 'status_pill.dart';
import 'task_log_line.dart';

/// How much of the log to show.
enum LogDetail { messages, activity, raw }

/// A task's log as a timeline: one section per run (planning, execution,
/// feedback, review), the agent's messages as markdown, and its tool calls
/// grouped into collapsible activity rows. [live] follows new output.
class TaskLogTimeline extends StatefulWidget {
  const TaskLogTimeline({super.key, required this.entries, this.live = false});

  final List<TaskLogEntry> entries;
  final bool live;

  @override
  State<TaskLogTimeline> createState() => _TaskLogTimelineState();
}

class _TaskLogTimelineState extends State<TaskLogTimeline> {
  static const _maxWidth = 960.0;

  final _scroll = ScrollController();
  LogDetail _detail = LogDetail.activity;

  /// Runs the dev opened or closed; others default to "only the latest is
  /// open".
  final _toggled = <int, bool>{};

  /// Whether to keep the view scrolled to the newest output.
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _scrollToEndSoon();
  }

  @override
  void didUpdateWidget(covariant TaskLogTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_follow && widget.entries.length != oldWidget.entries.length) {
      _scrollToEndSoon();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final atEnd =
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 48;
    if (atEnd != _follow) setState(() => _follow = atEnd);
  }

  void _scrollToEndSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final runs = buildLogTimeline(widget.entries);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PillSelector<LogDetail>(
              options: LogDetail.values,
              labelBuilder: (d) => switch (d) {
                LogDetail.messages => 'Messages',
                LogDetail.activity => 'All activity',
                LogDetail.raw => 'Raw',
              },
              selected: _detail,
              onChanged: (d) {
                setState(() => _detail = d);
                if (_follow) _scrollToEndSoon();
              },
            ),
            const Spacer(),
            if (widget.live) ...[
              const StatusDot(color: AppColors.live, pulsing: true),
              const SizedBox(width: Spacing.xs),
              Text(
                'live',
                style: AppTypography.caption.copyWith(color: AppColors.live),
              ),
            ],
          ],
        ),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: _detail == LogDetail.raw
              ? TaskLogView(entries: widget.entries)
              : Stack(
                  children: [
                    ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.only(bottom: Spacing.huge),
                      children: [
                        for (final (i, run) in runs.indexed)
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: _maxWidth,
                              ),
                              child: _RunSection(
                                run: run,
                                running:
                                    widget.live &&
                                    i == runs.length - 1 &&
                                    run.finished == null,
                                expanded:
                                    _toggled[run.index] ?? i == runs.length - 1,
                                onToggle: (open) =>
                                    setState(() => _toggled[run.index] = open),
                                detail: _detail,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (!_follow)
                      Positioned(
                        right: Spacing.lg,
                        bottom: Spacing.lg,
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            setState(() => _follow = true);
                            _scroll.animateTo(
                              _scroll.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          label: const Text('Jump to latest'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RunSection extends StatelessWidget {
  const _RunSection({
    required this.run,
    required this.running,
    required this.expanded,
    required this.onToggle,
    required this.detail,
  });

  final LogRun run;
  final bool running;
  final bool expanded;
  final ValueChanged<bool> onToggle;
  final LogDetail detail;

  @override
  Widget build(BuildContext context) {
    final finished = run.finished;
    final failed = finished?.failed ?? false;
    final icon = switch (run.phase) {
      LogPhase.planning => Icons.checklist_outlined,
      LogPhase.execution => Icons.build_outlined,
      LogPhase.feedback => Icons.forum_outlined,
      LogPhase.review => Icons.rate_review_outlined,
      null => Icons.play_arrow_outlined,
    };
    final startedAt = run.startedAt?.toLocal();
    final time = startedAt == null
        ? null
        : '${startedAt.hour.toString().padLeft(2, '0')}:'
              '${startedAt.minute.toString().padLeft(2, '0')}';
    final visible = [
      for (final block in run.blocks)
        if (detail == LogDetail.activity || block is MessageBlock) block,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.bg1,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onToggle(!expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.accentSoft),
                    const SizedBox(width: Spacing.sm),
                    Text('Run ${run.index}', style: AppTypography.label),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Text(
                        run.title ??
                            (run.isReview ? 'Code review' : 'Agent run'),
                        style: AppTypography.bodyStrong,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (run.stepCount > 0)
                      Text(
                        '${run.stepCount} steps  ·  ',
                        style: AppTypography.caption,
                      ),
                    if (time != null)
                      Text('$time  ·  ', style: AppTypography.caption),
                    if (running) ...[
                      const StatusDot(color: AppColors.live, pulsing: true),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        'Running',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.live,
                        ),
                      ),
                    ] else if (finished != null)
                      Text(
                        finished.text,
                        style: AppTypography.caption.copyWith(
                          color: failed ? AppColors.red : AppColors.live,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text('Stopped', style: AppTypography.caption),
                    const SizedBox(width: Spacing.sm),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.text2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: Spacing.md),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: Spacing.lg),
                child: Text(
                  running ? 'Working…' : 'No messages in this run.',
                  style: AppTypography.caption,
                ),
              ),
            for (final block in visible)
              Padding(
                padding: const EdgeInsets.only(
                  left: Spacing.lg,
                  bottom: Spacing.sm,
                ),
                child: switch (block) {
                  MessageBlock(:final text) => PlanContent(markdown: text),
                  ThinkingBlock(:final text) => _Expandable(
                    icon: Icons.psychology_outlined,
                    title: 'Thought',
                    child: Text(
                      text,
                      style: AppTypography.body.copyWith(
                        color: AppColors.text2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  ActivityBlock() => _Expandable(
                    icon: Icons.construction_outlined,
                    title:
                        '${block.steps.length} '
                        'step${block.steps.length == 1 ? '' : 's'}',
                    subtitle: block.summary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final step in block.steps) _StepRow(step: step),
                      ],
                    ),
                  ),
                },
              ),
          ],
        ],
      ),
    );
  }
}

/// A one-line summary row that expands to show [child].
class _Expandable extends StatefulWidget {
  const _Expandable({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  State<_Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<_Expandable> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Row(
              children: [
                Icon(widget.icon, size: 14, color: AppColors.text2),
                const SizedBox(width: Spacing.sm),
                Text(
                  widget.title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.text1,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  Text('  ·  ', style: AppTypography.caption),
                  Flexible(
                    child: Text(
                      widget.subtitle!,
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(width: Spacing.xs),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                  color: AppColors.text2,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Container(
            margin: const EdgeInsets.only(top: Spacing.xs, left: Spacing.xs),
            padding: const EdgeInsets.only(left: Spacing.md),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.border)),
            ),
            child: widget.child,
          ),
      ],
    );
  }
}

/// One tool call with its result status; expands to the full input and
/// output.
class _StepRow extends StatefulWidget {
  const _StepRow({required this.step});

  final ToolStep step;

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final result = step.result;
    final (marker, color) = result == null
        ? ('…', AppColors.text2)
        : result.failed
        ? ('✗', AppColors.red)
        : ('✓', AppColors.live);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Text(
                    marker,
                    style: AppTypography.code.copyWith(color: color),
                  ),
                ),
                Expanded(
                  child: Text(
                    step.call.text,
                    style: AppTypography.code.copyWith(color: AppColors.text1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              top: Spacing.xs,
              bottom: Spacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailBox(
                  label: 'Input',
                  text: step.call.detail ?? step.call.text,
                ),
                if (result != null) ...[
                  const SizedBox(height: Spacing.xs),
                  _DetailBox(
                    label: result.failed ? 'Error' : 'Output',
                    text: result.detail ?? result.text,
                    error: result.failed,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _DetailBox extends StatelessWidget {
  const _DetailBox({
    required this.label,
    required this.text,
    this.error = false,
  });

  final String label;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.codeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: error
              ? AppColors.red.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppTypography.label),
            const SizedBox(height: Spacing.xs),
            SelectableText(
              text.isEmpty ? '(empty)' : text,
              style: AppTypography.code.copyWith(
                color: error ? AppColors.red : AppColors.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
