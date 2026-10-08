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
