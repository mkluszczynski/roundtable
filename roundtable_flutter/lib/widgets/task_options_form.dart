import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/task_options.dart';
import 'pill_selector.dart';
import 'reviewer_select.dart';

/// A task's advanced options, as picked in the new-task form or edited on
/// the task view.
@immutable
class TaskOptions {
  const TaskOptions({
    this.skipPlanning = false,
    this.autoReview = false,
    this.reviewerAgentId,
    this.autoFixReview = false,
    this.maxReviewFixRounds = 2,
    this.autoMerge = false,
    this.autoFixFailingChecks = false,
    this.maxCheckFixAttempts = 2,
  });

  TaskOptions.fromDefaults(TaskDefaults d)
    : this(
        skipPlanning: d.skipPlanning,
        autoReview: d.autoReview,
        reviewerAgentId: d.reviewerAgentId,
        autoFixReview: d.autoFixReview,
        maxReviewFixRounds: d.maxReviewFixRounds,
        autoMerge: d.autoMerge,
        autoFixFailingChecks: d.autoFixFailingChecks,
        maxCheckFixAttempts: d.maxCheckFixAttempts,
      );

  TaskOptions.fromTask(Task t)
    : this(
        skipPlanning: t.skipPlanning,
        autoReview: t.autoReview,
        reviewerAgentId: t.reviewerAgentId,
        autoFixReview: t.autoFixReview,
        maxReviewFixRounds: t.maxReviewFixRounds,
        autoMerge: t.autoMerge,
        autoFixFailingChecks: t.autoFixFailingChecks,
        maxCheckFixAttempts: t.maxCheckFixAttempts,
      );

  final bool skipPlanning;
  final bool autoReview;
  final int? reviewerAgentId;
  final bool autoFixReview;
  final int maxReviewFixRounds;
  final bool autoMerge;
  final bool autoFixFailingChecks;
  final int maxCheckFixAttempts;

  TaskOptions copyWith({
    bool? skipPlanning,
    bool? autoReview,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
  }) => TaskOptions(
    skipPlanning: skipPlanning ?? this.skipPlanning,
    autoReview: autoReview ?? this.autoReview,
    reviewerAgentId: reviewerAgentId,
    autoFixReview: autoFixReview ?? this.autoFixReview,
    maxReviewFixRounds: maxReviewFixRounds ?? this.maxReviewFixRounds,
    autoMerge: autoMerge ?? this.autoMerge,
    autoFixFailingChecks: autoFixFailingChecks ?? this.autoFixFailingChecks,
    maxCheckFixAttempts: maxCheckFixAttempts ?? this.maxCheckFixAttempts,
  );

  /// [copyWith] can't tell "keep" from "clear" for the nullable reviewer.
  TaskOptions withReviewer(int? reviewerAgentId) => TaskOptions(
    skipPlanning: skipPlanning,
    autoReview: autoReview,
    reviewerAgentId: reviewerAgentId,
    autoFixReview: autoFixReview,
    maxReviewFixRounds: maxReviewFixRounds,
    autoMerge: autoMerge,
    autoFixFailingChecks: autoFixFailingChecks,
    maxCheckFixAttempts: maxCheckFixAttempts,
  );

  /// Equal as far as the task's behaviour goes: a round count only matters
  /// while its option is on.
  @override
  bool operator ==(Object other) =>
      other is TaskOptions &&
      other.skipPlanning == skipPlanning &&
      other.autoReview == autoReview &&
      other.reviewerAgentId == reviewerAgentId &&
      other.autoFixReview == autoFixReview &&
      (!autoFixReview || other.maxReviewFixRounds == maxReviewFixRounds) &&
      other.autoMerge == autoMerge &&
      other.autoFixFailingChecks == autoFixFailingChecks &&
      (!autoFixFailingChecks ||
          other.maxCheckFixAttempts == maxCheckFixAttempts);

  @override
  int get hashCode => Object.hash(
    skipPlanning,
    autoReview,
    reviewerAgentId,
    autoFixReview,
    autoMerge,
    autoFixFailingChecks,
  );
}

/// What's on, in one line — the options are collapsed or read-only in most
/// places, so this has to say it. With [defaults], also whether they differ
/// from the project's.
String taskOptionsSummary(TaskOptions options, {TaskDefaults? defaults}) {
  final on = [
    options.skipPlanning ? skipPlanningOption.title : 'Plan first',
    if (options.autoReview) autoReviewOption.title,
    if (options.autoFixReview) 'Auto fix ×${options.maxReviewFixRounds}',
    if (options.autoMerge) autoMergeOption.title,
    if (options.autoFixFailingChecks)
      'Auto fix CI ×${options.maxCheckFixAttempts}',
  ];
  final text = on.join(' · ');
  final custom =
      defaults != null && TaskOptions.fromDefaults(defaults) != options;
  return custom ? '$text — changed from project defaults' : text;
}

/// The checkboxes and selectors for [TaskOptions]. With [planningEditable]
/// false (the task already started), skip planning is shown but locked.
class TaskOptionsForm extends StatelessWidget {
  const TaskOptionsForm({
    super.key,
    required this.options,
    required this.onChanged,
    this.planningEditable = true,
  });

  final TaskOptions options;
  final ValueChanged<TaskOptions> onChanged;
  final bool planningEditable;

  @override
  Widget build(BuildContext context) {
    final o = options;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: o.skipPlanning,
          activeColor: AppColors.accent,
          title: Text(skipPlanningOption.title),
          subtitle: Text(
            planningEditable
                ? skipPlanningOption.description
                : 'Only changes before the agent starts',
          ),
          onChanged: planningEditable
              ? (value) => onChanged(o.copyWith(skipPlanning: value ?? false))
              : null,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: o.autoReview,
          activeColor: AppColors.accent,
          title: Text(autoReviewOption.title),
          subtitle: Text(
            o.autoReview && o.reviewerAgentId == null
                ? 'Pick a reviewer below, or auto review is skipped'
                : autoReviewOption.description,
          ),
          onChanged: (value) =>
              onChanged(o.copyWith(autoReview: value ?? false)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Spacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reviewerOption.title, style: AppTypography.body),
                    Text(
                      reviewerOption.description,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),
              ReviewerSelect(
                selected: o.reviewerAgentId,
                onChanged: (id) => onChanged(o.withReviewer(id)),
              ),
            ],
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: o.autoFixReview,
          activeColor: AppColors.accent,
          title: Text(autoFixOption.title),
          subtitle: Text(autoFixOption.description),
          onChanged: (value) =>
              onChanged(o.copyWith(autoFixReview: value ?? false)),
        ),
        if (o.autoFixReview)
          Row(
            children: [
              Expanded(
                child: Text(
                  maxFixRoundsOption.title,
                  style: AppTypography.body,
                ),
              ),
              PillSelector<int>(
                options: fixRoundChoices,
                labelBuilder: (n) => '$n',
                selected: o.maxReviewFixRounds,
                onChanged: (n) => onChanged(o.copyWith(maxReviewFixRounds: n)),
              ),
            ],
          ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: o.autoMerge,
          activeColor: AppColors.accent,
          title: Text(autoMergeOption.title),
          subtitle: Text(
            o.autoMerge && !o.autoReview
                ? autoMergeWithoutReviewHint
                : autoMergeOption.description,
            style: o.autoMerge && !o.autoReview
                ? const TextStyle(color: AppColors.warning)
                : null,
          ),
          onChanged: (value) =>
              onChanged(o.copyWith(autoMerge: value ?? false)),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: o.autoFixFailingChecks,
          activeColor: AppColors.accent,
          title: Text(autoFixChecksOption.title),
          subtitle: Text(autoFixChecksOption.description),
          onChanged: (value) =>
              onChanged(o.copyWith(autoFixFailingChecks: value ?? false)),
        ),
        if (o.autoFixFailingChecks)
          Row(
            children: [
              Expanded(
                child: Text(
                  maxCheckFixAttemptsOption.title,
                  style: AppTypography.body,
                ),
              ),
              PillSelector<int>(
                options: fixRoundChoices,
                labelBuilder: (n) => '$n',
                selected: o.maxCheckFixAttempts,
                onChanged: (n) => onChanged(o.copyWith(maxCheckFixAttempts: n)),
              ),
            ],
          ),
      ],
    );
  }
}
