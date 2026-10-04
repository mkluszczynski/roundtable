import 'package:roundtable_client/roundtable_client.dart';

import 'log_entry_kind.dart';

/// What the agent wrote right before its latest `AskUserQuestion` — the
/// explanation the question builds on, which `TaskQuestion` itself doesn't
/// carry. Null when there's none.
String? questionContext(List<TaskLogEntry> logs) {
  var end = logs.length;
  for (var i = logs.length - 1; i >= 0; i--) {
    final entry = logs[i];
    if (entry.effectiveKind == LogKind.toolCall &&
        (entry.toolName == 'AskUserQuestion' ||
            entry.text.startsWith('AskUserQuestion'))) {
      end = i;
      break;
    }
  }
  final message = <String>[];
  for (var i = end - 1; i >= 0; i--) {
    final entry = logs[i];
    final content = entry.text.trim();
    if (content.isEmpty) continue;
    // The agent's message ends where the previous tool call does.
    if (entry.effectiveKind != LogKind.message) break;
    message.insert(0, content);
  }
  return message.isEmpty ? null : message.join('\n\n');
}
