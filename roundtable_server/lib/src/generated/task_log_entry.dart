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
import 'log_kind.dart' as _i7oqmlti;
import 'log_phase.dart' as _iv8oofn2;
import 'log_source.dart' as _ilj2nbps;
import 'task.dart' as _iwn6t6fs;

/// A single line of output from a task's execution, streamed live to the panel.
abstract class TaskLogEntry
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
          : _iikm6kmi.Protocol().deserialize<_iwn6t6fs.Task>(
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
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
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
          : _is.BoolJsonExtension.fromJson(jsonSerialization['isError']),
      reviewId: jsonSerialization['reviewId'] as int?,
    );
  }

  static final t = TaskLogEntryTable();

  static const db = TaskLogEntryRepository._();

  @override
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

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaskLogEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static TaskLogEntryInclude include({_iwn6t6fs.TaskInclude? task}) {
    return TaskLogEntryInclude._(task: task);
  }

  static TaskLogEntryIncludeList includeList({
    _is.WhereExpressionBuilder<TaskLogEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskLogEntryTable>? orderBy,
    _is.OrderByListBuilder<TaskLogEntryTable>? orderByList,
    TaskLogEntryInclude? include,
  }) {
    return TaskLogEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaskLogEntry.t),
      orderByList: orderByList?.call(TaskLogEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class TaskLogEntryUpdateTable extends _is.UpdateTable<TaskLogEntryTable> {
  TaskLogEntryUpdateTable(super.table);

  _is.ColumnValue<int, int> taskId(int value) => _is.ColumnValue(
    table.taskId,
    value,
  );

  _is.ColumnValue<String, String> content(String value) => _is.ColumnValue(
    table.content,
    value,
  );

  _is.ColumnValue<_ilj2nbps.LogSource, _ilj2nbps.LogSource> source(
    _ilj2nbps.LogSource value,
  ) => _is.ColumnValue(
    table.source,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<_i7oqmlti.LogKind, _i7oqmlti.LogKind> kind(
    _i7oqmlti.LogKind? value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> runId(String? value) => _is.ColumnValue(
    table.runId,
    value,
  );

  _is.ColumnValue<_iv8oofn2.LogPhase, _iv8oofn2.LogPhase> phase(
    _iv8oofn2.LogPhase? value,
  ) => _is.ColumnValue(
    table.phase,
    value,
  );

  _is.ColumnValue<String, String> toolName(String? value) => _is.ColumnValue(
    table.toolName,
    value,
  );

  _is.ColumnValue<String, String> toolUseId(String? value) => _is.ColumnValue(
    table.toolUseId,
    value,
  );

  _is.ColumnValue<String, String> detail(String? value) => _is.ColumnValue(
    table.detail,
    value,
  );

  _is.ColumnValue<bool, bool> isError(bool? value) => _is.ColumnValue(
    table.isError,
    value,
  );

  _is.ColumnValue<int, int> reviewId(int? value) => _is.ColumnValue(
    table.reviewId,
    value,
  );
}

class TaskLogEntryTable extends _is.Table<int?> {
  TaskLogEntryTable({super.tableRelation})
    : super(tableName: 'task_log_entry') {
    updateTable = TaskLogEntryUpdateTable(this);
    taskId = _is.ColumnInt(
      'taskId',
      this,
    );
    content = _is.ColumnString(
      'content',
      this,
    );
    source = _is.ColumnEnum(
      'source',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    runId = _is.ColumnString(
      'runId',
      this,
    );
    phase = _is.ColumnEnum(
      'phase',
      this,
      _is.EnumSerialization.byName,
    );
    toolName = _is.ColumnString(
      'toolName',
      this,
    );
    toolUseId = _is.ColumnString(
      'toolUseId',
      this,
    );
    detail = _is.ColumnString(
      'detail',
      this,
    );
    isError = _is.ColumnBool(
      'isError',
      this,
    );
    reviewId = _is.ColumnInt(
      'reviewId',
      this,
    );
  }

  late final TaskLogEntryUpdateTable updateTable;

  late final _is.ColumnInt taskId;

  /// onDelete=Cascade: log entries have no meaning independent of their task.
  _iwn6t6fs.TaskTable? _task;

  late final _is.ColumnString content;

  late final _is.ColumnEnum<_ilj2nbps.LogSource> source;

  late final _is.ColumnDateTime createdAt;

  /// Structured fields (null on entries from older runners, which only
  /// sent [content] — the panel falls back to parsing its prefixes).
  late final _is.ColumnEnum<_i7oqmlti.LogKind> kind;

  /// Groups the entries of one `claude` invocation; a retry or a feedback
  /// iteration starts a new run.
  late final _is.ColumnString runId;

  late final _is.ColumnEnum<_iv8oofn2.LogPhase> phase;

  late final _is.ColumnString toolName;

  /// Pairs a toolResult with its toolCall.
  late final _is.ColumnString toolUseId;

  /// The longer form behind [content] (full tool input/output), truncated.
  late final _is.ColumnString detail;

  late final _is.ColumnBool isError;

  /// Set on entries from a code review run (CodeReview.id); no relation so
  /// deleting a review never touches the task's log.
  late final _is.ColumnInt reviewId;

  _iwn6t6fs.TaskTable get task {
    if (_task != null) return _task!;
    _task = _is.createRelationTable(
      relationFieldName: 'task',
      field: TaskLogEntry.t.taskId,
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
    content,
    source,
    createdAt,
    kind,
    runId,
    phase,
    toolName,
    toolUseId,
    detail,
    isError,
    reviewId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'task') {
      return task;
    }
    return null;
  }
}

class TaskLogEntryInclude extends _is.IncludeObject {
  TaskLogEntryInclude._({_iwn6t6fs.TaskInclude? task}) {
    _task = task;
  }

  _iwn6t6fs.TaskInclude? _task;

  @override
  Map<String, _is.Include?> get includes => {'task': _task};

  @override
  _is.Table<int?> get table => TaskLogEntry.t;
}

class TaskLogEntryIncludeList extends _is.IncludeList {
  TaskLogEntryIncludeList._({
    _is.WhereExpressionBuilder<TaskLogEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaskLogEntry.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaskLogEntry.t;
}

class TaskLogEntryRepository {
  const TaskLogEntryRepository._();

  final attachRow = const TaskLogEntryAttachRowRepository._();

  /// Returns a list of [TaskLogEntry]s matching the given query parameters.
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
  Future<List<TaskLogEntry>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskLogEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskLogEntryTable>? orderBy,
    _is.OrderByListBuilder<TaskLogEntryTable>? orderByList,
    _is.Transaction? transaction,
    TaskLogEntryInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaskLogEntry>(
      where: where?.call(TaskLogEntry.t),
      orderBy: orderBy?.call(TaskLogEntry.t),
      orderByList: orderByList?.call(TaskLogEntry.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaskLogEntry] matching the given query parameters.
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
  Future<TaskLogEntry?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskLogEntryTable>? where,
    int? offset,
    _is.OrderByBuilder<TaskLogEntryTable>? orderBy,
    _is.OrderByListBuilder<TaskLogEntryTable>? orderByList,
    _is.Transaction? transaction,
    TaskLogEntryInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaskLogEntry>(
      where: where?.call(TaskLogEntry.t),
      orderBy: orderBy?.call(TaskLogEntry.t),
      orderByList: orderByList?.call(TaskLogEntry.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaskLogEntry] by its [id] or null if no such row exists.
  Future<TaskLogEntry?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    TaskLogEntryInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaskLogEntry>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaskLogEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [TaskLogEntry]s will have their `id` fields set.
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
  Future<List<TaskLogEntry>> insert(
    _is.DatabaseSession session,
    List<TaskLogEntry> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaskLogEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaskLogEntry] and returns the inserted row.
  ///
  /// The returned [TaskLogEntry] will have its `id` field set.
  Future<TaskLogEntry> insertRow(
    _is.DatabaseSession session,
    TaskLogEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaskLogEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TaskLogEntry]s in the list and returns the resulting rows.
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
  /// The returned [TaskLogEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskLogEntry>> upsert(
    _is.DatabaseSession session,
    List<TaskLogEntry> rows, {
    required _is.ColumnSelections<TaskLogEntryTable> conflictColumns,
    _is.ColumnSelections<TaskLogEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<TaskLogEntryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaskLogEntry>(
      rows,
      conflictColumns: conflictColumns(TaskLogEntry.t),
      updateColumns: updateColumns?.call(TaskLogEntry.t),
      updateWhere: updateWhere?.call(TaskLogEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaskLogEntry] and returns the resulting row.
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
  /// The returned [TaskLogEntry] will have its `id` field set.
  Future<TaskLogEntry?> upsertRow(
    _is.DatabaseSession session,
    TaskLogEntry row, {
    required _is.ColumnSelections<TaskLogEntryTable> conflictColumns,
    _is.ColumnSelections<TaskLogEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<TaskLogEntryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaskLogEntry>(
      row,
      conflictColumns: conflictColumns(TaskLogEntry.t),
      updateColumns: updateColumns?.call(TaskLogEntry.t),
      updateWhere: updateWhere?.call(TaskLogEntry.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaskLogEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskLogEntry>> update(
    _is.DatabaseSession session,
    List<TaskLogEntry> rows, {
    _is.ColumnSelections<TaskLogEntryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaskLogEntry>(
      rows,
      columns: columns?.call(TaskLogEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaskLogEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaskLogEntry> updateRow(
    _is.DatabaseSession session,
    TaskLogEntry row, {
    _is.ColumnSelections<TaskLogEntryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaskLogEntry>(
      row,
      columns: columns?.call(TaskLogEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaskLogEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaskLogEntry?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaskLogEntryUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaskLogEntry>(
      id,
      columnValues: columnValues(TaskLogEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaskLogEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaskLogEntry>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaskLogEntryUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TaskLogEntryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskLogEntryTable>? orderBy,
    _is.OrderByListBuilder<TaskLogEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaskLogEntry>(
      columnValues: columnValues(TaskLogEntry.t.updateTable),
      where: where(TaskLogEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaskLogEntry.t),
      orderByList: orderByList?.call(TaskLogEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaskLogEntry]s in the list and returns the deleted rows.
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
  Future<List<TaskLogEntry>> delete(
    _is.DatabaseSession session,
    List<TaskLogEntry> rows, {
    _is.OrderByBuilder<TaskLogEntryTable>? orderBy,
    _is.OrderByListBuilder<TaskLogEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaskLogEntry>(
      rows,
      orderBy: orderBy?.call(TaskLogEntry.t),
      orderByList: orderByList?.call(TaskLogEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaskLogEntry].
  Future<TaskLogEntry> deleteRow(
    _is.DatabaseSession session,
    TaskLogEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaskLogEntry>(
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
  Future<List<TaskLogEntry>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaskLogEntryTable> where,
    _is.OrderByBuilder<TaskLogEntryTable>? orderBy,
    _is.OrderByListBuilder<TaskLogEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaskLogEntry>(
      where: where(TaskLogEntry.t),
      orderBy: orderBy?.call(TaskLogEntry.t),
      orderByList: orderByList?.call(TaskLogEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskLogEntryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaskLogEntry>(
      where: where?.call(TaskLogEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaskLogEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaskLogEntryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaskLogEntry>(
      where: where(TaskLogEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class TaskLogEntryAttachRowRepository {
  const TaskLogEntryAttachRowRepository._();

  /// Creates a relation between the given [TaskLogEntry] and [Task]
  /// by setting the [TaskLogEntry]'s foreign key `taskId` to refer to the [Task].
  Future<void> task(
    _is.DatabaseSession session,
    TaskLogEntry taskLogEntry,
    _iwn6t6fs.Task task, {
    _is.Transaction? transaction,
  }) async {
    if (taskLogEntry.id == null) {
      throw ArgumentError.notNull('taskLogEntry.id');
    }
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $taskLogEntry = taskLogEntry.copyWith(taskId: task.id);
    await session.db.updateRow<TaskLogEntry>(
      $taskLogEntry,
      columns: [TaskLogEntry.t.taskId],
      transaction: transaction,
    );
  }
}
