part of '../task_detail_screen.dart';

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
