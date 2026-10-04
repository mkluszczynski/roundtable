/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:roundtable_server/src/generated/protocol.dart' as _iikm6kmi;
import 'package:serverpod/serverpod.dart' as _is;
import 'task.dart' as _iwn6t6fs;

/// An image the dev attached to a task's prompt (e.g. a pasted screenshot).
/// The bytes live in the private cloud storage under [storagePath]; the
/// runner downloads them and points Claude Code at the files.
abstract class TaskAttachment
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
          : _iikm6kmi.Protocol().deserialize<_iwn6t6fs.Task>(
              jsonSerialization['task'],
            ),
      storagePath: jsonSerialization['storagePath'] as String,
      fileName: jsonSerialization['fileName'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = TaskAttachmentTable();

  static const db = TaskAttachmentRepository._();

  @override
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

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaskAttachment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static TaskAttachmentInclude include({_iwn6t6fs.TaskInclude? task}) {
    return TaskAttachmentInclude._(task: task);
  }

  static TaskAttachmentIncludeList includeList({
    _is.WhereExpressionBuilder<TaskAttachmentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskAttachmentTable>? orderBy,
    _is.OrderByListBuilder<TaskAttachmentTable>? orderByList,
    TaskAttachmentInclude? include,
  }) {
    return TaskAttachmentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaskAttachment.t),
      orderByList: orderByList?.call(TaskAttachment.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class TaskAttachmentUpdateTable extends _is.UpdateTable<TaskAttachmentTable> {
  TaskAttachmentUpdateTable(super.table);

  _is.ColumnValue<int, int> taskId(int? value) => _is.ColumnValue(
    table.taskId,
    value,
  );

  _is.ColumnValue<String, String> storagePath(String value) => _is.ColumnValue(
    table.storagePath,
    value,
  );

  _is.ColumnValue<String, String> fileName(String value) => _is.ColumnValue(
    table.fileName,
    value,
  );

  _is.ColumnValue<String, String> mimeType(String value) => _is.ColumnValue(
    table.mimeType,
    value,
  );

  _is.ColumnValue<int, int> sizeBytes(int value) => _is.ColumnValue(
    table.sizeBytes,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class TaskAttachmentTable extends _is.Table<int?> {
  TaskAttachmentTable({super.tableRelation})
    : super(tableName: 'task_attachment') {
    updateTable = TaskAttachmentUpdateTable(this);
    taskId = _is.ColumnInt(
      'taskId',
      this,
    );
    storagePath = _is.ColumnString(
      'storagePath',
      this,
    );
    fileName = _is.ColumnString(
      'fileName',
      this,
    );
    mimeType = _is.ColumnString(
      'mimeType',
      this,
    );
    sizeBytes = _is.ColumnInt(
      'sizeBytes',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final TaskAttachmentUpdateTable updateTable;

  late final _is.ColumnInt taskId;

  /// Null between upload and the task's creation — attachments are
  /// uploaded while the dev is still writing the prompt.
  /// onDelete=Cascade: an attachment means nothing without its task.
  _iwn6t6fs.TaskTable? _task;

  late final _is.ColumnString storagePath;

  late final _is.ColumnString fileName;

  late final _is.ColumnString mimeType;

  late final _is.ColumnInt sizeBytes;

  late final _is.ColumnDateTime createdAt;

  _iwn6t6fs.TaskTable get task {
    if (_task != null) return _task!;
    _task = _is.createRelationTable(
      relationFieldName: 'task',
      field: TaskAttachment.t.taskId,
      foreignField: _iwn6t6fs.Task.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iwn6t6fs.TaskTable(tableRelation: foreignTableRelation),
    );
    return _task!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    taskId,
    storagePath,
    fileName,
    mimeType,
    sizeBytes,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'task') {
      return task;
    }
    return null;
  }
}

class TaskAttachmentInclude extends _is.IncludeObject {
  TaskAttachmentInclude._({_iwn6t6fs.TaskInclude? task}) {
    _task = task;
  }

  _iwn6t6fs.TaskInclude? _task;

  @override
  Map<String, _is.Include?> get includes => {'task': _task};

  @override
  _is.Table<int?> get table => TaskAttachment.t;
}

class TaskAttachmentIncludeList extends _is.IncludeList {
  TaskAttachmentIncludeList._({
    _is.WhereExpressionBuilder<TaskAttachmentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaskAttachment.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaskAttachment.t;
}

class TaskAttachmentRepository {
  const TaskAttachmentRepository._();

  final attachRow = const TaskAttachmentAttachRowRepository._();

  final detachRow = const TaskAttachmentDetachRowRepository._();

  /// Returns a list of [TaskAttachment]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<TaskAttachment>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskAttachmentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskAttachmentTable>? orderBy,
    _is.OrderByListBuilder<TaskAttachmentTable>? orderByList,
    _is.Transaction? transaction,
    TaskAttachmentInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaskAttachment>(
      where: where?.call(TaskAttachment.t),
      orderBy: orderBy?.call(TaskAttachment.t),
      orderByList: orderByList?.call(TaskAttachment.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaskAttachment] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<TaskAttachment?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskAttachmentTable>? where,
    int? offset,
    _is.OrderByBuilder<TaskAttachmentTable>? orderBy,
    _is.OrderByListBuilder<TaskAttachmentTable>? orderByList,
    _is.Transaction? transaction,
    TaskAttachmentInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaskAttachment>(
      where: where?.call(TaskAttachment.t),
      orderBy: orderBy?.call(TaskAttachment.t),
      orderByList: orderByList?.call(TaskAttachment.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaskAttachment] by its [id] or null if no such row exists.
  Future<TaskAttachment?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    TaskAttachmentInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaskAttachment>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaskAttachment]s in the list and returns the inserted rows.
  ///
  /// The returned [TaskAttachment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskAttachment>> insert(
    _is.DatabaseSession session,
    List<TaskAttachment> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaskAttachment>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaskAttachment] and returns the inserted row.
  ///
  /// The returned [TaskAttachment] will have its `id` field set.
  Future<TaskAttachment> insertRow(
    _is.DatabaseSession session,
    TaskAttachment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaskAttachment>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TaskAttachment]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [TaskAttachment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskAttachment>> upsert(
    _is.DatabaseSession session,
    List<TaskAttachment> rows, {
    required _is.ColumnSelections<TaskAttachmentTable> conflictColumns,
    _is.ColumnSelections<TaskAttachmentTable>? updateColumns,
    _is.WhereExpressionBuilder<TaskAttachmentTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaskAttachment>(
      rows,
      conflictColumns: conflictColumns(TaskAttachment.t),
      updateColumns: updateColumns?.call(TaskAttachment.t),
      updateWhere: updateWhere?.call(TaskAttachment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaskAttachment] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [TaskAttachment] will have its `id` field set.
  Future<TaskAttachment?> upsertRow(
    _is.DatabaseSession session,
    TaskAttachment row, {
    required _is.ColumnSelections<TaskAttachmentTable> conflictColumns,
    _is.ColumnSelections<TaskAttachmentTable>? updateColumns,
    _is.WhereExpressionBuilder<TaskAttachmentTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaskAttachment>(
      row,
      conflictColumns: conflictColumns(TaskAttachment.t),
      updateColumns: updateColumns?.call(TaskAttachment.t),
      updateWhere: updateWhere?.call(TaskAttachment.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaskAttachment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskAttachment>> update(
    _is.DatabaseSession session,
    List<TaskAttachment> rows, {
    _is.ColumnSelections<TaskAttachmentTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaskAttachment>(
      rows,
      columns: columns?.call(TaskAttachment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaskAttachment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaskAttachment> updateRow(
    _is.DatabaseSession session,
    TaskAttachment row, {
    _is.ColumnSelections<TaskAttachmentTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaskAttachment>(
      row,
      columns: columns?.call(TaskAttachment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaskAttachment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaskAttachment?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaskAttachmentUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaskAttachment>(
      id,
      columnValues: columnValues(TaskAttachment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaskAttachment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskAttachment>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaskAttachmentUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TaskAttachmentTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskAttachmentTable>? orderBy,
    _is.OrderByListBuilder<TaskAttachmentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaskAttachment>(
      columnValues: columnValues(TaskAttachment.t.updateTable),
      where: where(TaskAttachment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaskAttachment.t),
      orderByList: orderByList?.call(TaskAttachment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaskAttachment]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskAttachment>> delete(
    _is.DatabaseSession session,
    List<TaskAttachment> rows, {
    _is.OrderByBuilder<TaskAttachmentTable>? orderBy,
    _is.OrderByListBuilder<TaskAttachmentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaskAttachment>(
      rows,
      orderBy: orderBy?.call(TaskAttachment.t),
      orderByList: orderByList?.call(TaskAttachment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaskAttachment].
  Future<TaskAttachment> deleteRow(
    _is.DatabaseSession session,
    TaskAttachment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaskAttachment>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskAttachment>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaskAttachmentTable> where,
    _is.OrderByBuilder<TaskAttachmentTable>? orderBy,
    _is.OrderByListBuilder<TaskAttachmentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaskAttachment>(
      where: where(TaskAttachment.t),
      orderBy: orderBy?.call(TaskAttachment.t),
      orderByList: orderByList?.call(TaskAttachment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskAttachmentTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaskAttachment>(
      where: where?.call(TaskAttachment.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaskAttachment] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaskAttachmentTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaskAttachment>(
      where: where(TaskAttachment.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class TaskAttachmentAttachRowRepository {
  const TaskAttachmentAttachRowRepository._();

  /// Creates a relation between the given [TaskAttachment] and [Task]
  /// by setting the [TaskAttachment]'s foreign key `taskId` to refer to the [Task].
  Future<void> task(
    _is.DatabaseSession session,
    TaskAttachment taskAttachment,
    _iwn6t6fs.Task task, {
    _is.Transaction? transaction,
  }) async {
    if (taskAttachment.id == null) {
      throw ArgumentError.notNull('taskAttachment.id');
    }
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $taskAttachment = taskAttachment.copyWith(taskId: task.id);
    await session.db.updateRow<TaskAttachment>(
      $taskAttachment,
      columns: [TaskAttachment.t.taskId],
      transaction: transaction,
    );
  }
}

class TaskAttachmentDetachRowRepository {
  const TaskAttachmentDetachRowRepository._();

  /// Detaches the relation between this [TaskAttachment] and the [Task] set in `task`
  /// by setting the [TaskAttachment]'s foreign key `taskId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> task(
    _is.DatabaseSession session,
    TaskAttachment taskAttachment, {
    _is.Transaction? transaction,
  }) async {
    if (taskAttachment.id == null) {
      throw ArgumentError.notNull('taskAttachment.id');
    }

    var $taskAttachment = taskAttachment.copyWith(taskId: null);
    await session.db.updateRow<TaskAttachment>(
      $taskAttachment,
      columns: [TaskAttachment.t.taskId],
      transaction: transaction,
    );
  }
}
