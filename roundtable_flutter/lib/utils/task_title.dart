import 'package:roundtable_client/roundtable_client.dart';

/// What the board calls [task]: its title (set by the agent or the dev),
/// or the first non-blank line of the prompt while it has none.
String taskDisplayTitle(Task task) {
  final title = task.title?.trim();
  if (title != null && title.isNotEmpty) return title;
  return task.prompt
      .split('\n')
      .map((l) => l.trim())
      .firstWhere((l) => l.isNotEmpty, orElse: () => task.prompt.trim());
}
