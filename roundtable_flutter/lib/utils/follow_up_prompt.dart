import 'package:roundtable_client/roundtable_client.dart';

/// The prompt a follow-up task starts with: an empty first part for the
/// dev's instruction, then [task] as context — its prompt, PR and the
/// agent's final reply — since the new task runs in a fresh session.
String followUpPrompt(Task task) {
  final quotedPrompt = task.prompt
      .trim()
      .split('\n')
      .map((line) => '> $line')
      .join('\n');
  final buffer = StringBuffer()
    ..writeln()
    ..writeln()
    ..writeln('---')
    ..writeln('Context: follow-up to task #${task.id}.')
    ..writeln()
    ..writeln('Its prompt:')
    ..writeln(quotedPrompt);
  final prUrl = task.prUrl;
  if (prUrl != null) {
    buffer
      ..writeln()
      ..writeln('Its pull request: $prUrl');
  }
  final result = task.resultSummary?.trim();
  if (result != null && result.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln("The agent's final reply:")
      ..writeln(result);
  }
  return buffer.toString().trimRight();
}
