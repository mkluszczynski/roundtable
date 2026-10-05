import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/error_message.dart';
import '../utils/tool_catalog.dart';

/// Edits a project's toolchains: one row per tool (label, version, remove),
/// an "Add tool" menu over [toolCatalog] plus "Other…" for any mise id, and
/// "Detect from repo", which merges [onDetect]'s suggestions into the list
/// without touching tools already there. Controlled: every change goes
/// through [onChanged]; a version is committed when its field loses focus
/// or is submitted, not on each keystroke.
class ToolListEditor extends StatefulWidget {
  const ToolListEditor({
    super.key,
    required this.tools,
    required this.onChanged,
    this.onDetect,
  });

  final List<ProjectTool> tools;
  final ValueChanged<List<ProjectTool>> onChanged;
  final Future<List<ProjectTool>> Function()? onDetect;

  @override
  State<ToolListEditor> createState() => ToolListEditorState();
}

class ToolListEditorState extends State<ToolListEditor> {
  bool _detecting = false;

  /// The outcome of the last detection, shown under the buttons.
  String? _detectMessage;
  bool _detectFailed = false;

  /// Runs [ToolListEditor.onDetect] and merges the result — also called by
  /// the add-project dialog once a repo URL is entered.
  Future<void> detect() async {
    final onDetect = widget.onDetect;
    if (onDetect == null || _detecting) return;
    setState(() {
      _detecting = true;
      _detectMessage = null;
    });
    try {
      final suggested = await onDetect();
      if (!mounted) return;
      final have = {for (final t in widget.tools) t.name};
      final added = [
        for (final t in suggested)
          if (!have.contains(t.name)) t,
      ];
      setState(() {
        _detectFailed = false;
        _detectMessage = suggested.isEmpty
            ? 'Nothing detected — add the tools by hand.'
            : added.isEmpty
            ? 'Already up to date with the repo.'
            : 'Added ${added.map((t) => t.name).join(', ')} from the repo — '
                  'check the versions.';
      });
      if (added.isNotEmpty) widget.onChanged([...widget.tools, ...added]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detectFailed = true;
        _detectMessage = "Couldn't read the repo: ${errorMessage(e)}";
      });
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  void _add(String name) {
    if (widget.tools.any((t) => t.name == name)) return;
    widget.onChanged([
      ...widget.tools,
      ProjectTool(name: name, version: 'latest'),
    ]);
  }

  Future<void> _addOther() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _OtherToolDialog(),
    );
    if (name != null && name.isNotEmpty) _add(name);
  }

  void _setVersion(ProjectTool tool, String version) {
    final trimmed = version.trim();
    final next = trimmed.isEmpty ? 'latest' : trimmed;
    if (next == tool.version) return;
    widget.onChanged([
      for (final t in widget.tools)
        t.name == tool.name ? t.copyWith(version: next) : t,
    ]);
  }

  void _remove(ProjectTool tool) => widget.onChanged([
    for (final t in widget.tools)
      if (t.name != tool.name) t,
  ]);

  @override
  Widget build(BuildContext context) {
    final have = {for (final t in widget.tools) t.name};
    final available = toolCatalog.where((t) => !have.contains(t.name));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.tools.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Text(
              'No tools — agents only get what the machine already has.',
              style: AppTypography.caption,
            ),
          ),
        for (final tool in widget.tools)
          _ToolRow(
            key: ValueKey(tool.name),
            tool: tool,
            onVersionChanged: (v) => _setVersion(tool, v),
            onRemove: () => _remove(tool),
          ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            PopupMenuButton<String>(
              tooltip: 'Add a toolchain',
              color: AppColors.bg1,
              position: PopupMenuPosition.under,
              onSelected: (name) => name.isEmpty ? _addOther() : _add(name),
              itemBuilder: (_) => [
                for (final t in available)
                  PopupMenuItem(
                    value: t.name,
                    child: Text(t.label, style: AppTypography.body),
                  ),
                PopupMenuItem(
                  value: '',
                  child: Text(
                    'Other (mise tool id)…',
                    style: AppTypography.body.copyWith(color: AppColors.text1),
                  ),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.accentSoft),
                    SizedBox(width: Spacing.xs),
                    Text(
                      'Add tool',
                      style: TextStyle(color: AppColors.accentSoft),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.onDetect != null) ...[
              const SizedBox(width: Spacing.md),
              TextButton.icon(
                onPressed: _detecting ? null : detect,
                icon: _detecting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('Detect from repo'),
              ),
            ],
          ],
        ),
        if (_detectMessage != null)
          Text(
            _detectMessage!,
            style: AppTypography.caption.copyWith(
              color: _detectFailed ? AppColors.red : null,
            ),
          ),
      ],
    );
  }
}

class _ToolRow extends StatefulWidget {
  const _ToolRow({
    super.key,
    required this.tool,
    required this.onVersionChanged,
    required this.onRemove,
  });

  final ProjectTool tool;
  final ValueChanged<String> onVersionChanged;
  final VoidCallback onRemove;

  @override
  State<_ToolRow> createState() => _ToolRowState();
}

class _ToolRowState extends State<_ToolRow> {
  late final _controller = TextEditingController(text: widget.tool.version);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) widget.onVersionChanged(_controller.text);
    });
  }

  @override
  void didUpdateWidget(_ToolRow old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && _controller.text != widget.tool.version) {
      _controller.text = widget.tool.version;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hint = toolCatalog
        .where((t) => t.name == widget.tool.name)
        .firstOrNull
        ?.versionHint;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              toolLabel(widget.tool.name),
              style: AppTypography.bodyStrong,
            ),
          ),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              style: AppTypography.code,
              decoration: InputDecoration(
                isDense: true,
                hintText: hint == null ? 'latest' : 'e.g. $hint',
              ),
              onSubmitted: widget.onVersionChanged,
            ),
          ),
          IconButton(
            tooltip: 'Remove ${widget.tool.name}',
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.text1,
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}

class _OtherToolDialog extends StatefulWidget {
  const _OtherToolDialog();

  @override
  State<_OtherToolDialog> createState() => _OtherToolDialogState();
}

class _OtherToolDialogState extends State<_OtherToolDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() =>
      Navigator.of(context).pop(_controller.text.trim().toLowerCase());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bg1,
      title: const Text('Add a tool by mise id'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              style: AppTypography.code,
              decoration: const InputDecoration(
                labelText: 'Tool id',
                hintText: 'e.g. terraform, npm:prettier, pub:melos',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Any tool from the mise registry (mise.jdx.dev/registry), or '
              'a Dart CLI from pub.dev as pub:<package>.',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
