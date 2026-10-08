part of '../task_detail_screen.dart';

/// Everything that changes the task's lifecycle, pinned under the rail: the
/// status's primary action first, destructive ones last.
class _RailActions extends StatelessWidget {
  const _RailActions({required this.state, this.bar = false});

  final TaskDetailLoaded state;

  /// Under the one-column layout: the actions side by side, as a bar.
  final bool bar;

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    final bloc = context.read<TaskDetailBloc>();
    final busy = state.reviewActive || state.reviewBusy;
    final destructive = OutlinedButton.styleFrom(
      foregroundColor: AppColors.red,
      side: BorderSide(color: AppColors.red.withValues(alpha: 0.5)),
    );
    final submitting = state.submitting;
    final autoMergeHint = state.task.autoMerge ? const _AutoMergeHint() : null;
    final blocked = state.mergeBlockedByChecks;
    final actions = [
      for (final action in state.availableActions)
        switch (action) {
          TaskAction.resolveConflicts => FilledButton.icon(
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
          ),
          TaskAction.fixChecks => FilledButton.icon(
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
          TaskAction.accept => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (autoMergeHint != null) ...[
                autoMergeHint,
                const SizedBox(height: Spacing.sm),
              ],
              _acceptButton(
                FilledButton.icon(
                  onPressed: busy || blocked != null
                      ? null
                      : () => _confirmAcceptTask(context, task.id!),
                  icon: const Icon(Icons.merge, size: 16),
                  label: const Text('Accept & merge'),
                ),
                blocked: blocked,
              ),
            ],
          ),
          TaskAction.mergeAnyway => OutlinedButton.icon(
            style: destructive,
            onPressed: busy
                ? null
                : () => _confirmAcceptTask(
                    context,
                    task.id!,
                    overriddenChecks: blocked,
                  ),
            icon: const Icon(Icons.warning_amber_outlined, size: 16),
            label: const Text('Merge anyway'),
          ),
          TaskAction.retry => OutlinedButton.icon(
            onPressed: submitting
                ? null
                : () => bloc.add(TaskRetried(task.id!)),
            icon: const Icon(Icons.replay, size: 16),
            label: const Text('Retry task'),
          ),
          TaskAction.cancel => Tooltip(
            message: 'Move back to the backlog as a draft',
            child: OutlinedButton.icon(
              style: destructive,
              onPressed: submitting
                  ? null
                  : () => bloc.add(TaskCancelled(task.id!)),
              icon: const Icon(Icons.stop_circle_outlined, size: 16),
              label: const Text('Cancel task'),
            ),
          ),
          TaskAction.followUp => OutlinedButton.icon(
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
          TaskAction.delete => OutlinedButton.icon(
            style: destructive,
            onPressed: submitting
                ? null
                : () => _confirmDeleteTask(context, task.id!),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Delete task'),
          ),
        },
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.all(bar ? Spacing.md : Spacing.xl),
      child: bar
          ? SafeArea(
              top: false,
              child: Row(
                children: [
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: Spacing.sm),
                    Expanded(child: action),
                  ],
                ],
              ),
            )
          : Column(
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

/// "Accept & merge" with the reason it's disabled on hover, if any.
Widget _acceptButton(Widget button, {required String? blocked}) =>
    blocked == null ? button : Tooltip(message: blocked, child: button);

/// Shown above "Accept & merge" when the task merges by itself.
class _AutoMergeHint extends StatelessWidget {
  const _AutoMergeHint();

  @override
  Widget build(BuildContext context) => const Tooltip(
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
  );
}
