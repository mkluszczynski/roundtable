import 'dart:convert';

import 'package:roundtable_client/roundtable_client.dart';

import 'log_entry_kind.dart';

/// One `claude` invocation in a task's log: a planning/execution/feedback
/// run or a code review, with its content grouped into [blocks].
class LogRun {
  LogRun({required this.index, this.phase, this.title, this.startedAt});

  /// 1-based position among the task's runs.
  final int index;
  LogPhase? phase;

  /// From the run's `runStarted` entry, e.g. "Ada started planning".
  String? title;
  DateTime? startedAt;

  /// The run's `runFinished` entry, null while it's still going.
  TaskLogEntry? finished;
  final List<LogBlock> blocks = [];

  /// The code review this run belongs to (structured review runs).
  int? reviewId;

  bool get isReview => phase == LogPhase.review;

  int get stepCount => blocks.whereType<ActivityBlock>().fold(
    0,
    (sum, b) => sum + b.steps.length,
  );
}

sealed class LogBlock {}

/// Something the agent wrote, rendered as markdown.
class MessageBlock extends LogBlock {
  MessageBlock(this.text);

  String text;
}

class ThinkingBlock extends LogBlock {
  ThinkingBlock(this.text);

  final String text;
}

/// Something the runner did around the run (pushed, opened the PR…).
class EventBlock extends LogBlock {
  EventBlock(this.text);

  final String text;
}

/// A decision the agent asked the dev for — a question (AskUserQuestion)
/// or plan approval (ExitPlanMode) — with the dev's response once it came.
class DecisionBlock extends LogBlock {
  DecisionBlock(this.step);

  final ToolStep step;

  bool get isPlan => step.toolName == 'ExitPlanMode';

  /// The question asked (AskUserQuestion's first question).
  String? get question {
    final detail = step.call.detail;
    if (detail != null) {
      try {
        final input = jsonDecode(detail);
        if (input is Map) {
          final questions = input['questions'];
          if (questions is List && questions.isNotEmpty) {
            final first = questions.first;
            if (first is Map && first['question'] is String) {
              return first['question'] as String;
            }
          }
          if (input['question'] is String) return input['question'] as String;
        }
      } catch (_) {
        // Fall through to the summary.
      }
    }
    final match = RegExp(r'"question"\s*:\s*"([^"]+)').firstMatch(
      step.call.text,
    );
    return match?.group(1);
  }

  /// The dev's answer, from Claude Code's `"question"="answer"` receipt.
  String? get answer {
    final result = step.result;
    if (result == null) return null;
    final text = result.detail ?? result.text;
    final match = RegExp(r'"="([\s\S]*?)"(?:[.,]|\s|$)').firstMatch(text);
    return match?.group(1) ?? text;
  }
}

/// Consecutive tool calls between two messages.
class ActivityBlock extends LogBlock {
  final List<ToolStep> steps = [];

  /// "Read ×4, Grep ×3, Bash ×2".
  String get summary {
    final counts = <String, int>{};
    for (final step in steps) {
      counts.update(step.toolName, (n) => n + 1, ifAbsent: () => 1);
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .map((e) => e.value == 1 ? e.key : '${e.key} ×${e.value}')
        .join(', ');
  }
}

/// A tool call and, once it arrived, its result.
class ToolStep {
  ToolStep(this.call);

  final TaskLogEntry call;
  TaskLogEntry? result;

  String get toolName {
    final name = call.toolName;
    if (name != null) return name;
    // Legacy lines: "Read(/a)", "Bash: ls", "Grep 'x' in …", "Explore: …".
    final match = RegExp(r'^[A-Za-z_]+').firstMatch(call.text);
    return match?.group(0) ?? 'Tool';
  }
}

final _legacyReviewPrefix = RegExp(r'^\[review\]\s*');

/// Groups a task's log [entries] into runs and blocks. Structured entries
/// are grouped by `runId`; older ones start a new run after a finished run
/// or when the stream switches between task and `[review]` lines.
List<LogRun> buildLogTimeline(List<TaskLogEntry> entries) {
  final runs = <LogRun>[];
  final byRunId = <String, LogRun>{};
  LogRun? legacyRun;
  bool? legacyRunIsReview;

  LogRun startRun({LogPhase? phase, DateTime? at}) {
    final run = LogRun(index: runs.length + 1, phase: phase, startedAt: at);
    runs.add(run);
    return run;
  }

  for (var entry in entries) {
    LogRun run;
    final runId = entry.runId;
    if (runId != null) {
      run = byRunId[runId] ??= startRun(
        phase: entry.phase,
        at: entry.createdAt,
      );
    } else {
      // Legacy entry: normalize the `[review]` prefix into a phase.
      final isReview = _legacyReviewPrefix.hasMatch(entry.content);
      if (isReview) {
        entry = entry.copyWith(
          content: entry.content.replaceFirst(_legacyReviewPrefix, ''),
        );
      }
      final current = legacyRun;
      if (current == null ||
          current.finished != null ||
          legacyRunIsReview != isReview) {
        legacyRun = startRun(
          phase: isReview ? LogPhase.review : null,
          at: entry.createdAt,
        );
        legacyRunIsReview = isReview;
        // "[review] Leon started a code review" opens the review run.
        if (isReview && entry.content.endsWith('started a code review')) {
          legacyRun.title = entry.content;
          continue;
        }
      }
      run = legacyRun!;
    }
    _addToRun(run, entry);
  }
  return runs;
}

bool _isDecision(TaskLogEntry call) {
  final name = ToolStep(call).toolName;
  return name == 'AskUserQuestion' || name == 'ExitPlanMode';
}

void _addToRun(LogRun run, TaskLogEntry entry) {
  run.reviewId ??= entry.reviewId;
  switch (entry.effectiveKind) {
    case LogKind.runStarted:
      run.title = entry.text;
      run.startedAt ??= entry.createdAt;
    case LogKind.runFinished:
      run.finished = entry;
    case LogKind.message:
      final last = run.blocks.lastOrNull;
      if (last is MessageBlock) {
        last.text = '${last.text}\n\n${entry.text}';
      } else {
        run.blocks.add(MessageBlock(entry.text));
      }
    case LogKind.thinking:
      run.blocks.add(ThinkingBlock(entry.text));
    case LogKind.event:
      run.blocks.add(EventBlock(entry.text));
    case LogKind.toolCall when _isDecision(entry):
      run.blocks.add(DecisionBlock(ToolStep(entry)));
    case LogKind.toolCall:
      final last = run.blocks.lastOrNull;
      final activity = last is ActivityBlock ? last : ActivityBlock();
      if (activity != last) run.blocks.add(activity);
      activity.steps.add(ToolStep(entry));
    case LogKind.toolResult:
      final step = _stepForResult(run, entry);
      if (step != null) step.result = entry;
  }
}

/// The call [result] answers: by `toolUseId`, or (legacy) the latest call
/// still waiting for a result.
ToolStep? _stepForResult(LogRun run, TaskLogEntry result) {
  final steps = [
    for (final block in run.blocks)
      ...switch (block) {
        ActivityBlock(:final steps) => steps,
        DecisionBlock(:final step) => [step],
        _ => const <ToolStep>[],
      },
  ];
  final id = result.toolUseId;
  if (id != null) {
    for (final step in steps.reversed) {
      if (step.call.toolUseId == id) return step;
    }
  }
  for (final step in steps) {
    if (step.result == null) return step;
  }
  return null;
}
