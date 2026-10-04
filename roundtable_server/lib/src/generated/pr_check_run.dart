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

/// One GitHub Actions job run for a task PR's head commit. Mirrored from the
/// Actions API by `syncChecks` (lib/src/pr_checks.dart); the rows of a
/// previous head commit are replaced once the PR gets a new one.
abstract class PrCheckRun
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PrCheckRun._({
    this.id,
    required this.taskId,
    this.task,
    required this.headSha,
    required this.workflowRunId,
    required this.runAttempt,
    required this.workflowName,
    required this.jobId,
    required this.jobName,
    required this.status,
    this.conclusion,
    this.failedStep,
    this.htmlUrl,
    this.startedAt,
    this.completedAt,
  });

  factory PrCheckRun({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    required String headSha,
    required int workflowRunId,
    required int runAttempt,
    required String workflowName,
    required int jobId,
    required String jobName,
    required String status,
    String? conclusion,
    String? failedStep,
    String? htmlUrl,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _PrCheckRunImpl;

  factory PrCheckRun.fromJson(Map<String, dynamic> jsonSerialization) {
    return PrCheckRun(
      id: jsonSerialization['id'] as int?,
      taskId: jsonSerialization['taskId'] as int,
      task: jsonSerialization['task'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<_iwn6t6fs.Task>(
              jsonSerialization['task'],
            ),
      headSha: jsonSerialization['headSha'] as String,
      workflowRunId: jsonSerialization['workflowRunId'] as int,
      runAttempt: jsonSerialization['runAttempt'] as int,
      workflowName: jsonSerialization['workflowName'] as String,
      jobId: jsonSerialization['jobId'] as int,
      jobName: jsonSerialization['jobName'] as String,
      status: jsonSerialization['status'] as String,
      conclusion: jsonSerialization['conclusion'] as String?,
      failedStep: jsonSerialization['failedStep'] as String?,
      htmlUrl: jsonSerialization['htmlUrl'] as String?,
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
    );
  }

  static final t = PrCheckRunTable();

  static const db = PrCheckRunRepository._();

  @override
  int? id;

  int taskId;

  /// onDelete=Cascade: a check has no meaning independent of its task.
  _iwn6t6fs.Task? task;

  /// The commit the job ran on — always the task's `prHeadSha`.
  String headSha;

  /// The workflow run the job belongs to, and which attempt of it (a
  /// re-run on GitHub bumps it).
  int workflowRunId;

  int runAttempt;

  String workflowName;

  /// GitHub's job id, used to fetch the job's log.
  int jobId;

  String jobName;

  /// `queued`, `in_progress`, `completed`, ... as GitHub reports it.
  String status;

  /// Set once completed: `success`, `failure`, `cancelled`, `skipped`, ...
  String? conclusion;

  /// Name of the first step that failed, if any.
  String? failedStep;

  /// The job's page on GitHub.
  String? htmlUrl;

  DateTime? startedAt;

  DateTime? completedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PrCheckRun]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PrCheckRun copyWith({
    int? id,
    int? taskId,
    _iwn6t6fs.Task? task,
    String? headSha,
    int? workflowRunId,
    int? runAttempt,
    String? workflowName,
    int? jobId,
    String? jobName,
    String? status,
    String? conclusion,
    String? failedStep,
    String? htmlUrl,
    DateTime? startedAt,
    DateTime? completedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PrCheckRun',
      if (id != null) 'id': id,
      'taskId': taskId,
      if (task != null) 'task': task?.toJson(),
      'headSha': headSha,
      'workflowRunId': workflowRunId,
      'runAttempt': runAttempt,
      'workflowName': workflowName,
      'jobId': jobId,
      'jobName': jobName,
      'status': status,
      if (conclusion != null) 'conclusion': conclusion,
      if (failedStep != null) 'failedStep': failedStep,
      if (htmlUrl != null) 'htmlUrl': htmlUrl,
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PrCheckRun',
      if (id != null) 'id': id,
      'taskId': taskId,
      if (task != null) 'task': task?.toJsonForProtocol(),
      'headSha': headSha,
      'workflowRunId': workflowRunId,
      'runAttempt': runAttempt,
      'workflowName': workflowName,
      'jobId': jobId,
      'jobName': jobName,
      'status': status,
      if (conclusion != null) 'conclusion': conclusion,
      if (failedStep != null) 'failedStep': failedStep,
      if (htmlUrl != null) 'htmlUrl': htmlUrl,
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  static PrCheckRunInclude include({_iwn6t6fs.TaskInclude? task}) {
    return PrCheckRunInclude._(task: task);
  }

  static PrCheckRunIncludeList includeList({
    _is.WhereExpressionBuilder<PrCheckRunTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PrCheckRunTable>? orderBy,
    _is.OrderByListBuilder<PrCheckRunTable>? orderByList,
    PrCheckRunInclude? include,
  }) {
    return PrCheckRunIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PrCheckRun.t),
      orderByList: orderByList?.call(PrCheckRun.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrCheckRunImpl extends PrCheckRun {
  _PrCheckRunImpl({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    required String headSha,
    required int workflowRunId,
    required int runAttempt,
    required String workflowName,
    required int jobId,
    required String jobName,
    required String status,
    String? conclusion,
    String? failedStep,
    String? htmlUrl,
    DateTime? startedAt,
    DateTime? completedAt,
  }) : super._(
         id: id,
         taskId: taskId,
         task: task,
         headSha: headSha,
         workflowRunId: workflowRunId,
         runAttempt: runAttempt,
         workflowName: workflowName,
         jobId: jobId,
         jobName: jobName,
         status: status,
         conclusion: conclusion,
         failedStep: failedStep,
         htmlUrl: htmlUrl,
         startedAt: startedAt,
         completedAt: completedAt,
       );

  /// Returns a shallow copy of this [PrCheckRun]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PrCheckRun copyWith({
    Object? id = _Undefined,
    int? taskId,
    Object? task = _Undefined,
    String? headSha,
    int? workflowRunId,
    int? runAttempt,
    String? workflowName,
    int? jobId,
    String? jobName,
    String? status,
    Object? conclusion = _Undefined,
    Object? failedStep = _Undefined,
    Object? htmlUrl = _Undefined,
    Object? startedAt = _Undefined,
    Object? completedAt = _Undefined,
  }) {
    return PrCheckRun(
      id: id is int? ? id : this.id,
      taskId: taskId ?? this.taskId,
      task: task is _iwn6t6fs.Task? ? task : this.task?.copyWith(),
      headSha: headSha ?? this.headSha,
      workflowRunId: workflowRunId ?? this.workflowRunId,
      runAttempt: runAttempt ?? this.runAttempt,
      workflowName: workflowName ?? this.workflowName,
      jobId: jobId ?? this.jobId,
      jobName: jobName ?? this.jobName,
      status: status ?? this.status,
      conclusion: conclusion is String? ? conclusion : this.conclusion,
      failedStep: failedStep is String? ? failedStep : this.failedStep,
      htmlUrl: htmlUrl is String? ? htmlUrl : this.htmlUrl,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
    );
  }
}

class PrCheckRunUpdateTable extends _is.UpdateTable<PrCheckRunTable> {
  PrCheckRunUpdateTable(super.table);

  _is.ColumnValue<int, int> taskId(int value) => _is.ColumnValue(
    table.taskId,
    value,
  );

  _is.ColumnValue<String, String> headSha(String value) => _is.ColumnValue(
    table.headSha,
    value,
  );

  _is.ColumnValue<int, int> workflowRunId(int value) => _is.ColumnValue(
    table.workflowRunId,
    value,
  );

  _is.ColumnValue<int, int> runAttempt(int value) => _is.ColumnValue(
    table.runAttempt,
    value,
  );

  _is.ColumnValue<String, String> workflowName(String value) => _is.ColumnValue(
    table.workflowName,
    value,
  );

  _is.ColumnValue<int, int> jobId(int value) => _is.ColumnValue(
    table.jobId,
    value,
  );

  _is.ColumnValue<String, String> jobName(String value) => _is.ColumnValue(
    table.jobName,
    value,
  );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> conclusion(String? value) => _is.ColumnValue(
    table.conclusion,
    value,
  );

  _is.ColumnValue<String, String> failedStep(String? value) => _is.ColumnValue(
    table.failedStep,
    value,
  );

  _is.ColumnValue<String, String> htmlUrl(String? value) => _is.ColumnValue(
    table.htmlUrl,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> startedAt(DateTime? value) =>
      _is.ColumnValue(
        table.startedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _is.ColumnValue(
        table.completedAt,
        value,
      );
}

class PrCheckRunTable extends _is.Table<int?> {
  PrCheckRunTable({super.tableRelation}) : super(tableName: 'pr_check_run') {
    updateTable = PrCheckRunUpdateTable(this);
    taskId = _is.ColumnInt(
      'taskId',
      this,
    );
    headSha = _is.ColumnString(
      'headSha',
      this,
    );
    workflowRunId = _is.ColumnInt(
      'workflowRunId',
      this,
    );
    runAttempt = _is.ColumnInt(
      'runAttempt',
      this,
    );
    workflowName = _is.ColumnString(
      'workflowName',
      this,
    );
    jobId = _is.ColumnInt(
      'jobId',
      this,
    );
    jobName = _is.ColumnString(
      'jobName',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    conclusion = _is.ColumnString(
      'conclusion',
      this,
    );
    failedStep = _is.ColumnString(
      'failedStep',
      this,
    );
    htmlUrl = _is.ColumnString(
      'htmlUrl',
      this,
    );
    startedAt = _is.ColumnDateTime(
      'startedAt',
      this,
    );
    completedAt = _is.ColumnDateTime(
      'completedAt',
      this,
    );
  }

  late final PrCheckRunUpdateTable updateTable;

  late final _is.ColumnInt taskId;

  /// onDelete=Cascade: a check has no meaning independent of its task.
  _iwn6t6fs.TaskTable? _task;

  /// The commit the job ran on — always the task's `prHeadSha`.
  late final _is.ColumnString headSha;

  /// The workflow run the job belongs to, and which attempt of it (a
  /// re-run on GitHub bumps it).
  late final _is.ColumnInt workflowRunId;

  late final _is.ColumnInt runAttempt;

  late final _is.ColumnString workflowName;

  /// GitHub's job id, used to fetch the job's log.
  late final _is.ColumnInt jobId;

  late final _is.ColumnString jobName;

  /// `queued`, `in_progress`, `completed`, ... as GitHub reports it.
  late final _is.ColumnString status;

  /// Set once completed: `success`, `failure`, `cancelled`, `skipped`, ...
  late final _is.ColumnString conclusion;

  /// Name of the first step that failed, if any.
  late final _is.ColumnString failedStep;

  /// The job's page on GitHub.
  late final _is.ColumnString htmlUrl;

  late final _is.ColumnDateTime startedAt;

  late final _is.ColumnDateTime completedAt;

  _iwn6t6fs.TaskTable get task {
    if (_task != null) return _task!;
    _task = _is.createRelationTable(
      relationFieldName: 'task',
      field: PrCheckRun.t.taskId,
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
    headSha,
    workflowRunId,
    runAttempt,
    workflowName,
    jobId,
    jobName,
    status,
    conclusion,
    failedStep,
    htmlUrl,
    startedAt,
    completedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'task') {
      return task;
    }
    return null;
  }
}

class PrCheckRunInclude extends _is.IncludeObject {
  PrCheckRunInclude._({_iwn6t6fs.TaskInclude? task}) {
    _task = task;
  }

  _iwn6t6fs.TaskInclude? _task;

  @override
  Map<String, _is.Include?> get includes => {'task': _task};

  @override
  _is.Table<int?> get table => PrCheckRun.t;
}

class PrCheckRunIncludeList extends _is.IncludeList {
  PrCheckRunIncludeList._({
    _is.WhereExpressionBuilder<PrCheckRunTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PrCheckRun.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PrCheckRun.t;
}

class PrCheckRunRepository {
  const PrCheckRunRepository._();

  final attachRow = const PrCheckRunAttachRowRepository._();

  /// Returns a list of [PrCheckRun]s matching the given query parameters.
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
  Future<List<PrCheckRun>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PrCheckRunTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PrCheckRunTable>? orderBy,
    _is.OrderByListBuilder<PrCheckRunTable>? orderByList,
    _is.Transaction? transaction,
    PrCheckRunInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PrCheckRun>(
      where: where?.call(PrCheckRun.t),
      orderBy: orderBy?.call(PrCheckRun.t),
      orderByList: orderByList?.call(PrCheckRun.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PrCheckRun] matching the given query parameters.
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
  Future<PrCheckRun?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PrCheckRunTable>? where,
    int? offset,
    _is.OrderByBuilder<PrCheckRunTable>? orderBy,
    _is.OrderByListBuilder<PrCheckRunTable>? orderByList,
    _is.Transaction? transaction,
    PrCheckRunInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PrCheckRun>(
      where: where?.call(PrCheckRun.t),
      orderBy: orderBy?.call(PrCheckRun.t),
      orderByList: orderByList?.call(PrCheckRun.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PrCheckRun] by its [id] or null if no such row exists.
  Future<PrCheckRun?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    PrCheckRunInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PrCheckRun>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PrCheckRun]s in the list and returns the inserted rows.
  ///
  /// The returned [PrCheckRun]s will have their `id` fields set.
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
  Future<List<PrCheckRun>> insert(
    _is.DatabaseSession session,
    List<PrCheckRun> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PrCheckRun>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PrCheckRun] and returns the inserted row.
  ///
  /// The returned [PrCheckRun] will have its `id` field set.
  Future<PrCheckRun> insertRow(
    _is.DatabaseSession session,
    PrCheckRun row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PrCheckRun>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PrCheckRun]s in the list and returns the resulting rows.
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
  /// The returned [PrCheckRun]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PrCheckRun>> upsert(
    _is.DatabaseSession session,
    List<PrCheckRun> rows, {
    required _is.ColumnSelections<PrCheckRunTable> conflictColumns,
    _is.ColumnSelections<PrCheckRunTable>? updateColumns,
    _is.WhereExpressionBuilder<PrCheckRunTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PrCheckRun>(
      rows,
      conflictColumns: conflictColumns(PrCheckRun.t),
      updateColumns: updateColumns?.call(PrCheckRun.t),
      updateWhere: updateWhere?.call(PrCheckRun.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PrCheckRun] and returns the resulting row.
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
  /// The returned [PrCheckRun] will have its `id` field set.
  Future<PrCheckRun?> upsertRow(
    _is.DatabaseSession session,
    PrCheckRun row, {
    required _is.ColumnSelections<PrCheckRunTable> conflictColumns,
    _is.ColumnSelections<PrCheckRunTable>? updateColumns,
    _is.WhereExpressionBuilder<PrCheckRunTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PrCheckRun>(
      row,
      conflictColumns: conflictColumns(PrCheckRun.t),
      updateColumns: updateColumns?.call(PrCheckRun.t),
      updateWhere: updateWhere?.call(PrCheckRun.t),
      transaction: transaction,
    );
  }

  /// Updates all [PrCheckRun]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PrCheckRun>> update(
    _is.DatabaseSession session,
    List<PrCheckRun> rows, {
    _is.ColumnSelections<PrCheckRunTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PrCheckRun>(
      rows,
      columns: columns?.call(PrCheckRun.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PrCheckRun]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PrCheckRun> updateRow(
    _is.DatabaseSession session,
    PrCheckRun row, {
    _is.ColumnSelections<PrCheckRunTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PrCheckRun>(
      row,
      columns: columns?.call(PrCheckRun.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PrCheckRun] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PrCheckRun?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PrCheckRunUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PrCheckRun>(
      id,
      columnValues: columnValues(PrCheckRun.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PrCheckRun]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PrCheckRun>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PrCheckRunUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PrCheckRunTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PrCheckRunTable>? orderBy,
    _is.OrderByListBuilder<PrCheckRunTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PrCheckRun>(
      columnValues: columnValues(PrCheckRun.t.updateTable),
      where: where(PrCheckRun.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PrCheckRun.t),
      orderByList: orderByList?.call(PrCheckRun.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PrCheckRun]s in the list and returns the deleted rows.
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
  Future<List<PrCheckRun>> delete(
    _is.DatabaseSession session,
    List<PrCheckRun> rows, {
    _is.OrderByBuilder<PrCheckRunTable>? orderBy,
    _is.OrderByListBuilder<PrCheckRunTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PrCheckRun>(
      rows,
      orderBy: orderBy?.call(PrCheckRun.t),
      orderByList: orderByList?.call(PrCheckRun.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PrCheckRun].
  Future<PrCheckRun> deleteRow(
    _is.DatabaseSession session,
    PrCheckRun row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PrCheckRun>(
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
  Future<List<PrCheckRun>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PrCheckRunTable> where,
    _is.OrderByBuilder<PrCheckRunTable>? orderBy,
    _is.OrderByListBuilder<PrCheckRunTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PrCheckRun>(
      where: where(PrCheckRun.t),
      orderBy: orderBy?.call(PrCheckRun.t),
      orderByList: orderByList?.call(PrCheckRun.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PrCheckRunTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PrCheckRun>(
      where: where?.call(PrCheckRun.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PrCheckRun] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PrCheckRunTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PrCheckRun>(
      where: where(PrCheckRun.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class PrCheckRunAttachRowRepository {
  const PrCheckRunAttachRowRepository._();

  /// Creates a relation between the given [PrCheckRun] and [Task]
  /// by setting the [PrCheckRun]'s foreign key `taskId` to refer to the [Task].
  Future<void> task(
    _is.DatabaseSession session,
    PrCheckRun prCheckRun,
    _iwn6t6fs.Task task, {
    _is.Transaction? transaction,
  }) async {
    if (prCheckRun.id == null) {
      throw ArgumentError.notNull('prCheckRun.id');
    }
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $prCheckRun = prCheckRun.copyWith(taskId: task.id);
    await session.db.updateRow<PrCheckRun>(
      $prCheckRun,
      columns: [PrCheckRun.t.taskId],
      transaction: transaction,
    );
  }
}
