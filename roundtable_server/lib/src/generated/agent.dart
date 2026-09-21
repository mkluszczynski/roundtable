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
import 'agent_effort.dart' as _iexg9pz4;
import 'agent_execution_mode.dart' as _i4babe00;
import 'agent_role.dart' as _idfmm35v;
import 'agent_status.dart' as _i69bozh7;
import 'machine.dart' as _i0hti3f2;
import 'task.dart' as _iwn6t6fs;

/// A named persona hosted on a machine, with a role and its own status.
abstract class Agent implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Agent._({
    this.id,
    required this.machineId,
    this.machine,
    required this.name,
    _idfmm35v.AgentRole? role,
    this.defaultModel,
    this.defaultEffort,
    _i4babe00.AgentExecutionMode? executionMode,
    _i69bozh7.AgentStatus? status,
    DateTime? createdAt,
    this.tasks,
  }) : role = role ?? _idfmm35v.AgentRole.generalist,
       executionMode = executionMode ?? _i4babe00.AgentExecutionMode.native,
       status = status ?? _i69bozh7.AgentStatus.idle,
       createdAt = createdAt ?? DateTime.now();

  factory Agent({
    int? id,
    required int machineId,
    _i0hti3f2.Machine? machine,
    required String name,
    _idfmm35v.AgentRole? role,
    String? defaultModel,
    _iexg9pz4.AgentEffort? defaultEffort,
    _i4babe00.AgentExecutionMode? executionMode,
    _i69bozh7.AgentStatus? status,
    DateTime? createdAt,
    List<_iwn6t6fs.Task>? tasks,
  }) = _AgentImpl;

  factory Agent.fromJson(Map<String, dynamic> jsonSerialization) {
    return Agent(
      id: jsonSerialization['id'] as int?,
      machineId: jsonSerialization['machineId'] as int,
      machine: jsonSerialization['machine'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<_i0hti3f2.Machine>(
              jsonSerialization['machine'],
            ),
      name: jsonSerialization['name'] as String,
      role: jsonSerialization['role'] == null
          ? null
          : _idfmm35v.AgentRole.fromJson((jsonSerialization['role'] as String)),
      defaultModel: jsonSerialization['defaultModel'] as String?,
      defaultEffort: jsonSerialization['defaultEffort'] == null
          ? null
          : _iexg9pz4.AgentEffort.fromJson(
              (jsonSerialization['defaultEffort'] as String),
            ),
      executionMode: jsonSerialization['executionMode'] == null
          ? null
          : _i4babe00.AgentExecutionMode.fromJson(
              (jsonSerialization['executionMode'] as String),
            ),
      status: jsonSerialization['status'] == null
          ? null
          : _i69bozh7.AgentStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      tasks: jsonSerialization['tasks'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<List<_iwn6t6fs.Task>>(
              jsonSerialization['tasks'],
            ),
    );
  }

  static final t = AgentTable();

  static const db = AgentRepository._();

  @override
  int? id;

  int machineId;

  _i0hti3f2.Machine? machine;

  /// The agent's display name.
  String name;

  _idfmm35v.AgentRole role;

  /// e.g. "claude-opus-4-7" — deliberately String, not an enum: model names change more often than
  /// it's worth migrating the schema for.
  String? defaultModel;

  _iexg9pz4.AgentEffort? defaultEffort;

  /// docker: implementation deferred.
  _i4babe00.AgentExecutionMode executionMode;

  /// "offline" deliberately doesn't exist here — that follows from Machine.status.
  _i69bozh7.AgentStatus status;

  DateTime createdAt;

  List<_iwn6t6fs.Task>? tasks;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Agent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Agent copyWith({
    int? id,
    int? machineId,
    _i0hti3f2.Machine? machine,
    String? name,
    _idfmm35v.AgentRole? role,
    String? defaultModel,
    _iexg9pz4.AgentEffort? defaultEffort,
    _i4babe00.AgentExecutionMode? executionMode,
    _i69bozh7.AgentStatus? status,
    DateTime? createdAt,
    List<_iwn6t6fs.Task>? tasks,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Agent',
      if (id != null) 'id': id,
      'machineId': machineId,
      if (machine != null) 'machine': machine?.toJson(),
      'name': name,
      'role': role.toJson(),
      if (defaultModel != null) 'defaultModel': defaultModel,
      if (defaultEffort != null) 'defaultEffort': defaultEffort?.toJson(),
      'executionMode': executionMode.toJson(),
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
      if (tasks != null) 'tasks': tasks?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Agent',
      if (id != null) 'id': id,
      'machineId': machineId,
      if (machine != null) 'machine': machine?.toJsonForProtocol(),
      'name': name,
      'role': role.toJson(),
      if (defaultModel != null) 'defaultModel': defaultModel,
      if (defaultEffort != null) 'defaultEffort': defaultEffort?.toJson(),
      'executionMode': executionMode.toJson(),
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
      if (tasks != null)
        'tasks': tasks?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  static AgentInclude include({
    _i0hti3f2.MachineInclude? machine,
    _iwn6t6fs.TaskIncludeList? tasks,
  }) {
    return AgentInclude._(
      machine: machine,
      tasks: tasks,
    );
  }

  static AgentIncludeList includeList({
    _is.WhereExpressionBuilder<AgentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AgentTable>? orderBy,
    _is.OrderByListBuilder<AgentTable>? orderByList,
    AgentInclude? include,
  }) {
    return AgentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Agent.t),
      orderByList: orderByList?.call(Agent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AgentImpl extends Agent {
  _AgentImpl({
    int? id,
    required int machineId,
    _i0hti3f2.Machine? machine,
    required String name,
    _idfmm35v.AgentRole? role,
    String? defaultModel,
    _iexg9pz4.AgentEffort? defaultEffort,
    _i4babe00.AgentExecutionMode? executionMode,
    _i69bozh7.AgentStatus? status,
    DateTime? createdAt,
    List<_iwn6t6fs.Task>? tasks,
  }) : super._(
         id: id,
         machineId: machineId,
         machine: machine,
         name: name,
         role: role,
         defaultModel: defaultModel,
         defaultEffort: defaultEffort,
         executionMode: executionMode,
         status: status,
         createdAt: createdAt,
         tasks: tasks,
       );

  /// Returns a shallow copy of this [Agent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Agent copyWith({
    Object? id = _Undefined,
    int? machineId,
    Object? machine = _Undefined,
    String? name,
    _idfmm35v.AgentRole? role,
    Object? defaultModel = _Undefined,
    Object? defaultEffort = _Undefined,
    _i4babe00.AgentExecutionMode? executionMode,
    _i69bozh7.AgentStatus? status,
    DateTime? createdAt,
    Object? tasks = _Undefined,
  }) {
    return Agent(
      id: id is int? ? id : this.id,
      machineId: machineId ?? this.machineId,
      machine: machine is _i0hti3f2.Machine?
          ? machine
          : this.machine?.copyWith(),
      name: name ?? this.name,
      role: role ?? this.role,
      defaultModel: defaultModel is String? ? defaultModel : this.defaultModel,
      defaultEffort: defaultEffort is _iexg9pz4.AgentEffort?
          ? defaultEffort
          : this.defaultEffort,
      executionMode: executionMode ?? this.executionMode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      tasks: tasks is List<_iwn6t6fs.Task>?
          ? tasks
          : this.tasks?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class AgentUpdateTable extends _is.UpdateTable<AgentTable> {
  AgentUpdateTable(super.table);

  _is.ColumnValue<int, int> machineId(int value) => _is.ColumnValue(
    table.machineId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<_idfmm35v.AgentRole, _idfmm35v.AgentRole> role(
    _idfmm35v.AgentRole value,
  ) => _is.ColumnValue(
    table.role,
    value,
  );

  _is.ColumnValue<String, String> defaultModel(String? value) =>
      _is.ColumnValue(
        table.defaultModel,
        value,
      );

  _is.ColumnValue<_iexg9pz4.AgentEffort, _iexg9pz4.AgentEffort> defaultEffort(
    _iexg9pz4.AgentEffort? value,
  ) => _is.ColumnValue(
    table.defaultEffort,
    value,
  );

  _is.ColumnValue<_i4babe00.AgentExecutionMode, _i4babe00.AgentExecutionMode>
  executionMode(_i4babe00.AgentExecutionMode value) => _is.ColumnValue(
    table.executionMode,
    value,
  );

  _is.ColumnValue<_i69bozh7.AgentStatus, _i69bozh7.AgentStatus> status(
    _i69bozh7.AgentStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class AgentTable extends _is.Table<int?> {
  AgentTable({super.tableRelation}) : super(tableName: 'agent') {
    updateTable = AgentUpdateTable(this);
    machineId = _is.ColumnInt(
      'machineId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    role = _is.ColumnEnum(
      'role',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    defaultModel = _is.ColumnString(
      'defaultModel',
      this,
    );
    defaultEffort = _is.ColumnEnum(
      'defaultEffort',
      this,
      _is.EnumSerialization.byName,
    );
    executionMode = _is.ColumnEnum(
      'executionMode',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final AgentUpdateTable updateTable;

  late final _is.ColumnInt machineId;

  _i0hti3f2.MachineTable? _machine;

  /// The agent's display name.
  late final _is.ColumnString name;

  late final _is.ColumnEnum<_idfmm35v.AgentRole> role;

  /// e.g. "claude-opus-4-7" — deliberately String, not an enum: model names change more often than
  /// it's worth migrating the schema for.
  late final _is.ColumnString defaultModel;

  late final _is.ColumnEnum<_iexg9pz4.AgentEffort> defaultEffort;

  /// docker: implementation deferred.
  late final _is.ColumnEnum<_i4babe00.AgentExecutionMode> executionMode;

  /// "offline" deliberately doesn't exist here — that follows from Machine.status.
  late final _is.ColumnEnum<_i69bozh7.AgentStatus> status;

  late final _is.ColumnDateTime createdAt;

  _iwn6t6fs.TaskTable? ___tasks;

  _is.ManyRelation<_iwn6t6fs.TaskTable>? _tasks;

  _i0hti3f2.MachineTable get machine {
    if (_machine != null) return _machine!;
    _machine = _is.createRelationTable(
      relationFieldName: 'machine',
      field: Agent.t.machineId,
      foreignField: _i0hti3f2.Machine.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i0hti3f2.MachineTable(tableRelation: foreignTableRelation),
    );
    return _machine!;
  }

  _iwn6t6fs.TaskTable get __tasks {
    if (___tasks != null) return ___tasks!;
    ___tasks = _is.createRelationTable(
      relationFieldName: '__tasks',
      field: Agent.t.id,
      foreignField: _iwn6t6fs.Task.t.agentId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iwn6t6fs.TaskTable(tableRelation: foreignTableRelation),
    );
    return ___tasks!;
  }

  _is.ManyRelation<_iwn6t6fs.TaskTable> get tasks {
    if (_tasks != null) return _tasks!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'tasks',
      field: Agent.t.id,
      foreignField: _iwn6t6fs.Task.t.agentId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iwn6t6fs.TaskTable(tableRelation: foreignTableRelation),
    );
    _tasks = _is.ManyRelation<_iwn6t6fs.TaskTable>(
      tableWithRelations: relationTable,
      table: _iwn6t6fs.TaskTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _tasks!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    machineId,
    name,
    role,
    defaultModel,
    defaultEffort,
    executionMode,
    status,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'machine') {
      return machine;
    }
    if (relationField == 'tasks') {
      return __tasks;
    }
    return null;
  }
}

class AgentInclude extends _is.IncludeObject {
  AgentInclude._({
    _i0hti3f2.MachineInclude? machine,
    _iwn6t6fs.TaskIncludeList? tasks,
  }) {
    _machine = machine;
    _tasks = tasks;
  }

  _i0hti3f2.MachineInclude? _machine;

  _iwn6t6fs.TaskIncludeList? _tasks;

  @override
  Map<String, _is.Include?> get includes => {
    'machine': _machine,
    'tasks': _tasks,
  };

  @override
  _is.Table<int?> get table => Agent.t;
}

class AgentIncludeList extends _is.IncludeList {
  AgentIncludeList._({
    _is.WhereExpressionBuilder<AgentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Agent.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Agent.t;
}

class AgentRepository {
  const AgentRepository._();

  final attach = const AgentAttachRepository._();

  final attachRow = const AgentAttachRowRepository._();

  final detach = const AgentDetachRepository._();

  final detachRow = const AgentDetachRowRepository._();

  /// Returns a list of [Agent]s matching the given query parameters.
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
  Future<List<Agent>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AgentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AgentTable>? orderBy,
    _is.OrderByListBuilder<AgentTable>? orderByList,
    _is.Transaction? transaction,
    AgentInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Agent>(
      where: where?.call(Agent.t),
      orderBy: orderBy?.call(Agent.t),
      orderByList: orderByList?.call(Agent.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Agent] matching the given query parameters.
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
  Future<Agent?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AgentTable>? where,
    int? offset,
    _is.OrderByBuilder<AgentTable>? orderBy,
    _is.OrderByListBuilder<AgentTable>? orderByList,
    _is.Transaction? transaction,
    AgentInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Agent>(
      where: where?.call(Agent.t),
      orderBy: orderBy?.call(Agent.t),
      orderByList: orderByList?.call(Agent.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Agent] by its [id] or null if no such row exists.
  Future<Agent?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    AgentInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Agent>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Agent]s in the list and returns the inserted rows.
  ///
  /// The returned [Agent]s will have their `id` fields set.
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
  Future<List<Agent>> insert(
    _is.DatabaseSession session,
    List<Agent> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Agent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Agent] and returns the inserted row.
  ///
  /// The returned [Agent] will have its `id` field set.
  Future<Agent> insertRow(
    _is.DatabaseSession session,
    Agent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Agent>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Agent]s in the list and returns the resulting rows.
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
  /// The returned [Agent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Agent>> upsert(
    _is.DatabaseSession session,
    List<Agent> rows, {
    required _is.ColumnSelections<AgentTable> conflictColumns,
    _is.ColumnSelections<AgentTable>? updateColumns,
    _is.WhereExpressionBuilder<AgentTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Agent>(
      rows,
      conflictColumns: conflictColumns(Agent.t),
      updateColumns: updateColumns?.call(Agent.t),
      updateWhere: updateWhere?.call(Agent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Agent] and returns the resulting row.
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
  /// The returned [Agent] will have its `id` field set.
  Future<Agent?> upsertRow(
    _is.DatabaseSession session,
    Agent row, {
    required _is.ColumnSelections<AgentTable> conflictColumns,
    _is.ColumnSelections<AgentTable>? updateColumns,
    _is.WhereExpressionBuilder<AgentTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Agent>(
      row,
      conflictColumns: conflictColumns(Agent.t),
      updateColumns: updateColumns?.call(Agent.t),
      updateWhere: updateWhere?.call(Agent.t),
      transaction: transaction,
    );
  }

  /// Updates all [Agent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Agent>> update(
    _is.DatabaseSession session,
    List<Agent> rows, {
    _is.ColumnSelections<AgentTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Agent>(
      rows,
      columns: columns?.call(Agent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Agent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Agent> updateRow(
    _is.DatabaseSession session,
    Agent row, {
    _is.ColumnSelections<AgentTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Agent>(
      row,
      columns: columns?.call(Agent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Agent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Agent?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<AgentUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Agent>(
      id,
      columnValues: columnValues(Agent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Agent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Agent>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AgentUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AgentTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AgentTable>? orderBy,
    _is.OrderByListBuilder<AgentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Agent>(
      columnValues: columnValues(Agent.t.updateTable),
      where: where(Agent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Agent.t),
      orderByList: orderByList?.call(Agent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Agent]s in the list and returns the deleted rows.
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
  Future<List<Agent>> delete(
    _is.DatabaseSession session,
    List<Agent> rows, {
    _is.OrderByBuilder<AgentTable>? orderBy,
    _is.OrderByListBuilder<AgentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Agent>(
      rows,
      orderBy: orderBy?.call(Agent.t),
      orderByList: orderByList?.call(Agent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Agent].
  Future<Agent> deleteRow(
    _is.DatabaseSession session,
    Agent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Agent>(
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
  Future<List<Agent>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AgentTable> where,
    _is.OrderByBuilder<AgentTable>? orderBy,
    _is.OrderByListBuilder<AgentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Agent>(
      where: where(Agent.t),
      orderBy: orderBy?.call(Agent.t),
      orderByList: orderByList?.call(Agent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AgentTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Agent>(
      where: where?.call(Agent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Agent] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AgentTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Agent>(
      where: where(Agent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class AgentAttachRepository {
  const AgentAttachRepository._();

  /// Creates a relation between this [Agent] and the given [Task]s
  /// by setting each [Task]'s foreign key `agentId` to refer to this [Agent].
  Future<void> tasks(
    _is.DatabaseSession session,
    Agent agent,
    List<_iwn6t6fs.Task> task, {
    _is.Transaction? transaction,
  }) async {
    if (task.any((e) => e.id == null)) {
      throw ArgumentError.notNull('task.id');
    }
    if (agent.id == null) {
      throw ArgumentError.notNull('agent.id');
    }

    var $task = task.map((e) => e.copyWith(agentId: agent.id)).toList();
    await session.db.update<_iwn6t6fs.Task>(
      $task,
      columns: [_iwn6t6fs.Task.t.agentId],
      transaction: transaction,
    );
  }
}

class AgentAttachRowRepository {
  const AgentAttachRowRepository._();

  /// Creates a relation between the given [Agent] and [Machine]
  /// by setting the [Agent]'s foreign key `machineId` to refer to the [Machine].
  Future<void> machine(
    _is.DatabaseSession session,
    Agent agent,
    _i0hti3f2.Machine machine, {
    _is.Transaction? transaction,
  }) async {
    if (agent.id == null) {
      throw ArgumentError.notNull('agent.id');
    }
    if (machine.id == null) {
      throw ArgumentError.notNull('machine.id');
    }

    var $agent = agent.copyWith(machineId: machine.id);
    await session.db.updateRow<Agent>(
      $agent,
      columns: [Agent.t.machineId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Agent] and the given [Task]
  /// by setting the [Task]'s foreign key `agentId` to refer to this [Agent].
  Future<void> tasks(
    _is.DatabaseSession session,
    Agent agent,
    _iwn6t6fs.Task task, {
    _is.Transaction? transaction,
  }) async {
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }
    if (agent.id == null) {
      throw ArgumentError.notNull('agent.id');
    }

    var $task = task.copyWith(agentId: agent.id);
    await session.db.updateRow<_iwn6t6fs.Task>(
      $task,
      columns: [_iwn6t6fs.Task.t.agentId],
      transaction: transaction,
    );
  }
}

class AgentDetachRepository {
  const AgentDetachRepository._();

  /// Detaches the relation between this [Agent] and the given [Task]
  /// by setting the [Task]'s foreign key `agentId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> tasks(
    _is.DatabaseSession session,
    List<_iwn6t6fs.Task> task, {
    _is.Transaction? transaction,
  }) async {
    if (task.any((e) => e.id == null)) {
      throw ArgumentError.notNull('task.id');
    }

    var $task = task.map((e) => e.copyWith(agentId: null)).toList();
    await session.db.update<_iwn6t6fs.Task>(
      $task,
      columns: [_iwn6t6fs.Task.t.agentId],
      transaction: transaction,
    );
  }
}

class AgentDetachRowRepository {
  const AgentDetachRowRepository._();

  /// Detaches the relation between this [Agent] and the given [Task]
  /// by setting the [Task]'s foreign key `agentId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> tasks(
    _is.DatabaseSession session,
    _iwn6t6fs.Task task, {
    _is.Transaction? transaction,
  }) async {
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $task = task.copyWith(agentId: null);
    await session.db.updateRow<_iwn6t6fs.Task>(
      $task,
      columns: [_iwn6t6fs.Task.t.agentId],
      transaction: transaction,
    );
  }
}
