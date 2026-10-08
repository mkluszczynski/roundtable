import 'dart:convert';

import 'package:roundtable_client/roundtable_client.dart';

/// The instructions given to the reviewer agent. The working tree is the
/// task's branch; [baseSha] is where it forked off the default branch.
/// [imagePaths] are the images attached to the task's prompt;
/// [previousComments] are earlier reviews' comments, to check and not repeat.
String buildReviewPrompt({
  required String rolePrompt,
  required String taskPrompt,
  required String baseSha,
  List<String> imagePaths = const [],
  List<ReviewComment> previousComments = const [],
  bool canRunChecks = false,
}) =>
    '''
$rolePrompt You are reviewing another agent's change. Do not modify any files.

The change was made for this task:
<task>
$taskPrompt
</task>
${_attachedImagesSection(imagePaths)}${_previousCommentsSection(previousComments)}
Before reviewing, read the repo's conventions if these files exist: AGENTS.md, CLAUDE.md, CONTRIBUTING.md (at the root and next to the changed code). Judge the change against them.

Inspect it with `git diff $baseSha...HEAD` and read surrounding code as needed. Look for bugs, missed requirements, security problems, broken conventions, and clear maintainability issues. Skip pure style preferences.

Scope: comment on code the change adds or modifies. Raise untouched code only when the change breaks it.

Severity:
- blocker: a bug, data loss, a security problem, or a requirement of the task that isn't met. The change must not be merged as is.
- issue: a real problem worth fixing before merging (missing error handling or test, a broken convention, a maintainability trap).
- nit: cosmetic or optional; never blocks merging.
When unsure between two severities, pick the lower one.

Each comment names the problem and how to fix it, concretely enough for another agent to act on without asking.

${canRunChecks ? '''Verify, don't guess: you run in a disposable container and may run any command. Run the project's checks that cover the change — analyzer, formatter check, tests, build — with the project toolchains. A failing check is a blocker or issue like any other finding. Never fix anything yourself. Say in the summary which checks you ran and their result, and which you couldn't run.''' : '''You can't run commands here other than git's read-only ones: judge the code by reading it, and say in the summary which checks (tests, analyzer, build) the developer should run.'''}

End your reply with exactly one fenced ```json block of this shape:
{"verdict": "approve" | "changes_requested", "summary": "<one paragraph verdict>", "comments": [{"path": "<repo-relative path>", "line": <line number in the new file, or null>, "severity": "blocker" | "issue" | "nit", "body": "<what is wrong and how to fix it>"}]${previousComments.isEmpty ? '' : ', "previous": [{"id": <earlier comment id>, "fixed": true | false, "note": "<if not fixed: what is still wrong, else null>"}]'}}
Use "changes_requested" exactly when a blocker or issue remains (new or earlier and not fixed), else "approve". Use an empty comments list if the change is good.''';

/// Earlier reviews' comments with their state: the reviewer checks each one
/// that wasn't dismissed and reports it under `previous`, never repeating
/// it among the new comments.
String _previousCommentsSection(List<ReviewComment> comments) {
  if (comments.isEmpty) return '';
  String state(ReviewComment c) => switch (c.state) {
    ReviewCommentState.open => 'still open',
    ReviewCommentState.sentToFix ||
    ReviewCommentState.resolved => 'the agent was asked to fix it',
    ReviewCommentState.dismissed => 'dismissed by the developer',
    ReviewCommentState.superseded => 'superseded',
  };
  final list = comments
      .map((c) {
        final location = c.line == null ? c.path : '${c.path}:${c.line}';
        return '- id ${c.id} · $location · ${c.severity.name} · ${state(c)}\n'
            '  ${c.body.replaceAll('\n', '\n  ')}';
      })
      .join('\n');
  return '''
This change was reviewed before. Earlier comments:
$list

For every earlier comment that wasn't dismissed, check the current code and report it under "previous": fixed or not, with a note on what is still wrong. Don't repeat earlier comments among the new ones, and don't raise again what the developer dismissed. New comments are only for problems not listed above.
''';
}

String _attachedImagesSection(List<String> imagePaths) {
  if (imagePaths.isEmpty) return '';
  final list = imagePaths.map((p) => '- $p').join('\n');
  return '\nThe developer attached ${imagePaths.length} image(s) to this task '
      '(screenshots or mockups). They are part of the requirements: open '
      'each one with the Read tool before reviewing the change:\n$list\n';
}

/// What the reviewer's final reply ([parseReviewOutput]) holds. [verdict]
/// is null when the reviewer didn't give a valid one.
typedef ReviewFindings = ({
  String summary,
  List<ReviewCommentDraft> comments,
  List<ReviewCommentCheck> checks,
  CodeReviewVerdict? verdict,
});

/// Parses the reviewer's final reply: the last fenced ```json block (or the
/// whole text, if it's bare JSON). Returns `null` if no valid block is found.
ReviewFindings? parseReviewOutput(String text) {
  final blocks = RegExp(
    r'```json\s*\n([\s\S]*?)\n\s*```',
  ).allMatches(text).toList();
  final raw = blocks.isEmpty ? text.trim() : blocks.last.group(1)!;

  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  final summary = decoded['summary'];
  final comments = decoded['comments'];
  if (summary is! String || comments is! List) return null;

  final drafts = <ReviewCommentDraft>[];
  for (final c in comments) {
    if (c is! Map<String, dynamic>) continue;
    final path = c['path'];
    final body = c['body'];
    if (path is! String || body is! String || path.isEmpty) continue;
    final line = c['line'];
    drafts.add(
      ReviewCommentDraft(
        path: path,
        line: line is int && line > 0 ? line : null,
        body: body,
        severity: ReviewCommentSeverity.values.firstWhere(
          (s) => s.name == c['severity'],
          orElse: () => ReviewCommentSeverity.issue,
        ),
      ),
    );
  }
  final checks = <ReviewCommentCheck>[];
  if (decoded['previous'] case final List previous) {
    for (final p in previous) {
      if (p is! Map<String, dynamic>) continue;
      final id = p['id'];
      final fixed = p['fixed'];
      if (id is! int || fixed is! bool) continue;
      final note = p['note'];
      checks.add(
        ReviewCommentCheck(
          commentId: id,
          fixed: fixed,
          note: note is String && note.trim().isNotEmpty ? note : null,
        ),
      );
    }
  }
  final verdict = switch (decoded['verdict']) {
    'approve' => CodeReviewVerdict.approve,
    'changes_requested' ||
    'changesRequested' => CodeReviewVerdict.changesRequested,
    _ => null,
  };
  return (summary: summary, comments: drafts, checks: checks, verdict: verdict);
}
