part of '../task_detail_screen.dart';

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
class _ChangesView extends StatefulWidget {
  const _ChangesView({required this.state});

  final TaskDetailLoaded state;

  @override
  State<_ChangesView> createState() => _ChangesViewState();
}

class _ChangesViewState extends State<_ChangesView> {
  /// Narrow: the selected file's diff is open in place of the list.
  bool _showingDiff = false;

  /// Below this width the list and the diff take turns.
  static const _sideBySideMin = 720.0;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= _sideBySideMin;
        // One file: a list of one is a needless tap, show its diff.
        final single = files.length == 1;
        if (single && state.selectedFile == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<TaskDetailBloc>().add(FileSelected(files.single));
            }
          });
        }
        final list = ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return _FileRow(
              file: file,
              selected:
                  sideBySide && file.filename == state.selectedFile?.filename,
              openComments: openCommentsOn(file.filename),
              onTap: () {
                context.read<TaskDetailBloc>().add(FileSelected(file));
                if (!sideBySide) setState(() => _showingDiff = true);
              },
            );
          },
        );
        final Widget body;
        if (sideBySide) {
          body = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 320, child: list),
              VerticalDivider(width: 1, color: AppColors.border),
              Expanded(child: _SelectedFileDiff(state: state)),
            ],
          );
        } else if (single) {
          body = _SelectedFileDiff(state: state);
        } else if (_showingDiff && state.selectedFile != null) {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _showingDiff = false),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text('All ${files.length} files'),
              ),
              Expanded(child: _SelectedFileDiff(state: state)),
            ],
          );
        } else {
          body = list;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChangeStats(files: files),
            if (state.inReview && state.hasConflicts) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                'This branch has conflicts with '
                '${state.mergeStatus!.baseBranch}.',
                style: AppTypography.body.copyWith(color: AppColors.red),
              ),
            ],
            const SizedBox(height: Spacing.md),
            Expanded(child: body),
            if (state.inReview) ...[
              const SizedBox(height: Spacing.md),
              _IterationFeedbackRow(state: state),
            ],
          ],
        );
      },
    );
  }
}

/// One changed file: its name first (what the dev looks for), the folder
/// under it — a long path cut from the end would hide the name.
class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.file,
    required this.selected,
    required this.openComments,
    required this.onTap,
  });

  final DiffFile file;
  final bool selected;
  final int openComments;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slash = file.filename.lastIndexOf('/');
    final name = file.filename.substring(slash + 1);
    final folder = slash < 0 ? null : file.filename.substring(0, slash);
    return Material(
      color: selected ? AppColors.bg2 : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.smd,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 20,
                color: AppColors.text1,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.bodyStrong,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [?folder, file.status].join(' · '),
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      style: AppTypography.code,
                      children: [
                        TextSpan(
                          text: '+${file.additions} ',
                          style: const TextStyle(color: AppColors.live),
                        ),
                        TextSpan(
                          text: '-${file.deletions}',
                          style: const TextStyle(color: AppColors.red),
                        ),
                      ],
                    ),
                  ),
                  if (openComments > 0)
                    Text(
                      '$openComments comment${openComments == 1 ? '' : 's'}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    final slash = file.filename.lastIndexOf('/');
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name, then folder; the view switch wraps under them when the
            // pane is narrow.
            Wrap(
              spacing: Spacing.lg,
              runSpacing: Spacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.filename.substring(slash + 1),
                      style: AppTypography.cardTitle,
                    ),
                    if (slash > 0)
                      Text(
                        file.filename.substring(0, slash),
                        style: AppTypography.caption,
                      ),
                  ],
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
