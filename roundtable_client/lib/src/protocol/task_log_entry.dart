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
  }) : source = source ?? _ilj2nbps.LogSource.agent,
       createdAt = createdAt ?? DateTime.now();

  factory TaskLogEntry({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    required String content,
    _ilj2nbps.LogSource? source,
    DateTime? createdAt,
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
  }) : super._(
         id: id,
         taskId: taskId,
         task: task,
         content: content,
         source: source,
         createdAt: createdAt,
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
  }) {
    return TaskLogEntry(
      id: id is int? ? id : this.id,
      taskId: taskId ?? this.taskId,
      task: task is _iwn6t6fs.Task? ? task : this.task?.copyWith(),
      content: content ?? this.content,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
