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

/// A git repository that agents run tasks against.
abstract class Project
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Project._({
    this.id,
    required this.name,
    required this.repoUrl,
    this.repoAccessToken,
    this.dockerImage,
    DateTime? createdAt,
    this.tasks,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Project({
    int? id,
    required String name,
    required String repoUrl,
    String? repoAccessToken,
    String? dockerImage,
    DateTime? createdAt,
    List<_iwn6t6fs.Task>? tasks,
  }) = _ProjectImpl;

  factory Project.fromJson(Map<String, dynamic> jsonSerialization) {
    return Project(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      repoUrl: jsonSerialization['repoUrl'] as String,
      repoAccessToken: jsonSerialization['repoAccessToken'] as String?,
      dockerImage: jsonSerialization['dockerImage'] as String?,
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

  static final t = ProjectTable();

  static const db = ProjectRepository._();

  @override
  int? id;

  /// The project's display name.
  String name;

  /// The URL of the git repository.
  String repoUrl;

  /// Fine-grained GitHub PAT, scoped to a single repo. Never reaches the panel.
  String? repoAccessToken;

  /// Base image for agents in docker mode. Only relevant once docker execution mode is implemented.
  String? dockerImage;

  DateTime createdAt;

  List<_iwn6t6fs.Task>? tasks;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Project]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Project copyWith({
    int? id,
    String? name,
    String? repoUrl,
    String? repoAccessToken,
    String? dockerImage,
    DateTime? createdAt,
    List<_iwn6t6fs.Task>? tasks,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Project',
      if (id != null) 'id': id,
      'name': name,
      'repoUrl': repoUrl,
      if (repoAccessToken != null) 'repoAccessToken': repoAccessToken,
      if (dockerImage != null) 'dockerImage': dockerImage,
      'createdAt': createdAt.toJson(),
      if (tasks != null) 'tasks': tasks?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Project',
      if (id != null) 'id': id,
      'name': name,
      'repoUrl': repoUrl,
      if (dockerImage != null) 'dockerImage': dockerImage,
      'createdAt': createdAt.toJson(),
      if (tasks != null)
        'tasks': tasks?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  static ProjectInclude include({_iwn6t6fs.TaskIncludeList? tasks}) {
    return ProjectInclude._(tasks: tasks);
  }

  static ProjectIncludeList includeList({
    _is.WhereExpressionBuilder<ProjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProjectTable>? orderBy,
    _is.OrderByListBuilder<ProjectTable>? orderByList,
    ProjectInclude? include,
  }) {
    return ProjectIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProjectImpl extends Project {
  _ProjectImpl({
    int? id,
    required String name,
    required String repoUrl,
    String? repoAccessToken,
    String? dockerImage,
    DateTime? createdAt,
    List<_iwn6t6fs.Task>? tasks,
  }) : super._(
         id: id,
         name: name,
         repoUrl: repoUrl,
         repoAccessToken: repoAccessToken,
         dockerImage: dockerImage,
         createdAt: createdAt,
         tasks: tasks,
       );

  /// Returns a shallow copy of this [Project]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Project copyWith({
    Object? id = _Undefined,
    String? name,
    String? repoUrl,
    Object? repoAccessToken = _Undefined,
    Object? dockerImage = _Undefined,
    DateTime? createdAt,
    Object? tasks = _Undefined,
  }) {
    return Project(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      repoUrl: repoUrl ?? this.repoUrl,
      repoAccessToken: repoAccessToken is String?
          ? repoAccessToken
          : this.repoAccessToken,
      dockerImage: dockerImage is String? ? dockerImage : this.dockerImage,
      createdAt: createdAt ?? this.createdAt,
      tasks: tasks is List<_iwn6t6fs.Task>?
          ? tasks
          : this.tasks?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class ProjectUpdateTable extends _is.UpdateTable<ProjectTable> {
  ProjectUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> repoUrl(String value) => _is.ColumnValue(
    table.repoUrl,
    value,
  );

  _is.ColumnValue<String, String> repoAccessToken(String? value) =>
      _is.ColumnValue(
        table.repoAccessToken,
        value,
      );

  _is.ColumnValue<String, String> dockerImage(String? value) => _is.ColumnValue(
    table.dockerImage,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ProjectTable extends _is.Table<int?> {
  ProjectTable({super.tableRelation}) : super(tableName: 'project') {
    updateTable = ProjectUpdateTable(this);
    name = _is.ColumnString(
      'name',
      this,
    );
    repoUrl = _is.ColumnString(
      'repoUrl',
      this,
    );
    repoAccessToken = _is.ColumnString(
      'repoAccessToken',
      this,
    );
    dockerImage = _is.ColumnString(
      'dockerImage',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final ProjectUpdateTable updateTable;

  /// The project's display name.
  late final _is.ColumnString name;

  /// The URL of the git repository.
  late final _is.ColumnString repoUrl;

  /// Fine-grained GitHub PAT, scoped to a single repo. Never reaches the panel.
  late final _is.ColumnString repoAccessToken;

  /// Base image for agents in docker mode. Only relevant once docker execution mode is implemented.
  late final _is.ColumnString dockerImage;

  late final _is.ColumnDateTime createdAt;

  _iwn6t6fs.TaskTable? ___tasks;

  _is.ManyRelation<_iwn6t6fs.TaskTable>? _tasks;

  _iwn6t6fs.TaskTable get __tasks {
    if (___tasks != null) return ___tasks!;
    ___tasks = _is.createRelationTable(
      relationFieldName: '__tasks',
      field: Project.t.id,
      foreignField: _iwn6t6fs.Task.t.projectId,
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
      field: Project.t.id,
      foreignField: _iwn6t6fs.Task.t.projectId,
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
    name,
    repoUrl,
    repoAccessToken,
    dockerImage,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'tasks') {
      return __tasks;
    }
    return null;
  }
}

class ProjectInclude extends _is.IncludeObject {
  ProjectInclude._({_iwn6t6fs.TaskIncludeList? tasks}) {
    _tasks = tasks;
  }

  _iwn6t6fs.TaskIncludeList? _tasks;

  @override
  Map<String, _is.Include?> get includes => {'tasks': _tasks};

  @override
  _is.Table<int?> get table => Project.t;
}

class ProjectIncludeList extends _is.IncludeList {
  ProjectIncludeList._({
    _is.WhereExpressionBuilder<ProjectTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Project.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Project.t;
}

class ProjectRepository {
  const ProjectRepository._();

  final attach = const ProjectAttachRepository._();

  final attachRow = const ProjectAttachRowRepository._();

  /// Returns a list of [Project]s matching the given query parameters.
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
  Future<List<Project>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProjectTable>? orderBy,
    _is.OrderByListBuilder<ProjectTable>? orderByList,
    _is.Transaction? transaction,
    ProjectInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Project>(
      where: where?.call(Project.t),
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Project] matching the given query parameters.
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
  Future<Project?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProjectTable>? where,
    int? offset,
    _is.OrderByBuilder<ProjectTable>? orderBy,
    _is.OrderByListBuilder<ProjectTable>? orderByList,
    _is.Transaction? transaction,
    ProjectInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Project>(
      where: where?.call(Project.t),
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Project] by its [id] or null if no such row exists.
  Future<Project?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    ProjectInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Project>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Project]s in the list and returns the inserted rows.
  ///
  /// The returned [Project]s will have their `id` fields set.
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
  Future<List<Project>> insert(
    _is.DatabaseSession session,
    List<Project> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Project>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Project] and returns the inserted row.
  ///
  /// The returned [Project] will have its `id` field set.
  Future<Project> insertRow(
    _is.DatabaseSession session,
    Project row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Project>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Project]s in the list and returns the resulting rows.
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
  /// The returned [Project]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Project>> upsert(
    _is.DatabaseSession session,
    List<Project> rows, {
    required _is.ColumnSelections<ProjectTable> conflictColumns,
    _is.ColumnSelections<ProjectTable>? updateColumns,
    _is.WhereExpressionBuilder<ProjectTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Project>(
      rows,
      conflictColumns: conflictColumns(Project.t),
      updateColumns: updateColumns?.call(Project.t),
      updateWhere: updateWhere?.call(Project.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Project] and returns the resulting row.
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
  /// The returned [Project] will have its `id` field set.
  Future<Project?> upsertRow(
    _is.DatabaseSession session,
    Project row, {
    required _is.ColumnSelections<ProjectTable> conflictColumns,
    _is.ColumnSelections<ProjectTable>? updateColumns,
    _is.WhereExpressionBuilder<ProjectTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Project>(
      row,
      conflictColumns: conflictColumns(Project.t),
      updateColumns: updateColumns?.call(Project.t),
      updateWhere: updateWhere?.call(Project.t),
      transaction: transaction,
    );
  }

  /// Updates all [Project]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Project>> update(
    _is.DatabaseSession session,
    List<Project> rows, {
    _is.ColumnSelections<ProjectTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Project>(
      rows,
      columns: columns?.call(Project.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Project]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Project> updateRow(
    _is.DatabaseSession session,
    Project row, {
    _is.ColumnSelections<ProjectTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Project>(
      row,
      columns: columns?.call(Project.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Project] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Project?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ProjectUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Project>(
      id,
      columnValues: columnValues(Project.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Project]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Project>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ProjectUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ProjectTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProjectTable>? orderBy,
    _is.OrderByListBuilder<ProjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Project>(
      columnValues: columnValues(Project.t.updateTable),
      where: where(Project.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Project]s in the list and returns the deleted rows.
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
  Future<List<Project>> delete(
    _is.DatabaseSession session,
    List<Project> rows, {
    _is.OrderByBuilder<ProjectTable>? orderBy,
    _is.OrderByListBuilder<ProjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Project>(
      rows,
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Project].
  Future<Project> deleteRow(
    _is.DatabaseSession session,
    Project row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Project>(
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
  Future<List<Project>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProjectTable> where,
    _is.OrderByBuilder<ProjectTable>? orderBy,
    _is.OrderByListBuilder<ProjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Project>(
      where: where(Project.t),
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProjectTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Project>(
      where: where?.call(Project.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Project] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProjectTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Project>(
      where: where(Project.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ProjectAttachRepository {
  const ProjectAttachRepository._();

  /// Creates a relation between this [Project] and the given [Task]s
  /// by setting each [Task]'s foreign key `projectId` to refer to this [Project].
  Future<void> tasks(
    _is.DatabaseSession session,
    Project project,
    List<_iwn6t6fs.Task> task, {
    _is.Transaction? transaction,
  }) async {
    if (task.any((e) => e.id == null)) {
      throw ArgumentError.notNull('task.id');
    }
    if (project.id == null) {
      throw ArgumentError.notNull('project.id');
    }

    var $task = task.map((e) => e.copyWith(projectId: project.id)).toList();
    await session.db.update<_iwn6t6fs.Task>(
      $task,
      columns: [_iwn6t6fs.Task.t.projectId],
      transaction: transaction,
    );
  }
}

class ProjectAttachRowRepository {
  const ProjectAttachRowRepository._();

  /// Creates a relation between this [Project] and the given [Task]
  /// by setting the [Task]'s foreign key `projectId` to refer to this [Project].
  Future<void> tasks(
    _is.DatabaseSession session,
    Project project,
    _iwn6t6fs.Task task, {
    _is.Transaction? transaction,
  }) async {
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }
    if (project.id == null) {
      throw ArgumentError.notNull('project.id');
    }

    var $task = task.copyWith(projectId: project.id);
    await session.db.updateRow<_iwn6t6fs.Task>(
      $task,
      columns: [_iwn6t6fs.Task.t.projectId],
      transaction: transaction,
    );
  }
}
