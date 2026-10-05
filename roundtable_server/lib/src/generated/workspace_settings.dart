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
import 'agent.dart' as _ijo8h3v4;

/// Workspace-wide settings — a single row while the app is single-tenant.
/// Holds the defaults a project inherits unless it overrides them.
abstract class WorkspaceSettings
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WorkspaceSettings._({
    this.id,
    bool? skipPlanning,
    bool? autoReview,
    this.reviewerAgentId,
    this.reviewerAgent,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    DateTime? updatedAt,
  }) : skipPlanning = skipPlanning ?? false,
       autoReview = autoReview ?? false,
       autoFixReview = autoFixReview ?? false,
       maxReviewFixRounds = maxReviewFixRounds ?? 2,
       autoMerge = autoMerge ?? false,
       autoFixFailingChecks = autoFixFailingChecks ?? false,
       maxCheckFixAttempts = maxCheckFixAttempts ?? 2,
       updatedAt = updatedAt ?? DateTime.now();

  factory WorkspaceSettings({
    int? id,
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    DateTime? updatedAt,
  }) = _WorkspaceSettingsImpl;

  factory WorkspaceSettings.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceSettings(
      id: jsonSerialization['id'] as int?,
      skipPlanning: jsonSerialization['skipPlanning'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['skipPlanning']),
      autoReview: jsonSerialization['autoReview'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['autoReview']),
      reviewerAgentId: jsonSerialization['reviewerAgentId'] as int?,
      reviewerAgent: jsonSerialization['reviewerAgent'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<_ijo8h3v4.Agent>(
              jsonSerialization['reviewerAgent'],
            ),
      autoFixReview: jsonSerialization['autoFixReview'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['autoFixReview']),
      maxReviewFixRounds: jsonSerialization['maxReviewFixRounds'] as int?,
      autoMerge: jsonSerialization['autoMerge'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['autoMerge']),
      autoFixFailingChecks: jsonSerialization['autoFixFailingChecks'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['autoFixFailingChecks'],
            ),
      maxCheckFixAttempts: jsonSerialization['maxCheckFixAttempts'] as int?,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = WorkspaceSettingsTable();

  static const db = WorkspaceSettingsRepository._();

  @override
  int? id;

  /// Default for Task.skipPlanning on new tasks.
  bool skipPlanning;

  /// Default for Task.autoReview on new tasks.
  bool autoReview;

  int? reviewerAgentId;

  /// Default reviewer for new tasks.
  _ijo8h3v4.Agent? reviewerAgent;

  /// Defaults for Task.autoFixReview / maxReviewFixRounds.
  bool autoFixReview;

  int maxReviewFixRounds;

  /// Default for Task.autoMerge on new tasks.
  bool autoMerge;

  /// Defaults for Task.autoFixFailingChecks / maxCheckFixAttempts.
  bool autoFixFailingChecks;

  int maxCheckFixAttempts;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceSettings]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceSettings copyWith({
    int? id,
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceSettings',
      if (id != null) 'id': id,
      'skipPlanning': skipPlanning,
      'autoReview': autoReview,
      if (reviewerAgentId != null) 'reviewerAgentId': reviewerAgentId,
      if (reviewerAgent != null) 'reviewerAgent': reviewerAgent?.toJson(),
      'autoFixReview': autoFixReview,
      'maxReviewFixRounds': maxReviewFixRounds,
      'autoMerge': autoMerge,
      'autoFixFailingChecks': autoFixFailingChecks,
      'maxCheckFixAttempts': maxCheckFixAttempts,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceSettings',
      if (id != null) 'id': id,
      'skipPlanning': skipPlanning,
      'autoReview': autoReview,
      if (reviewerAgentId != null) 'reviewerAgentId': reviewerAgentId,
      if (reviewerAgent != null)
        'reviewerAgent': reviewerAgent?.toJsonForProtocol(),
      'autoFixReview': autoFixReview,
      'maxReviewFixRounds': maxReviewFixRounds,
      'autoMerge': autoMerge,
      'autoFixFailingChecks': autoFixFailingChecks,
      'maxCheckFixAttempts': maxCheckFixAttempts,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static WorkspaceSettingsInclude include({
    _ijo8h3v4.AgentInclude? reviewerAgent,
  }) {
    return WorkspaceSettingsInclude._(reviewerAgent: reviewerAgent);
  }

  static WorkspaceSettingsIncludeList includeList({
    _is.WhereExpressionBuilder<WorkspaceSettingsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceSettingsTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceSettingsTable>? orderByList,
    WorkspaceSettingsInclude? include,
  }) {
    return WorkspaceSettingsIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceSettings.t),
      orderByList: orderByList?.call(WorkspaceSettings.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceSettingsImpl extends WorkspaceSettings {
  _WorkspaceSettingsImpl({
    int? id,
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         skipPlanning: skipPlanning,
         autoReview: autoReview,
         reviewerAgentId: reviewerAgentId,
         reviewerAgent: reviewerAgent,
         autoFixReview: autoFixReview,
         maxReviewFixRounds: maxReviewFixRounds,
         autoMerge: autoMerge,
         autoFixFailingChecks: autoFixFailingChecks,
         maxCheckFixAttempts: maxCheckFixAttempts,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [WorkspaceSettings]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceSettings copyWith({
    Object? id = _Undefined,
    bool? skipPlanning,
    bool? autoReview,
    Object? reviewerAgentId = _Undefined,
    Object? reviewerAgent = _Undefined,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    DateTime? updatedAt,
  }) {
    return WorkspaceSettings(
      id: id is int? ? id : this.id,
      skipPlanning: skipPlanning ?? this.skipPlanning,
      autoReview: autoReview ?? this.autoReview,
      reviewerAgentId: reviewerAgentId is int?
          ? reviewerAgentId
          : this.reviewerAgentId,
      reviewerAgent: reviewerAgent is _ijo8h3v4.Agent?
          ? reviewerAgent
          : this.reviewerAgent?.copyWith(),
      autoFixReview: autoFixReview ?? this.autoFixReview,
      maxReviewFixRounds: maxReviewFixRounds ?? this.maxReviewFixRounds,
      autoMerge: autoMerge ?? this.autoMerge,
      autoFixFailingChecks: autoFixFailingChecks ?? this.autoFixFailingChecks,
      maxCheckFixAttempts: maxCheckFixAttempts ?? this.maxCheckFixAttempts,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class WorkspaceSettingsUpdateTable
    extends _is.UpdateTable<WorkspaceSettingsTable> {
  WorkspaceSettingsUpdateTable(super.table);

  _is.ColumnValue<bool, bool> skipPlanning(bool value) => _is.ColumnValue(
    table.skipPlanning,
    value,
  );

  _is.ColumnValue<bool, bool> autoReview(bool value) => _is.ColumnValue(
    table.autoReview,
    value,
  );

  _is.ColumnValue<int, int> reviewerAgentId(int? value) => _is.ColumnValue(
    table.reviewerAgentId,
    value,
  );

  _is.ColumnValue<bool, bool> autoFixReview(bool value) => _is.ColumnValue(
    table.autoFixReview,
    value,
  );

  _is.ColumnValue<int, int> maxReviewFixRounds(int value) => _is.ColumnValue(
    table.maxReviewFixRounds,
    value,
  );

  _is.ColumnValue<bool, bool> autoMerge(bool value) => _is.ColumnValue(
    table.autoMerge,
    value,
  );

  _is.ColumnValue<bool, bool> autoFixFailingChecks(bool value) =>
      _is.ColumnValue(
        table.autoFixFailingChecks,
        value,
      );

  _is.ColumnValue<int, int> maxCheckFixAttempts(int value) => _is.ColumnValue(
    table.maxCheckFixAttempts,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class WorkspaceSettingsTable extends _is.Table<int?> {
  WorkspaceSettingsTable({super.tableRelation})
    : super(tableName: 'workspace_settings') {
    updateTable = WorkspaceSettingsUpdateTable(this);
    skipPlanning = _is.ColumnBool(
      'skipPlanning',
      this,
      hasDefault: true,
    );
    autoReview = _is.ColumnBool(
      'autoReview',
      this,
      hasDefault: true,
    );
    reviewerAgentId = _is.ColumnInt(
      'reviewerAgentId',
      this,
    );
    autoFixReview = _is.ColumnBool(
      'autoFixReview',
      this,
      hasDefault: true,
    );
    maxReviewFixRounds = _is.ColumnInt(
      'maxReviewFixRounds',
      this,
      hasDefault: true,
    );
    autoMerge = _is.ColumnBool(
      'autoMerge',
      this,
      hasDefault: true,
    );
    autoFixFailingChecks = _is.ColumnBool(
      'autoFixFailingChecks',
      this,
      hasDefault: true,
    );
    maxCheckFixAttempts = _is.ColumnInt(
      'maxCheckFixAttempts',
      this,
      hasDefault: true,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
  }

  late final WorkspaceSettingsUpdateTable updateTable;

  /// Default for Task.skipPlanning on new tasks.
  late final _is.ColumnBool skipPlanning;

  /// Default for Task.autoReview on new tasks.
  late final _is.ColumnBool autoReview;

  late final _is.ColumnInt reviewerAgentId;

  /// Default reviewer for new tasks.
  _ijo8h3v4.AgentTable? _reviewerAgent;

  /// Defaults for Task.autoFixReview / maxReviewFixRounds.
  late final _is.ColumnBool autoFixReview;

  late final _is.ColumnInt maxReviewFixRounds;

  /// Default for Task.autoMerge on new tasks.
  late final _is.ColumnBool autoMerge;

  /// Defaults for Task.autoFixFailingChecks / maxCheckFixAttempts.
  late final _is.ColumnBool autoFixFailingChecks;

  late final _is.ColumnInt maxCheckFixAttempts;

  late final _is.ColumnDateTime updatedAt;

  _ijo8h3v4.AgentTable get reviewerAgent {
    if (_reviewerAgent != null) return _reviewerAgent!;
    _reviewerAgent = _is.createRelationTable(
      relationFieldName: 'reviewerAgent',
      field: WorkspaceSettings.t.reviewerAgentId,
      foreignField: _ijo8h3v4.Agent.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ijo8h3v4.AgentTable(tableRelation: foreignTableRelation),
    );
    return _reviewerAgent!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    skipPlanning,
    autoReview,
    reviewerAgentId,
    autoFixReview,
    maxReviewFixRounds,
    autoMerge,
    autoFixFailingChecks,
    maxCheckFixAttempts,
    updatedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'reviewerAgent') {
      return reviewerAgent;
    }
    return null;
  }
}

class WorkspaceSettingsInclude extends _is.IncludeObject {
  WorkspaceSettingsInclude._({_ijo8h3v4.AgentInclude? reviewerAgent}) {
    _reviewerAgent = reviewerAgent;
  }

  _ijo8h3v4.AgentInclude? _reviewerAgent;

  @override
  Map<String, _is.Include?> get includes => {'reviewerAgent': _reviewerAgent};

  @override
  _is.Table<int?> get table => WorkspaceSettings.t;
}

class WorkspaceSettingsIncludeList extends _is.IncludeList {
  WorkspaceSettingsIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceSettingsTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceSettings.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceSettings.t;
}

class WorkspaceSettingsRepository {
  const WorkspaceSettingsRepository._();

  final attachRow = const WorkspaceSettingsAttachRowRepository._();

  final detachRow = const WorkspaceSettingsDetachRowRepository._();

  /// Returns a list of [WorkspaceSettings]s matching the given query parameters.
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
  Future<List<WorkspaceSettings>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceSettingsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceSettingsTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceSettingsTable>? orderByList,
    _is.Transaction? transaction,
    WorkspaceSettingsInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceSettings>(
      where: where?.call(WorkspaceSettings.t),
      orderBy: orderBy?.call(WorkspaceSettings.t),
      orderByList: orderByList?.call(WorkspaceSettings.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceSettings] matching the given query parameters.
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
  Future<WorkspaceSettings?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceSettingsTable>? where,
    int? offset,
    _is.OrderByBuilder<WorkspaceSettingsTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceSettingsTable>? orderByList,
    _is.Transaction? transaction,
    WorkspaceSettingsInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceSettings>(
      where: where?.call(WorkspaceSettings.t),
      orderBy: orderBy?.call(WorkspaceSettings.t),
      orderByList: orderByList?.call(WorkspaceSettings.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceSettings] by its [id] or null if no such row exists.
  Future<WorkspaceSettings?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    WorkspaceSettingsInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceSettings>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceSettings]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceSettings]s will have their `id` fields set.
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
  Future<List<WorkspaceSettings>> insert(
    _is.DatabaseSession session,
    List<WorkspaceSettings> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceSettings>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceSettings] and returns the inserted row.
  ///
  /// The returned [WorkspaceSettings] will have its `id` field set.
  Future<WorkspaceSettings> insertRow(
    _is.DatabaseSession session,
    WorkspaceSettings row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceSettings>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceSettings]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceSettings]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceSettings>> upsert(
    _is.DatabaseSession session,
    List<WorkspaceSettings> rows, {
    required _is.ColumnSelections<WorkspaceSettingsTable> conflictColumns,
    _is.ColumnSelections<WorkspaceSettingsTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceSettingsTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceSettings>(
      rows,
      conflictColumns: conflictColumns(WorkspaceSettings.t),
      updateColumns: updateColumns?.call(WorkspaceSettings.t),
      updateWhere: updateWhere?.call(WorkspaceSettings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceSettings] and returns the resulting row.
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
  /// The returned [WorkspaceSettings] will have its `id` field set.
  Future<WorkspaceSettings?> upsertRow(
    _is.DatabaseSession session,
    WorkspaceSettings row, {
    required _is.ColumnSelections<WorkspaceSettingsTable> conflictColumns,
    _is.ColumnSelections<WorkspaceSettingsTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceSettingsTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceSettings>(
      row,
      conflictColumns: conflictColumns(WorkspaceSettings.t),
      updateColumns: updateColumns?.call(WorkspaceSettings.t),
      updateWhere: updateWhere?.call(WorkspaceSettings.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceSettings]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceSettings>> update(
    _is.DatabaseSession session,
    List<WorkspaceSettings> rows, {
    _is.ColumnSelections<WorkspaceSettingsTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceSettings>(
      rows,
      columns: columns?.call(WorkspaceSettings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceSettings]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceSettings> updateRow(
    _is.DatabaseSession session,
    WorkspaceSettings row, {
    _is.ColumnSelections<WorkspaceSettingsTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceSettings>(
      row,
      columns: columns?.call(WorkspaceSettings.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceSettings] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceSettings?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WorkspaceSettingsUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceSettings>(
      id,
      columnValues: columnValues(WorkspaceSettings.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceSettings]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceSettings>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WorkspaceSettingsUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WorkspaceSettingsTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceSettingsTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceSettingsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceSettings>(
      columnValues: columnValues(WorkspaceSettings.t.updateTable),
      where: where(WorkspaceSettings.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceSettings.t),
      orderByList: orderByList?.call(WorkspaceSettings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceSettings]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceSettings>> delete(
    _is.DatabaseSession session,
    List<WorkspaceSettings> rows, {
    _is.OrderByBuilder<WorkspaceSettingsTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceSettingsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceSettings>(
      rows,
      orderBy: orderBy?.call(WorkspaceSettings.t),
      orderByList: orderByList?.call(WorkspaceSettings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceSettings].
  Future<WorkspaceSettings> deleteRow(
    _is.DatabaseSession session,
    WorkspaceSettings row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceSettings>(
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
  Future<List<WorkspaceSettings>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceSettingsTable> where,
    _is.OrderByBuilder<WorkspaceSettingsTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceSettingsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceSettings>(
      where: where(WorkspaceSettings.t),
      orderBy: orderBy?.call(WorkspaceSettings.t),
      orderByList: orderByList?.call(WorkspaceSettings.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceSettingsTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceSettings>(
      where: where?.call(WorkspaceSettings.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceSettings] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceSettingsTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceSettings>(
      where: where(WorkspaceSettings.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class WorkspaceSettingsAttachRowRepository {
  const WorkspaceSettingsAttachRowRepository._();

  /// Creates a relation between the given [WorkspaceSettings] and [Agent]
  /// by setting the [WorkspaceSettings]'s foreign key `reviewerAgentId` to refer to the [Agent].
  Future<void> reviewerAgent(
    _is.DatabaseSession session,
    WorkspaceSettings workspaceSettings,
    _ijo8h3v4.Agent reviewerAgent, {
    _is.Transaction? transaction,
  }) async {
    if (workspaceSettings.id == null) {
      throw ArgumentError.notNull('workspaceSettings.id');
    }
    if (reviewerAgent.id == null) {
      throw ArgumentError.notNull('reviewerAgent.id');
    }

    var $workspaceSettings = workspaceSettings.copyWith(
      reviewerAgentId: reviewerAgent.id,
    );
    await session.db.updateRow<WorkspaceSettings>(
      $workspaceSettings,
      columns: [WorkspaceSettings.t.reviewerAgentId],
      transaction: transaction,
    );
  }
}

class WorkspaceSettingsDetachRowRepository {
  const WorkspaceSettingsDetachRowRepository._();

  /// Detaches the relation between this [WorkspaceSettings] and the [Agent] set in `reviewerAgent`
  /// by setting the [WorkspaceSettings]'s foreign key `reviewerAgentId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> reviewerAgent(
    _is.DatabaseSession session,
    WorkspaceSettings workspaceSettings, {
    _is.Transaction? transaction,
  }) async {
    if (workspaceSettings.id == null) {
      throw ArgumentError.notNull('workspaceSettings.id');
    }

    var $workspaceSettings = workspaceSettings.copyWith(reviewerAgentId: null);
    await session.db.updateRow<WorkspaceSettings>(
      $workspaceSettings,
      columns: [WorkspaceSettings.t.reviewerAgentId],
      transaction: transaction,
    );
  }
}
