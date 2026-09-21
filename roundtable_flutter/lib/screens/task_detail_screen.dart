import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../blocs/task_detail_bloc.dart';
import '../client.dart';
import '../repositories/task_repository.dart';

/// Lets the dev answer a pending plan-mode question (design doc §6.4
/// `AskUserQuestion`) and approve or give feedback on a ready plan (§6.4
/// `ExitPlanMode`). There's no task list/detail screen yet, so — like
/// [TaskDiffScreen] — a task id is entered directly rather than picked from
/// one.
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskDetailBloc(TaskRepository(client)),
      child: const _TaskDetailView(),
    );
  }
}

class _TaskDetailView extends StatefulWidget {
  const _TaskDetailView();

  @override
  State<_TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<_TaskDetailView> {
  final _taskIdController = TextEditingController();

  @override
  void dispose() {
    _taskIdController.dispose();
    super.dispose();
  }

  void _load() {
    final taskId = int.tryParse(_taskIdController.text);
    if (taskId == null) return;
    context.read<TaskDetailBloc>().add(TaskDetailSubscribed(taskId));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _taskIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Task id',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: _load, child: const Text('Load')),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: BlocBuilder<TaskDetailBloc, TaskDetailState>(
            builder: (context, state) {
              return switch (state) {
                TaskDetailInitial() => const Center(
                  child: Text('Enter a task id to view its status'),
                ),
                TaskDetailLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                TaskDetailError(:final message) => Center(
                  child: Text('Failed to load task: $message'),
                ),
                TaskDetailLoaded() => _TaskDetailBody(state: state),
              };
            },
          ),
        ),
      ],
    );
  }
}

class _TaskDetailBody extends StatelessWidget {
  const _TaskDetailBody({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Task #${task.id}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 12),
                Chip(label: Text(task.status.name)),
              ],
            ),
            const SizedBox(height: 8),
            Text(task.prompt),
            const SizedBox(height: 24),
            if (task.status == TaskStatus.waitingForAnswer)
              _PendingQuestion(state: state)
            else if (task.status == TaskStatus.planReady)
              _PlanReview(state: state)
            else
              Text('No action needed for this task right now.'),
          ],
        ),
      ),
    );
  }
}

class _PendingQuestion extends StatelessWidget {
  const _PendingQuestion({required this.state});

  final TaskDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final question = state.pendingQuestion;
    if (question == null) {
      return const Text('Waiting for the question to load…');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question from the agent',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(question.question),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: question.options
              .map(
                (option) => FilledButton(
                  onPressed: state.submitting
                      ? null
                      : () => context.read<TaskDetailBloc>().add(
                          AnswerSubmitted(question.id!, option),
                        ),
                  child: Text(option),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PlanReview extends StatefulWidget {
  const _PlanReview({required this.state});

  final TaskDetailLoaded state;

  @override
  State<_PlanReview> createState() => _PlanReviewState();
}

class _PlanReviewState extends State<_PlanReview> {
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.state.task;
    final submitting = widget.state.submitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan ready for review',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(task.currentPlan ?? ''),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: submitting
              ? null
              : () =>
                    context.read<TaskDetailBloc>().add(PlanApproved(task.id!)),
          icon: const Icon(Icons.check),
          label: const Text('Approve'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _feedbackController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Feedback',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: submitting
              ? null
              : () {
                  final message = _feedbackController.text.trim();
                  if (message.isEmpty) return;
                  context.read<TaskDetailBloc>().add(
                    PlanFeedbackSubmitted(task.id!, message),
                  );
                  _feedbackController.clear();
                },
          child: const Text('Send Feedback'),
        ),
      ],
    );
  }
}
