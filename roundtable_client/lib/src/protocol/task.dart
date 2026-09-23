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
import 'project.dart' as _ifiazq2p;
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
    bool? skipPlanning,
    _ic097rko.TaskStatus? status,
    this.currentPlan,
    this.failureReason,
    this.claudeSessionId,
    this.branchName,
    this.prUrl,
    DateTime? createdAt,
    this.startedAt,
    this.finishedAt,
    DateTime? lastProgressAt,
    this.logs,
    this.feedback,
    this.questions,
  }) : skipPlanning = skipPlanning ?? false,
       status = status ?? _ic097rko.TaskStatus.queued,
       createdAt = createdAt ?? DateTime.now(),
       lastProgressAt = lastProgressAt ?? DateTime.now();

  factory Task({
    int? id,
    required int projectId,
    _ifiazq2p.Project? project,
    int? agentId,
    _ijo8h3v4.Agent? agent,
    required String prompt,
    bool? skipPlanning,
    _ic097rko.TaskStatus? status,
    String? currentPlan,
    String? failureReason,
    String? claudeSessionId,
    String? branchName,
    String? prUrl,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? lastProgressAt,
    List<_ihv3trno.TaskLogEntry>? logs,
    List<_i5hi2zxr.TaskFeedback>? feedback,
    List<_ivtt8ejd.TaskQuestion>? questions,
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
      skipPlanning: jsonSerialization['skipPlanning'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['skipPlanning']),
      status: jsonSerialization['status'] == null
          ? null
          : _ic097rko.TaskStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      currentPlan: jsonSerialization['currentPlan'] as String?,
      failureReason: jsonSerialization['failureReason'] as String?,
      claudeSessionId: jsonSerialization['claudeSessionId'] as String?,
      branchName: jsonSerialization['branchName'] as String?,
      prUrl: jsonSerialization['prUrl'] as String?,
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

  /// Saves Claude Code usage on trivial tasks by skipping the planning phase entirely.
  bool skipPlanning;

  _ic097rko.TaskStatus status;

  /// Content of the latest ExitPlanMode plan, when status=planReady.
  String? currentPlan;

  /// Short error summary, no log-scrolling needed.
  String? failureReason;

  /// Claude Code session id, for --resume on feedback.
  String? claudeSessionId;

  String? branchName;

  String? prUrl;

  DateTime createdAt;

  DateTime? startedAt;

  DateTime? finishedAt;

  /// Bumped on every sign of activity (a log line, a status transition).
  /// Used by StalledTaskFutureCall to detect a task that's stopped making progress.
  DateTime lastProgressAt;

  List<_ihv3trno.TaskLogEntry>? logs;

  List<_i5hi2zxr.TaskFeedback>? feedback;

  List<_ivtt8ejd.TaskQuestion>? questions;

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
    bool? skipPlanning,
    _ic097rko.TaskStatus? status,
    String? currentPlan,
    String? failureReason,
    String? claudeSessionId,
    String? branchName,
    String? prUrl,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? lastProgressAt,
    List<_ihv3trno.TaskLogEntry>? logs,
    List<_i5hi2zxr.TaskFeedback>? feedback,
    List<_ivtt8ejd.TaskQuestion>? questions,
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
      'skipPlanning': skipPlanning,
      'status': status.toJson(),
      if (currentPlan != null) 'currentPlan': currentPlan,
      if (failureReason != null) 'failureReason': failureReason,
      if (claudeSessionId != null) 'claudeSessionId': claudeSessionId,
      if (branchName != null) 'branchName': branchName,
      if (prUrl != null) 'prUrl': prUrl,
      'createdAt': createdAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (finishedAt != null) 'finishedAt': finishedAt?.toJson(),
      'lastProgressAt': lastProgressAt.toJson(),
      if (logs != null) 'logs': logs?.toJson(valueToJson: (v) => v.toJson()),
      if (feedback != null)
        'feedback': feedback?.toJson(valueToJson: (v) => v.toJson()),
      if (questions != null)
        'questions': questions?.toJson(valueToJson: (v) => v.toJson()),
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
      'skipPlanning': skipPlanning,
      'status': status.toJson(),
      if (currentPlan != null) 'currentPlan': currentPlan,
      if (failureReason != null) 'failureReason': failureReason,
      if (claudeSessionId != null) 'claudeSessionId': claudeSessionId,
      if (branchName != null) 'branchName': branchName,
      if (prUrl != null) 'prUrl': prUrl,
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
    bool? skipPlanning,
    _ic097rko.TaskStatus? status,
    String? currentPlan,
    String? failureReason,
    String? claudeSessionId,
    String? branchName,
    String? prUrl,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? lastProgressAt,
    List<_ihv3trno.TaskLogEntry>? logs,
    List<_i5hi2zxr.TaskFeedback>? feedback,
    List<_ivtt8ejd.TaskQuestion>? questions,
  }) : super._(
         id: id,
         projectId: projectId,
         project: project,
         agentId: agentId,
         agent: agent,
         prompt: prompt,
         skipPlanning: skipPlanning,
         status: status,
         currentPlan: currentPlan,
         failureReason: failureReason,
         claudeSessionId: claudeSessionId,
         branchName: branchName,
         prUrl: prUrl,
         createdAt: createdAt,
         startedAt: startedAt,
         finishedAt: finishedAt,
         lastProgressAt: lastProgressAt,
         logs: logs,
         feedback: feedback,
         questions: questions,
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
    bool? skipPlanning,
    _ic097rko.TaskStatus? status,
    Object? currentPlan = _Undefined,
    Object? failureReason = _Undefined,
    Object? claudeSessionId = _Undefined,
    Object? branchName = _Undefined,
    Object? prUrl = _Undefined,
    DateTime? createdAt,
    Object? startedAt = _Undefined,
    Object? finishedAt = _Undefined,
    DateTime? lastProgressAt,
    Object? logs = _Undefined,
    Object? feedback = _Undefined,
    Object? questions = _Undefined,
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
      skipPlanning: skipPlanning ?? this.skipPlanning,
      status: status ?? this.status,
      currentPlan: currentPlan is String? ? currentPlan : this.currentPlan,
      failureReason: failureReason is String?
          ? failureReason
          : this.failureReason,
      claudeSessionId: claudeSessionId is String?
          ? claudeSessionId
          : this.claudeSessionId,
      branchName: branchName is String? ? branchName : this.branchName,
      prUrl: prUrl is String? ? prUrl : this.prUrl,
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
    );
  }
}
