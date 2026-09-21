import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../client.dart';
import '../cubits/task_diff_cubit.dart';
import '../repositories/task_repository.dart';
import '../widgets/diff_view.dart';

/// Stand-in for a full task detail screen (design doc §6.7): enter a task
/// id, see its PR's changed files and diffs. There's no task list/detail
/// screen yet, so a task id is entered directly rather than picked from one.
class TaskDiffScreen extends StatelessWidget {
  const TaskDiffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskDiffCubit(TaskRepository(client)),
      child: const _TaskDiffView(),
    );
  }
}

class _TaskDiffView extends StatefulWidget {
  const _TaskDiffView();

  @override
  State<_TaskDiffView> createState() => _TaskDiffViewState();
}

class _TaskDiffViewState extends State<_TaskDiffView> {
  final _taskIdController = TextEditingController();

  @override
  void dispose() {
    _taskIdController.dispose();
    super.dispose();
  }

  void _load() {
    final taskId = int.tryParse(_taskIdController.text);
    if (taskId == null) return;
    context.read<TaskDiffCubit>().fetchChangedFiles(taskId);
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
          child: BlocBuilder<TaskDiffCubit, TaskDiffState>(
            builder: (context, state) {
              return switch (state) {
                TaskDiffInitial() => const Center(
                  child: Text('Enter a task id to view its diff'),
                ),
                TaskDiffLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                TaskDiffError(:final message) => Center(
                  child: Text('Failed to load diff: $message'),
                ),
                TaskDiffLoaded(:final files) when files.isEmpty => const Center(
                  child: Text('No changed files'),
                ),
                TaskDiffLoaded() => _ChangedFiles(state: state),
              };
            },
          ),
        ),
      ],
    );
  }
}

class _ChangedFiles extends StatelessWidget {
  const _ChangedFiles({required this.state});

  final TaskDiffLoaded state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: ListView.builder(
            itemCount: state.files.length,
            itemBuilder: (context, index) {
              final file = state.files[index];
              final selected = file.filename == state.selectedFile?.filename;
              return ListTile(
                selected: selected,
                leading: const Icon(Icons.description_outlined),
                title: Text(file.filename, overflow: TextOverflow.ellipsis),
                subtitle: Text(file.status),
                trailing: Text(
                  '+${file.additions} -${file.deletions}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                onTap: () => context.read<TaskDiffCubit>().selectFile(file),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _SelectedFileDiff(state: state)),
      ],
    );
  }
}

class _SelectedFileDiff extends StatelessWidget {
  const _SelectedFileDiff({required this.state});

  final TaskDiffLoaded state;

  @override
  Widget build(BuildContext context) {
    final file = state.selectedFile;
    if (file == null) {
      return const Center(child: Text('Select a file to view its diff'));
    }

    final patch = file.patch;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    file.filename,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: state.fileContentLoading
                      ? null
                      : () =>
                            context.read<TaskDiffCubit>().loadFullFileContent(),
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
            const SizedBox(height: 12),
            if (patch == null)
              const Text('No textual diff available for this file (binary?)')
            else
              DiffView(patch: patch),
            if (state.fileContentError != null) ...[
              const SizedBox(height: 12),
              Text(
                'Failed to load file content: ${state.fileContentError}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (state.fileContent != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text('Full file', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SelectionArea(
                child: Text(
                  state.fileContent!,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
