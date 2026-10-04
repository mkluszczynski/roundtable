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
import 'log_kind.dart' as _i7oqmlti;
import 'log_phase.dart' as _iv8oofn2;
import 'log_source.dart' as _ilj2nbps;
import 'task.dart' as _iwn6t6fs;

/// A single line of output from a task's execution, streamed live to the panel.
abstract class TaskLogEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  TaskLogEntry._({
    this.id,
    required this.taskId,
    this.task,
    required this.content,
    _ilj2nbps.LogSource? source,
    DateTime? createdAt,
    this.kind,
    this.runId,
    this.phase,
    this.toolName,
    this.toolUseId,
    this.detail,
    this.isError,
    this.reviewId,
  }) : source = source ?? _ilj2nbps.LogSource.agent,
       createdAt = createdAt ?? DateTime.now();

  factory TaskLogEntry({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    required String content,
    _ilj2nbps.LogSource? source,
    DateTime? createdAt,
    _i7oqmlti.LogKind? kind,
    String? runId,
    _iv8oofn2.LogPhase? phase,
    String? toolName,
    String? toolUseId,
    String? detail,
    bool? isError,
    int? reviewId,
  }) = _TaskLogEntryImpl;

  factory TaskLogEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaskLogEntry(
      id: jsonSerialization['id'] as int?,
      taskId: jsonSerialization['taskId'] as int,
      task: jsonSerialization['task'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<_iwn6t6fs.Task>(
              jsonSerialization['task'],
            ),
      content: jsonSerialization['content'] as String,
      source: jsonSerialization['source'] == null
          ? null
          : _ilj2nbps.LogSource.fromJson(
              (jsonSerialization['source'] as String),
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      kind: jsonSerialization['kind'] == null
          ? null
          : _i7oqmlti.LogKind.fromJson((jsonSerialization['kind'] as String)),
      runId: jsonSerialization['runId'] as String?,
      phase: jsonSerialization['phase'] == null
          ? null
          : _iv8oofn2.LogPhase.fromJson((jsonSerialization['phase'] as String)),
      toolName: jsonSerialization['toolName'] as String?,
      toolUseId: jsonSerialization['toolUseId'] as String?,
      detail: jsonSerialization['detail'] as String?,
      isError: jsonSerialization['isError'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['isError']),
      reviewId: jsonSerialization['reviewId'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int taskId;

  /// onDelete=Cascade: log entries have no meaning independent of their task.
  _iwn6t6fs.Task? task;

  String content;

  _ilj2nbps.LogSource source;

  DateTime createdAt;

  /// Structured fields (null on entries from older runners, which only
  /// sent [content] — the panel falls back to parsing its prefixes).
  _i7oqmlti.LogKind? kind;

  /// Groups the entries of one `claude` invocation; a retry or a feedback
  /// iteration starts a new run.
  String? runId;

  _iv8oofn2.LogPhase? phase;

  String? toolName;

  /// Pairs a toolResult with its toolCall.
  String? toolUseId;

  /// The longer form behind [content] (full tool input/output), truncated.
  String? detail;

  bool? isError;

  /// Set on entries from a code review run (CodeReview.id); no relation so
  /// deleting a review never touches the task's log.
  int? reviewId;

  /// Returns a shallow copy of this [TaskLogEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  TaskLogEntry copyWith({
    int? id,
    int? taskId,
    _iwn6t6fs.Task? task,
    String? content,
    _ilj2nbps.LogSource? source,
    DateTime? createdAt,
    _i7oqmlti.LogKind? kind,
    String? runId,
    _iv8oofn2.LogPhase? phase,
    String? toolName,
    String? toolUseId,
    String? detail,
    bool? isError,
    int? reviewId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TaskLogEntry',
      if (id != null) 'id': id,
      'taskId': taskId,
      if (task != null) 'task': task?.toJson(),
      'content': content,
      'source': source.toJson(),
      'createdAt': createdAt.toJson(),
      if (kind != null) 'kind': kind?.toJson(),
      if (runId != null) 'runId': runId,
      if (phase != null) 'phase': phase?.toJson(),
      if (toolName != null) 'toolName': toolName,
      if (toolUseId != null) 'toolUseId': toolUseId,
      if (detail != null) 'detail': detail,
      if (isError != null) 'isError': isError,
      if (reviewId != null) 'reviewId': reviewId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TaskLogEntry',
      if (id != null) 'id': id,
      'taskId': taskId,
      if (task != null) 'task': task?.toJsonForProtocol(),
      'content': content,
      'source': source.toJson(),
      'createdAt': createdAt.toJson(),
      if (kind != null) 'kind': kind?.toJson(),
      if (runId != null) 'runId': runId,
      if (phase != null) 'phase': phase?.toJson(),
      if (toolName != null) 'toolName': toolName,
      if (toolUseId != null) 'toolUseId': toolUseId,
      if (detail != null) 'detail': detail,
      if (isError != null) 'isError': isError,
      if (reviewId != null) 'reviewId': reviewId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaskLogEntryImpl extends TaskLogEntry {
  _TaskLogEntryImpl({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    required String content,
    _ilj2nbps.LogSource? source,
    DateTime? createdAt,
    _i7oqmlti.LogKind? kind,
    String? runId,
    _iv8oofn2.LogPhase? phase,
    String? toolName,
    String? toolUseId,
    String? detail,
    bool? isError,
    int? reviewId,
  }) : super._(
         id: id,
         taskId: taskId,
         task: task,
         content: content,
         source: source,
         createdAt: createdAt,
         kind: kind,
         runId: runId,
         phase: phase,
         toolName: toolName,
         toolUseId: toolUseId,
         detail: detail,
         isError: isError,
         reviewId: reviewId,
       );

  /// Returns a shallow copy of this [TaskLogEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  TaskLogEntry copyWith({
    Object? id = _Undefined,
    int? taskId,
    Object? task = _Undefined,
    String? content,
    _ilj2nbps.LogSource? source,
    DateTime? createdAt,
    Object? kind = _Undefined,
    Object? runId = _Undefined,
    Object? phase = _Undefined,
    Object? toolName = _Undefined,
    Object? toolUseId = _Undefined,
    Object? detail = _Undefined,
    Object? isError = _Undefined,
    Object? reviewId = _Undefined,
  }) {
    return TaskLogEntry(
      id: id is int? ? id : this.id,
      taskId: taskId ?? this.taskId,
      task: task is _iwn6t6fs.Task? ? task : this.task?.copyWith(),
      content: content ?? this.content,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      kind: kind is _i7oqmlti.LogKind? ? kind : this.kind,
      runId: runId is String? ? runId : this.runId,
      phase: phase is _iv8oofn2.LogPhase? ? phase : this.phase,
      toolName: toolName is String? ? toolName : this.toolName,
      toolUseId: toolUseId is String? ? toolUseId : this.toolUseId,
      detail: detail is String? ? detail : this.detail,
      isError: isError is bool? ? isError : this.isError,
      reviewId: reviewId is int? ? reviewId : this.reviewId,
    );
  }
}
