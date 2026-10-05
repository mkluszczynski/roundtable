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

const autoReviewOption = TaskOptionInfo(
  'Auto review',
  'Request an AI code review every time the agent finishes a version',
);

const reviewerOption = TaskOptionInfo(
  'Reviewer',
  'Reviews the PR — used by auto review and pre-selected for manual ones',
);

const autoFixOption = TaskOptionInfo(
  'Auto fix review',
  'Send the review\'s blockers and issues to the agent without waiting — '
      'nits stay for you',
);

const maxFixRoundsOption = TaskOptionInfo(
  'Fix rounds',
  'How many review → fix rounds auto fix runs before handing over to you',
);

/// Choices offered for [maxFixRoundsOption].
const fixRoundChoices = [1, 2, 3, 5];

const autoMergeOption = TaskOptionInfo(
  'Auto merge',
  'Squash-merge the PR once CI passes and, with auto review, the review '
      'has no open blockers or issues',
);

/// Shown when auto merge is on without auto review.
const autoMergeWithoutReviewHint =
    'Without auto review this merges as soon as CI passes — no review';

const autoFixChecksOption = TaskOptionInfo(
  'Auto fix CI',
  'Send failing GitHub Actions checks and their logs to the agent without '
      'waiting',
);

const maxCheckFixAttemptsOption = TaskOptionInfo(
  'CI fix attempts',
  'How many automatic CI fix runs a task gets before handing over to you',
);
