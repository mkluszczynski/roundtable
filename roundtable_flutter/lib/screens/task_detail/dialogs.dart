part of '../task_detail_screen.dart';

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
