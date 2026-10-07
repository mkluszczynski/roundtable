import 'package:flutter/material.dart';

import '../utils/agent_role_label.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../blocs/task_detail_bloc.dart';
import '../client.dart';
import '../repositories/agent_repository.dart';
import '../repositories/machine_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import '../utils/checkout_command.dart';
import '../utils/code_language.dart';
import '../utils/follow_up_prompt.dart';
import '../widgets/copy_icon_button.dart';
import '../utils/pr_checks.dart';
import '../utils/question_context.dart';
import '../utils/open_task.dart';
import '../utils/task_status_label.dart';
import '../utils/task_timeline.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/agent_avatar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_modal.dart';
import '../widgets/code_block.dart';
import '../widgets/create_task_dialog.dart';
import '../widgets/diff_view.dart';
import '../widgets/edit_task_dialog.dart';
import '../widgets/pill_selector.dart';
import '../widgets/rail_nav_item.dart';
import '../widgets/rail_section.dart';
import '../widgets/plan_content.dart';
import '../widgets/pr_checks_view.dart';
import '../widgets/reassign_agent_dialog.dart';
import '../widgets/rename_task_dialog.dart';
import '../widgets/request_review_dialog.dart';
import '../widgets/review_comment_card.dart';
import '../widgets/status_pill.dart';
import '../widgets/tag_chip.dart';
import '../widgets/task_attachments_view.dart';
import '../widgets/task_options_form.dart';
import '../utils/log_timeline.dart';
import '../widgets/task_log_timeline.dart';
import '../widgets/task_timeline_view.dart';
import '../utils/relative_time.dart';

/// Mirrors the server's `cancelTask` guard (`nonTerminalTaskStatuses` minus
/// `draft`, docs/ARCHITECTURE.md) — the header's "Cancel task" button, which
/// moves the task back to the backlog as an agent-less draft, only shows
/// while the task is still something a `cancelTask` call can act on.
const _cancellableStatuses = {
  TaskStatus.queued,
  TaskStatus.cloning,
  TaskStatus.planning,
  TaskStatus.waitingForAnswer,
  TaskStatus.planReady,
  TaskStatus.running,
  TaskStatus.awaitingReview,
  TaskStatus.paused,
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

Future<void> _openRenameTaskDialog(BuildContext context, Task task) async {
  final bloc = context.read<TaskDetailBloc>();
  final title = await showDialog<String>(
    context: context,
    builder: (_) => RenameTaskDialog(taskId: task.id!, title: task.title),
  );
  if (title != null && title != (task.title ?? '')) {
    bloc.add(TaskRenamed(task.id!, title));
  }
}

void _openEditTaskDialog(BuildContext context, Task task) {
  final repository = TaskRepository(client);
  showDialog<void>(
    context: context,
    builder: (_) => EditTaskDialog(
      task: task,
      onSave: (prompt, options) => repository.updateTaskSettings(
        task.id!,
        prompt,
        skipPlanning: options.skipPlanning,
        autoReview: options.autoReview,
        reviewerAgentId: options.reviewerAgentId,
        autoFixReview: options.autoFixReview,
        maxReviewFixRounds: options.maxReviewFixRounds,
        autoMerge: options.autoMerge,
        autoFixFailingChecks: options.autoFixFailingChecks,
        maxCheckFixAttempts: options.maxCheckFixAttempts,
      ),
    ),
  );
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

void _openRequestReviewDialog(BuildContext context, Task task) {
  final bloc = context.read<TaskDetailBloc>();
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: RequestReviewDialog(
        taskId: task.id!,
        initialAgentId: task.reviewerAgentId,
      ),
    ),
  );
}

/// [overriddenChecks]: why the CI checks would block the merge — confirming
/// merges anyway.
Future<void> _confirmAcceptTask(
  BuildContext context,
  int taskId, {
  String? overriddenChecks,
}) async {
  final bloc = context.read<TaskDetailBloc>();
  final force = overriddenChecks != null;
  final confirmed = await showAppModal<bool>(
    context,
    icon: Icons.merge,
    tone: force ? AppModalTone.danger : AppModalTone.normal,
    title: force ? 'Merge despite the CI checks?' : 'Accept and merge?',
    subtitle: force
        ? '$overriddenChecks. This squash-merges the PR of Task #$taskId '
              'anyway — GitHub still enforces the checks its branch '
              'protection requires.'
        : 'This squash-merges the PR on GitHub and moves Task #$taskId to '
              'Done.',
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
          style: force
              ? FilledButton.styleFrom(backgroundColor: AppColors.red)
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(force ? 'Merge anyway' : 'Accept & merge'),
        ),
      ),
    ],
  );
  if (confirmed ?? false) {
    bloc.add(TaskAccepted(taskId, force: force));
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

Future<void> _confirmFixFailingChecks(
  BuildContext context,
  int taskId,
  int failedCount,
) async {
  final bloc = context.read<TaskDetailBloc>();
  final confirmed = await showAppModal<bool>(
    context,
    icon: Icons.build_outlined,
    tone: AppModalTone.danger,
    title: 'Send failing CI checks to the agent?',
    subtitle:
        'The agent gets the logs of the failing jobs ($failedCount) of Task '
        '#$taskId, fixes them and pushes. To pick jobs or add a note, use the '
        'CI checks view.',
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
          child: const Text('Send to agent'),
        ),
      ),
    ],
  );
  if (confirmed ?? false) {
    bloc
      ..add(const CheckJobsSelectionCleared())
      ..add(FailingChecksSentToFix(taskId, ''));
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
      child: _OpenTaskReporter(
        taskId: initialTaskId,
        child: const Scaffold(
          backgroundColor: AppColors.bg0,
          body: _TaskDetailView(),
        ),
      ),
    );
  }
}

/// Marks [taskId] as the open task ([openTaskId]) while this screen lives.
class _OpenTaskReporter extends StatefulWidget {
  const _OpenTaskReporter({required this.taskId, required this.child});

  final int taskId;
  final Widget child;

  @override
  State<_OpenTaskReporter> createState() => _OpenTaskReporterState();
}

class _OpenTaskReporterState extends State<_OpenTaskReporter> {
  @override
  void initState() {
    super.initState();
    // After the frame: the rail listening to it may be building now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) openTaskId.value = widget.taskId;
    });
  }

  @override
  void dispose() {
    // Not now: the tree is locked while it's torn down.
    final id = widget.taskId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (openTaskId.value == id) openTaskId.value = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// What the main area shows — picked from the rail's navigation.
enum _TaskSection { overview, plan, changes, review, checks, logs }

bool _isLive(TaskStatus s) =>
    s == TaskStatus.planning || s == TaskStatus.running;

/// A task in review or done with a PR — not one that finished without
/// changing code (its result is in Overview instead).
bool _hasPullRequestViews(Task task) =>
    (task.status == TaskStatus.awaitingReview ||
        task.status == TaskStatus.done) &&
    (task.prUrl != null || task.branchName != null);

/// The section a task opens on: the log while the agent works and while its
/// PR awaits review (so the dev reads the agent's closing message before the
/// diff), the diff of a done task's PR, otherwise whatever needs the dev's
/// attention.
_TaskSection _defaultSectionFor(Task task) {
  if (_isLive(task.status)) return _TaskSection.logs;
  if (_hasPullRequestViews(task)) {
    return task.status == TaskStatus.awaitingReview
        ? _TaskSection.logs
        : _TaskSection.changes;
  }
  return _TaskSection.overview;
}

/// Overview only exists while the status has its own content (question,
/// plan, failure…) — live tasks have the log, PR tasks have Changes/Review.
/// Plan stays reachable as a read-only tab once there is one, so the dev can
/// switch back to it after leaving `planReady` — except right on
/// `planReady` itself, where Overview already shows it with approve/feedback.
/// AI review stays reachable once the task has a PR or a review, so the dev
/// can read the comments an (auto) fix run is working on.
Set<_TaskSection> _availableSectionsFor(TaskDetailLoaded state) {
  final task = state.task;
  final s = task.status;
  return {
    if (!_isLive(s) && !_hasPullRequestViews(task)) _TaskSection.overview,
    if (task.currentPlan != null && s != TaskStatus.planReady)
      _TaskSection.plan,
    if (_hasPullRequestViews(task)) _TaskSection.changes,
    if (_hasPullRequestViews(task) ||
        task.prUrl != null ||
        state.reviews.isNotEmpty)
      _TaskSection.review,
    // Also while a fix run is going, so the dev sees what it's fixing.
    if (task.prUrl != null) _TaskSection.checks,
    _TaskSection.logs,
  };
}

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

  int get sentToFixCommentCount => reviewComments
      .where((c) => c.state == ReviewCommentState.sentToFix)
      .length;

  bool get hasConflicts => mergeStatus?.hasConflicts ?? false;

  int get failedCheckCount =>
      checks?.runs.where(isFailedCheckRun).length ??
      (task.checkState == PrCheckState.failure ? 1 : 0);

  /// Why "Accept & merge" is disabled, or null when the CI checks allow it.
  /// The server enforces the same rule in `acceptTask`.
  String? get mergeBlockedByChecks => switch (task.checkState) {
    PrCheckState.success || PrCheckState.none => null,
    PrCheckState.pending => 'Waiting for the CI checks to finish',
    PrCheckState.failure =>
      'CI checks are failing — send them to the agent or fix them first',
  };
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
            TaskDetailInitial() || TaskDetailLoading() || TaskDetailDeleted() =>
              const Center(child: CircularProgressIndicator()),
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
    final picked = _section;
    final section =
        picked != null && _availableSectionsFor(state).contains(picked)
        ? picked
        : _defaultSectionFor(state.task);
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
                  const TextSpan(text: '  ·  '),
                  task.title == null
                      ? TextSpan(
                          text: 'Untitled',
                          style: AppTypography.body.copyWith(
                            color: AppColors.text2,
                          ),
                        )
                      : TextSpan(
                          text: task.title,
                          style: AppTypography.bodyStrong.copyWith(
                            color: AppColors.text0,
                          ),
                        ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(
              Icons.edit_outlined,
              size: 16,
              color: AppColors.text1,
            ),
            onPressed: () => _openRenameTaskDialog(context, task),
            visualDensity: VisualDensity.compact,
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
                      TimelineLink.log => _TaskSection.logs,
                      TimelineLink.review => _TaskSection.review,
                    }),
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
    final available = _availableSectionsFor(state);
    final files = state.files;
    final openComments = state.openCommentCount;
    final sentToFixComments = state.sentToFixCommentCount;
    return RailSection(
      label: 'View',
      child: Column(
        children: [
          for (final s in _TaskSection.values)
            if (available.contains(s))
              RailNavItem(
                icon: switch (s) {
                  _TaskSection.overview => Icons.dashboard_outlined,
                  _TaskSection.plan => Icons.checklist_outlined,
                  _TaskSection.changes => Icons.difference_outlined,
                  _TaskSection.review => Icons.rate_review_outlined,
                  _TaskSection.checks => Icons.fact_check_outlined,
                  _TaskSection.logs => Icons.terminal,
                },
                label: switch (s) {
                  _TaskSection.overview => switch (state.task.status) {
                    TaskStatus.waitingForAnswer => 'Question',
                    TaskStatus.planReady => 'Plan',
                    TaskStatus.done || TaskStatus.awaitingReview => 'Result',
                    _ => 'Details',
                  },
                  _TaskSection.plan => 'Plan',
                  _TaskSection.changes => 'Changes',
                  _TaskSection.review => 'AI review',
                  _TaskSection.checks => 'CI checks',
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
                  _TaskSection.review when openComments > 0 => CountBadge(
                    openComments,
                  ),
                  _TaskSection.review when sentToFixComments > 0 => CountBadge(
                    sentToFixComments,
                    color: AppColors.text2,
                  ),
                  _TaskSection.checks
                      when state.task.checkState == PrCheckState.failure =>
                    CountBadge(state.failedCheckCount, color: AppColors.red),
                  _TaskSection.checks
                      when state.task.checkState != PrCheckState.none =>
                    StatusDot(
                      color: checkStateAppearance(state.task.checkState).color,
                      pulsing: checkStateAppearance(
                        state.task.checkState,
                      ).pulsing,
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
            onPressed: () => launchUrl(
              Uri.parse(task.prUrl!),
              mode: LaunchMode.externalApplication,
            ),
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
        else ...[
          if (task.checkState == PrCheckState.failure)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: busy || state.checksBusy
                  ? null
                  : () => _confirmFixFailingChecks(
                      context,
                      task.id!,
                      state.failedCheckCount,
                    ),
              icon: const Icon(Icons.build_outlined, size: 16),
              label: const Text('Fix CI checks'),
            ),
          ..._acceptButtons(context, state, busy: busy),
        ],
      if (_retryableStatuses.contains(task.status))
        OutlinedButton.icon(
          onPressed: state.submitting
              ? null
              : () => bloc.add(TaskRetried(task.id!)),
          icon: const Icon(Icons.replay, size: 16),
          label: const Text('Retry task'),
        ),
      if (_cancellableStatuses.contains(task.status))
        Tooltip(
          message: 'Move back to the backlog as a draft',
          child: OutlinedButton.icon(
            style: destructive,
            onPressed: state.submitting
                ? null
                : () => bloc.add(TaskCancelled(task.id!)),
            icon: const Icon(Icons.stop_circle_outlined, size: 16),
            label: const Text('Cancel task'),
          ),
        ),
      if (task.status == TaskStatus.done)
        OutlinedButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => CreateTaskDialog(
              initialProjectId: task.projectId,
              initialAgentId: task.agentId,
              initialPrompt: followUpPrompt(task),
            ),
          ),
          icon: const Icon(Icons.add_task, size: 16),
          label: const Text('Follow-up task'),
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

/// "Accept & merge", disabled (with the reason on hover) until the CI
/// checks allow merging — plus "Merge anyway" for a flaky or non-required
/// job the dev decides to ignore.
List<Widget> _acceptButtons(
  BuildContext context,
  TaskDetailLoaded state, {
  required bool busy,
}) {
  final blocked = state.mergeBlockedByChecks;
  final button = FilledButton.icon(
    onPressed: busy || blocked != null
        ? null
        : () => _confirmAcceptTask(context, state.task.id!),
    icon: const Icon(Icons.merge, size: 16),
    label: const Text('Accept & merge'),
  );
  final autoMergeHint = state.task.autoMerge
      ? const Tooltip(
          message:
              'Merges by itself once CI passes and, with auto review, the '
              'review has no open blockers or issues',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_mode, size: 14, color: AppColors.live),
              SizedBox(width: Spacing.xs),
              Text(
                'Auto merge on',
                style: TextStyle(color: AppColors.live, fontSize: 12),
              ),
            ],
          ),
        )
      : null;
  if (blocked == null) return [?autoMergeHint, button];
  return [
    ?autoMergeHint,
    Tooltip(message: blocked, child: button),
    OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.red,
        side: BorderSide(color: AppColors.red.withValues(alpha: 0.5)),
      ),
      onPressed: busy
          ? null
          : () => _confirmAcceptTask(
              context,
              state.task.id!,
              overriddenChecks: blocked,
            ),
      icon: const Icon(Icons.warning_amber_outlined, size: 16),
      label: const Text('Merge anyway'),
    ),
  ];
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
      _TaskSection.plan => _ReadingColumn(child: _PlanView(state: state)),
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
      _TaskSection.checks => _ReadingColumn(child: _ChecksView(state: state)),
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
          if (questionContext(state.logs) case final context?) ...[
            AppCard(child: PlanContent(markdown: context)),
            const SizedBox(height: Spacing.xl),
          ],
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
          _FeedbackRow(
            controller: _customController,
            hint: question.options.isEmpty
                ? 'Write your answer…'
                : 'Or write your own answer…',
            submitLabel: 'Submit answer',
            primarySubmit: true,
            // A picked option is a complete answer on its own.
            allowEmpty: _selectedOption != null,
            submitting: state.submitting,
            onChanged: (value) => setState(() {
              if (_selectedOption != null && value.trim().isNotEmpty) {
                _selectedOption = null;
              }
            }),
            onSubmit: (custom) {
              final answer = custom.isNotEmpty ? custom : _selectedOption;
              if (answer == null) return;
              context.read<TaskDetailBloc>().add(
                AnswerSubmitted(question.id!, answer),
              );
            },
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
          _PlanContentCard(markdown: task.currentPlan ?? ''),
          const SizedBox(height: Spacing.xl),
          _FeedbackRow(
            hint: 'Ask for changes to the plan…',
            submitLabel: 'Request changes',
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

/// The plan, reachable as a read-only tab after it's been approved — lets
/// the dev switch over to the log/diff and still come back to re-read it.
class _PlanView extends StatelessWidget {
  const _PlanView({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _PlanContentCard(markdown: state.task.currentPlan ?? ''),
    );
  }
}

class _PlanContentCard extends StatelessWidget {
  const _PlanContentCard({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) =>
      AppCard(child: PlanContent(markdown: markdown));
}

class _LiveExecution extends StatelessWidget {
  const _LiveExecution({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.logs.isEmpty) {
      return Text('Waiting for output…', style: AppTypography.body);
    }
    return TaskLogTimeline(entries: state.logs, live: true);
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
      return Center(child: Text('No changed files', style: AppTypography.body));
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
          if (_isLive(state.task.status) &&
              state.sentToFixCommentCount > 0) ...[
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
    this.primarySubmit = false,
    this.controller,
    this.onChanged,
  });

  final String hint;

  /// Makes the send button the filled primary action — for a composer with
  /// no [trailing] action of its own (answering a question).
  final bool primarySubmit;

  /// Owned by the caller when it needs to read or clear the text itself.
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
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
  late final _controller = widget.controller ?? TextEditingController();
  bool _focused = false;

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final message = _controller.text.trim();
    if (message.isEmpty && !widget.allowEmpty) return;
    widget.onSubmit(message);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    final canSend = !widget.submitting && (hasText || widget.allowEmpty);
    // A composer: the text box and its actions in one bordered surface, so
    // the send action reads as part of the message, not a second primary.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (canSend) _submit();
        },
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
          if (canSend) _submit();
        },
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Focus(
              onFocusChange: (focused) => setState(() => _focused = focused),
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 8,
                style: AppTypography.body,
                enabled: !widget.submitting,
                onChanged: (value) {
                  setState(() {});
                  widget.onChanged?.call(value);
                },
                decoration: InputDecoration(
                  hintText: widget.hint,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.lg,
                    Spacing.lg,
                    Spacing.sm,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.xs,
                Spacing.sm,
                Spacing.sm,
              ),
              child: Row(
                children: [
                  Text('Ctrl + Enter to send', style: AppTypography.caption),
                  const Spacer(),
                  if (widget.primarySubmit)
                    FilledButton.icon(
                      onPressed: canSend ? _submit : null,
                      icon: const Icon(Icons.send, size: 14),
                      label: Text(widget.submitLabel),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: canSend ? _submit : null,
                      icon: const Icon(Icons.send, size: 14),
                      label: Text(widget.submitLabel),
                    ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: Spacing.sm),
                    widget.trailing!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
