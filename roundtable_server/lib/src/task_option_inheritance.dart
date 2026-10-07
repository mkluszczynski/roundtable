import 'package:serverpod/serverpod.dart';

import 'endpoints/non_terminal_task_statuses.dart';
import 'endpoints/settings_endpoint.dart';
import 'endpoints/task_endpoint.dart';
import 'generated/protocol.dart';

/// The task options that follow the project/workspace defaults unless the
/// dev sets them on the task (`Task.overriddenOptions`). `skipPlanning` is
/// left out: it only matters when the task starts.
const taskOptionNames = [
  'autoReview',
  'reviewerAgentId',
  'autoFixReview',
  'maxReviewFixRounds',
  'autoMerge',
  'autoFixFailingChecks',
  'maxCheckFixAttempts',
];

Map<String, Object?> _taskValues(Task t) => {
  'autoReview': t.autoReview,
  'reviewerAgentId': t.reviewerAgentId,
  'autoFixReview': t.autoFixReview,
  'maxReviewFixRounds': t.maxReviewFixRounds,
  'autoMerge': t.autoMerge,
  'autoFixFailingChecks': t.autoFixFailingChecks,
  'maxCheckFixAttempts': t.maxCheckFixAttempts,
};

Map<String, Object?> _defaultValues(TaskDefaults d) => {
  'autoReview': d.autoReview,
  'reviewerAgentId': d.reviewerAgentId,
  'autoFixReview': d.autoFixReview,
  'maxReviewFixRounds': d.maxReviewFixRounds,
  'autoMerge': d.autoMerge,
  'autoFixFailingChecks': d.autoFixFailingChecks,
  'maxCheckFixAttempts': d.maxCheckFixAttempts,
};

/// The options of a new [task] that differ from [defaults]: the dev
/// changed them in the form, so they stay as set.
List<String> optionsDifferingFrom(Task task, TaskDefaults defaults) {
  final values = _taskValues(task);
  final inherited = _defaultValues(defaults);
  return [
    for (final name in taskOptionNames)
      if (values[name] != inherited[name]) name,
  ];
}

/// [current]'s overrides plus the options [edited] changes.
List<String> overridesAfterEdit(Task current, Task edited) {
  final before = _taskValues(current);
  final after = _taskValues(edited);
  final overridden = {...?current.overriddenOptions};
  return [
    for (final name in taskOptionNames)
      if (overridden.contains(name) || before[name] != after[name]) name,
  ];
}

/// [task] with its inherited (not overridden) options set to [defaults].
Task withInheritedOptions(Task task, TaskDefaults defaults) {
  final keep = {...?task.overriddenOptions};
  T pick<T>(String name, T own, T inherited) =>
      keep.contains(name) ? own : inherited;
  return task.copyWith(
    autoReview: pick('autoReview', task.autoReview, defaults.autoReview),
    reviewerAgentId: pick(
      'reviewerAgentId',
      task.reviewerAgentId,
      defaults.reviewerAgentId,
    ),
    autoFixReview: pick(
      'autoFixReview',
      task.autoFixReview,
      defaults.autoFixReview,
    ),
    maxReviewFixRounds: pick(
      'maxReviewFixRounds',
      task.maxReviewFixRounds,
      defaults.maxReviewFixRounds,
    ),
    autoMerge: pick('autoMerge', task.autoMerge, defaults.autoMerge),
    autoFixFailingChecks: pick(
      'autoFixFailingChecks',
      task.autoFixFailingChecks,
      defaults.autoFixFailingChecks,
    ),
    maxCheckFixAttempts: pick(
      'maxCheckFixAttempts',
      task.maxCheckFixAttempts,
      defaults.maxCheckFixAttempts,
    ),
  );
}

/// After the workspace or [projectId]'s defaults changed: brings the
/// unfinished tasks' inherited options in line and tells the panel.
Future<void> propagateTaskDefaults(Session session, {int? projectId}) async {
  final workspace = await workspaceSettings(session);
  final projects = projectId == null
      ? await Project.db.find(session)
      : [?await Project.db.findById(session, projectId)];
  for (final project in projects) {
    final defaults = resolveTaskDefaults(project, workspace);
    final tasks = await Task.db.find(
      session,
      where: (t) =>
          t.projectId.equals(project.id!) &
          t.status.inSet(nonTerminalTaskStatuses),
    );
    for (final task in tasks) {
      final next = withInheritedOptions(task, defaults);
      if (_mapEquals(_taskValues(next), _taskValues(task))) continue;
      // Only the option columns: the daemon writes the others concurrently.
      final updated = await Task.db.updateRow(
        session,
        next,
        columns: (t) => [
          t.autoReview,
          t.reviewerAgentId,
          t.autoFixReview,
          t.maxReviewFixRounds,
          t.autoMerge,
          t.autoFixFailingChecks,
          t.maxCheckFixAttempts,
        ],
      );
      await session.messages.postMessage(
        TaskEndpoint.channelForTask(updated.id!),
        updated,
      );
      await session.messages.postMessage(
        TaskEndpoint.channelForAllTasks(),
        updated,
      );
    }
  }
}

bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) =>
    a.keys.every((k) => a[k] == b[k]);
