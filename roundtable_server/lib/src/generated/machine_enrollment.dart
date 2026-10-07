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
import 'package:serverpod/serverpod.dart' as _is;

/// A one-time install token from the panel's "Add machine" dialog. The
/// machine itself is only created when install-agent.sh redeems it via
/// MachineEndpoint.enroll, so an abandoned dialog or a failed install leaves
/// no machine behind (docs/FLOWS.md §1).
abstract class MachineEnrollment
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  MachineEnrollment._({
    this.id,
    required this.tokenHash,
    this.name,
    required this.expiresAt,
    this.machineId,
  });

  factory MachineEnrollment({
    int? id,
    required String tokenHash,
    String? name,
    required DateTime expiresAt,
    int? machineId,
  }) = _MachineEnrollmentImpl;

  factory MachineEnrollment.fromJson(Map<String, dynamic> jsonSerialization) {
    return MachineEnrollment(
      id: jsonSerialization['id'] as int?,
      tokenHash: jsonSerialization['tokenHash'] as String,
      name: jsonSerialization['name'] as String?,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      machineId: jsonSerialization['machineId'] as int?,
    );
  }

  static final t = MachineEnrollmentTable();

  static const db = MachineEnrollmentRepository._();

  @override
  int? id;

  /// Hash of the raw enrollment token. The raw token is shown to the dev only once.
  String tokenHash;

  /// Name chosen in the panel. Null means the machine's hostname.
  String? name;

  DateTime expiresAt;

  /// The machine created by redeeming this token. Set means used.
  int? machineId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [MachineEnrollment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MachineEnrollment copyWith({
    int? id,
    String? tokenHash,
    String? name,
    DateTime? expiresAt,
    int? machineId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MachineEnrollment',
      if (id != null) 'id': id,
      'tokenHash': tokenHash,
      if (name != null) 'name': name,
      'expiresAt': expiresAt.toJson(),
      if (machineId != null) 'machineId': machineId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static MachineEnrollmentInclude include() {
    return MachineEnrollmentInclude._();
  }

  static MachineEnrollmentIncludeList includeList({
    _is.WhereExpressionBuilder<MachineEnrollmentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MachineEnrollmentTable>? orderBy,
    _is.OrderByListBuilder<MachineEnrollmentTable>? orderByList,
    MachineEnrollmentInclude? include,
  }) {
    return MachineEnrollmentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MachineEnrollment.t),
      orderByList: orderByList?.call(MachineEnrollment.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MachineEnrollmentImpl extends MachineEnrollment {
  _MachineEnrollmentImpl({
    int? id,
    required String tokenHash,
    String? name,
    required DateTime expiresAt,
    int? machineId,
  }) : super._(
         id: id,
         tokenHash: tokenHash,
         name: name,
         expiresAt: expiresAt,
         machineId: machineId,
       );

  /// Returns a shallow copy of this [MachineEnrollment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MachineEnrollment copyWith({
    Object? id = _Undefined,
    String? tokenHash,
    Object? name = _Undefined,
    DateTime? expiresAt,
    Object? machineId = _Undefined,
  }) {
    return MachineEnrollment(
      id: id is int? ? id : this.id,
      tokenHash: tokenHash ?? this.tokenHash,
      name: name is String? ? name : this.name,
      expiresAt: expiresAt ?? this.expiresAt,
      machineId: machineId is int? ? machineId : this.machineId,
    );
  }
}

class MachineEnrollmentUpdateTable
    extends _is.UpdateTable<MachineEnrollmentTable> {
  MachineEnrollmentUpdateTable(super.table);

  _is.ColumnValue<String, String> tokenHash(String value) => _is.ColumnValue(
    table.tokenHash,
    value,
  );

  _is.ColumnValue<String, String> name(String? value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<int, int> machineId(int? value) => _is.ColumnValue(
    table.machineId,
    value,
  );
}

class MachineEnrollmentTable extends _is.Table<int?> {
  MachineEnrollmentTable({super.tableRelation})
    : super(tableName: 'machine_enrollment') {
    updateTable = MachineEnrollmentUpdateTable(this);
    tokenHash = _is.ColumnString(
      'tokenHash',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    machineId = _is.ColumnInt(
      'machineId',
      this,
    );
  }

  late final MachineEnrollmentUpdateTable updateTable;

  /// Hash of the raw enrollment token. The raw token is shown to the dev only once.
  late final _is.ColumnString tokenHash;

  /// Name chosen in the panel. Null means the machine's hostname.
  late final _is.ColumnString name;

  late final _is.ColumnDateTime expiresAt;

  /// The machine created by redeeming this token. Set means used.
  late final _is.ColumnInt machineId;

  @override
  List<_is.Column> get columns => [
    id,
    tokenHash,
    name,
    expiresAt,
    machineId,
  ];
}

class MachineEnrollmentInclude extends _is.IncludeObject {
  MachineEnrollmentInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => MachineEnrollment.t;
}

class MachineEnrollmentIncludeList extends _is.IncludeList {
  MachineEnrollmentIncludeList._({
    _is.WhereExpressionBuilder<MachineEnrollmentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MachineEnrollment.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => MachineEnrollment.t;
}

class MachineEnrollmentRepository {
  const MachineEnrollmentRepository._();

  /// Returns a list of [MachineEnrollment]s matching the given query parameters.
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
  Future<List<MachineEnrollment>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MachineEnrollmentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MachineEnrollmentTable>? orderBy,
    _is.OrderByListBuilder<MachineEnrollmentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MachineEnrollment>(
      where: where?.call(MachineEnrollment.t),
      orderBy: orderBy?.call(MachineEnrollment.t),
      orderByList: orderByList?.call(MachineEnrollment.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [MachineEnrollment] matching the given query parameters.
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
  Future<MachineEnrollment?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MachineEnrollmentTable>? where,
    int? offset,
    _is.OrderByBuilder<MachineEnrollmentTable>? orderBy,
    _is.OrderByListBuilder<MachineEnrollmentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MachineEnrollment>(
      where: where?.call(MachineEnrollment.t),
      orderBy: orderBy?.call(MachineEnrollment.t),
      orderByList: orderByList?.call(MachineEnrollment.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MachineEnrollment] by its [id] or null if no such row exists.
  Future<MachineEnrollment?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MachineEnrollment>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MachineEnrollment]s in the list and returns the inserted rows.
  ///
  /// The returned [MachineEnrollment]s will have their `id` fields set.
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
  Future<List<MachineEnrollment>> insert(
    _is.DatabaseSession session,
    List<MachineEnrollment> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<MachineEnrollment>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [MachineEnrollment] and returns the inserted row.
  ///
  /// The returned [MachineEnrollment] will have its `id` field set.
  Future<MachineEnrollment> insertRow(
    _is.DatabaseSession session,
    MachineEnrollment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<MachineEnrollment>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [MachineEnrollment]s in the list and returns the resulting rows.
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
  /// The returned [MachineEnrollment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MachineEnrollment>> upsert(
    _is.DatabaseSession session,
    List<MachineEnrollment> rows, {
    required _is.ColumnSelections<MachineEnrollmentTable> conflictColumns,
    _is.ColumnSelections<MachineEnrollmentTable>? updateColumns,
    _is.WhereExpressionBuilder<MachineEnrollmentTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<MachineEnrollment>(
      rows,
      conflictColumns: conflictColumns(MachineEnrollment.t),
      updateColumns: updateColumns?.call(MachineEnrollment.t),
      updateWhere: updateWhere?.call(MachineEnrollment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [MachineEnrollment] and returns the resulting row.
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
  /// The returned [MachineEnrollment] will have its `id` field set.
  Future<MachineEnrollment?> upsertRow(
    _is.DatabaseSession session,
    MachineEnrollment row, {
    required _is.ColumnSelections<MachineEnrollmentTable> conflictColumns,
    _is.ColumnSelections<MachineEnrollmentTable>? updateColumns,
    _is.WhereExpressionBuilder<MachineEnrollmentTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<MachineEnrollment>(
      row,
      conflictColumns: conflictColumns(MachineEnrollment.t),
      updateColumns: updateColumns?.call(MachineEnrollment.t),
      updateWhere: updateWhere?.call(MachineEnrollment.t),
      transaction: transaction,
    );
  }

  /// Updates all [MachineEnrollment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MachineEnrollment>> update(
    _is.DatabaseSession session,
    List<MachineEnrollment> rows, {
    _is.ColumnSelections<MachineEnrollmentTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<MachineEnrollment>(
      rows,
      columns: columns?.call(MachineEnrollment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [MachineEnrollment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MachineEnrollment> updateRow(
    _is.DatabaseSession session,
    MachineEnrollment row, {
    _is.ColumnSelections<MachineEnrollmentTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<MachineEnrollment>(
      row,
      columns: columns?.call(MachineEnrollment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MachineEnrollment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MachineEnrollment?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MachineEnrollmentUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<MachineEnrollment>(
      id,
      columnValues: columnValues(MachineEnrollment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MachineEnrollment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MachineEnrollment>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MachineEnrollmentUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<MachineEnrollmentTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MachineEnrollmentTable>? orderBy,
    _is.OrderByListBuilder<MachineEnrollmentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<MachineEnrollment>(
      columnValues: columnValues(MachineEnrollment.t.updateTable),
      where: where(MachineEnrollment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MachineEnrollment.t),
      orderByList: orderByList?.call(MachineEnrollment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [MachineEnrollment]s in the list and returns the deleted rows.
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
  Future<List<MachineEnrollment>> delete(
    _is.DatabaseSession session,
    List<MachineEnrollment> rows, {
    _is.OrderByBuilder<MachineEnrollmentTable>? orderBy,
    _is.OrderByListBuilder<MachineEnrollmentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<MachineEnrollment>(
      rows,
      orderBy: orderBy?.call(MachineEnrollment.t),
      orderByList: orderByList?.call(MachineEnrollment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [MachineEnrollment].
  Future<MachineEnrollment> deleteRow(
    _is.DatabaseSession session,
    MachineEnrollment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MachineEnrollment>(
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
  Future<List<MachineEnrollment>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MachineEnrollmentTable> where,
    _is.OrderByBuilder<MachineEnrollmentTable>? orderBy,
    _is.OrderByListBuilder<MachineEnrollmentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<MachineEnrollment>(
      where: where(MachineEnrollment.t),
      orderBy: orderBy?.call(MachineEnrollment.t),
      orderByList: orderByList?.call(MachineEnrollment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MachineEnrollmentTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<MachineEnrollment>(
      where: where?.call(MachineEnrollment.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MachineEnrollment] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MachineEnrollmentTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MachineEnrollment>(
      where: where(MachineEnrollment.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
