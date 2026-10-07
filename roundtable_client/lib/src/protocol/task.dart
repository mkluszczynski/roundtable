/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:roundtable_client/src/protocol/protocol.dart' as _i35hmugi;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'agent.dart' as _ijo8h3v4;
import 'log_phase.dart' as _iv8oofn2;
import 'pr_check_state.dart' as _ivypql97;
import 'project.dart' as _ifiazq2p;
import 'task_attachment.dart' as _isyamz65;
import 'task_feedback.dart' as _i5hi2zxr;
import 'task_log_entry.dart' as _ihv3trno;
import 'task_question.dart' as _ivtt8ejd;
import 'task_status.dart' as _ic097rko;

/// A single unit of work assigned to an agent on a project's repository.
abstract class Task
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Task._({
    this.id,
    required this.projectId,
    this.project,
    this.agentId,
    this.agent,
    required this.prompt,
    this.title,
    bool? skipPlanning,
    bool? autoReview,
    this.reviewerAgentId,
    this.reviewerAgent,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    int? reviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    _ic097rko.TaskStatus? status,
    this.currentPlan,
    this.failureReason,
    this.resultSummary,
    this.pausedUntil,
    this.pauseReason,
    this.pausedPhase,
    this.claudeSessionId,
    this.branchName,
    this.prUrl,
    this.prHeadSha,
    this.prHeadSeenAt,
    _ivypql97.PrCheckState? checkState,
    this.checkError,
    int? checkFixAttempts,
    this.checkFixSentForSha,
    this.prAdditions,
    this.prDeletions,
    int? openReviewComments,
    DateTime? createdAt,
    this.startedAt,
    this.finishedAt,
    DateTime? lastProgressAt,
    this.logs,
    this.feedback,
    this.questions,
    this.attachments,
  }) : skipPlanning = skipPlanning ?? false,
       autoReview = autoReview ?? false,
       autoFixReview = autoFixReview ?? false,
       maxReviewFixRounds = maxReviewFixRounds ?? 2,
       reviewFixRounds = reviewFixRounds ?? 0,
       autoMerge = autoMerge ?? false,
       autoFixFailingChecks = autoFixFailingChecks ?? false,
       maxCheckFixAttempts = maxCheckFixAttempts ?? 2,
       status = status ?? _ic097rko.TaskStatus.queued,
       checkState = checkState ?? _ivypql97.PrCheckState.none,
       checkFixAttempts = checkFixAttempts ?? 0,
       openReviewComments = openReviewComments ?? 0,
       createdAt = createdAt ?? DateTime.now(),
       lastProgressAt = lastProgressAt ?? DateTime.now();

  factory Task({
    int? id,
    required int projectId,
    _ifiazq2p.Project? project,
    int? agentId,
    _ijo8h3v4.Agent? agent,
    required String prompt,
    String? title,
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    int? reviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    _ic097rko.TaskStatus? status,
    String? currentPlan,
    String? failureReason,
    String? resultSummary,
    DateTime? pausedUntil,
    String? pauseReason,
    _iv8oofn2.LogPhase? pausedPhase,
    String? claudeSessionId,
    String? branchName,
    String? prUrl,
    String? prHeadSha,
    DateTime? prHeadSeenAt,
    _ivypql97.PrCheckState? checkState,
    String? checkError,
    int? checkFixAttempts,
    String? checkFixSentForSha,
    int? prAdditions,
    int? prDeletions,
    int? openReviewComments,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? lastProgressAt,
    List<_ihv3trno.TaskLogEntry>? logs,
    List<_i5hi2zxr.TaskFeedback>? feedback,
    List<_ivtt8ejd.TaskQuestion>? questions,
    List<_isyamz65.TaskAttachment>? attachments,
  }) = _TaskImpl;

  factory Task.fromJson(Map<String, dynamic> jsonSerialization) {
    return Task(
      id: jsonSerialization['id'] as int?,
      projectId: jsonSerialization['projectId'] as int,
      project: jsonSerialization['project'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<_ifiazq2p.Project>(
              jsonSerialization['project'],
            ),
      agentId: jsonSerialization['agentId'] as int?,
      agent: jsonSerialization['agent'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<_ijo8h3v4.Agent>(
              jsonSerialization['agent'],
            ),
      prompt: jsonSerialization['prompt'] as String,
      title: jsonSerialization['title'] as String?,
      skipPlanning: jsonSerialization['skipPlanning'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['skipPlanning']),
      autoReview: jsonSerialization['autoReview'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['autoReview']),
      reviewerAgentId: jsonSerialization['reviewerAgentId'] as int?,
      reviewerAgent: jsonSerialization['reviewerAgent'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<_ijo8h3v4.Agent>(
              jsonSerialization['reviewerAgent'],
            ),
      autoFixReview: jsonSerialization['autoFixReview'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['autoFixReview']),
      maxReviewFixRounds: jsonSerialization['maxReviewFixRounds'] as int?,
      reviewFixRounds: jsonSerialization['reviewFixRounds'] as int?,
      autoMerge: jsonSerialization['autoMerge'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['autoMerge']),
      autoFixFailingChecks: jsonSerialization['autoFixFailingChecks'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['autoFixFailingChecks'],
            ),
      maxCheckFixAttempts: jsonSerialization['maxCheckFixAttempts'] as int?,
      status: jsonSerialization['status'] == null
          ? null
          : _ic097rko.TaskStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      currentPlan: jsonSerialization['currentPlan'] as String?,
      failureReason: jsonSerialization['failureReason'] as String?,
      resultSummary: jsonSerialization['resultSummary'] as String?,
      pausedUntil: jsonSerialization['pausedUntil'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['pausedUntil'],
            ),
      pauseReason: jsonSerialization['pauseReason'] as String?,
      pausedPhase: jsonSerialization['pausedPhase'] == null
          ? null
          : _iv8oofn2.LogPhase.fromJson(
              (jsonSerialization['pausedPhase'] as String),
            ),
      claudeSessionId: jsonSerialization['claudeSessionId'] as String?,
      branchName: jsonSerialization['branchName'] as String?,
      prUrl: jsonSerialization['prUrl'] as String?,
      prHeadSha: jsonSerialization['prHeadSha'] as String?,
      prHeadSeenAt: jsonSerialization['prHeadSeenAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['prHeadSeenAt'],
            ),
      checkState: jsonSerialization['checkState'] == null
          ? null
          : _ivypql97.PrCheckState.fromJson(
              (jsonSerialization['checkState'] as String),
            ),
      checkError: jsonSerialization['checkError'] as String?,
      checkFixAttempts: jsonSerialization['checkFixAttempts'] as int?,
      checkFixSentForSha: jsonSerialization['checkFixSentForSha'] as String?,
      prAdditions: jsonSerialization['prAdditions'] as int?,
      prDeletions: jsonSerialization['prDeletions'] as int?,
      openReviewComments: jsonSerialization['openReviewComments'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      finishedAt: jsonSerialization['finishedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['finishedAt'],
            ),
      lastProgressAt: jsonSerialization['lastProgressAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastProgressAt'],
            ),
      logs: jsonSerialization['logs'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<List<_ihv3trno.TaskLogEntry>>(
              jsonSerialization['logs'],
            ),
      feedback: jsonSerialization['feedback'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<List<_i5hi2zxr.TaskFeedback>>(
              jsonSerialization['feedback'],
            ),
      questions: jsonSerialization['questions'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<List<_ivtt8ejd.TaskQuestion>>(
              jsonSerialization['questions'],
            ),
      attachments: jsonSerialization['attachments'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<List<_isyamz65.TaskAttachment>>(
              jsonSerialization['attachments'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int projectId;

  /// onDelete=Cascade: a task has no meaning independent of its project,
  /// unlike Agent (kept optional/SetNull for task history, see below).
  _ifiazq2p.Project? project;

  int? agentId;

  /// Optional — this opens the door to task queueing without a schema change.
  /// onDelete=SetNull: deleting an agent (once its non-terminal tasks are
  /// gone) keeps its terminal/historical tasks around, just unassigned.
  _ijo8h3v4.Agent? agent;

  /// The task prompt given by the dev.
  String prompt;

  /// Short name shown on the board instead of the prompt. Suggested by the
  /// agent at the start of its first run (only while null, see
  /// `TaskEndpoint.suggestTitle`); the dev can rename it any time.
  String? title;

  /// Saves Claude Code usage on trivial tasks by skipping the planning phase entirely.
  bool skipPlanning;

  /// Queue an AI code review by [reviewerAgent] every time a run leaves the
  /// task awaiting review with a PR.
  bool autoReview;

  int? reviewerAgentId;

  /// The agent that reviews this task's PR: picked up front, used by auto
  /// review and pre-selected when the dev requests one by hand.
  _ijo8h3v4.Agent? reviewerAgent;

  /// After each AI review, send its open blocker/issue comments to the
  /// agent without waiting for the dev — up to [maxReviewFixRounds] times.
  bool autoFixReview;

  int maxReviewFixRounds;

  /// Review rounds auto fix has sent so far; caps the review ↔ fix loop.
  int reviewFixRounds;

  /// Squash-merge the PR without the dev once it's ready: CI green (or no
  /// CI), no review or fix run in flight, and — with [autoReview] — the
  /// latest version reviewed with no open blockers or issues. Turned off
  /// if GitHub refuses the merge, so the dev takes over.
  bool autoMerge;

  /// Send failing CI checks to the agent without waiting for the dev —
  /// once per commit, at most [maxCheckFixAttempts] times until they pass.
  bool autoFixFailingChecks;

  int maxCheckFixAttempts;

  _ic097rko.TaskStatus status;

  /// Content of the latest ExitPlanMode plan, when status=planReady.
  String? currentPlan;

  /// Short error summary, no log-scrolling needed.
  String? failureReason;

  /// The agent's final reply from its last run (the `result` of Claude
  /// Code's stream). Shown as the task's result — it's the whole outcome
  /// when the agent finished without changing code, e.g. it answered a
  /// question or found nothing to change.
  String? resultSummary;

  /// Set while `paused`: when the usage limit resets and the task resumes.
  /// Also set, with [pausedPhase] `review`, on an `awaitingReview` task
  /// whose code review waits for the limit (`refreshReviewPause`).
  DateTime? pausedUntil;

  /// The limit message shown while paused, e.g. "You've hit your session
  /// limit · resets 12:40am".
  String? pauseReason;

  /// Which kind of run was interrupted, so the resume continues the same
  /// session the same way (planning keeps plan mode). Cleared by the
  /// daemon once the resumed run starts.
  _iv8oofn2.LogPhase? pausedPhase;

  /// Claude Code session id, for --resume on feedback.
  String? claudeSessionId;

  String? branchName;

  String? prUrl;

  /// The PR's head commit the CI checks ([checkState], `PrCheckRun`) belong
  /// to. A new commit (a fix run, a manual push) resets the checks.
  String? prHeadSha;

  /// When [prHeadSha] was first seen — a new commit's workflows get a grace
  /// period to show up before "no CI" counts as mergeable.
  DateTime? prHeadSeenAt;

  /// Aggregated GitHub Actions result for [prHeadSha]; `acceptTask` only
  /// merges on `success` (or `none` after the grace period).
  _ivypql97.PrCheckState checkState;

  /// Why the checks can't be read (e.g. a token without "Actions: Read"),
  /// in which case [checkState] stays `none` and GitHub's own branch
  /// protection decides whether the PR can merge.
  String? checkError;

  /// Fix runs sent for failing checks since they last passed — caps the
  /// task's auto-fix ([maxCheckFixAttempts]).
  int checkFixAttempts;

  /// The head commit whose failing checks were last sent to the agent, so
  /// the same failure is never auto-sent twice.
  String? checkFixSentForSha;

  /// Lines added/removed by the PR at [prHeadSha], as GitHub counts them —
  /// kept on the task so the kanban needs no diff fetch. Null until the
  /// first checks sync.
  int? prAdditions;

  int? prDeletions;

  /// Review comments still `open` or `sentToFix`, across all the task's
  /// reviews. Kept up to date by `postReviewChanged`.
  int openReviewComments;

  DateTime createdAt;

  DateTime? startedAt;

  DateTime? finishedAt;

  /// Bumped on every sign of activity (a log line, a status transition).
  /// Used by StalledTaskFutureCall to detect a task that's stopped making progress.
  DateTime lastProgressAt;

  List<_ihv3trno.TaskLogEntry>? logs;

  List<_i5hi2zxr.TaskFeedback>? feedback;

  List<_ivtt8ejd.TaskQuestion>? questions;

  List<_isyamz65.TaskAttachment>? attachments;

  /// Returns a shallow copy of this [Task]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Task copyWith({
    int? id,
    int? projectId,
    _ifiazq2p.Project? project,
    int? agentId,
    _ijo8h3v4.Agent? agent,
    String? prompt,
    String? title,
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    int? reviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    _ic097rko.TaskStatus? status,
    String? currentPlan,
    String? failureReason,
    String? resultSummary,
    DateTime? pausedUntil,
    String? pauseReason,
    _iv8oofn2.LogPhase? pausedPhase,
    String? claudeSessionId,
    String? branchName,
    String? prUrl,
    String? prHeadSha,
    DateTime? prHeadSeenAt,
    _ivypql97.PrCheckState? checkState,
    String? checkError,
    int? checkFixAttempts,
    String? checkFixSentForSha,
    int? prAdditions,
    int? prDeletions,
    int? openReviewComments,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? lastProgressAt,
    List<_ihv3trno.TaskLogEntry>? logs,
    List<_i5hi2zxr.TaskFeedback>? feedback,
    List<_ivtt8ejd.TaskQuestion>? questions,
    List<_isyamz65.TaskAttachment>? attachments,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Task',
      if (id != null) 'id': id,
      'projectId': projectId,
      if (project != null) 'project': project?.toJson(),
      if (agentId != null) 'agentId': agentId,
      if (agent != null) 'agent': agent?.toJson(),
      'prompt': prompt,
      if (title != null) 'title': title,
      'skipPlanning': skipPlanning,
      'autoReview': autoReview,
      if (reviewerAgentId != null) 'reviewerAgentId': reviewerAgentId,
      if (reviewerAgent != null) 'reviewerAgent': reviewerAgent?.toJson(),
      'autoFixReview': autoFixReview,
      'maxReviewFixRounds': maxReviewFixRounds,
      'reviewFixRounds': reviewFixRounds,
      'autoMerge': autoMerge,
      'autoFixFailingChecks': autoFixFailingChecks,
      'maxCheckFixAttempts': maxCheckFixAttempts,
      'status': status.toJson(),
      if (currentPlan != null) 'currentPlan': currentPlan,
      if (failureReason != null) 'failureReason': failureReason,
      if (resultSummary != null) 'resultSummary': resultSummary,
      if (pausedUntil != null) 'pausedUntil': pausedUntil?.toJson(),
      if (pauseReason != null) 'pauseReason': pauseReason,
      if (pausedPhase != null) 'pausedPhase': pausedPhase?.toJson(),
      if (claudeSessionId != null) 'claudeSessionId': claudeSessionId,
      if (branchName != null) 'branchName': branchName,
      if (prUrl != null) 'prUrl': prUrl,
      if (prHeadSha != null) 'prHeadSha': prHeadSha,
      if (prHeadSeenAt != null) 'prHeadSeenAt': prHeadSeenAt?.toJson(),
      'checkState': checkState.toJson(),
      if (checkError != null) 'checkError': checkError,
      'checkFixAttempts': checkFixAttempts,
      if (checkFixSentForSha != null) 'checkFixSentForSha': checkFixSentForSha,
      if (prAdditions != null) 'prAdditions': prAdditions,
      if (prDeletions != null) 'prDeletions': prDeletions,
      'openReviewComments': openReviewComments,
      'createdAt': createdAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (finishedAt != null) 'finishedAt': finishedAt?.toJson(),
      'lastProgressAt': lastProgressAt.toJson(),
      if (logs != null) 'logs': logs?.toJson(valueToJson: (v) => v.toJson()),
      if (feedback != null)
        'feedback': feedback?.toJson(valueToJson: (v) => v.toJson()),
      if (questions != null)
        'questions': questions?.toJson(valueToJson: (v) => v.toJson()),
      if (attachments != null)
        'attachments': attachments?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Task',
      if (id != null) 'id': id,
      'projectId': projectId,
      if (project != null) 'project': project?.toJsonForProtocol(),
      if (agentId != null) 'agentId': agentId,
      if (agent != null) 'agent': agent?.toJsonForProtocol(),
      'prompt': prompt,
      if (title != null) 'title': title,
      'skipPlanning': skipPlanning,
      'autoReview': autoReview,
      if (reviewerAgentId != null) 'reviewerAgentId': reviewerAgentId,
      if (reviewerAgent != null)
        'reviewerAgent': reviewerAgent?.toJsonForProtocol(),
      'autoFixReview': autoFixReview,
      'maxReviewFixRounds': maxReviewFixRounds,
      'reviewFixRounds': reviewFixRounds,
      'autoMerge': autoMerge,
      'autoFixFailingChecks': autoFixFailingChecks,
      'maxCheckFixAttempts': maxCheckFixAttempts,
      'status': status.toJson(),
      if (currentPlan != null) 'currentPlan': currentPlan,
      if (failureReason != null) 'failureReason': failureReason,
      if (resultSummary != null) 'resultSummary': resultSummary,
      if (pausedUntil != null) 'pausedUntil': pausedUntil?.toJson(),
      if (pauseReason != null) 'pauseReason': pauseReason,
      if (pausedPhase != null) 'pausedPhase': pausedPhase?.toJson(),
      if (claudeSessionId != null) 'claudeSessionId': claudeSessionId,
      if (branchName != null) 'branchName': branchName,
      if (prUrl != null) 'prUrl': prUrl,
      if (prHeadSha != null) 'prHeadSha': prHeadSha,
      if (prHeadSeenAt != null) 'prHeadSeenAt': prHeadSeenAt?.toJson(),
      'checkState': checkState.toJson(),
      if (checkError != null) 'checkError': checkError,
      'checkFixAttempts': checkFixAttempts,
      if (checkFixSentForSha != null) 'checkFixSentForSha': checkFixSentForSha,
      if (prAdditions != null) 'prAdditions': prAdditions,
      if (prDeletions != null) 'prDeletions': prDeletions,
      'openReviewComments': openReviewComments,
      'createdAt': createdAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (finishedAt != null) 'finishedAt': finishedAt?.toJson(),
      'lastProgressAt': lastProgressAt.toJson(),
      if (logs != null)
        'logs': logs?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (feedback != null)
        'feedback': feedback?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (questions != null)
        'questions': questions?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (attachments != null)
        'attachments': attachments?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaskImpl extends Task {
  _TaskImpl({
    int? id,
    required int projectId,
    _ifiazq2p.Project? project,
    int? agentId,
    _ijo8h3v4.Agent? agent,
    required String prompt,
    String? title,
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    int? reviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    _ic097rko.TaskStatus? status,
    String? currentPlan,
    String? failureReason,
    String? resultSummary,
    DateTime? pausedUntil,
    String? pauseReason,
    _iv8oofn2.LogPhase? pausedPhase,
    String? claudeSessionId,
    String? branchName,
    String? prUrl,
    String? prHeadSha,
    DateTime? prHeadSeenAt,
    _ivypql97.PrCheckState? checkState,
    String? checkError,
    int? checkFixAttempts,
    String? checkFixSentForSha,
    int? prAdditions,
    int? prDeletions,
    int? openReviewComments,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? lastProgressAt,
    List<_ihv3trno.TaskLogEntry>? logs,
    List<_i5hi2zxr.TaskFeedback>? feedback,
    List<_ivtt8ejd.TaskQuestion>? questions,
    List<_isyamz65.TaskAttachment>? attachments,
  }) : super._(
         id: id,
         projectId: projectId,
         project: project,
         agentId: agentId,
         agent: agent,
         prompt: prompt,
         title: title,
         skipPlanning: skipPlanning,
         autoReview: autoReview,
         reviewerAgentId: reviewerAgentId,
         reviewerAgent: reviewerAgent,
         autoFixReview: autoFixReview,
         maxReviewFixRounds: maxReviewFixRounds,
         reviewFixRounds: reviewFixRounds,
         autoMerge: autoMerge,
         autoFixFailingChecks: autoFixFailingChecks,
         maxCheckFixAttempts: maxCheckFixAttempts,
         status: status,
         currentPlan: currentPlan,
         failureReason: failureReason,
         resultSummary: resultSummary,
         pausedUntil: pausedUntil,
         pauseReason: pauseReason,
         pausedPhase: pausedPhase,
         claudeSessionId: claudeSessionId,
         branchName: branchName,
         prUrl: prUrl,
         prHeadSha: prHeadSha,
         prHeadSeenAt: prHeadSeenAt,
         checkState: checkState,
         checkError: checkError,
         checkFixAttempts: checkFixAttempts,
         checkFixSentForSha: checkFixSentForSha,
         prAdditions: prAdditions,
         prDeletions: prDeletions,
         openReviewComments: openReviewComments,
         createdAt: createdAt,
         startedAt: startedAt,
         finishedAt: finishedAt,
         lastProgressAt: lastProgressAt,
         logs: logs,
         feedback: feedback,
         questions: questions,
         attachments: attachments,
       );

  /// Returns a shallow copy of this [Task]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Task copyWith({
    Object? id = _Undefined,
    int? projectId,
    Object? project = _Undefined,
    Object? agentId = _Undefined,
    Object? agent = _Undefined,
    String? prompt,
    Object? title = _Undefined,
    bool? skipPlanning,
    bool? autoReview,
    Object? reviewerAgentId = _Undefined,
    Object? reviewerAgent = _Undefined,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    int? reviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    _ic097rko.TaskStatus? status,
    Object? currentPlan = _Undefined,
    Object? failureReason = _Undefined,
    Object? resultSummary = _Undefined,
    Object? pausedUntil = _Undefined,
    Object? pauseReason = _Undefined,
    Object? pausedPhase = _Undefined,
    Object? claudeSessionId = _Undefined,
    Object? branchName = _Undefined,
    Object? prUrl = _Undefined,
    Object? prHeadSha = _Undefined,
    Object? prHeadSeenAt = _Undefined,
    _ivypql97.PrCheckState? checkState,
    Object? checkError = _Undefined,
    int? checkFixAttempts,
    Object? checkFixSentForSha = _Undefined,
    Object? prAdditions = _Undefined,
    Object? prDeletions = _Undefined,
    int? openReviewComments,
    DateTime? createdAt,
    Object? startedAt = _Undefined,
    Object? finishedAt = _Undefined,
    DateTime? lastProgressAt,
    Object? logs = _Undefined,
    Object? feedback = _Undefined,
    Object? questions = _Undefined,
    Object? attachments = _Undefined,
  }) {
    return Task(
      id: id is int? ? id : this.id,
      projectId: projectId ?? this.projectId,
      project: project is _ifiazq2p.Project?
          ? project
          : this.project?.copyWith(),
      agentId: agentId is int? ? agentId : this.agentId,
      agent: agent is _ijo8h3v4.Agent? ? agent : this.agent?.copyWith(),
      prompt: prompt ?? this.prompt,
      title: title is String? ? title : this.title,
      skipPlanning: skipPlanning ?? this.skipPlanning,
      autoReview: autoReview ?? this.autoReview,
      reviewerAgentId: reviewerAgentId is int?
          ? reviewerAgentId
          : this.reviewerAgentId,
      reviewerAgent: reviewerAgent is _ijo8h3v4.Agent?
          ? reviewerAgent
          : this.reviewerAgent?.copyWith(),
      autoFixReview: autoFixReview ?? this.autoFixReview,
      maxReviewFixRounds: maxReviewFixRounds ?? this.maxReviewFixRounds,
      reviewFixRounds: reviewFixRounds ?? this.reviewFixRounds,
      autoMerge: autoMerge ?? this.autoMerge,
      autoFixFailingChecks: autoFixFailingChecks ?? this.autoFixFailingChecks,
      maxCheckFixAttempts: maxCheckFixAttempts ?? this.maxCheckFixAttempts,
      status: status ?? this.status,
      currentPlan: currentPlan is String? ? currentPlan : this.currentPlan,
      failureReason: failureReason is String?
          ? failureReason
          : this.failureReason,
      resultSummary: resultSummary is String?
          ? resultSummary
          : this.resultSummary,
      pausedUntil: pausedUntil is DateTime? ? pausedUntil : this.pausedUntil,
      pauseReason: pauseReason is String? ? pauseReason : this.pauseReason,
      pausedPhase: pausedPhase is _iv8oofn2.LogPhase?
          ? pausedPhase
          : this.pausedPhase,
      claudeSessionId: claudeSessionId is String?
          ? claudeSessionId
          : this.claudeSessionId,
      branchName: branchName is String? ? branchName : this.branchName,
      prUrl: prUrl is String? ? prUrl : this.prUrl,
      prHeadSha: prHeadSha is String? ? prHeadSha : this.prHeadSha,
      prHeadSeenAt: prHeadSeenAt is DateTime?
          ? prHeadSeenAt
          : this.prHeadSeenAt,
      checkState: checkState ?? this.checkState,
      checkError: checkError is String? ? checkError : this.checkError,
      checkFixAttempts: checkFixAttempts ?? this.checkFixAttempts,
      checkFixSentForSha: checkFixSentForSha is String?
          ? checkFixSentForSha
          : this.checkFixSentForSha,
      prAdditions: prAdditions is int? ? prAdditions : this.prAdditions,
      prDeletions: prDeletions is int? ? prDeletions : this.prDeletions,
      openReviewComments: openReviewComments ?? this.openReviewComments,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      finishedAt: finishedAt is DateTime? ? finishedAt : this.finishedAt,
      lastProgressAt: lastProgressAt ?? this.lastProgressAt,
      logs: logs is List<_ihv3trno.TaskLogEntry>?
          ? logs
          : this.logs?.map((e0) => e0.copyWith()).toList(),
      feedback: feedback is List<_i5hi2zxr.TaskFeedback>?
          ? feedback
          : this.feedback?.map((e0) => e0.copyWith()).toList(),
      questions: questions is List<_ivtt8ejd.TaskQuestion>?
          ? questions
          : this.questions?.map((e0) => e0.copyWith()).toList(),
      attachments: attachments is List<_isyamz65.TaskAttachment>?
          ? attachments
          : this.attachments?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
