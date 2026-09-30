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
import 'task_feedback_phase.dart' as _iitmdld3;

/// A message from the dev to the agent within the same session — the phase field distinguishes plan
/// feedback from post-PR review feedback in the history.
abstract class TaskFeedback
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  TaskFeedback._({
    this.id,
    required this.taskId,
    this.task,
    required this.message,
    required this.phase,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TaskFeedback({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    required String message,
    required _iitmdld3.TaskFeedbackPhase phase,
    DateTime? createdAt,
  }) = _TaskFeedbackImpl;

  factory TaskFeedback.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaskFeedback(
      id: jsonSerialization['id'] as int?,
      taskId: jsonSerialization['taskId'] as int,
      task: jsonSerialization['task'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<_iwn6t6fs.Task>(
              jsonSerialization['task'],
            ),
      message: jsonSerialization['message'] as String,
      phase: _iitmdld3.TaskFeedbackPhase.fromJson(
        (jsonSerialization['phase'] as String),
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

  /// onDelete=Cascade: feedback has no meaning independent of its task.
  _iwn6t6fs.Task? task;

  String message;

  _iitmdld3.TaskFeedbackPhase phase;

  DateTime createdAt;

  /// Returns a shallow copy of this [TaskFeedback]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  TaskFeedback copyWith({
    int? id,
    int? taskId,
    _iwn6t6fs.Task? task,
    String? message,
    _iitmdld3.TaskFeedbackPhase? phase,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TaskFeedback',
      if (id != null) 'id': id,
      'taskId': taskId,
      if (task != null) 'task': task?.toJson(),
      'message': message,
      'phase': phase.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TaskFeedback',
      if (id != null) 'id': id,
      'taskId': taskId,
      if (task != null) 'task': task?.toJsonForProtocol(),
      'message': message,
      'phase': phase.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaskFeedbackImpl extends TaskFeedback {
  _TaskFeedbackImpl({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    required String message,
    required _iitmdld3.TaskFeedbackPhase phase,
    DateTime? createdAt,
  }) : super._(
         id: id,
         taskId: taskId,
         task: task,
         message: message,
         phase: phase,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TaskFeedback]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  TaskFeedback copyWith({
    Object? id = _Undefined,
    int? taskId,
    Object? task = _Undefined,
    String? message,
    _iitmdld3.TaskFeedbackPhase? phase,
    DateTime? createdAt,
  }) {
    return TaskFeedback(
      id: id is int? ? id : this.id,
      taskId: taskId ?? this.taskId,
      task: task is _iwn6t6fs.Task? ? task : this.task?.copyWith(),
      message: message ?? this.message,
      phase: phase ?? this.phase,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
