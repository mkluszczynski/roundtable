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
import 'machine_metric.dart' as _ixivwx7g;
import 'machine_status.dart' as _i6yugb3s;

/// A registered host (laptop, VPS) running the agent daemon. Pure infrastructure — an Agent is the
/// persona living on it.
abstract class Machine
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Machine._({
    this.id,
    required this.name,
    this.tokenHash,
    _i6yugb3s.MachineStatus? status,
    this.lastSeenAt,
    DateTime? createdAt,
    this.agents,
    this.metrics,
  }) : status = status ?? _i6yugb3s.MachineStatus.offline,
       createdAt = createdAt ?? DateTime.now();

  factory Machine({
    int? id,
    required String name,
    String? tokenHash,
    _i6yugb3s.MachineStatus? status,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    List<_ijo8h3v4.Agent>? agents,
    List<_ixivwx7g.MachineMetric>? metrics,
  }) = _MachineImpl;

  factory Machine.fromJson(Map<String, dynamic> jsonSerialization) {
    return Machine(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      tokenHash: jsonSerialization['tokenHash'] as String?,
      status: jsonSerialization['status'] == null
          ? null
          : _i6yugb3s.MachineStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      lastSeenAt: jsonSerialization['lastSeenAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['lastSeenAt']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      agents: jsonSerialization['agents'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<List<_ijo8h3v4.Agent>>(
              jsonSerialization['agents'],
            ),
      metrics: jsonSerialization['metrics'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<List<_ixivwx7g.MachineMetric>>(
              jsonSerialization['metrics'],
            ),
    );
  }

  static final t = MachineTable();

  static const db = MachineRepository._();

  @override
  int? id;

  /// The machine's display name.
  String name;

  /// Hash of the machine's registration token. The raw token is shown to the dev only once.
  String? tokenHash;

  _i6yugb3s.MachineStatus status;

  /// Last time a heartbeat was received from this machine's daemon.
  DateTime? lastSeenAt;

  DateTime createdAt;

  List<_ijo8h3v4.Agent>? agents;

  List<_ixivwx7g.MachineMetric>? metrics;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Machine]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Machine copyWith({
    int? id,
    String? name,
    String? tokenHash,
    _i6yugb3s.MachineStatus? status,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    List<_ijo8h3v4.Agent>? agents,
    List<_ixivwx7g.MachineMetric>? metrics,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Machine',
      if (id != null) 'id': id,
      'name': name,
      if (tokenHash != null) 'tokenHash': tokenHash,
      'status': status.toJson(),
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt?.toJson(),
      'createdAt': createdAt.toJson(),
      if (agents != null)
        'agents': agents?.toJson(valueToJson: (v) => v.toJson()),
      if (metrics != null)
        'metrics': metrics?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Machine',
      if (id != null) 'id': id,
      'name': name,
      'status': status.toJson(),
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt?.toJson(),
      'createdAt': createdAt.toJson(),
      if (agents != null)
        'agents': agents?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (metrics != null)
        'metrics': metrics?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  static MachineInclude include({
    _ijo8h3v4.AgentIncludeList? agents,
    _ixivwx7g.MachineMetricIncludeList? metrics,
  }) {
    return MachineInclude._(
      agents: agents,
      metrics: metrics,
    );
  }

  static MachineIncludeList includeList({
    _is.WhereExpressionBuilder<MachineTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MachineTable>? orderBy,
    _is.OrderByListBuilder<MachineTable>? orderByList,
    MachineInclude? include,
  }) {
    return MachineIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Machine.t),
      orderByList: orderByList?.call(Machine.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MachineImpl extends Machine {
  _MachineImpl({
    int? id,
    required String name,
    String? tokenHash,
    _i6yugb3s.MachineStatus? status,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    List<_ijo8h3v4.Agent>? agents,
    List<_ixivwx7g.MachineMetric>? metrics,
  }) : super._(
         id: id,
         name: name,
         tokenHash: tokenHash,
         status: status,
         lastSeenAt: lastSeenAt,
         createdAt: createdAt,
         agents: agents,
         metrics: metrics,
       );

  /// Returns a shallow copy of this [Machine]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Machine copyWith({
    Object? id = _Undefined,
    String? name,
    Object? tokenHash = _Undefined,
    _i6yugb3s.MachineStatus? status,
    Object? lastSeenAt = _Undefined,
    DateTime? createdAt,
    Object? agents = _Undefined,
    Object? metrics = _Undefined,
  }) {
    return Machine(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      tokenHash: tokenHash is String? ? tokenHash : this.tokenHash,
      status: status ?? this.status,
      lastSeenAt: lastSeenAt is DateTime? ? lastSeenAt : this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      agents: agents is List<_ijo8h3v4.Agent>?
          ? agents
          : this.agents?.map((e0) => e0.copyWith()).toList(),
      metrics: metrics is List<_ixivwx7g.MachineMetric>?
          ? metrics
          : this.metrics?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class MachineUpdateTable extends _is.UpdateTable<MachineTable> {
  MachineUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> tokenHash(String? value) => _is.ColumnValue(
    table.tokenHash,
    value,
  );

  _is.ColumnValue<_i6yugb3s.MachineStatus, _i6yugb3s.MachineStatus> status(
    _i6yugb3s.MachineStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> lastSeenAt(DateTime? value) =>
      _is.ColumnValue(
        table.lastSeenAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class MachineTable extends _is.Table<int?> {
  MachineTable({super.tableRelation}) : super(tableName: 'machine') {
    updateTable = MachineUpdateTable(this);
    name = _is.ColumnString(
      'name',
      this,
    );
    tokenHash = _is.ColumnString(
      'tokenHash',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    lastSeenAt = _is.ColumnDateTime(
      'lastSeenAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final MachineUpdateTable updateTable;

  /// The machine's display name.
  late final _is.ColumnString name;

  /// Hash of the machine's registration token. The raw token is shown to the dev only once.
  late final _is.ColumnString tokenHash;

  late final _is.ColumnEnum<_i6yugb3s.MachineStatus> status;

  /// Last time a heartbeat was received from this machine's daemon.
  late final _is.ColumnDateTime lastSeenAt;

  late final _is.ColumnDateTime createdAt;

  _ijo8h3v4.AgentTable? ___agents;

  _is.ManyRelation<_ijo8h3v4.AgentTable>? _agents;

  _ixivwx7g.MachineMetricTable? ___metrics;

  _is.ManyRelation<_ixivwx7g.MachineMetricTable>? _metrics;

  _ijo8h3v4.AgentTable get __agents {
    if (___agents != null) return ___agents!;
    ___agents = _is.createRelationTable(
      relationFieldName: '__agents',
      field: Machine.t.id,
      foreignField: _ijo8h3v4.Agent.t.machineId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ijo8h3v4.AgentTable(tableRelation: foreignTableRelation),
    );
    return ___agents!;
  }

  _ixivwx7g.MachineMetricTable get __metrics {
    if (___metrics != null) return ___metrics!;
    ___metrics = _is.createRelationTable(
      relationFieldName: '__metrics',
      field: Machine.t.id,
      foreignField: _ixivwx7g.MachineMetric.t.machineId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ixivwx7g.MachineMetricTable(tableRelation: foreignTableRelation),
    );
    return ___metrics!;
  }

  _is.ManyRelation<_ijo8h3v4.AgentTable> get agents {
    if (_agents != null) return _agents!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'agents',
      field: Machine.t.id,
      foreignField: _ijo8h3v4.Agent.t.machineId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ijo8h3v4.AgentTable(tableRelation: foreignTableRelation),
    );
    _agents = _is.ManyRelation<_ijo8h3v4.AgentTable>(
      tableWithRelations: relationTable,
      table: _ijo8h3v4.AgentTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _agents!;
  }

  _is.ManyRelation<_ixivwx7g.MachineMetricTable> get metrics {
    if (_metrics != null) return _metrics!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'metrics',
      field: Machine.t.id,
      foreignField: _ixivwx7g.MachineMetric.t.machineId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ixivwx7g.MachineMetricTable(tableRelation: foreignTableRelation),
    );
    _metrics = _is.ManyRelation<_ixivwx7g.MachineMetricTable>(
      tableWithRelations: relationTable,
      table: _ixivwx7g.MachineMetricTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _metrics!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    name,
    tokenHash,
    status,
    lastSeenAt,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'agents') {
      return __agents;
    }
    if (relationField == 'metrics') {
      return __metrics;
    }
    return null;
  }
}

class MachineInclude extends _is.IncludeObject {
  MachineInclude._({
    _ijo8h3v4.AgentIncludeList? agents,
    _ixivwx7g.MachineMetricIncludeList? metrics,
  }) {
    _agents = agents;
    _metrics = metrics;
  }

  _ijo8h3v4.AgentIncludeList? _agents;

  _ixivwx7g.MachineMetricIncludeList? _metrics;

  @override
  Map<String, _is.Include?> get includes => {
    'agents': _agents,
    'metrics': _metrics,
  };

  @override
  _is.Table<int?> get table => Machine.t;
}

class MachineIncludeList extends _is.IncludeList {
  MachineIncludeList._({
    _is.WhereExpressionBuilder<MachineTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Machine.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Machine.t;
}

class MachineRepository {
  const MachineRepository._();

  final attach = const MachineAttachRepository._();

  final attachRow = const MachineAttachRowRepository._();

  /// Returns a list of [Machine]s matching the given query parameters.
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
  Future<List<Machine>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MachineTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MachineTable>? orderBy,
    _is.OrderByListBuilder<MachineTable>? orderByList,
    _is.Transaction? transaction,
    MachineInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Machine>(
      where: where?.call(Machine.t),
      orderBy: orderBy?.call(Machine.t),
      orderByList: orderByList?.call(Machine.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Machine] matching the given query parameters.
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
  Future<Machine?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MachineTable>? where,
    int? offset,
    _is.OrderByBuilder<MachineTable>? orderBy,
    _is.OrderByListBuilder<MachineTable>? orderByList,
    _is.Transaction? transaction,
    MachineInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Machine>(
      where: where?.call(Machine.t),
      orderBy: orderBy?.call(Machine.t),
      orderByList: orderByList?.call(Machine.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Machine] by its [id] or null if no such row exists.
  Future<Machine?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    MachineInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Machine>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Machine]s in the list and returns the inserted rows.
  ///
  /// The returned [Machine]s will have their `id` fields set.
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
  Future<List<Machine>> insert(
    _is.DatabaseSession session,
    List<Machine> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Machine>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Machine] and returns the inserted row.
  ///
  /// The returned [Machine] will have its `id` field set.
  Future<Machine> insertRow(
    _is.DatabaseSession session,
    Machine row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Machine>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Machine]s in the list and returns the resulting rows.
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
  /// The returned [Machine]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Machine>> upsert(
    _is.DatabaseSession session,
    List<Machine> rows, {
    required _is.ColumnSelections<MachineTable> conflictColumns,
    _is.ColumnSelections<MachineTable>? updateColumns,
    _is.WhereExpressionBuilder<MachineTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Machine>(
      rows,
      conflictColumns: conflictColumns(Machine.t),
      updateColumns: updateColumns?.call(Machine.t),
      updateWhere: updateWhere?.call(Machine.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Machine] and returns the resulting row.
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
  /// The returned [Machine] will have its `id` field set.
  Future<Machine?> upsertRow(
    _is.DatabaseSession session,
    Machine row, {
    required _is.ColumnSelections<MachineTable> conflictColumns,
    _is.ColumnSelections<MachineTable>? updateColumns,
    _is.WhereExpressionBuilder<MachineTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Machine>(
      row,
      conflictColumns: conflictColumns(Machine.t),
      updateColumns: updateColumns?.call(Machine.t),
      updateWhere: updateWhere?.call(Machine.t),
      transaction: transaction,
    );
  }

  /// Updates all [Machine]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Machine>> update(
    _is.DatabaseSession session,
    List<Machine> rows, {
    _is.ColumnSelections<MachineTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Machine>(
      rows,
      columns: columns?.call(Machine.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Machine]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Machine> updateRow(
    _is.DatabaseSession session,
    Machine row, {
    _is.ColumnSelections<MachineTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Machine>(
      row,
      columns: columns?.call(Machine.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Machine] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Machine?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MachineUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Machine>(
      id,
      columnValues: columnValues(Machine.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Machine]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Machine>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MachineUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<MachineTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MachineTable>? orderBy,
    _is.OrderByListBuilder<MachineTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Machine>(
      columnValues: columnValues(Machine.t.updateTable),
      where: where(Machine.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Machine.t),
      orderByList: orderByList?.call(Machine.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Machine]s in the list and returns the deleted rows.
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
  Future<List<Machine>> delete(
    _is.DatabaseSession session,
    List<Machine> rows, {
    _is.OrderByBuilder<MachineTable>? orderBy,
    _is.OrderByListBuilder<MachineTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Machine>(
      rows,
      orderBy: orderBy?.call(Machine.t),
      orderByList: orderByList?.call(Machine.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Machine].
  Future<Machine> deleteRow(
    _is.DatabaseSession session,
    Machine row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Machine>(
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
  Future<List<Machine>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MachineTable> where,
    _is.OrderByBuilder<MachineTable>? orderBy,
    _is.OrderByListBuilder<MachineTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Machine>(
      where: where(Machine.t),
      orderBy: orderBy?.call(Machine.t),
      orderByList: orderByList?.call(Machine.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MachineTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Machine>(
      where: where?.call(Machine.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Machine] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MachineTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Machine>(
      where: where(Machine.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class MachineAttachRepository {
  const MachineAttachRepository._();

  /// Creates a relation between this [Machine] and the given [Agent]s
  /// by setting each [Agent]'s foreign key `machineId` to refer to this [Machine].
  Future<void> agents(
    _is.DatabaseSession session,
    Machine machine,
    List<_ijo8h3v4.Agent> agent, {
    _is.Transaction? transaction,
  }) async {
    if (agent.any((e) => e.id == null)) {
      throw ArgumentError.notNull('agent.id');
    }
    if (machine.id == null) {
      throw ArgumentError.notNull('machine.id');
    }

    var $agent = agent.map((e) => e.copyWith(machineId: machine.id)).toList();
    await session.db.update<_ijo8h3v4.Agent>(
      $agent,
      columns: [_ijo8h3v4.Agent.t.machineId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Machine] and the given [MachineMetric]s
  /// by setting each [MachineMetric]'s foreign key `machineId` to refer to this [Machine].
  Future<void> metrics(
    _is.DatabaseSession session,
    Machine machine,
    List<_ixivwx7g.MachineMetric> machineMetric, {
    _is.Transaction? transaction,
  }) async {
    if (machineMetric.any((e) => e.id == null)) {
      throw ArgumentError.notNull('machineMetric.id');
    }
    if (machine.id == null) {
      throw ArgumentError.notNull('machine.id');
    }

    var $machineMetric = machineMetric
        .map((e) => e.copyWith(machineId: machine.id))
        .toList();
    await session.db.update<_ixivwx7g.MachineMetric>(
      $machineMetric,
      columns: [_ixivwx7g.MachineMetric.t.machineId],
      transaction: transaction,
    );
  }
}

class MachineAttachRowRepository {
  const MachineAttachRowRepository._();

  /// Creates a relation between this [Machine] and the given [Agent]
  /// by setting the [Agent]'s foreign key `machineId` to refer to this [Machine].
  Future<void> agents(
    _is.DatabaseSession session,
    Machine machine,
    _ijo8h3v4.Agent agent, {
    _is.Transaction? transaction,
  }) async {
    if (agent.id == null) {
      throw ArgumentError.notNull('agent.id');
    }
    if (machine.id == null) {
      throw ArgumentError.notNull('machine.id');
    }

    var $agent = agent.copyWith(machineId: machine.id);
    await session.db.updateRow<_ijo8h3v4.Agent>(
      $agent,
      columns: [_ijo8h3v4.Agent.t.machineId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Machine] and the given [MachineMetric]
  /// by setting the [MachineMetric]'s foreign key `machineId` to refer to this [Machine].
  Future<void> metrics(
    _is.DatabaseSession session,
    Machine machine,
    _ixivwx7g.MachineMetric machineMetric, {
    _is.Transaction? transaction,
  }) async {
    if (machineMetric.id == null) {
      throw ArgumentError.notNull('machineMetric.id');
    }
    if (machine.id == null) {
      throw ArgumentError.notNull('machine.id');
    }

    var $machineMetric = machineMetric.copyWith(machineId: machine.id);
    await session.db.updateRow<_ixivwx7g.MachineMetric>(
      $machineMetric,
      columns: [_ixivwx7g.MachineMetric.t.machineId],
      transaction: transaction,
    );
  }
}
