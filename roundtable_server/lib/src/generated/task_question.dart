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

/// A clarifying question raised by the agent during plan mode (AskUserQuestion), awaiting an answer
/// from the dev.
abstract class TaskQuestion
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
          : _iikm6kmi.Protocol().deserialize<_iwn6t6fs.Task>(
              jsonSerialization['task'],
            ),
      question: jsonSerialization['question'] as String,
      options: _iikm6kmi.Protocol().deserialize<List<String>>(
        jsonSerialization['options'],
      ),
      answer: jsonSerialization['answer'] as String?,
      answeredAt: jsonSerialization['answeredAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['answeredAt']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = TaskQuestionTable();

  static const db = TaskQuestionRepository._();

  @override
  int? id;

  int taskId;

  /// onDelete=Cascade: questions have no meaning independent of their task.
  _iwn6t6fs.Task? task;

  String question;

  List<String> options;

  String? answer;

  DateTime? answeredAt;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaskQuestion]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static TaskQuestionInclude include({_iwn6t6fs.TaskInclude? task}) {
    return TaskQuestionInclude._(task: task);
  }

  static TaskQuestionIncludeList includeList({
    _is.WhereExpressionBuilder<TaskQuestionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskQuestionTable>? orderBy,
    _is.OrderByListBuilder<TaskQuestionTable>? orderByList,
    TaskQuestionInclude? include,
  }) {
    return TaskQuestionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaskQuestion.t),
      orderByList: orderByList?.call(TaskQuestion.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class TaskQuestionUpdateTable extends _is.UpdateTable<TaskQuestionTable> {
  TaskQuestionUpdateTable(super.table);

  _is.ColumnValue<int, int> taskId(int value) => _is.ColumnValue(
    table.taskId,
    value,
  );

  _is.ColumnValue<String, String> question(String value) => _is.ColumnValue(
    table.question,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> options(List<String> value) =>
      _is.ColumnValue(
        table.options,
        value,
      );

  _is.ColumnValue<String, String> answer(String? value) => _is.ColumnValue(
    table.answer,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> answeredAt(DateTime? value) =>
      _is.ColumnValue(
        table.answeredAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class TaskQuestionTable extends _is.Table<int?> {
  TaskQuestionTable({super.tableRelation}) : super(tableName: 'task_question') {
    updateTable = TaskQuestionUpdateTable(this);
    taskId = _is.ColumnInt(
      'taskId',
      this,
    );
    question = _is.ColumnString(
      'question',
      this,
    );
    options = _is.ColumnSerializable<List<String>>(
      'options',
      this,
    );
    answer = _is.ColumnString(
      'answer',
      this,
    );
    answeredAt = _is.ColumnDateTime(
      'answeredAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final TaskQuestionUpdateTable updateTable;

  late final _is.ColumnInt taskId;

  /// onDelete=Cascade: questions have no meaning independent of their task.
  _iwn6t6fs.TaskTable? _task;

  late final _is.ColumnString question;

  late final _is.ColumnSerializable<List<String>> options;

  late final _is.ColumnString answer;

  late final _is.ColumnDateTime answeredAt;

  late final _is.ColumnDateTime createdAt;

  _iwn6t6fs.TaskTable get task {
    if (_task != null) return _task!;
    _task = _is.createRelationTable(
      relationFieldName: 'task',
      field: TaskQuestion.t.taskId,
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
    question,
    options,
    answer,
    answeredAt,
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

class TaskQuestionInclude extends _is.IncludeObject {
  TaskQuestionInclude._({_iwn6t6fs.TaskInclude? task}) {
    _task = task;
  }

  _iwn6t6fs.TaskInclude? _task;

  @override
  Map<String, _is.Include?> get includes => {'task': _task};

  @override
  _is.Table<int?> get table => TaskQuestion.t;
}

class TaskQuestionIncludeList extends _is.IncludeList {
  TaskQuestionIncludeList._({
    _is.WhereExpressionBuilder<TaskQuestionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaskQuestion.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaskQuestion.t;
}

class TaskQuestionRepository {
  const TaskQuestionRepository._();

  final attachRow = const TaskQuestionAttachRowRepository._();

  /// Returns a list of [TaskQuestion]s matching the given query parameters.
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
  Future<List<TaskQuestion>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskQuestionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskQuestionTable>? orderBy,
    _is.OrderByListBuilder<TaskQuestionTable>? orderByList,
    _is.Transaction? transaction,
    TaskQuestionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaskQuestion>(
      where: where?.call(TaskQuestion.t),
      orderBy: orderBy?.call(TaskQuestion.t),
      orderByList: orderByList?.call(TaskQuestion.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaskQuestion] matching the given query parameters.
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
  Future<TaskQuestion?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskQuestionTable>? where,
    int? offset,
    _is.OrderByBuilder<TaskQuestionTable>? orderBy,
    _is.OrderByListBuilder<TaskQuestionTable>? orderByList,
    _is.Transaction? transaction,
    TaskQuestionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaskQuestion>(
      where: where?.call(TaskQuestion.t),
      orderBy: orderBy?.call(TaskQuestion.t),
      orderByList: orderByList?.call(TaskQuestion.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaskQuestion] by its [id] or null if no such row exists.
  Future<TaskQuestion?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    TaskQuestionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaskQuestion>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaskQuestion]s in the list and returns the inserted rows.
  ///
  /// The returned [TaskQuestion]s will have their `id` fields set.
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
  Future<List<TaskQuestion>> insert(
    _is.DatabaseSession session,
    List<TaskQuestion> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaskQuestion>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaskQuestion] and returns the inserted row.
  ///
  /// The returned [TaskQuestion] will have its `id` field set.
  Future<TaskQuestion> insertRow(
    _is.DatabaseSession session,
    TaskQuestion row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaskQuestion>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TaskQuestion]s in the list and returns the resulting rows.
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
  /// The returned [TaskQuestion]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskQuestion>> upsert(
    _is.DatabaseSession session,
    List<TaskQuestion> rows, {
    required _is.ColumnSelections<TaskQuestionTable> conflictColumns,
    _is.ColumnSelections<TaskQuestionTable>? updateColumns,
    _is.WhereExpressionBuilder<TaskQuestionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaskQuestion>(
      rows,
      conflictColumns: conflictColumns(TaskQuestion.t),
      updateColumns: updateColumns?.call(TaskQuestion.t),
      updateWhere: updateWhere?.call(TaskQuestion.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaskQuestion] and returns the resulting row.
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
  /// The returned [TaskQuestion] will have its `id` field set.
  Future<TaskQuestion?> upsertRow(
    _is.DatabaseSession session,
    TaskQuestion row, {
    required _is.ColumnSelections<TaskQuestionTable> conflictColumns,
    _is.ColumnSelections<TaskQuestionTable>? updateColumns,
    _is.WhereExpressionBuilder<TaskQuestionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaskQuestion>(
      row,
      conflictColumns: conflictColumns(TaskQuestion.t),
      updateColumns: updateColumns?.call(TaskQuestion.t),
      updateWhere: updateWhere?.call(TaskQuestion.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaskQuestion]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskQuestion>> update(
    _is.DatabaseSession session,
    List<TaskQuestion> rows, {
    _is.ColumnSelections<TaskQuestionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaskQuestion>(
      rows,
      columns: columns?.call(TaskQuestion.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaskQuestion]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaskQuestion> updateRow(
    _is.DatabaseSession session,
    TaskQuestion row, {
    _is.ColumnSelections<TaskQuestionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaskQuestion>(
      row,
      columns: columns?.call(TaskQuestion.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaskQuestion] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaskQuestion?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaskQuestionUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaskQuestion>(
      id,
      columnValues: columnValues(TaskQuestion.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaskQuestion]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskQuestion>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaskQuestionUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TaskQuestionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskQuestionTable>? orderBy,
    _is.OrderByListBuilder<TaskQuestionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaskQuestion>(
      columnValues: columnValues(TaskQuestion.t.updateTable),
      where: where(TaskQuestion.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaskQuestion.t),
      orderByList: orderByList?.call(TaskQuestion.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaskQuestion]s in the list and returns the deleted rows.
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
  Future<List<TaskQuestion>> delete(
    _is.DatabaseSession session,
    List<TaskQuestion> rows, {
    _is.OrderByBuilder<TaskQuestionTable>? orderBy,
    _is.OrderByListBuilder<TaskQuestionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaskQuestion>(
      rows,
      orderBy: orderBy?.call(TaskQuestion.t),
      orderByList: orderByList?.call(TaskQuestion.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaskQuestion].
  Future<TaskQuestion> deleteRow(
    _is.DatabaseSession session,
    TaskQuestion row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaskQuestion>(
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
  Future<List<TaskQuestion>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaskQuestionTable> where,
    _is.OrderByBuilder<TaskQuestionTable>? orderBy,
    _is.OrderByListBuilder<TaskQuestionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaskQuestion>(
      where: where(TaskQuestion.t),
      orderBy: orderBy?.call(TaskQuestion.t),
      orderByList: orderByList?.call(TaskQuestion.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskQuestionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaskQuestion>(
      where: where?.call(TaskQuestion.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaskQuestion] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaskQuestionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaskQuestion>(
      where: where(TaskQuestion.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class TaskQuestionAttachRowRepository {
  const TaskQuestionAttachRowRepository._();

  /// Creates a relation between the given [TaskQuestion] and [Task]
  /// by setting the [TaskQuestion]'s foreign key `taskId` to refer to the [Task].
  Future<void> task(
    _is.DatabaseSession session,
    TaskQuestion taskQuestion,
    _iwn6t6fs.Task task, {
    _is.Transaction? transaction,
  }) async {
    if (taskQuestion.id == null) {
      throw ArgumentError.notNull('taskQuestion.id');
    }
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $taskQuestion = taskQuestion.copyWith(taskId: task.id);
    await session.db.updateRow<TaskQuestion>(
      $taskQuestion,
      columns: [TaskQuestion.t.taskId],
      transaction: transaction,
    );
  }
}
