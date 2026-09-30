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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// Broadcast on `all-tasks` when a task is deleted (design doc §6.1) — deleting
/// the row leaves no `Task` to post as an update, so subscribers (the
/// dashboard kanban) drop it from their local task list by id instead.
abstract class TaskDeleted
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  TaskDeleted._({required this.taskId});

  factory TaskDeleted({required int taskId}) = _TaskDeletedImpl;

  factory TaskDeleted.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaskDeleted(taskId: jsonSerialization['taskId'] as int);
  }

  int taskId;

  /// Returns a shallow copy of this [TaskDeleted]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  TaskDeleted copyWith({int? taskId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TaskDeleted',
      'taskId': taskId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TaskDeleted',
      'taskId': taskId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _TaskDeletedImpl extends TaskDeleted {
  _TaskDeletedImpl({required int taskId}) : super._(taskId: taskId);

  /// Returns a shallow copy of this [TaskDeleted]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  TaskDeleted copyWith({int? taskId}) {
    return TaskDeleted(taskId: taskId ?? this.taskId);
  }
}
