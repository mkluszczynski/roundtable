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
import 'machine.dart' as _i0hti3f2;

/// A single CPU/RAM reading reported by a machine's daemon. Grows over time — needs periodic
/// cleanup of old entries.
abstract class MachineMetric
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  MachineMetric._({
    this.id,
    required this.machineId,
    this.machine,
    required this.cpuPercent,
    required this.memoryUsedMb,
    required this.memoryTotalMb,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  factory MachineMetric({
    int? id,
    required int machineId,
    _i0hti3f2.Machine? machine,
    required double cpuPercent,
    required int memoryUsedMb,
    required int memoryTotalMb,
    DateTime? recordedAt,
  }) = _MachineMetricImpl;

  factory MachineMetric.fromJson(Map<String, dynamic> jsonSerialization) {
    return MachineMetric(
      id: jsonSerialization['id'] as int?,
      machineId: jsonSerialization['machineId'] as int,
      machine: jsonSerialization['machine'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<_i0hti3f2.Machine>(
              jsonSerialization['machine'],
            ),
      cpuPercent: (jsonSerialization['cpuPercent'] as num).toDouble(),
      memoryUsedMb: jsonSerialization['memoryUsedMb'] as int,
      memoryTotalMb: jsonSerialization['memoryTotalMb'] as int,
      recordedAt: jsonSerialization['recordedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['recordedAt']),
    );
  }

  static final t = MachineMetricTable();

  static const db = MachineMetricRepository._();

  @override
  int? id;

  int machineId;

  /// onDelete=Cascade: metrics are disposable telemetry, not history worth
  /// preserving once the machine itself is gone (unlike Task, kept as an
  /// audit trail via onDelete=SetNull).
  _i0hti3f2.Machine? machine;

  double cpuPercent;

  int memoryUsedMb;

  int memoryTotalMb;

  DateTime recordedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [MachineMetric]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MachineMetric copyWith({
    int? id,
    int? machineId,
    _i0hti3f2.Machine? machine,
    double? cpuPercent,
    int? memoryUsedMb,
    int? memoryTotalMb,
    DateTime? recordedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MachineMetric',
      if (id != null) 'id': id,
      'machineId': machineId,
      if (machine != null) 'machine': machine?.toJson(),
      'cpuPercent': cpuPercent,
      'memoryUsedMb': memoryUsedMb,
      'memoryTotalMb': memoryTotalMb,
      'recordedAt': recordedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MachineMetric',
      if (id != null) 'id': id,
      'machineId': machineId,
      if (machine != null) 'machine': machine?.toJsonForProtocol(),
      'cpuPercent': cpuPercent,
      'memoryUsedMb': memoryUsedMb,
      'memoryTotalMb': memoryTotalMb,
      'recordedAt': recordedAt.toJson(),
    };
  }

  static MachineMetricInclude include({_i0hti3f2.MachineInclude? machine}) {
    return MachineMetricInclude._(machine: machine);
  }

  static MachineMetricIncludeList includeList({
    _is.WhereExpressionBuilder<MachineMetricTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MachineMetricTable>? orderBy,
    _is.OrderByListBuilder<MachineMetricTable>? orderByList,
    MachineMetricInclude? include,
  }) {
    return MachineMetricIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MachineMetric.t),
      orderByList: orderByList?.call(MachineMetric.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MachineMetricImpl extends MachineMetric {
  _MachineMetricImpl({
    int? id,
    required int machineId,
    _i0hti3f2.Machine? machine,
    required double cpuPercent,
    required int memoryUsedMb,
    required int memoryTotalMb,
    DateTime? recordedAt,
  }) : super._(
         id: id,
         machineId: machineId,
         machine: machine,
         cpuPercent: cpuPercent,
         memoryUsedMb: memoryUsedMb,
         memoryTotalMb: memoryTotalMb,
         recordedAt: recordedAt,
       );

  /// Returns a shallow copy of this [MachineMetric]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MachineMetric copyWith({
    Object? id = _Undefined,
    int? machineId,
    Object? machine = _Undefined,
    double? cpuPercent,
    int? memoryUsedMb,
    int? memoryTotalMb,
    DateTime? recordedAt,
  }) {
    return MachineMetric(
      id: id is int? ? id : this.id,
      machineId: machineId ?? this.machineId,
      machine: machine is _i0hti3f2.Machine?
          ? machine
          : this.machine?.copyWith(),
      cpuPercent: cpuPercent ?? this.cpuPercent,
      memoryUsedMb: memoryUsedMb ?? this.memoryUsedMb,
      memoryTotalMb: memoryTotalMb ?? this.memoryTotalMb,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}

class MachineMetricUpdateTable extends _is.UpdateTable<MachineMetricTable> {
  MachineMetricUpdateTable(super.table);

  _is.ColumnValue<int, int> machineId(int value) => _is.ColumnValue(
    table.machineId,
    value,
  );

  _is.ColumnValue<double, double> cpuPercent(double value) => _is.ColumnValue(
    table.cpuPercent,
    value,
  );

  _is.ColumnValue<int, int> memoryUsedMb(int value) => _is.ColumnValue(
    table.memoryUsedMb,
    value,
  );

  _is.ColumnValue<int, int> memoryTotalMb(int value) => _is.ColumnValue(
    table.memoryTotalMb,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> recordedAt(DateTime value) =>
      _is.ColumnValue(
        table.recordedAt,
        value,
      );
}

class MachineMetricTable extends _is.Table<int?> {
  MachineMetricTable({super.tableRelation})
    : super(tableName: 'machine_metric') {
    updateTable = MachineMetricUpdateTable(this);
    machineId = _is.ColumnInt(
      'machineId',
      this,
    );
    cpuPercent = _is.ColumnDouble(
      'cpuPercent',
      this,
    );
    memoryUsedMb = _is.ColumnInt(
      'memoryUsedMb',
      this,
    );
    memoryTotalMb = _is.ColumnInt(
      'memoryTotalMb',
      this,
    );
    recordedAt = _is.ColumnDateTime(
      'recordedAt',
      this,
      hasDefault: true,
    );
  }

  late final MachineMetricUpdateTable updateTable;

  late final _is.ColumnInt machineId;

  /// onDelete=Cascade: metrics are disposable telemetry, not history worth
  /// preserving once the machine itself is gone (unlike Task, kept as an
  /// audit trail via onDelete=SetNull).
  _i0hti3f2.MachineTable? _machine;

  late final _is.ColumnDouble cpuPercent;

  late final _is.ColumnInt memoryUsedMb;

  late final _is.ColumnInt memoryTotalMb;

  late final _is.ColumnDateTime recordedAt;

  _i0hti3f2.MachineTable get machine {
    if (_machine != null) return _machine!;
    _machine = _is.createRelationTable(
      relationFieldName: 'machine',
      field: MachineMetric.t.machineId,
      foreignField: _i0hti3f2.Machine.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i0hti3f2.MachineTable(tableRelation: foreignTableRelation),
    );
    return _machine!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    machineId,
    cpuPercent,
    memoryUsedMb,
    memoryTotalMb,
    recordedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'machine') {
      return machine;
    }
    return null;
  }
}

class MachineMetricInclude extends _is.IncludeObject {
  MachineMetricInclude._({_i0hti3f2.MachineInclude? machine}) {
    _machine = machine;
  }

  _i0hti3f2.MachineInclude? _machine;

  @override
  Map<String, _is.Include?> get includes => {'machine': _machine};

  @override
  _is.Table<int?> get table => MachineMetric.t;
}

class MachineMetricIncludeList extends _is.IncludeList {
  MachineMetricIncludeList._({
    _is.WhereExpressionBuilder<MachineMetricTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MachineMetric.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => MachineMetric.t;
}

class MachineMetricRepository {
  const MachineMetricRepository._();

  final attachRow = const MachineMetricAttachRowRepository._();

  /// Returns a list of [MachineMetric]s matching the given query parameters.
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
  Future<List<MachineMetric>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MachineMetricTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MachineMetricTable>? orderBy,
    _is.OrderByListBuilder<MachineMetricTable>? orderByList,
    _is.Transaction? transaction,
    MachineMetricInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MachineMetric>(
      where: where?.call(MachineMetric.t),
      orderBy: orderBy?.call(MachineMetric.t),
      orderByList: orderByList?.call(MachineMetric.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [MachineMetric] matching the given query parameters.
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
  Future<MachineMetric?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MachineMetricTable>? where,
    int? offset,
    _is.OrderByBuilder<MachineMetricTable>? orderBy,
    _is.OrderByListBuilder<MachineMetricTable>? orderByList,
    _is.Transaction? transaction,
    MachineMetricInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MachineMetric>(
      where: where?.call(MachineMetric.t),
      orderBy: orderBy?.call(MachineMetric.t),
      orderByList: orderByList?.call(MachineMetric.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MachineMetric] by its [id] or null if no such row exists.
  Future<MachineMetric?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    MachineMetricInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MachineMetric>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MachineMetric]s in the list and returns the inserted rows.
  ///
  /// The returned [MachineMetric]s will have their `id` fields set.
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
  Future<List<MachineMetric>> insert(
    _is.DatabaseSession session,
    List<MachineMetric> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<MachineMetric>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [MachineMetric] and returns the inserted row.
  ///
  /// The returned [MachineMetric] will have its `id` field set.
  Future<MachineMetric> insertRow(
    _is.DatabaseSession session,
    MachineMetric row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<MachineMetric>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [MachineMetric]s in the list and returns the resulting rows.
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
  /// The returned [MachineMetric]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MachineMetric>> upsert(
    _is.DatabaseSession session,
    List<MachineMetric> rows, {
    required _is.ColumnSelections<MachineMetricTable> conflictColumns,
    _is.ColumnSelections<MachineMetricTable>? updateColumns,
    _is.WhereExpressionBuilder<MachineMetricTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<MachineMetric>(
      rows,
      conflictColumns: conflictColumns(MachineMetric.t),
      updateColumns: updateColumns?.call(MachineMetric.t),
      updateWhere: updateWhere?.call(MachineMetric.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [MachineMetric] and returns the resulting row.
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
  /// The returned [MachineMetric] will have its `id` field set.
  Future<MachineMetric?> upsertRow(
    _is.DatabaseSession session,
    MachineMetric row, {
    required _is.ColumnSelections<MachineMetricTable> conflictColumns,
    _is.ColumnSelections<MachineMetricTable>? updateColumns,
    _is.WhereExpressionBuilder<MachineMetricTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<MachineMetric>(
      row,
      conflictColumns: conflictColumns(MachineMetric.t),
      updateColumns: updateColumns?.call(MachineMetric.t),
      updateWhere: updateWhere?.call(MachineMetric.t),
      transaction: transaction,
    );
  }

  /// Updates all [MachineMetric]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MachineMetric>> update(
    _is.DatabaseSession session,
    List<MachineMetric> rows, {
    _is.ColumnSelections<MachineMetricTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<MachineMetric>(
      rows,
      columns: columns?.call(MachineMetric.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [MachineMetric]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MachineMetric> updateRow(
    _is.DatabaseSession session,
    MachineMetric row, {
    _is.ColumnSelections<MachineMetricTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<MachineMetric>(
      row,
      columns: columns?.call(MachineMetric.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MachineMetric] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MachineMetric?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MachineMetricUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<MachineMetric>(
      id,
      columnValues: columnValues(MachineMetric.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MachineMetric]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MachineMetric>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MachineMetricUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<MachineMetricTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MachineMetricTable>? orderBy,
    _is.OrderByListBuilder<MachineMetricTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<MachineMetric>(
      columnValues: columnValues(MachineMetric.t.updateTable),
      where: where(MachineMetric.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MachineMetric.t),
      orderByList: orderByList?.call(MachineMetric.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [MachineMetric]s in the list and returns the deleted rows.
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
  Future<List<MachineMetric>> delete(
    _is.DatabaseSession session,
    List<MachineMetric> rows, {
    _is.OrderByBuilder<MachineMetricTable>? orderBy,
    _is.OrderByListBuilder<MachineMetricTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<MachineMetric>(
      rows,
      orderBy: orderBy?.call(MachineMetric.t),
      orderByList: orderByList?.call(MachineMetric.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [MachineMetric].
  Future<MachineMetric> deleteRow(
    _is.DatabaseSession session,
    MachineMetric row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MachineMetric>(
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
  Future<List<MachineMetric>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MachineMetricTable> where,
    _is.OrderByBuilder<MachineMetricTable>? orderBy,
    _is.OrderByListBuilder<MachineMetricTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<MachineMetric>(
      where: where(MachineMetric.t),
      orderBy: orderBy?.call(MachineMetric.t),
      orderByList: orderByList?.call(MachineMetric.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MachineMetricTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<MachineMetric>(
      where: where?.call(MachineMetric.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MachineMetric] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MachineMetricTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MachineMetric>(
      where: where(MachineMetric.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class MachineMetricAttachRowRepository {
  const MachineMetricAttachRowRepository._();

  /// Creates a relation between the given [MachineMetric] and [Machine]
  /// by setting the [MachineMetric]'s foreign key `machineId` to refer to the [Machine].
  Future<void> machine(
    _is.DatabaseSession session,
    MachineMetric machineMetric,
    _i0hti3f2.Machine machine, {
    _is.Transaction? transaction,
  }) async {
    if (machineMetric.id == null) {
      throw ArgumentError.notNull('machineMetric.id');
    }
    if (machine.id == null) {
      throw ArgumentError.notNull('machine.id');
    }

    var $machineMetric = machineMetric.copyWith(machineId: machine.id);
    await session.db.updateRow<MachineMetric>(
      $machineMetric,
      columns: [MachineMetric.t.machineId],
      transaction: transaction,
    );
  }
}
