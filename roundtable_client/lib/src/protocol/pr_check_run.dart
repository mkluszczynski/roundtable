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
import 'task.dart' as _iwn6t6fs;

/// One GitHub Actions job run for a task PR's head commit. Mirrored from the
/// Actions API by `syncChecks` (lib/src/pr_checks.dart); the rows of a
/// previous head commit are replaced once the PR gets a new one.
abstract class PrCheckRun
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PrCheckRun._({
    this.id,
    required this.taskId,
    this.task,
    required this.headSha,
    required this.workflowRunId,
    required this.runAttempt,
    required this.workflowName,
    required this.jobId,
    required this.jobName,
    required this.status,
    this.conclusion,
    this.failedStep,
    this.htmlUrl,
    this.startedAt,
    this.completedAt,
  });

  factory PrCheckRun({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    required String headSha,
    required int workflowRunId,
    required int runAttempt,
    required String workflowName,
    required int jobId,
    required String jobName,
    required String status,
    String? conclusion,
    String? failedStep,
    String? htmlUrl,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _PrCheckRunImpl;

  factory PrCheckRun.fromJson(Map<String, dynamic> jsonSerialization) {
    return PrCheckRun(
      id: jsonSerialization['id'] as int?,
      taskId: jsonSerialization['taskId'] as int,
      task: jsonSerialization['task'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<_iwn6t6fs.Task>(
              jsonSerialization['task'],
            ),
      headSha: jsonSerialization['headSha'] as String,
      workflowRunId: jsonSerialization['workflowRunId'] as int,
      runAttempt: jsonSerialization['runAttempt'] as int,
      workflowName: jsonSerialization['workflowName'] as String,
      jobId: jsonSerialization['jobId'] as int,
      jobName: jsonSerialization['jobName'] as String,
      status: jsonSerialization['status'] as String,
      conclusion: jsonSerialization['conclusion'] as String?,
      failedStep: jsonSerialization['failedStep'] as String?,
      htmlUrl: jsonSerialization['htmlUrl'] as String?,
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int taskId;

  /// onDelete=Cascade: a check has no meaning independent of its task.
  _iwn6t6fs.Task? task;

  /// The commit the job ran on — always the task's `prHeadSha`.
  String headSha;

  /// The workflow run the job belongs to, and which attempt of it (a
  /// re-run on GitHub bumps it).
  int workflowRunId;

  int runAttempt;

  String workflowName;

  /// GitHub's job id, used to fetch the job's log.
  int jobId;

  String jobName;

  /// `queued`, `in_progress`, `completed`, ... as GitHub reports it.
  String status;

  /// Set once completed: `success`, `failure`, `cancelled`, `skipped`, ...
  String? conclusion;

  /// Name of the first step that failed, if any.
  String? failedStep;

  /// The job's page on GitHub.
  String? htmlUrl;

  DateTime? startedAt;

  DateTime? completedAt;

  /// Returns a shallow copy of this [PrCheckRun]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PrCheckRun copyWith({
    int? id,
    int? taskId,
    _iwn6t6fs.Task? task,
    String? headSha,
    int? workflowRunId,
    int? runAttempt,
    String? workflowName,
    int? jobId,
    String? jobName,
    String? status,
    String? conclusion,
    String? failedStep,
    String? htmlUrl,
    DateTime? startedAt,
    DateTime? completedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PrCheckRun',
      if (id != null) 'id': id,
      'taskId': taskId,
      if (task != null) 'task': task?.toJson(),
      'headSha': headSha,
      'workflowRunId': workflowRunId,
      'runAttempt': runAttempt,
      'workflowName': workflowName,
      'jobId': jobId,
      'jobName': jobName,
      'status': status,
      if (conclusion != null) 'conclusion': conclusion,
      if (failedStep != null) 'failedStep': failedStep,
      if (htmlUrl != null) 'htmlUrl': htmlUrl,
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PrCheckRun',
      if (id != null) 'id': id,
      'taskId': taskId,
      if (task != null) 'task': task?.toJsonForProtocol(),
      'headSha': headSha,
      'workflowRunId': workflowRunId,
      'runAttempt': runAttempt,
      'workflowName': workflowName,
      'jobId': jobId,
      'jobName': jobName,
      'status': status,
      if (conclusion != null) 'conclusion': conclusion,
      if (failedStep != null) 'failedStep': failedStep,
      if (htmlUrl != null) 'htmlUrl': htmlUrl,
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrCheckRunImpl extends PrCheckRun {
  _PrCheckRunImpl({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    required String headSha,
    required int workflowRunId,
    required int runAttempt,
    required String workflowName,
    required int jobId,
    required String jobName,
    required String status,
    String? conclusion,
    String? failedStep,
    String? htmlUrl,
    DateTime? startedAt,
    DateTime? completedAt,
  }) : super._(
         id: id,
         taskId: taskId,
         task: task,
         headSha: headSha,
         workflowRunId: workflowRunId,
         runAttempt: runAttempt,
         workflowName: workflowName,
         jobId: jobId,
         jobName: jobName,
         status: status,
         conclusion: conclusion,
         failedStep: failedStep,
         htmlUrl: htmlUrl,
         startedAt: startedAt,
         completedAt: completedAt,
       );

  /// Returns a shallow copy of this [PrCheckRun]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PrCheckRun copyWith({
    Object? id = _Undefined,
    int? taskId,
    Object? task = _Undefined,
    String? headSha,
    int? workflowRunId,
    int? runAttempt,
    String? workflowName,
    int? jobId,
    String? jobName,
    String? status,
    Object? conclusion = _Undefined,
    Object? failedStep = _Undefined,
    Object? htmlUrl = _Undefined,
    Object? startedAt = _Undefined,
    Object? completedAt = _Undefined,
  }) {
    return PrCheckRun(
      id: id is int? ? id : this.id,
      taskId: taskId ?? this.taskId,
      task: task is _iwn6t6fs.Task? ? task : this.task?.copyWith(),
      headSha: headSha ?? this.headSha,
      workflowRunId: workflowRunId ?? this.workflowRunId,
      runAttempt: runAttempt ?? this.runAttempt,
      workflowName: workflowName ?? this.workflowName,
      jobId: jobId ?? this.jobId,
      jobName: jobName ?? this.jobName,
      status: status ?? this.status,
      conclusion: conclusion is String? ? conclusion : this.conclusion,
      failedStep: failedStep is String? ? failedStep : this.failedStep,
      htmlUrl: htmlUrl is String? ? htmlUrl : this.htmlUrl,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
    );
  }
}
