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

/// Mirrors the server's `nonTerminalTaskStatuses` (design doc §5, §6.8) —
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
    title: 'Delete task?',
    subtitle: 'This permanently removes Task #$taskId and its logs.',
    child: const SizedBox.shrink(),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: AppColors.red),
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Delete'),
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
    title: 'Accept and merge?',
    subtitle:
        'This squash-merges the PR on GitHub and moves Task #$taskId to Done.',
    child: const SizedBox.shrink(),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Accept & merge'),
      ),
    ],
  );
  if (confirmed ?? false) {
    bloc.add(TaskAccepted(taskId));
  }
}

/// One screen driven by `Task.status`, switching between the task lifecycle's
/// 4 sub-states (design doc §6.4, §6.7): waiting for an answer, plan
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

class _TaskDetailView extends StatelessWidget {
  const _TaskDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskDetailBloc, TaskDetailState>(
      listenWhen: (previous, current) => current is TaskDetailDeleted,
      listener: (context, state) {
        if (Navigator.canPop(context)) Navigator.of(context).pop();
      },
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
            TaskDetailLoaded() => Column(
              children: [
                _Header(state: state),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 320, child: _InfoRail(state: state)),
                      VerticalDivider(width: 1, color: AppColors.border),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(Spacing.xl),
                          child: _SubState(state: state),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          };
        },
      ),
    );
  }
}

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
          Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.text1),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                )
              : const SizedBox.shrink(),
          Expanded(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: AppTypography.bodyStrong,
                children: [
                  const TextSpan(text: 'Roundtable  /  '),
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
          StatusPill.fromAppearance(
            taskStatusAppearance(task.status),
            label: task.status.label,
          ),
          if (state.agent != null) ...[
            const SizedBox(width: Spacing.lg),
            AgentAvatar(name: state.agent!.name),
            const SizedBox(width: Spacing.sm),
            Text(state.agent!.name, style: AppTypography.body),
            if (_reassignableStatuses.contains(task.status)) ...[
              const SizedBox(width: Spacing.xs),
              IconButton(
                icon: const Icon(
                  Icons.swap_horiz,
                  size: 18,
                  color: AppColors.text2,
                ),
                tooltip: 'Reassign agent',
                visualDensity: VisualDensity.compact,
                onPressed: () => _openReassignAgentDialog(
                  context,
                  task.id!,
                  task.agentId,
                ),
              ),
            ],
          ] else ...[
            const SizedBox(width: Spacing.lg),
            OutlinedButton(
              onPressed: () =>
                  _openReassignAgentDialog(context, task.id!, null),
              child: Text(
                task.status == TaskStatus.draft
                    ? 'Assign & start'
                    : 'Assign agent',
              ),
            ),
          ],
          if (_cancellableStatuses.contains(task.status)) ...[
            const SizedBox(width: Spacing.lg),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: BorderSide(color: AppColors.red.withValues(alpha: 0.5)),
              ),
              onPressed: state.submitting
                  ? null
                  : () => context.read<TaskDetailBloc>().add(
                      TaskCancelled(task.id!),
                    ),
              child: const Text('Cancel task'),
            ),
          ],
          if (_retryableStatuses.contains(task.status)) ...[
            const SizedBox(width: Spacing.lg),
            OutlinedButton(
              onPressed: state.submitting
                  ? null
                  : () => context.read<TaskDetailBloc>().add(
                      TaskRetried(task.id!),
                    ),
              child: const Text('Retry task'),
            ),
          ],
          if (_deletableStatuses.contains(task.status)) ...[
            const SizedBox(width: Spacing.lg),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: BorderSide(color: AppColors.red.withValues(alpha: 0.5)),
              ),
              onPressed: state.submitting
                  ? null
                  : () => _confirmDeleteTask(context, task.id!),
              child: const Text('Delete task'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRail extends StatelessWidget {
  const _InfoRail({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    final agent = state.agent;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          if (agent != null)
            _RailSection(
              label: 'Agent',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AgentAvatar(name: agent.name),
                      const SizedBox(width: Spacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(agent.name, style: AppTypography.bodyStrong),
                          Text(
                            '${agent.role.name} specialist',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      TagChip(agent.defaultModel ?? 'default model'),
                      TagChip(
                        'effort: ${agent.defaultEffort?.name ?? 'default'}',
                      ),
                    ],
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
          if (task.branchName != null)
            _RailSection(
              label: 'Branch',
              child: Row(
                children: [
                  const Icon(
                    Icons.call_split,
                    size: 14,
                    color: AppColors.text1,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(task.branchName!, style: AppTypography.code),
                ],
              ),
            ),
          if (task.prUrl != null)
            _RailSection(
              label: 'Pull request',
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(task.prUrl!),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('Open PR'),
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

class _SubState extends StatefulWidget {
  const _SubState({required this.state});

  final TaskDetailLoaded state;

  @override
  State<_SubState> createState() => _SubStateState();
}

class _SubStateState extends State<_SubState> {
  bool _showLogs = false;

  static bool _isLive(TaskStatus s) =>
      s == TaskStatus.planning || s == TaskStatus.running;

  @override
  void didUpdateWidget(covariant _SubState oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasLive = _isLive(oldWidget.state.task.status);
    final isPlanReady = widget.state.task.status == TaskStatus.planReady;
    if (wasLive && isPlanReady && _showLogs) {
      setState(() => _showLogs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    // Live statuses already show the log; the toggle only matters elsewhere.
    if (_isLive(state.task.status)) return _LiveExecution(state: state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PillSelector<bool>(
          options: const [false, true],
          labelBuilder: (showLogs) => showLogs ? 'Logs' : 'Details',
          selected: _showLogs,
          onChanged: (v) => setState(() => _showLogs = v),
        ),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: _showLogs
              ? _LogHistory(state: state)
              : _SubStateBody(state: state),
        ),
      ],
    );
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

class _SubStateBody extends StatelessWidget {
  const _SubStateBody({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return switch (state.task.status) {
      TaskStatus.waitingForAnswer => _PendingQuestion(state: state),
      TaskStatus.planReady => _PlanReview(state: state),
      TaskStatus.planning || TaskStatus.running => _LiveExecution(
        state: state,
      ),
      TaskStatus.awaitingReview || TaskStatus.done => _DiffReview(
        state: state,
      ),
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

class _PendingQuestion extends StatelessWidget {
  const _PendingQuestion({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final question = state.pendingQuestion;
    if (question == null) {
      return Text(
        'Waiting for the question to load…',
        style: AppTypography.body,
      );
    }

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
                onTap: state.submitting
                    ? null
                    : () => context.read<TaskDetailBloc>().add(
                        AnswerSubmitted(question.id!, option),
                      ),
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
  const _OptionRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.lg,
          ),
          child: Text(label, style: AppTypography.body),
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

class _DiffReview extends StatelessWidget {
  const _DiffReview({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final files = state.files;
    if (files == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (files.isEmpty) {
      return Center(
        child: Text('No changed files', style: AppTypography.body),
      );
    }

    final additions = files.fold<int>(0, (sum, f) => sum + f.additions);
    final deletions = files.fold<int>(0, (sum, f) => sum + f.deletions);
    final inReview = state.task.status == TaskStatus.awaitingReview;
    final latestReview = state.reviews.isEmpty ? null : state.reviews.last;
    final reviewActive =
        latestReview != null &&
        (latestReview.status == CodeReviewStatus.queued ||
            latestReview.status == CodeReviewStatus.running);
    final comments = state.reviewComments;
    final openCount = comments
        .where((c) => c.state == ReviewCommentState.open)
        .length;
    final selectedCount = state.selectedCommentIds.length;
    int openCommentsOn(String path) => comments
        .where((c) => c.path == path && c.state == ReviewCommentState.open)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.bodyStrong,
                  children: [
                    TextSpan(text: 'Changes across ${files.length} files  '),
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
              ),
            ),
            if (state.task.prUrl != null)
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(state.task.prUrl!),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('View full PR on GitHub'),
              ),
            if (inReview) ...[
              const SizedBox(width: Spacing.sm),
              OutlinedButton.icon(
                onPressed: reviewActive || state.reviewBusy
                    ? null
                    : () => _openRequestReviewDialog(context, state.task.id!),
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: Text(
                  state.reviews.isEmpty ? 'Request AI review' : 'Review again',
                ),
              ),
              const SizedBox(width: Spacing.sm),
              FilledButton.icon(
                onPressed: reviewActive || state.reviewBusy
                    ? null
                    : () => _confirmAcceptTask(context, state.task.id!),
                icon: const Icon(Icons.merge, size: 16),
                label: const Text('Accept & merge'),
              ),
            ],
          ],
        ),
        if (latestReview != null) ...[
          const SizedBox(height: Spacing.md),
          _ReviewStatusRow(review: latestReview),
        ],
        if (state.reviewError != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            state.reviewError!,
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
        if (comments.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          _ReviewCommentsPanel(
            state: state,
            openCount: openCount,
            editable: inReview && !reviewActive,
          ),
        ],
        if (inReview) ...[
          const SizedBox(height: Spacing.md),
          _FeedbackRow(
            hint: selectedCount == 0
                ? 'Leave feedback for another iteration…'
                : 'Optional note to send with the selected comments…',
            submitting: state.submitting || state.reviewBusy || reviewActive,
            submitLabel: selectedCount == 0
                ? 'Send feedback'
                : 'Send $selectedCount comment${selectedCount == 1 ? '' : 's'} to agent',
            allowEmpty: selectedCount > 0,
            onSubmit: (message) => context.read<TaskDetailBloc>().add(
              selectedCount == 0
                  ? ReviewFeedbackSubmitted(state.task.id!, message)
                  : CommentsSentToFix(state.task.id!, message),
            ),
          ),
        ],
      ],
    );
  }
}

/// The latest review's progress and the reviewer's overall verdict.
class _ReviewStatusRow extends StatelessWidget {
  const _ReviewStatusRow({required this.review});

  final CodeReview review;

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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

/// Every review comment, newest review first — the overview to triage from.
/// Comments are also shown inline in the selected file's diff.
class _ReviewCommentsPanel extends StatelessWidget {
  const _ReviewCommentsPanel({
    required this.state,
    required this.openCount,
    required this.editable,
  });

  final TaskDetailLoaded state;
  final int openCount;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final comments = state.reviewComments.reversed.toList();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review comments · $openCount open of ${comments.length}',
            style: AppTypography.bodyStrong,
          ),
          const SizedBox(height: Spacing.sm),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: comments.length,
              separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) => _commentCard(
                context,
                state,
                comments[index],
                editable: editable,
              ),
            ),
          ),
        ],
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
  );
}

class _SelectedFileDiff extends StatelessWidget {
  const _SelectedFileDiff({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
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
                TextButton.icon(
                  onPressed: state.fileContentLoading
                      ? null
                      : () => context.read<TaskDetailBloc>().add(
                          const FullFileContentRequested(),
                        ),
                  icon: state.fileContentLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.description),
                  label: const Text('View full file'),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            for (final comment in unplaced) ...[
              _commentCard(context, state, comment, editable: editable),
              const SizedBox(height: Spacing.sm),
            ],
            if (patch == null)
              Text(
                'No textual diff available for this file (binary?)',
                style: AppTypography.body,
              )
            else
              DiffView(
                patch: patch,
                annotations: {
                  for (final MapEntry(key: line, value: onLine)
                      in byLine.entries)
                    line: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final comment in onLine)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: Spacing.xs,
                            ),
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
                },
              ),
            if (state.fileContentError != null) ...[
              const SizedBox(height: Spacing.lg),
              Text(
                'Failed to load file content: ${state.fileContentError}',
                style: AppTypography.body.copyWith(color: AppColors.red),
              ),
            ],
            if (state.fileContent != null) ...[
              const SizedBox(height: Spacing.xl),
              Divider(color: AppColors.border),
              const SizedBox(height: Spacing.md),
              Text('Full file', style: AppTypography.cardTitle),
              const SizedBox(height: Spacing.md),
              CodeBlock(code: state.fileContent!),
            ],
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
