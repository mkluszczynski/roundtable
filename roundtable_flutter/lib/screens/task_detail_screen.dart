import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../blocs/task_detail_bloc.dart';
import '../client.dart';
import '../repositories/agent_repository.dart';
import '../repositories/machine_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import '../utils/code_language.dart';
import '../utils/task_status_label.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/agent_avatar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_modal.dart';
import '../widgets/code_block.dart';
import '../widgets/diff_view.dart';
import '../widgets/pill_selector.dart';
import '../widgets/plan_content.dart';
import '../widgets/reassign_agent_dialog.dart';
import '../widgets/request_review_dialog.dart';
import '../widgets/review_comment_card.dart';
import '../widgets/status_pill.dart';
import '../widgets/tag_chip.dart';
import '../widgets/task_log_line.dart';
import '../utils/relative_time.dart';

/// Mirrors the server's `nonTerminalTaskStatuses` (docs/ARCHITECTURE.md) —
/// the header's "Cancel task" button only shows while the task is still
/// something a `cancelTask` call can act on.
const _cancellableStatuses = {
  TaskStatus.draft,
  TaskStatus.queued,
  TaskStatus.cloning,
  TaskStatus.planning,
  TaskStatus.waitingForAnswer,
  TaskStatus.planReady,
  TaskStatus.running,
  TaskStatus.awaitingReview,
};

/// Mirrors the server's `retryTask` guard — a "Retry task" button lets the
/// dev re-queue a failed/cancelled run without recreating the task from
/// scratch (e.g. after fixing an agent-runner install issue).
const _retryableStatuses = {TaskStatus.failed, TaskStatus.cancelled};

/// Mirrors the server's `deleteTask` guard — only a terminal task (nothing
/// left in `nonTerminalTaskStatuses`) can be deleted; a running one has to be
/// cancelled first.
const _deletableStatuses = {
  TaskStatus.draft,
  TaskStatus.done,
  TaskStatus.failed,
  TaskStatus.cancelled,
};

/// Mirrors the server's `reassignAgent` guard — a task can be moved to a
/// different agent while it's still in the backlog or parked in review, but
/// not while actively executing under its current agent.
const _reassignableStatuses = {
  TaskStatus.draft,
  TaskStatus.queued,
  TaskStatus.cloning,
  TaskStatus.awaitingReview,
};

Future<void> _confirmDeleteTask(BuildContext context, int taskId) async {
  final bloc = context.read<TaskDetailBloc>();
  final confirmed = await showAppModal<bool>(
    context,
    icon: Icons.delete_outline,
    tone: AppModalTone.danger,
    title: 'Delete task?',
    subtitle: 'This permanently removes Task #$taskId and its logs.',
    child: const SizedBox.shrink(),
    actions: [
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ),
      Builder(
        builder: (context) => FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ),
    ],
  );
  if (confirmed ?? false) {
    bloc.add(TaskDeleteRequested(taskId));
  }
}

void _openReassignAgentDialog(
  BuildContext context,
  int taskId,
  int? currentAgentId,
) {
  final bloc = context.read<TaskDetailBloc>();
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: ReassignAgentDialog(
        taskId: taskId,
        currentAgentId: currentAgentId,
      ),
    ),
  );
}

void _openRequestReviewDialog(BuildContext context, int taskId) {
  final bloc = context.read<TaskDetailBloc>();
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: RequestReviewDialog(taskId: taskId),
    ),
  );
}

Future<void> _confirmAcceptTask(BuildContext context, int taskId) async {
  final bloc = context.read<TaskDetailBloc>();
  final confirmed = await showAppModal<bool>(
    context,
    icon: Icons.merge,
    title: 'Accept and merge?',
    subtitle:
        'This squash-merges the PR on GitHub and moves Task #$taskId to Done.',
    child: const SizedBox.shrink(),
    actions: [
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ),
      Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Accept & merge'),
        ),
      ),
    ],
  );
  if (confirmed ?? false) {
    bloc.add(TaskAccepted(taskId));
  }
}

Future<void> _confirmResolveConflicts(
  BuildContext context,
  int taskId,
  String baseBranch,
) async {
  final bloc = context.read<TaskDetailBloc>();
  final confirmed = await showAppModal<bool>(
    context,
    icon: Icons.call_merge,
    tone: AppModalTone.danger,
    title: 'Resolve conflicts?',
    subtitle:
        'The agent will merge $baseBranch into the branch of Task #$taskId, '
        'resolve the conflicts and push.',
    child: const SizedBox.shrink(),
    actions: [
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ),
      Builder(
        builder: (context) => FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Resolve conflicts'),
        ),
      ),
    ],
  );
  if (confirmed ?? false) {
    bloc.add(ConflictsResolveRequested(taskId));
  }
}

/// One screen driven by `Task.status`, switching between the task lifecycle's
/// 4 sub-states (docs/FLOWS.md §4): waiting for an answer, plan
/// approval, live execution (log tail), and diff review. Always entered from
/// a dashboard kanban card with a concrete [initialTaskId].
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.initialTaskId});

  final int initialTaskId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskDetailBloc(
        TaskRepository(client),
        projectRepository: ProjectRepository(client),
        agentRepository: AgentRepository(client),
        machineRepository: MachineRepository(client),
      )..add(TaskDetailSubscribed(initialTaskId)),
      child: const Scaffold(
        backgroundColor: AppColors.bg0,
        body: _TaskDetailView(),
      ),
    );
  }
}

/// What the main area shows — picked from the rail's navigation.
enum _TaskSection { overview, changes, review, logs }

bool _isLive(TaskStatus s) =>
    s == TaskStatus.planning || s == TaskStatus.running;

bool _hasPullRequestViews(TaskStatus s) =>
    s == TaskStatus.awaitingReview || s == TaskStatus.done;

/// The section a task opens on: the live log while the agent works, the
/// diff once there's a PR, otherwise whatever needs the dev's attention.
_TaskSection _defaultSectionFor(TaskStatus s) {
  if (_isLive(s)) return _TaskSection.logs;
  if (_hasPullRequestViews(s)) return _TaskSection.changes;
  return _TaskSection.overview;
}

/// Overview only exists while the status has its own content (question,
/// plan, failure…) — live tasks have the log, PR tasks have Changes/Review.
Set<_TaskSection> _availableSectionsFor(TaskStatus s) => {
  if (!_isLive(s) && !_hasPullRequestViews(s)) _TaskSection.overview,
  if (_hasPullRequestViews(s)) ...{_TaskSection.changes, _TaskSection.review},
  _TaskSection.logs,
};

extension _TaskDetailLoadedX on TaskDetailLoaded {
  bool get inReview => task.status == TaskStatus.awaitingReview;

  CodeReview? get latestReview => reviews.isEmpty ? null : reviews.last;

  bool get reviewActive => reviews.any(
    (r) =>
        r.status == CodeReviewStatus.queued ||
        r.status == CodeReviewStatus.running,
  );

  int get openCommentCount =>
      reviewComments.where((c) => c.state == ReviewCommentState.open).length;

  bool get hasConflicts => mergeStatus?.hasConflicts ?? false;
}

class _TaskDetailView extends StatefulWidget {
  const _TaskDetailView();

  @override
  State<_TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<_TaskDetailView> {
  /// Null until the dev picks a section; until then (and after every
  /// status change) the status's default section is shown.
  _TaskSection? _section;

  void _select(_TaskSection section) => setState(() => _section = section);

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TaskDetailBloc, TaskDetailState>(
          listenWhen: (previous, current) => current is TaskDetailDeleted,
          listener: (context, state) {
            if (Navigator.canPop(context)) Navigator.of(context).pop();
          },
        ),
        BlocListener<TaskDetailBloc, TaskDetailState>(
          listenWhen: (previous, current) =>
              previous is TaskDetailLoaded &&
              current is TaskDetailLoaded &&
              previous.task.status != current.task.status,
          listener: (context, state) => setState(() => _section = null),
        ),
      ],
      child: BlocBuilder<TaskDetailBloc, TaskDetailState>(
        builder: (context, state) {
          return switch (state) {
            TaskDetailInitial() ||
            TaskDetailLoading() ||
            TaskDetailDeleted() => const Center(
              child: CircularProgressIndicator(),
            ),
            TaskDetailError(:final message) => Center(
              child: Text(
                'Failed to load task: $message',
                style: AppTypography.body.copyWith(color: AppColors.red),
              ),
            ),
            TaskDetailLoaded() => _buildLoaded(state),
          };
        },
      ),
    );
  }

  Widget _buildLoaded(TaskDetailLoaded state) {
    final status = state.task.status;
    final picked = _section;
    final section =
        picked != null && _availableSectionsFor(status).contains(picked)
        ? picked
        : _defaultSectionFor(status);
    return Column(
      children: [
        _Header(state: state),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 320,
                child: _InfoRail(
                  state: state,
                  section: section,
                  onSectionSelected: _select,
                ),
              ),
              VerticalDivider(width: 1, color: AppColors.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: _SectionContent(
                    state: state,
                    section: section,
                    onSectionSelected: _select,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Task identity only: back, breadcrumb and the status right next to it.
/// Everything that manages the task lives in the rail.
class _Header extends StatelessWidget {
  const _Header({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xl,
        vertical: Spacing.lg,
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back, color: AppColors.text1),
              onPressed: () => Navigator.of(context).pop(),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: Spacing.sm),
          ],
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.text1,
                ),
                children: [
                  TextSpan(text: '${state.project?.name ?? '…'}  /  '),
                  TextSpan(
                    text: 'Task #${task.id}',
                    style: AppTypography.code.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          StatusPill.fromAppearance(
            taskStatusAppearance(task.status),
            label: task.status.label,
          ),
        ],
      ),
    );
  }
}

class _InfoRail extends StatelessWidget {
  const _InfoRail({
    required this.state,
    required this.section,
    required this.onSectionSelected,
  });

  final TaskDetailLoaded state;
  final _TaskSection section;
  final ValueChanged<_TaskSection> onSectionSelected;

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
                _RailNav(
                  state: state,
                  section: section,
                  onSelected: onSectionSelected,
                ),
                if (task.branchName != null || task.prUrl != null)
                  _RailSection(
                    label: 'Branch',
                    child: _BranchRow(task: task),
                  ),
                _RailSection(
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
                _RailSection(
                  label: 'Prompt',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Text(task.prompt, style: AppTypography.body),
                    ),
                  ),
                ),
                _RailSection(
                  label: 'Timeline',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TimelineRow('Created', task.createdAt),
                      if (task.startedAt != null)
                        _TimelineRow('Started running', task.startedAt),
                      if (task.finishedAt != null)
                        _TimelineRow('Finished', task.finishedAt),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _RailActions(state: state),
      ],
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
      return _RailSection(
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
    return _RailSection(
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
                      '${agent.role.name} specialist',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              if (_reassignableStatuses.contains(task.status))
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
class _RailNav extends StatelessWidget {
  const _RailNav({
    required this.state,
    required this.section,
    required this.onSelected,
  });

  final TaskDetailLoaded state;
  final _TaskSection section;
  final ValueChanged<_TaskSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final available = _availableSectionsFor(state.task.status);
    final files = state.files;
    final openComments = state.openCommentCount;
    return _RailSection(
      label: 'View',
      child: Column(
        children: [
          for (final s in _TaskSection.values)
            if (available.contains(s))
              _RailNavItem(
                icon: switch (s) {
                  _TaskSection.overview => Icons.dashboard_outlined,
                  _TaskSection.changes => Icons.difference_outlined,
                  _TaskSection.review => Icons.rate_review_outlined,
                  _TaskSection.logs => Icons.terminal,
                },
                label: switch (s) {
                  _TaskSection.overview => switch (state.task.status) {
                    TaskStatus.waitingForAnswer => 'Question',
                    TaskStatus.planReady => 'Plan',
                    _ => 'Details',
                  },
                  _TaskSection.changes => 'Changes',
                  _TaskSection.review => 'AI review',
                  _TaskSection.logs => 'Logs',
                },
                selected: section == s,
                onTap: () => onSelected(s),
                trailing: switch (s) {
                  _TaskSection.changes when files != null => Text.rich(
                    TextSpan(
                      style: AppTypography.code,
                      children: [
                        TextSpan(
                          text:
                              '+${files.fold<int>(0, (n, f) => n + f.additions)} ',
                          style: const TextStyle(color: AppColors.live),
                        ),
                        TextSpan(
                          text:
                              '-${files.fold<int>(0, (n, f) => n + f.deletions)}',
                          style: const TextStyle(color: AppColors.red),
                        ),
                      ],
                    ),
                  ),
                  _TaskSection.review when state.reviewActive =>
                    const StatusDot(color: AppColors.live, pulsing: true),
                  _TaskSection.review when openComments > 0 => _CountBadge(
                    openComments,
                  ),
                  _TaskSection.logs when _isLive(state.task.status) =>
                    const StatusDot(color: AppColors.live, pulsing: true),
                  _ => null,
                },
              ),
        ],
      ),
    );
  }
}

class _RailNavItem extends StatelessWidget {
  const _RailNavItem({
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
    final color = selected ? AppColors.text0 : AppColors.text1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? AppColors.bg2 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  width: 2,
                  color: selected ? AppColors.accent : Colors.transparent,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppColors.accent : AppColors.text2,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style:
                        (selected
                                ? AppTypography.bodyStrong
                                : AppTypography.body)
                            .copyWith(color: color),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: AppTypography.caption.copyWith(color: AppColors.warning),
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
        Expanded(
          child: Tooltip(
            message: task.branchName ?? '',
            child: Text(
              task.branchName ?? '—',
              style: AppTypography.code,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (task.prUrl != null)
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(task.prUrl!),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('PR'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
      ],
    );
  }
}

/// Everything that changes the task's lifecycle, pinned under the rail: the
/// status's primary action first, destructive ones last.
class _RailActions extends StatelessWidget {
  const _RailActions({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    final bloc = context.read<TaskDetailBloc>();
    final busy = state.reviewActive || state.reviewBusy;
    final destructive = OutlinedButton.styleFrom(
      foregroundColor: AppColors.red,
      side: BorderSide(color: AppColors.red.withValues(alpha: 0.5)),
    );
    final actions = <Widget>[
      if (state.inReview)
        if (state.hasConflicts)
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: busy
                ? null
                : () => _confirmResolveConflicts(
                    context,
                    task.id!,
                    state.mergeStatus!.baseBranch,
                  ),
            icon: const Icon(Icons.call_merge, size: 16),
            label: const Text('Resolve conflicts'),
          )
        else
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => _confirmAcceptTask(context, task.id!),
            icon: const Icon(Icons.merge, size: 16),
            label: const Text('Accept & merge'),
          ),
      if (_retryableStatuses.contains(task.status))
        OutlinedButton.icon(
          onPressed: state.submitting
              ? null
              : () => bloc.add(TaskRetried(task.id!)),
          icon: const Icon(Icons.replay, size: 16),
          label: const Text('Retry task'),
        ),
      if (_cancellableStatuses.contains(task.status))
        OutlinedButton.icon(
          style: destructive,
          onPressed: state.submitting
              ? null
              : () => bloc.add(TaskCancelled(task.id!)),
          icon: const Icon(Icons.stop_circle_outlined, size: 16),
          label: const Text('Cancel task'),
        ),
      if (_deletableStatuses.contains(task.status))
        OutlinedButton.icon(
          style: destructive,
          onPressed: state.submitting
              ? null
              : () => _confirmDeleteTask(context, task.id!),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Delete task'),
        ),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, action) in actions.indexed) ...[
            if (i > 0) const SizedBox(height: Spacing.sm),
            action,
          ],
        ],
      ),
    );
  }
}

class _RailSection extends StatelessWidget {
  const _RailSection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTypography.label),
          const SizedBox(height: Spacing.sm),
          child,
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow(this.label, this.at);

  final String label;
  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final timestamp = at;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.caption)),
          Text(
            timestamp == null ? '—' : relativeTime(timestamp),
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _SectionContent extends StatelessWidget {
  const _SectionContent({
    required this.state,
    required this.section,
    required this.onSectionSelected,
  });

  final TaskDetailLoaded state;
  final _TaskSection section;
  final ValueChanged<_TaskSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      _TaskSection.overview => _Overview(state: state),
      _TaskSection.changes => _ChangesView(state: state),
      _TaskSection.review => _ReviewView(
        state: state,
        onOpenFile: (path) {
          final file = state.files
              ?.where((f) => f.filename == path)
              .firstOrNull;
          if (file == null) return;
          context.read<TaskDetailBloc>().add(FileSelected(file));
          onSectionSelected(_TaskSection.changes);
        },
      ),
      _TaskSection.logs =>
        _isLive(state.task.status)
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
    return TaskLogView(entries: state.logs);
  }
}

/// What needs the dev's attention for the current status.
class _Overview extends StatelessWidget {
  const _Overview({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return switch (state.task.status) {
      TaskStatus.waitingForAnswer => _PendingQuestion(
        key: ValueKey(state.pendingQuestion?.id),
        state: state,
      ),
      TaskStatus.planReady => _PlanReview(state: state),
      TaskStatus.planning || TaskStatus.running => _LiveExecution(
        state: state,
      ),
      // Never shown: these statuses have no Overview section.
      TaskStatus.awaitingReview || TaskStatus.done => const SizedBox.shrink(),
      TaskStatus.failed => Text(
        state.task.failureReason ?? 'This task failed.',
        style: AppTypography.body.copyWith(color: AppColors.red),
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

class _PendingQuestion extends StatefulWidget {
  const _PendingQuestion({super.key, required this.state});

  final TaskDetailLoaded state;

  @override
  State<_PendingQuestion> createState() => _PendingQuestionState();
}

class _PendingQuestionState extends State<_PendingQuestion> {
  String? _selectedOption;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _submit(int questionId) {
    final custom = _customController.text.trim();
    final answer = custom.isNotEmpty ? custom : _selectedOption;
    if (answer == null) return;
    context.read<TaskDetailBloc>().add(AnswerSubmitted(questionId, answer));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final question = state.pendingQuestion;
    if (question == null) {
      return Text(
        'Waiting for the question to load…',
        style: AppTypography.body,
      );
    }

    final hasAnswer =
        _selectedOption != null || _customController.text.trim().isNotEmpty;
    final canSubmit = hasAnswer && !state.submitting;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: AppColors.accent),
              const SizedBox(width: Spacing.sm),
              Text(
                'CLAUDE IS ASKING A QUESTION',
                style: AppTypography.label.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Text(question.question, style: AppTypography.cardTitle),
          const SizedBox(height: Spacing.xl),
          for (final option in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _OptionRow(
                label: option,
                selected: _selectedOption == option,
                onTap: state.submitting
                    ? null
                    : () => setState(() {
                        _selectedOption = option;
                        _customController.clear();
                      }),
              ),
            ),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _customController,
            enabled: !state.submitting,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Or write your own answer…',
            ),
            onChanged: (value) => setState(() {
              if (_selectedOption != null && value.trim().isNotEmpty) {
                _selectedOption = null;
              }
            }),
          ),
          const SizedBox(height: Spacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: canSubmit ? () => _submit(question.id!) : null,
              child: const Text('Submit answer'),
            ),
          ),
          if (state.submitting) ...[
            const SizedBox(height: Spacing.md),
            Text(
              'Answer sent — agent continuing…',
              style: AppTypography.body.copyWith(color: AppColors.text1),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.14)
                : AppColors.bg2,
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: selected ? AppColors.text0 : AppColors.text1,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanReview extends StatelessWidget {
  const _PlanReview({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    final submitting = state.submitting;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: AppColors.accent),
              const SizedBox(width: Spacing.sm),
              Text(
                'PLAN READY FOR REVIEW',
                style: AppTypography.label.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          AppCard(child: PlanContent(markdown: task.currentPlan ?? '')),
          const SizedBox(height: Spacing.xl),
          _FeedbackRow(
            hint: 'Give feedback',
            submitting: submitting,
            onSubmit: (message) => context.read<TaskDetailBloc>().add(
              PlanFeedbackSubmitted(task.id!, message),
            ),
            trailing: FilledButton.icon(
              onPressed: submitting
                  ? null
                  : () => context.read<TaskDetailBloc>().add(
                      PlanApproved(task.id!),
                    ),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Approve & run'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveExecution extends StatelessWidget {
  const _LiveExecution({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('LIVE OUTPUT', style: AppTypography.label),
            const Spacer(),
            const StatusDot(color: AppColors.live, pulsing: true),
            const SizedBox(width: Spacing.xs),
            Text(
              'streaming',
              style: AppTypography.caption.copyWith(color: AppColors.live),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Expanded(
          child: state.logs.isEmpty
              ? Text('Waiting for output…', style: AppTypography.body)
              : TaskLogView(entries: state.logs),
        ),
      ],
    );
  }
}

/// Spinner / error-with-retry while the PR's changed files aren't loaded;
/// null once they are.
Widget? _filesPlaceholder(BuildContext context, TaskDetailLoaded state) {
  if (state.files != null) return null;
  final error = state.filesError;
  if (error == null) {
    return const Center(child: CircularProgressIndicator());
  }
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Couldn't load the PR's changes: $error",
          style: AppTypography.body.copyWith(color: AppColors.red),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.md),
        OutlinedButton.icon(
          onPressed: () => context.read<TaskDetailBloc>().add(
            ChangedFilesReloaded(state.task.id!),
          ),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

/// The PR's diff: file list + the selected file with review comments inline.
class _ChangesView extends StatelessWidget {
  const _ChangesView({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final placeholder = _filesPlaceholder(context, state);
    if (placeholder != null) return placeholder;
    final files = state.files!;
    if (files.isEmpty) {
      return Center(
        child: Text('No changed files', style: AppTypography.body),
      );
    }

    final comments = state.reviewComments;
    int openCommentsOn(String path) => comments
        .where((c) => c.path == path && c.state == ReviewCommentState.open)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChangeStats(files: files),
        if (state.inReview && state.hasConflicts) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            'This branch has conflicts with ${state.mergeStatus!.baseBranch}.',
            style: AppTypography.body.copyWith(color: AppColors.red),
          ),
        ],
        const SizedBox(height: Spacing.md),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final selected =
                        file.filename == state.selectedFile?.filename;
                    return ListTile(
                      selected: selected,
                      selectedTileColor: AppColors.bg2,
                      leading: const Icon(
                        Icons.description_outlined,
                        color: AppColors.text1,
                      ),
                      title: Text(
                        file.filename,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyStrong,
                      ),
                      subtitle: Text(file.status, style: AppTypography.caption),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${file.additions} -${file.deletions}',
                            style: AppTypography.code,
                          ),
                          if (openCommentsOn(file.filename) case final n
                              when n > 0)
                            Text(
                              '$n comment${n == 1 ? '' : 's'}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                        ],
                      ),
                      onTap: () => context.read<TaskDetailBloc>().add(
                        FileSelected(file),
                      ),
                    );
                  },
                ),
              ),
              VerticalDivider(width: 1, color: AppColors.border),
              Expanded(child: _SelectedFileDiff(state: state)),
            ],
          ),
        ),
        if (state.inReview) ...[
          const SizedBox(height: Spacing.md),
          _IterationFeedbackRow(state: state),
        ],
      ],
    );
  }
}

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    : () => _openRequestReviewDialog(context, state.task.id!),
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: Text(
                  state.reviews.isEmpty ? 'Request AI review' : 'Review again',
                ),
              ),
          ],
        ),
        if (latestReview != null) ...[
          const SizedBox(height: Spacing.md),
          _ReviewStatusRow(review: latestReview, maxLines: null),
        ],
        if (state.reviewError != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            state.reviewError!,
            style: AppTypography.body.copyWith(color: AppColors.red),
          ),
        ],
        const SizedBox(height: Spacing.lg),
        Expanded(
          child: comments.isEmpty
              ? Center(
                  child: Text(
                    latestReview == null
                        ? 'No AI review yet — request one to get comments '
                              'on this PR.'
                        : reviewActive
                        ? 'Review in progress…'
                        : 'The review left no comments.',
                    style: AppTypography.body.copyWith(color: AppColors.text1),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comments · ${state.openCommentCount} open of '
                      '${comments.length}',
                      style: AppTypography.bodyStrong,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Expanded(
                      child: ListView.separated(
                        itemCount: comments.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: Spacing.sm),
                        itemBuilder: (context, index) => _commentCard(
                          context,
                          state,
                          comments[index],
                          editable: editable,
                          onOpenLocation: canOpenFiles
                              ? () => onOpenFile(comments[index].path)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (state.inReview) ...[
          const SizedBox(height: Spacing.md),
          _IterationFeedbackRow(state: state),
        ],
      ],
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
          : 'Send $selectedCount comment${selectedCount == 1 ? '' : 's'} to agent',
      allowEmpty: selectedCount > 0,
      onSubmit: (message) => context.read<TaskDetailBloc>().add(
        selectedCount == 0
            ? ReviewFeedbackSubmitted(state.task.id!, message)
            : CommentsSentToFix(state.task.id!, message),
      ),
    );
  }
}

/// The latest review's progress and the reviewer's overall verdict.
class _ReviewStatusRow extends StatelessWidget {
  const _ReviewStatusRow({required this.review, this.maxLines = 3});

  final CodeReview review;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final (color, label, pulsing) = switch (review.status) {
      CodeReviewStatus.queued => (AppColors.text2, 'Review queued', false),
      CodeReviewStatus.running => (AppColors.live, 'Reviewing…', true),
      CodeReviewStatus.completed => (AppColors.accentSoft, 'AI review', false),
      CodeReviewStatus.failed => (AppColors.red, 'Review failed', false),
    };
    final detail = review.status == CodeReviewStatus.failed
        ? review.failureReason
        : review.summary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusPill(color: color, label: label, pulsing: pulsing),
        if (detail != null) ...[
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              detail,
              style: AppTypography.body.copyWith(
                color: review.status == CodeReviewStatus.failed
                    ? AppColors.red
                    : AppColors.text1,
              ),
              maxLines: maxLines,
              overflow: maxLines == null ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
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

enum _FileViewMode { diff, fullFile }

class _SelectedFileDiff extends StatefulWidget {
  const _SelectedFileDiff({required this.state});

  final TaskDetailLoaded state;

  @override
  State<_SelectedFileDiff> createState() => _SelectedFileDiffState();
}

class _SelectedFileDiffState extends State<_SelectedFileDiff> {
  late _FileViewMode _mode = _defaultModeFor(widget.state.selectedFile);

  @override
  void didUpdateWidget(_SelectedFileDiff oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.selectedFile?.filename !=
        oldWidget.state.selectedFile?.filename) {
      _mode = _defaultModeFor(widget.state.selectedFile);
    }
    _maybeFetchFullFile();
  }

  @override
  void initState() {
    super.initState();
    _maybeFetchFullFile();
  }

  _FileViewMode _defaultModeFor(DiffFile? file) =>
      file?.patch == null ? _FileViewMode.fullFile : _FileViewMode.diff;

  void _maybeFetchFullFile() {
    final state = widget.state;
    if (_mode == _FileViewMode.fullFile &&
        state.selectedFile != null &&
        state.fileContent == null &&
        !state.fileContentLoading &&
        state.fileContentError == null) {
      context.read<TaskDetailBloc>().add(const FullFileContentRequested());
    }
  }

  void _selectMode(_FileViewMode mode) {
    setState(() => _mode = mode);
    _maybeFetchFullFile();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final file = state.selectedFile;
    if (file == null) {
      return Center(
        child: Text(
          'Select a file to view its diff',
          style: AppTypography.body,
        ),
      );
    }

    final patch = file.patch;
    final language = languageForFilename(file.filename);
    final editable =
        state.task.status == TaskStatus.awaitingReview &&
        !state.reviews.any(
          (r) =>
              r.status == CodeReviewStatus.queued ||
              r.status == CodeReviewStatus.running,
        );
    final shownLines = patch == null ? const <int>{} : _diffNewLines(patch);
    final byLine = <int, List<ReviewComment>>{};
    final unplaced = <ReviewComment>[];
    for (final comment in state.reviewComments) {
      if (comment.path != file.filename) continue;
      final line = comment.line;
      if (line != null && shownLines.contains(line)) {
        (byLine[line] ??= []).add(comment);
      } else {
        unplaced.add(comment);
      }
    }
    final annotations = {
      for (final MapEntry(key: line, value: onLine) in byLine.entries)
        line: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final comment in onLine)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xs),
                child: _commentCard(
                  context,
                  state,
                  comment,
                  editable: editable,
                  showLocation: false,
                ),
              ),
          ],
        ),
    };
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(file.filename, style: AppTypography.cardTitle),
                ),
                PillSelector<_FileViewMode>(
                  options: _FileViewMode.values,
                  labelBuilder: (mode) => switch (mode) {
                    _FileViewMode.diff => 'Diff',
                    _FileViewMode.fullFile => 'Full file',
                  },
                  selected: _mode,
                  onChanged: _selectMode,
                  disabledOptions: patch == null ? {_FileViewMode.diff} : {},
                  disabledHint: 'No diff',
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            for (final comment in unplaced) ...[
              _commentCard(context, state, comment, editable: editable),
              const SizedBox(height: Spacing.sm),
            ],
            if (_mode == _FileViewMode.diff)
              DiffView(
                patch: patch!,
                language: language,
                annotations: annotations,
              )
            else if (state.fileContentLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(Spacing.xl),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (state.fileContentError != null)
              Text(
                'Failed to load file content: ${state.fileContentError}',
                style: AppTypography.body.copyWith(color: AppColors.red),
              )
            else if (state.fileContent != null)
              patch != null
                  ? FullFileDiffView(
                      patch: patch,
                      fileContent: state.fileContent!,
                      language: language,
                      annotations: annotations,
                    )
                  : CodeBlock(code: state.fileContent!),
          ],
        ),
      ),
    );
  }
}

/// A feedback textarea + submit affordance, shared by the plan-review and
/// diff-review states (design brief: "Give feedback" / "Leave feedback for
/// another iteration…").
class _FeedbackRow extends StatefulWidget {
  const _FeedbackRow({
    required this.hint,
    required this.submitting,
    required this.onSubmit,
    this.trailing,
    this.submitLabel = 'Send feedback',
    this.allowEmpty = false,
  });

  final String hint;
  final String submitLabel;

  /// Submit even with an empty message (e.g. when sending selected review
  /// comments, where the note is optional).
  final bool allowEmpty;
  final bool submitting;
  final ValueChanged<String> onSubmit;

  /// An extra primary action shown alongside "Send feedback" (plan review's
  /// "Approve & run").
  final Widget? trailing;

  @override
  State<_FeedbackRow> createState() => _FeedbackRowState();
}

class _FeedbackRowState extends State<_FeedbackRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final message = _controller.text.trim();
    if (message.isEmpty && !widget.allowEmpty) return;
    widget.onSubmit(message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(hintText: widget.hint),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        if (widget.trailing != null) ...[
          widget.trailing!,
          const SizedBox(width: Spacing.sm),
        ],
        FilledButton(
          onPressed: widget.submitting ? null : _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

/// New-file line numbers a unified diff shows (added and context lines) —
/// where [DiffView] can place an inline comment.
Set<int> _diffNewLines(String patch) {
  final hunkHeader = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)');
  final lines = <int>{};
  int? next;
  for (final line in patch.split('\n')) {
    final header = hunkHeader.firstMatch(line);
    if (header != null) {
      next = int.parse(header.group(1)!);
      continue;
    }
    if (next == null || line.startsWith('-') || line.startsWith('\\')) {
      continue;
    }
    lines.add(next++);
  }
  return lines;
}
