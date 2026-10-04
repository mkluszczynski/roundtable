import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../cubits/create_task_cubit.dart';
import '../cubits/project_list_cubit.dart';
import '../repositories/attachment_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/error_message.dart';
import '../utils/image_paste.dart';
import 'agent_picker.dart';
import 'attachment_thumbnail.dart';
import 'app_modal.dart';

class CreateTaskDialog extends StatelessWidget {
  const CreateTaskDialog({super.key, this.initialProjectId});

  /// When set (opened from `project_detail_screen.dart`'s "New task"), the
  /// project is fixed and its picker is hidden — same pattern as
  /// `AddAgentDialog`'s scoped machine.
  final int? initialProjectId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ProjectListCubit(ProjectRepository(client))..fetchProjects(),
        ),
        BlocProvider(create: (_) => CreateTaskCubit(TaskRepository(client))),
      ],
      child: _CreateTaskDialogContent(initialProjectId: initialProjectId),
    );
  }
}

class _CreateTaskDialogContent extends StatefulWidget {
  const _CreateTaskDialogContent({this.initialProjectId});

  final int? initialProjectId;

  @override
  State<_CreateTaskDialogContent> createState() =>
      _CreateTaskDialogContentState();
}

class _CreateTaskDialogContentState extends State<_CreateTaskDialogContent> {
  final _promptController = TextEditingController();
  late int? _projectId = widget.initialProjectId;
  int? _agentId;
  bool _skipPlanning = false;

  late final _attachments = AttachmentRepository(client);
  final _images = <_PendingImage>[];
  late final void Function() _stopPasteListener;

  /// Set once the task is created — from then on the uploads belong to it
  /// and must not be discarded when the dialog closes.
  bool _submitted = false;

  static const _maxImages = 6;
  static const _maxBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _stopPasteListener = listenForPastedImages(
      (image) => _addImage(image.name, image.bytes),
    );
  }

  @override
  void dispose() {
    _stopPasteListener();
    _promptController.dispose();
    if (!_submitted) {
      // Closed without creating the task: drop the orphaned uploads.
      for (final image in _images) {
        final id = image.id;
        if (id != null) _attachments.discard(id).ignore();
      }
    }
    super.dispose();
  }

  bool get _uploading => _images.any((i) => i.uploading);

  bool get _canSubmit =>
      _projectId != null &&
      _promptController.text.trim().isNotEmpty &&
      !_uploading;

  Future<void> _addImage(String name, Uint8List bytes) async {
    if (_images.length >= _maxImages) {
      _showError('A task can have at most $_maxImages images.');
      return;
    }
    if (bytes.lengthInBytes > _maxBytes) {
      _showError('$name is larger than 5 MB.');
      return;
    }
    final image = _PendingImage(name: name, bytes: bytes);
    setState(() => _images.add(image));
    try {
      final uploaded = await _attachments.upload(name, bytes);
      if (!mounted) {
        _attachments.discard(uploaded.id!).ignore();
        return;
      }
      setState(() {
        image.id = uploaded.id;
        image.uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        image.uploading = false;
        image.error = errorMessage(e);
      });
    }
  }

  void _removeImage(_PendingImage image) {
    setState(() => _images.remove(image));
    final id = image.id;
    if (id != null) _attachments.discard(id).ignore();
  }

  Future<void> _pickImages() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    for (final file in files) {
      await _addImage(file.name, await file.readAsBytes());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateTaskCubit, CreateTaskState>(
      listener: (context, state) {
        if (state is CreateTaskSuccess) {
          // Look the messenger up before popping: afterwards this dialog's
          // context is deactivated and the lookup throws.
          final messenger = ScaffoldMessenger.of(context);
          Navigator.of(context).pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                state.task.status == TaskStatus.draft
                    ? 'Draft saved'
                    : 'Task created',
              ),
            ),
          );
        }
      },
      child: AppModal(
        icon: Icons.add_task,
        title: 'New task',
        subtitle: 'Describe the work, then pick who does it.',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          BlocBuilder<CreateTaskCubit, CreateTaskState>(
            builder: (context, state) {
              final submitting = state is CreateTaskSubmitting;
              return FilledButton(
                onPressed: (_canSubmit && !submitting)
                    ? () {
                        _submitted = true;
                        context.read<CreateTaskCubit>().submit(
                          projectId: _projectId!,
                          agentId: _agentId,
                          prompt: _promptController.text.trim(),
                          skipPlanning: _skipPlanning,
                          attachmentIds: [
                            for (final i in _images)
                              if (i.id != null) i.id!,
                          ],
                        );
                      }
                    : null,
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_agentId == null ? 'Save draft' : 'Create'),
              );
            },
          ),
        ],
        child: SizedBox(
          width: 496,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.initialProjectId == null) ...[
                  Text('PROJECT', style: AppTypography.label),
                  const SizedBox(height: Spacing.sm),
                  BlocBuilder<ProjectListCubit, ProjectListState>(
                    builder: (context, state) {
                      final projects = switch (state) {
                        ProjectListLoaded(:final projects) => projects,
                        _ => <Project>[],
                      };
                      return Wrap(
                        spacing: Spacing.sm,
                        runSpacing: Spacing.sm,
                        children: [
                          for (final project in projects)
                            SizedBox(
                              width: 244,
                              child: SelectableCard(
                                selected: _projectId == project.id,
                                onTap: () =>
                                    setState(() => _projectId = project.id),
                                child: _ProjectOption(project: project),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: Spacing.xl),
                ],
                Text('PROMPT', style: AppTypography.label),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    hintText:
                        'What should the agent do? Be as specific as you '
                        'would be with a teammate…',
                    alignLabelWithHint: true,
                  ),
                  minLines: 4,
                  maxLines: 8,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final image in _images)
                      AttachmentThumbnail(
                        name: image.name,
                        bytes: image.bytes,
                        uploading: image.uploading,
                        error: image.error,
                        onRemove: () => _removeImage(image),
                      ),
                    if (_images.length < _maxImages)
                      TextButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 16,
                        ),
                        label: const Text('Attach image'),
                      ),
                    if (kIsWeb && _images.isEmpty)
                      Text(
                        'or paste a screenshot (Ctrl+V)',
                        style: AppTypography.caption,
                      ),
                  ],
                ),
                const SizedBox(height: Spacing.xl),
                Text('AGENT', style: AppTypography.label),
                const SizedBox(height: Spacing.sm),
                AgentPicker(
                  selected: _agentId,
                  allowNone: true,
                  onChanged: (id) => setState(() => _agentId = id),
                ),
                const SizedBox(height: Spacing.sm),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _skipPlanning,
                  activeColor: AppColors.accent,
                  title: const Text('Skip planning'),
                  subtitle: const Text(
                    'Go straight to execution — saves usage on trivial tasks',
                  ),
                  onChanged: (value) =>
                      setState(() => _skipPlanning = value ?? false),
                ),
                BlocBuilder<CreateTaskCubit, CreateTaskState>(
                  builder: (context, state) {
                    if (state is CreateTaskError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: Spacing.md),
                        child: Text(
                          state.message,
                          style: const TextStyle(color: AppColors.red),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectOption extends StatelessWidget {
  const _ProjectOption({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    // `https://github.com/owner/repo(.git)` → `owner/repo`.
    final repo = Uri.tryParse(project.repoUrl)?.pathSegments
        .where((s) => s.isNotEmpty)
        .join('/')
        .replaceFirst(RegExp(r'\.git$'), '');
    return Row(
      children: [
        const Icon(Icons.folder_outlined, size: 18, color: AppColors.text1),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: AppTypography.bodyStrong,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                (repo == null || repo.isEmpty) ? project.repoUrl : repo,
                style: AppTypography.caption,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// An image added in the dialog: uploaded right away, linked to the task
/// on create.
class _PendingImage {
  _PendingImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
  int? id;
  bool uploading = true;
  String? error;
}
