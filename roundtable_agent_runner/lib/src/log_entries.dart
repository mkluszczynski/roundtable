import 'package:roundtable_client/roundtable_client.dart';

import 'stream_json_formatter.dart';

/// A fresh id for one `claude` invocation; groups its log entries.
String newRunId(String prefix) =>
    '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}';

/// [item] as a [TaskLogEntry] of run [runId] for task [taskId].
TaskLogEntry logEntryFor(
  LogItem item, {
  required int taskId,
  required String runId,
  required LogPhase phase,
  int? reviewId,
}) => TaskLogEntry(
  taskId: taskId,
  content: item.content,
  source: LogSource.agent,
  kind: item.kind,
  runId: runId,
  phase: phase,
  toolName: item.toolName,
  toolUseId: item.toolUseId,
  detail: item.detail,
  isError: item.isError,
  reviewId: reviewId,
);

final _jsonFence = RegExp(r'\n*```json\s*\{[\s\S]*```\s*$');

/// The reviewer's final message ends with the machine-readable
/// ```json {summary, comments}``` block, which the panel already shows as
/// the verdict and comment cards — drop it from the log.
String stripReviewJson(String message) =>
    message.replaceFirst(_jsonFence, '').trimRight();
