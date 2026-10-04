/// Copy for the advanced task options, shared by the workspace settings,
/// the project's overrides and the new-task form so they read the same.
class TaskOptionInfo {
  const TaskOptionInfo(this.title, this.description);

  final String title;
  final String description;
}

const skipPlanningOption = TaskOptionInfo(
  'Skip planning',
  'Go straight to execution — saves usage on trivial tasks',
);
