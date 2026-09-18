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

/// A clarifying question raised by the agent during plan mode (AskUserQuestion), awaiting an answer
/// from the dev.
abstract class TaskQuestion
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  TaskQuestion._({
    this.id,
    required this.taskId,
    this.task,
    required this.question,
    required this.options,
    this.answer,
    this.answeredAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TaskQuestion({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    required String question,
    required List<String> options,
    String? answer,
    DateTime? answeredAt,
    DateTime? createdAt,
  }) = _TaskQuestionImpl;

  factory TaskQuestion.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaskQuestion(
      id: jsonSerialization['id'] as int?,
      taskId: jsonSerialization['taskId'] as int,
      task: jsonSerialization['task'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<_iwn6t6fs.Task>(
              jsonSerialization['task'],
            ),
      question: jsonSerialization['question'] as String,
      options: _i35hmugi.Protocol().deserialize<List<String>>(
        jsonSerialization['options'],
      ),
      answer: jsonSerialization['answer'] as String?,
      answeredAt: jsonSerialization['answeredAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['answeredAt'],
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

  _iwn6t6fs.Task? task;

  String question;

  List<String> options;

  String? answer;

  DateTime? answeredAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [TaskQuestion]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  TaskQuestion copyWith({
    int? id,
    int? taskId,
    _iwn6t6fs.Task? task,
    String? question,
    List<String>? options,
    String? answer,
    DateTime? answeredAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TaskQuestion',
      if (id != null) 'id': id,
      'taskId': taskId,
      if (task != null) 'task': task?.toJson(),
      'question': question,
      'options': options.toJson(),
      if (answer != null) 'answer': answer,
      if (answeredAt != null) 'answeredAt': answeredAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TaskQuestion',
      if (id != null) 'id': id,
      'taskId': taskId,
      if (task != null) 'task': task?.toJsonForProtocol(),
      'question': question,
      'options': options.toJson(),
      if (answer != null) 'answer': answer,
      if (answeredAt != null) 'answeredAt': answeredAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaskQuestionImpl extends TaskQuestion {
  _TaskQuestionImpl({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    required String question,
    required List<String> options,
    String? answer,
    DateTime? answeredAt,
    DateTime? createdAt,
  }) : super._(
         id: id,
         taskId: taskId,
         task: task,
         question: question,
         options: options,
         answer: answer,
         answeredAt: answeredAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TaskQuestion]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  TaskQuestion copyWith({
    Object? id = _Undefined,
    int? taskId,
    Object? task = _Undefined,
    String? question,
    List<String>? options,
    Object? answer = _Undefined,
    Object? answeredAt = _Undefined,
    DateTime? createdAt,
  }) {
    return TaskQuestion(
      id: id is int? ? id : this.id,
      taskId: taskId ?? this.taskId,
      task: task is _iwn6t6fs.Task? ? task : this.task?.copyWith(),
      question: question ?? this.question,
      options: options ?? this.options.map((e0) => e0).toList(),
      answer: answer is String? ? answer : this.answer,
      answeredAt: answeredAt is DateTime? ? answeredAt : this.answeredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
