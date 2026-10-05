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

/// An agent's specialty, edited in the panel's Settings. Its [prompt] is
/// the static prefix of every task and review prompt the agent gets.
/// Context, not a permission restriction.
abstract class AgentRoleDefinition
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  AgentRoleDefinition._({
    this.id,
    required this.name,
    this.description,
    required this.prompt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AgentRoleDefinition({
    int? id,
    required String name,
    String? description,
    required String prompt,
    DateTime? createdAt,
  }) = _AgentRoleDefinitionImpl;

  factory AgentRoleDefinition.fromJson(Map<String, dynamic> jsonSerialization) {
    return AgentRoleDefinition(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      prompt: jsonSerialization['prompt'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = AgentRoleDefinitionTable();

  static const db = AgentRoleDefinitionRepository._();

  @override
  int? id;

  /// Shown on agent cards, e.g. "backend".
  String name;

  /// One line for the role pickers.
  String? description;

  /// Prompt prefix; `{name}` is replaced with the agent's own name.
  String prompt;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [AgentRoleDefinition]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AgentRoleDefinition copyWith({
    int? id,
    String? name,
    String? description,
    String? prompt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AgentRoleDefinition',
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'prompt': prompt,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AgentRoleDefinition',
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'prompt': prompt,
      'createdAt': createdAt.toJson(),
    };
  }

  static AgentRoleDefinitionInclude include() {
    return AgentRoleDefinitionInclude._();
  }

  static AgentRoleDefinitionIncludeList includeList({
    _is.WhereExpressionBuilder<AgentRoleDefinitionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AgentRoleDefinitionTable>? orderBy,
    _is.OrderByListBuilder<AgentRoleDefinitionTable>? orderByList,
    AgentRoleDefinitionInclude? include,
  }) {
    return AgentRoleDefinitionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AgentRoleDefinition.t),
      orderByList: orderByList?.call(AgentRoleDefinition.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AgentRoleDefinitionImpl extends AgentRoleDefinition {
  _AgentRoleDefinitionImpl({
    int? id,
    required String name,
    String? description,
    required String prompt,
    DateTime? createdAt,
  }) : super._(
         id: id,
         name: name,
         description: description,
         prompt: prompt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AgentRoleDefinition]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AgentRoleDefinition copyWith({
    Object? id = _Undefined,
    String? name,
    Object? description = _Undefined,
    String? prompt,
    DateTime? createdAt,
  }) {
    return AgentRoleDefinition(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AgentRoleDefinitionUpdateTable
    extends _is.UpdateTable<AgentRoleDefinitionTable> {
  AgentRoleDefinitionUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> description(String? value) => _is.ColumnValue(
    table.description,
    value,
  );

  _is.ColumnValue<String, String> prompt(String value) => _is.ColumnValue(
    table.prompt,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class AgentRoleDefinitionTable extends _is.Table<int?> {
  AgentRoleDefinitionTable({super.tableRelation})
    : super(tableName: 'agent_role') {
    updateTable = AgentRoleDefinitionUpdateTable(this);
    name = _is.ColumnString(
      'name',
      this,
    );
    description = _is.ColumnString(
      'description',
      this,
    );
    prompt = _is.ColumnString(
      'prompt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final AgentRoleDefinitionUpdateTable updateTable;

  /// Shown on agent cards, e.g. "backend".
  late final _is.ColumnString name;

  /// One line for the role pickers.
  late final _is.ColumnString description;

  /// Prompt prefix; `{name}` is replaced with the agent's own name.
  late final _is.ColumnString prompt;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    name,
    description,
    prompt,
    createdAt,
  ];
}

class AgentRoleDefinitionInclude extends _is.IncludeObject {
  AgentRoleDefinitionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => AgentRoleDefinition.t;
}

class AgentRoleDefinitionIncludeList extends _is.IncludeList {
  AgentRoleDefinitionIncludeList._({
    _is.WhereExpressionBuilder<AgentRoleDefinitionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AgentRoleDefinition.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => AgentRoleDefinition.t;
}

class AgentRoleDefinitionRepository {
  const AgentRoleDefinitionRepository._();

  /// Returns a list of [AgentRoleDefinition]s matching the given query parameters.
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
  Future<List<AgentRoleDefinition>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AgentRoleDefinitionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AgentRoleDefinitionTable>? orderBy,
    _is.OrderByListBuilder<AgentRoleDefinitionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AgentRoleDefinition>(
      where: where?.call(AgentRoleDefinition.t),
      orderBy: orderBy?.call(AgentRoleDefinition.t),
      orderByList: orderByList?.call(AgentRoleDefinition.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AgentRoleDefinition] matching the given query parameters.
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
  Future<AgentRoleDefinition?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AgentRoleDefinitionTable>? where,
    int? offset,
    _is.OrderByBuilder<AgentRoleDefinitionTable>? orderBy,
    _is.OrderByListBuilder<AgentRoleDefinitionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AgentRoleDefinition>(
      where: where?.call(AgentRoleDefinition.t),
      orderBy: orderBy?.call(AgentRoleDefinition.t),
      orderByList: orderByList?.call(AgentRoleDefinition.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AgentRoleDefinition] by its [id] or null if no such row exists.
  Future<AgentRoleDefinition?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AgentRoleDefinition>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AgentRoleDefinition]s in the list and returns the inserted rows.
  ///
  /// The returned [AgentRoleDefinition]s will have their `id` fields set.
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
  Future<List<AgentRoleDefinition>> insert(
    _is.DatabaseSession session,
    List<AgentRoleDefinition> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AgentRoleDefinition>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AgentRoleDefinition] and returns the inserted row.
  ///
  /// The returned [AgentRoleDefinition] will have its `id` field set.
  Future<AgentRoleDefinition> insertRow(
    _is.DatabaseSession session,
    AgentRoleDefinition row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AgentRoleDefinition>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AgentRoleDefinition]s in the list and returns the resulting rows.
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
  /// The returned [AgentRoleDefinition]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AgentRoleDefinition>> upsert(
    _is.DatabaseSession session,
    List<AgentRoleDefinition> rows, {
    required _is.ColumnSelections<AgentRoleDefinitionTable> conflictColumns,
    _is.ColumnSelections<AgentRoleDefinitionTable>? updateColumns,
    _is.WhereExpressionBuilder<AgentRoleDefinitionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AgentRoleDefinition>(
      rows,
      conflictColumns: conflictColumns(AgentRoleDefinition.t),
      updateColumns: updateColumns?.call(AgentRoleDefinition.t),
      updateWhere: updateWhere?.call(AgentRoleDefinition.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AgentRoleDefinition] and returns the resulting row.
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
  /// The returned [AgentRoleDefinition] will have its `id` field set.
  Future<AgentRoleDefinition?> upsertRow(
    _is.DatabaseSession session,
    AgentRoleDefinition row, {
    required _is.ColumnSelections<AgentRoleDefinitionTable> conflictColumns,
    _is.ColumnSelections<AgentRoleDefinitionTable>? updateColumns,
    _is.WhereExpressionBuilder<AgentRoleDefinitionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AgentRoleDefinition>(
      row,
      conflictColumns: conflictColumns(AgentRoleDefinition.t),
      updateColumns: updateColumns?.call(AgentRoleDefinition.t),
      updateWhere: updateWhere?.call(AgentRoleDefinition.t),
      transaction: transaction,
    );
  }

  /// Updates all [AgentRoleDefinition]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AgentRoleDefinition>> update(
    _is.DatabaseSession session,
    List<AgentRoleDefinition> rows, {
    _is.ColumnSelections<AgentRoleDefinitionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AgentRoleDefinition>(
      rows,
      columns: columns?.call(AgentRoleDefinition.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AgentRoleDefinition]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AgentRoleDefinition> updateRow(
    _is.DatabaseSession session,
    AgentRoleDefinition row, {
    _is.ColumnSelections<AgentRoleDefinitionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AgentRoleDefinition>(
      row,
      columns: columns?.call(AgentRoleDefinition.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AgentRoleDefinition] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AgentRoleDefinition?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<AgentRoleDefinitionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AgentRoleDefinition>(
      id,
      columnValues: columnValues(AgentRoleDefinition.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AgentRoleDefinition]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AgentRoleDefinition>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AgentRoleDefinitionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<AgentRoleDefinitionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AgentRoleDefinitionTable>? orderBy,
    _is.OrderByListBuilder<AgentRoleDefinitionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AgentRoleDefinition>(
      columnValues: columnValues(AgentRoleDefinition.t.updateTable),
      where: where(AgentRoleDefinition.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AgentRoleDefinition.t),
      orderByList: orderByList?.call(AgentRoleDefinition.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AgentRoleDefinition]s in the list and returns the deleted rows.
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
  Future<List<AgentRoleDefinition>> delete(
    _is.DatabaseSession session,
    List<AgentRoleDefinition> rows, {
    _is.OrderByBuilder<AgentRoleDefinitionTable>? orderBy,
    _is.OrderByListBuilder<AgentRoleDefinitionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AgentRoleDefinition>(
      rows,
      orderBy: orderBy?.call(AgentRoleDefinition.t),
      orderByList: orderByList?.call(AgentRoleDefinition.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AgentRoleDefinition].
  Future<AgentRoleDefinition> deleteRow(
    _is.DatabaseSession session,
    AgentRoleDefinition row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AgentRoleDefinition>(
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
  Future<List<AgentRoleDefinition>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AgentRoleDefinitionTable> where,
    _is.OrderByBuilder<AgentRoleDefinitionTable>? orderBy,
    _is.OrderByListBuilder<AgentRoleDefinitionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AgentRoleDefinition>(
      where: where(AgentRoleDefinition.t),
      orderBy: orderBy?.call(AgentRoleDefinition.t),
      orderByList: orderByList?.call(AgentRoleDefinition.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AgentRoleDefinitionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AgentRoleDefinition>(
      where: where?.call(AgentRoleDefinition.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AgentRoleDefinition] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AgentRoleDefinitionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AgentRoleDefinition>(
      where: where(AgentRoleDefinition.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
