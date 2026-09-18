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
import 'task_feedback_phase.dart' as _iitmdld3;

/// A message from the dev to the agent within the same session — the phase field distinguishes plan
/// feedback from post-PR review feedback in the history.
abstract class TaskFeedback
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
          : _iikm6kmi.Protocol().deserialize<_iwn6t6fs.Task>(
              jsonSerialization['task'],
            ),
      message: jsonSerialization['message'] as String,
      phase: _iitmdld3.TaskFeedbackPhase.fromJson(
        (jsonSerialization['phase'] as String),
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = TaskFeedbackTable();

  static const db = TaskFeedbackRepository._();

  @override
  int? id;

  int taskId;

  _iwn6t6fs.Task? task;

  String message;

  _iitmdld3.TaskFeedbackPhase phase;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaskFeedback]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static TaskFeedbackInclude include({_iwn6t6fs.TaskInclude? task}) {
    return TaskFeedbackInclude._(task: task);
  }

  static TaskFeedbackIncludeList includeList({
    _is.WhereExpressionBuilder<TaskFeedbackTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskFeedbackTable>? orderBy,
    _is.OrderByListBuilder<TaskFeedbackTable>? orderByList,
    TaskFeedbackInclude? include,
  }) {
    return TaskFeedbackIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaskFeedback.t),
      orderByList: orderByList?.call(TaskFeedback.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class TaskFeedbackUpdateTable extends _is.UpdateTable<TaskFeedbackTable> {
  TaskFeedbackUpdateTable(super.table);

  _is.ColumnValue<int, int> taskId(int value) => _is.ColumnValue(
    table.taskId,
    value,
  );

  _is.ColumnValue<String, String> message(String value) => _is.ColumnValue(
    table.message,
    value,
  );

  _is.ColumnValue<_iitmdld3.TaskFeedbackPhase, _iitmdld3.TaskFeedbackPhase>
  phase(_iitmdld3.TaskFeedbackPhase value) => _is.ColumnValue(
    table.phase,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class TaskFeedbackTable extends _is.Table<int?> {
  TaskFeedbackTable({super.tableRelation}) : super(tableName: 'task_feedback') {
    updateTable = TaskFeedbackUpdateTable(this);
    taskId = _is.ColumnInt(
      'taskId',
      this,
    );
    message = _is.ColumnString(
      'message',
      this,
    );
    phase = _is.ColumnEnum(
      'phase',
      this,
      _is.EnumSerialization.byName,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final TaskFeedbackUpdateTable updateTable;

  late final _is.ColumnInt taskId;

  _iwn6t6fs.TaskTable? _task;

  late final _is.ColumnString message;

  late final _is.ColumnEnum<_iitmdld3.TaskFeedbackPhase> phase;

  late final _is.ColumnDateTime createdAt;

  _iwn6t6fs.TaskTable get task {
    if (_task != null) return _task!;
    _task = _is.createRelationTable(
      relationFieldName: 'task',
      field: TaskFeedback.t.taskId,
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
    message,
    phase,
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

class TaskFeedbackInclude extends _is.IncludeObject {
  TaskFeedbackInclude._({_iwn6t6fs.TaskInclude? task}) {
    _task = task;
  }

  _iwn6t6fs.TaskInclude? _task;

  @override
  Map<String, _is.Include?> get includes => {'task': _task};

  @override
  _is.Table<int?> get table => TaskFeedback.t;
}

class TaskFeedbackIncludeList extends _is.IncludeList {
  TaskFeedbackIncludeList._({
    _is.WhereExpressionBuilder<TaskFeedbackTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaskFeedback.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaskFeedback.t;
}

class TaskFeedbackRepository {
  const TaskFeedbackRepository._();

  final attachRow = const TaskFeedbackAttachRowRepository._();

  /// Returns a list of [TaskFeedback]s matching the given query parameters.
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
  Future<List<TaskFeedback>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskFeedbackTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskFeedbackTable>? orderBy,
    _is.OrderByListBuilder<TaskFeedbackTable>? orderByList,
    _is.Transaction? transaction,
    TaskFeedbackInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaskFeedback>(
      where: where?.call(TaskFeedback.t),
      orderBy: orderBy?.call(TaskFeedback.t),
      orderByList: orderByList?.call(TaskFeedback.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaskFeedback] matching the given query parameters.
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
  Future<TaskFeedback?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskFeedbackTable>? where,
    int? offset,
    _is.OrderByBuilder<TaskFeedbackTable>? orderBy,
    _is.OrderByListBuilder<TaskFeedbackTable>? orderByList,
    _is.Transaction? transaction,
    TaskFeedbackInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaskFeedback>(
      where: where?.call(TaskFeedback.t),
      orderBy: orderBy?.call(TaskFeedback.t),
      orderByList: orderByList?.call(TaskFeedback.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaskFeedback] by its [id] or null if no such row exists.
  Future<TaskFeedback?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    TaskFeedbackInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaskFeedback>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaskFeedback]s in the list and returns the inserted rows.
  ///
  /// The returned [TaskFeedback]s will have their `id` fields set.
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
  Future<List<TaskFeedback>> insert(
    _is.DatabaseSession session,
    List<TaskFeedback> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaskFeedback>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaskFeedback] and returns the inserted row.
  ///
  /// The returned [TaskFeedback] will have its `id` field set.
  Future<TaskFeedback> insertRow(
    _is.DatabaseSession session,
    TaskFeedback row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaskFeedback>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TaskFeedback]s in the list and returns the resulting rows.
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
  /// The returned [TaskFeedback]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskFeedback>> upsert(
    _is.DatabaseSession session,
    List<TaskFeedback> rows, {
    required _is.ColumnSelections<TaskFeedbackTable> conflictColumns,
    _is.ColumnSelections<TaskFeedbackTable>? updateColumns,
    _is.WhereExpressionBuilder<TaskFeedbackTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaskFeedback>(
      rows,
      conflictColumns: conflictColumns(TaskFeedback.t),
      updateColumns: updateColumns?.call(TaskFeedback.t),
      updateWhere: updateWhere?.call(TaskFeedback.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaskFeedback] and returns the resulting row.
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
  /// The returned [TaskFeedback] will have its `id` field set.
  Future<TaskFeedback?> upsertRow(
    _is.DatabaseSession session,
    TaskFeedback row, {
    required _is.ColumnSelections<TaskFeedbackTable> conflictColumns,
    _is.ColumnSelections<TaskFeedbackTable>? updateColumns,
    _is.WhereExpressionBuilder<TaskFeedbackTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaskFeedback>(
      row,
      conflictColumns: conflictColumns(TaskFeedback.t),
      updateColumns: updateColumns?.call(TaskFeedback.t),
      updateWhere: updateWhere?.call(TaskFeedback.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaskFeedback]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskFeedback>> update(
    _is.DatabaseSession session,
    List<TaskFeedback> rows, {
    _is.ColumnSelections<TaskFeedbackTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaskFeedback>(
      rows,
      columns: columns?.call(TaskFeedback.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaskFeedback]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaskFeedback> updateRow(
    _is.DatabaseSession session,
    TaskFeedback row, {
    _is.ColumnSelections<TaskFeedbackTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaskFeedback>(
      row,
      columns: columns?.call(TaskFeedback.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaskFeedback] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaskFeedback?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaskFeedbackUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaskFeedback>(
      id,
      columnValues: columnValues(TaskFeedback.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaskFeedback]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskFeedback>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaskFeedbackUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TaskFeedbackTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskFeedbackTable>? orderBy,
    _is.OrderByListBuilder<TaskFeedbackTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaskFeedback>(
      columnValues: columnValues(TaskFeedback.t.updateTable),
      where: where(TaskFeedback.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaskFeedback.t),
      orderByList: orderByList?.call(TaskFeedback.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaskFeedback]s in the list and returns the deleted rows.
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
  Future<List<TaskFeedback>> delete(
    _is.DatabaseSession session,
    List<TaskFeedback> rows, {
    _is.OrderByBuilder<TaskFeedbackTable>? orderBy,
    _is.OrderByListBuilder<TaskFeedbackTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaskFeedback>(
      rows,
      orderBy: orderBy?.call(TaskFeedback.t),
      orderByList: orderByList?.call(TaskFeedback.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaskFeedback].
  Future<TaskFeedback> deleteRow(
    _is.DatabaseSession session,
    TaskFeedback row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaskFeedback>(
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
  Future<List<TaskFeedback>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaskFeedbackTable> where,
    _is.OrderByBuilder<TaskFeedbackTable>? orderBy,
    _is.OrderByListBuilder<TaskFeedbackTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaskFeedback>(
      where: where(TaskFeedback.t),
      orderBy: orderBy?.call(TaskFeedback.t),
      orderByList: orderByList?.call(TaskFeedback.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskFeedbackTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaskFeedback>(
      where: where?.call(TaskFeedback.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaskFeedback] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaskFeedbackTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaskFeedback>(
      where: where(TaskFeedback.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class TaskFeedbackAttachRowRepository {
  const TaskFeedbackAttachRowRepository._();

  /// Creates a relation between the given [TaskFeedback] and [Task]
  /// by setting the [TaskFeedback]'s foreign key `taskId` to refer to the [Task].
  Future<void> task(
    _is.DatabaseSession session,
    TaskFeedback taskFeedback,
    _iwn6t6fs.Task task, {
    _is.Transaction? transaction,
  }) async {
    if (taskFeedback.id == null) {
      throw ArgumentError.notNull('taskFeedback.id');
    }
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $taskFeedback = taskFeedback.copyWith(taskId: task.id);
    await session.db.updateRow<TaskFeedback>(
      $taskFeedback,
      columns: [TaskFeedback.t.taskId],
      transaction: transaction,
    );
  }
}
