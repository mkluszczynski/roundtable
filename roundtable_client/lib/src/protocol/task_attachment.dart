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

/// An image the dev attached to a task's prompt (e.g. a pasted screenshot).
/// The bytes live in the private cloud storage under [storagePath]; the
/// runner downloads them and points Claude Code at the files.
abstract class TaskAttachment
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  TaskAttachment._({
    this.id,
    this.taskId,
    this.task,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TaskAttachment({
    int? id,
    int? taskId,
    _iwn6t6fs.Task? task,
    required String storagePath,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    DateTime? createdAt,
  }) = _TaskAttachmentImpl;

  factory TaskAttachment.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaskAttachment(
      id: jsonSerialization['id'] as int?,
      taskId: jsonSerialization['taskId'] as int?,
      task: jsonSerialization['task'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<_iwn6t6fs.Task>(
              jsonSerialization['task'],
            ),
      storagePath: jsonSerialization['storagePath'] as String,
      fileName: jsonSerialization['fileName'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int? taskId;

  /// Null between upload and the task's creation — attachments are
  /// uploaded while the dev is still writing the prompt.
  /// onDelete=Cascade: an attachment means nothing without its task.
  _iwn6t6fs.Task? task;

  String storagePath;

  String fileName;

  String mimeType;

  int sizeBytes;

  DateTime createdAt;

  /// Returns a shallow copy of this [TaskAttachment]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  TaskAttachment copyWith({
    int? id,
    int? taskId,
    _iwn6t6fs.Task? task,
    String? storagePath,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TaskAttachment',
      if (id != null) 'id': id,
      if (taskId != null) 'taskId': taskId,
      if (task != null) 'task': task?.toJson(),
      'storagePath': storagePath,
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TaskAttachment',
      if (id != null) 'id': id,
      if (taskId != null) 'taskId': taskId,
      if (task != null) 'task': task?.toJsonForProtocol(),
      'storagePath': storagePath,
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaskAttachmentImpl extends TaskAttachment {
  _TaskAttachmentImpl({
    int? id,
    int? taskId,
    _iwn6t6fs.Task? task,
    required String storagePath,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    DateTime? createdAt,
  }) : super._(
         id: id,
         taskId: taskId,
         task: task,
         storagePath: storagePath,
         fileName: fileName,
         mimeType: mimeType,
         sizeBytes: sizeBytes,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TaskAttachment]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  TaskAttachment copyWith({
    Object? id = _Undefined,
    Object? taskId = _Undefined,
    Object? task = _Undefined,
    String? storagePath,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    DateTime? createdAt,
  }) {
    return TaskAttachment(
      id: id is int? ? id : this.id,
      taskId: taskId is int? ? taskId : this.taskId,
      task: task is _iwn6t6fs.Task? ? task : this.task?.copyWith(),
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
