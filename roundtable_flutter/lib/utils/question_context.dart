import 'package:roundtable_client/roundtable_client.dart';

/// Formatted log lines for tool calls and their results (see the runner's
/// `StreamJsonFormatter`) — everything else is the agent talking.
bool _isToolLine(String content) =>
    content.startsWith('🔧') ||
    content.startsWith('✓') ||
    content.startsWith('✗');

/// What the agent wrote right before its latest `AskUserQuestion` — the
/// explanation the question builds on, which `TaskQuestion` itself doesn't
/// carry. Null when there's none.
String? questionContext(List<TaskLogEntry> logs) {
  var end = logs.length;
  for (var i = logs.length - 1; i >= 0; i--) {
    if (logs[i].content.startsWith('🔧 AskUserQuestion')) {
      end = i;
      break;
    }
  }
  final message = <String>[];
  for (var i = end - 1; i >= 0; i--) {
    final content = logs[i].content.trim();
    if (content.isEmpty) continue;
    // The agent's message ends where the previous tool call does.
    if (_isToolLine(content)) break;
    message.insert(0, content);
  }
  return message.isEmpty ? null : message.join('\n\n');
}
