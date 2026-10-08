part of '../task_detail_screen.dart';

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
