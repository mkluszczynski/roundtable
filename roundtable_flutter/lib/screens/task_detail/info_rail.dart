part of '../task_detail_screen.dart';

class _InfoRail extends StatelessWidget {
  const _InfoRail({
    required this.state,
    required this.section,
    required this.onSectionSelected,
    this.inline = false,
  });

  final TaskDetailLoaded state;
  final TaskSection section;
  final ValueChanged<TaskSection> onSectionSelected;

  /// As the one-column layout's "Info" tab: the tabs replace the section
  /// list and the actions are pinned under every tab instead.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AgentSection(state: state),
                if (!inline)
                  _RailNav(
                    state: state,
                    section: section,
                    onSelected: onSectionSelected,
                  ),
                if (task.branchName != null || task.prUrl != null)
                  RailSection(
                    label: 'Branch',
                    child: _BranchRow(task: task),
                  ),
                RailSection(
                  label: 'Project',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 16,
                        color: AppColors.text1,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        state.project?.name ?? '…',
                        style: AppTypography.bodyStrong,
                      ),
                    ],
                  ),
                ),
                RailSection(
                  label: 'Prompt',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canEditPrompt(task))
                        IconButton(
                          tooltip: 'Edit prompt',
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppColors.text1,
                          ),
                          onPressed: () => _openEditTaskDialog(context, task),
                          visualDensity: VisualDensity.compact,
                        ),
                      CopyIconButton(text: task.prompt, tooltip: 'Copy prompt'),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.bg2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(Spacing.md),
                          child: SelectableText(
                            task.prompt,
                            style: AppTypography.body,
                          ),
                        ),
                      ),
                      TaskAttachmentsView(
                        key: ValueKey(task.id),
                        taskId: task.id!,
                      ),
                    ],
                  ),
                ),
                _SettingsSection(task: task),
                RailSection(
                  label: 'Timeline',
                  child: TaskTimelineView(
                    steps: buildTaskTimeline(
                      task: task,
                      logs: state.logs,
                      reviews: state.reviews,
                      feedback: state.feedback,
                    ),
                    onOpen: (link) => onSectionSelected(switch (link) {
                      TimelineLink.log => TaskSection.logs,
                      TimelineLink.review => TaskSection.review,
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!inline) _RailActions(state: state),
      ],
    );
  }
}

/// The task's advanced options, editable until it's done.
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final reviewerId = task.reviewerAgentId;
    return RailSection(
      label: 'Settings',
      trailing: task.status == TaskStatus.done
          ? null
          : IconButton(
              tooltip: 'Edit settings',
              icon: const Icon(Icons.tune, size: 16, color: AppColors.text1),
              onPressed: () => _openEditTaskDialog(context, task),
              visualDensity: VisualDensity.compact,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            taskOptionsSummary(TaskOptions.fromTask(task)),
            style: AppTypography.body,
          ),
          if (reviewerId != null) ...[
            const SizedBox(height: Spacing.xs),
            _ReviewerName(key: ValueKey(reviewerId), agentId: reviewerId),
          ],
        ],
      ),
    );
  }
}

class _ReviewerName extends StatefulWidget {
  const _ReviewerName({super.key, required this.agentId});

  final int agentId;

  @override
  State<_ReviewerName> createState() => _ReviewerNameState();
}

class _ReviewerNameState extends State<_ReviewerName> {
  late final Future<Agent?> _agent = AgentRepository(
    client,
  ).getAgent(widget.agentId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Agent?>(
      future: _agent,
      builder: (context, snapshot) => Text(
        'Reviewer: ${snapshot.data?.name ?? '…'}',
        style: AppTypography.caption,
      ),
    );
  }
}

/// Who runs the task, and the one place to (re)assign it.
class _AgentSection extends StatelessWidget {
  const _AgentSection({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    final agent = state.agent;
    if (agent == null) {
      return RailSection(
        label: 'Agent',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('No agent assigned', style: AppTypography.caption),
            const SizedBox(height: Spacing.sm),
            FilledButton.icon(
              onPressed: () =>
                  _openReassignAgentDialog(context, task.id!, null),
              icon: const Icon(Icons.person_add_alt_1, size: 16),
              label: Text(
                task.status == TaskStatus.draft
                    ? 'Assign & start'
                    : 'Assign agent',
              ),
            ),
          ],
        ),
      );
    }
    return RailSection(
      label: 'Agent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AgentAvatar(name: agent.name),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: AppTypography.bodyStrong,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${agent.roleLabel} specialist',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              if (task.canReassign)
                TextButton.icon(
                  onPressed: () =>
                      _openReassignAgentDialog(context, task.id!, agent.id),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Change'),
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              TagChip(agent.defaultModel ?? 'default model'),
              TagChip('effort: ${agent.defaultEffort?.name ?? 'default'}'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Switches the main area between the task's views.
IconData _sectionIcon(TaskSection s) => switch (s) {
  TaskSection.overview => Icons.dashboard_outlined,
  TaskSection.plan => Icons.checklist_outlined,
  TaskSection.changes => Icons.difference_outlined,
  TaskSection.review => Icons.rate_review_outlined,
  TaskSection.checks => Icons.fact_check_outlined,
  TaskSection.logs => Icons.terminal,
};

String _sectionLabel(TaskDetailLoaded state, TaskSection s) => switch (s) {
  TaskSection.overview => switch (state.task.status) {
    TaskStatus.waitingForAnswer => 'Question',
    TaskStatus.planReady => 'Plan',
    TaskStatus.done || TaskStatus.awaitingReview => 'Result',
    _ => 'Details',
  },
  TaskSection.plan => 'Plan',
  TaskSection.changes => 'Changes',
  TaskSection.review => 'AI review',
  TaskSection.checks => 'CI checks',
  TaskSection.logs => 'Logs',
};

/// What a section's entry shows on its right: diff totals, open comments,
/// CI state, a live dot.
Widget? _sectionTrailing(TaskDetailLoaded state, TaskSection s) {
  final files = state.files;
  final openComments = state.openCommentCount;
  final sentToFixComments = state.sentToFixCommentCount;
  return switch (s) {
    TaskSection.changes when files != null => Text.rich(
      TextSpan(
        style: AppTypography.code,
        children: [
          TextSpan(
            text: '+${files.fold<int>(0, (n, f) => n + f.additions)} ',
            style: const TextStyle(color: AppColors.live),
          ),
          TextSpan(
            text: '-${files.fold<int>(0, (n, f) => n + f.deletions)}',
            style: const TextStyle(color: AppColors.red),
          ),
        ],
      ),
    ),
    TaskSection.review when state.reviewActive => const StatusDot(
      color: AppColors.live,
      pulsing: true,
    ),
    TaskSection.review when openComments > 0 => CountBadge(openComments),
    TaskSection.review when sentToFixComments > 0 => CountBadge(
      sentToFixComments,
      color: AppColors.text2,
    ),
    TaskSection.checks when state.task.checkState == PrCheckState.failure =>
      CountBadge(state.failedCheckCount, color: AppColors.red),
    TaskSection.checks when state.task.checkState != PrCheckState.none =>
      StatusDot(
        color: checkStateAppearance(state.task.checkState).color,
        pulsing: checkStateAppearance(state.task.checkState).pulsing,
      ),
    TaskSection.logs when state.task.isLive => const StatusDot(
      color: AppColors.live,
      pulsing: true,
    ),
    _ => null,
  };
}

class _RailNav extends StatelessWidget {
  const _RailNav({
    required this.state,
    required this.section,
    required this.onSelected,
  });

  final TaskDetailLoaded state;
  final TaskSection section;
  final ValueChanged<TaskSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final available = state.availableSections;
    return RailSection(
      label: 'View',
      child: Column(
        children: [
          for (final s in TaskSection.values)
            if (available.contains(s))
              RailNavItem(
                icon: _sectionIcon(s),
                label: _sectionLabel(state, s),
                selected: section == s,
                onTap: () => onSelected(s),
                trailing: _sectionTrailing(state, s),
              ),
        ],
      ),
    );
  }
}

/// The sections as a row of tabs, for the one-column layout: the task's
/// details (what the rail shows beside the content on wider screens)
/// first, then each section.
class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
    required this.state,
    required this.section,
    required this.showingInfo,
    required this.onSelected,
    required this.onInfo,
  });

  final TaskDetailLoaded state;
  final TaskSection section;
  final bool showingInfo;
  final ValueChanged<TaskSection> onSelected;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final available = state.availableSections;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            _SectionTab(
              icon: Icons.info_outline,
              label: 'Info',
              selected: showingInfo,
              onTap: onInfo,
            ),
            for (final s in TaskSection.values)
              if (available.contains(s))
                _SectionTab(
                  icon: _sectionIcon(s),
                  label: _sectionLabel(state, s),
                  selected: !showingInfo && section == s,
                  trailing: _sectionTrailing(state, s),
                  onTap: () => onSelected(s),
                ),
          ],
        ),
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Spacing.xs),
      child: Material(
        color: selected ? AppColors.bg2 : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border(
                bottom: BorderSide(
                  width: 2,
                  color: selected ? AppColors.accent : Colors.transparent,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppColors.accent : AppColors.text2,
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  label,
                  style:
                      (selected ? AppTypography.bodyStrong : AppTypography.body)
                          .copyWith(
                            color: selected ? AppColors.text0 : AppColors.text1,
                          ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: Spacing.sm),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The task's branch, with the PR it backs one tap away.
class _BranchRow extends StatelessWidget {
  const _BranchRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.call_split, size: 14, color: AppColors.text1),
        const SizedBox(width: Spacing.xs),
        // The name and its copy button take the free space, so the PR
        // button ends at the rail's edge; the copy button stays right after
        // the name (a Spacer here would split the space with the name).
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Tooltip(
                  message: task.branchName ?? '',
                  child: Text(
                    task.branchName ?? '—',
                    style: AppTypography.code,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (task.branchName != null) ...[
                const SizedBox(width: Spacing.xs),
                CopyIconButton(
                  text: checkoutCommand(task.branchName!),
                  tooltip: 'Copy checkout commands',
                ),
              ],
            ],
          ),
        ),
        if (task.prUrl != null) ...[
          TextButton.icon(
            onPressed: () => openExternalUrl(task.prUrl!),
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('PR'),
            // No right padding: the label lines up with the rail's edge.
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.only(left: Spacing.sm),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ],
    );
  }
}
