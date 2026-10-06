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
import 'code_review_status.dart' as _i4rgwvgz;
import 'code_review_verdict.dart' as _ijks0ur1;
import 'review_comment.dart' as _itpwl327;
import 'task.dart' as _iwn6t6fs;

/// One AI code review of a task's PR, done by a reviewer agent (possibly on another machine).
abstract class CodeReview
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  CodeReview._({
    this.id,
    required this.taskId,
    this.task,
    this.reviewerAgentId,
    this.reviewerAgent,
    _i4rgwvgz.CodeReviewStatus? status,
    this.summary,
    this.verdict,
    this.failureReason,
    this.githubReviewId,
    DateTime? createdAt,
    this.finishedAt,
    this.comments,
  }) : status = status ?? _i4rgwvgz.CodeReviewStatus.queued,
       createdAt = createdAt ?? DateTime.now();

  factory CodeReview({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    _i4rgwvgz.CodeReviewStatus? status,
    String? summary,
    _ijks0ur1.CodeReviewVerdict? verdict,
    String? failureReason,
    int? githubReviewId,
    DateTime? createdAt,
    DateTime? finishedAt,
    List<_itpwl327.ReviewComment>? comments,
  }) = _CodeReviewImpl;

  factory CodeReview.fromJson(Map<String, dynamic> jsonSerialization) {
    return CodeReview(
      id: jsonSerialization['id'] as int?,
      taskId: jsonSerialization['taskId'] as int,
      task: jsonSerialization['task'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<_iwn6t6fs.Task>(
              jsonSerialization['task'],
            ),
      reviewerAgentId: jsonSerialization['reviewerAgentId'] as int?,
      reviewerAgent: jsonSerialization['reviewerAgent'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<_ijo8h3v4.Agent>(
              jsonSerialization['reviewerAgent'],
            ),
      status: jsonSerialization['status'] == null
          ? null
          : _i4rgwvgz.CodeReviewStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      summary: jsonSerialization['summary'] as String?,
      verdict: jsonSerialization['verdict'] == null
          ? null
          : _ijks0ur1.CodeReviewVerdict.fromJson(
              (jsonSerialization['verdict'] as String),
            ),
      failureReason: jsonSerialization['failureReason'] as String?,
      githubReviewId: jsonSerialization['githubReviewId'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      finishedAt: jsonSerialization['finishedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['finishedAt']),
      comments: jsonSerialization['comments'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<List<_itpwl327.ReviewComment>>(
              jsonSerialization['comments'],
            ),
    );
  }

  static final t = CodeReviewTable();

  static const db = CodeReviewRepository._();

  @override
  int? id;

  int taskId;

  /// onDelete=Cascade: a review has no meaning independent of its task.
  _iwn6t6fs.Task? task;

  int? reviewerAgentId;

  /// onDelete=SetNull: keep the review (and its comments) as history when the reviewer is deleted.
  _ijo8h3v4.Agent? reviewerAgent;

  _i4rgwvgz.CodeReviewStatus status;

  /// The reviewer's overall verdict, in its own words.
  String? summary;

  /// The reviewer's decision; null for reviews from before verdicts existed.
  _ijks0ur1.CodeReviewVerdict? verdict;

  String? failureReason;

  /// Id of the mirrored GitHub PR review, when mirroring succeeded.
  int? githubReviewId;

  DateTime createdAt;

  DateTime? finishedAt;

  List<_itpwl327.ReviewComment>? comments;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [CodeReview]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CodeReview copyWith({
    int? id,
    int? taskId,
    _iwn6t6fs.Task? task,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    _i4rgwvgz.CodeReviewStatus? status,
    String? summary,
    _ijks0ur1.CodeReviewVerdict? verdict,
    String? failureReason,
    int? githubReviewId,
    DateTime? createdAt,
    DateTime? finishedAt,
    List<_itpwl327.ReviewComment>? comments,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CodeReview',
      if (id != null) 'id': id,
      'taskId': taskId,
      if (task != null) 'task': task?.toJson(),
      if (reviewerAgentId != null) 'reviewerAgentId': reviewerAgentId,
      if (reviewerAgent != null) 'reviewerAgent': reviewerAgent?.toJson(),
      'status': status.toJson(),
      if (summary != null) 'summary': summary,
      if (verdict != null) 'verdict': verdict?.toJson(),
      if (failureReason != null) 'failureReason': failureReason,
      if (githubReviewId != null) 'githubReviewId': githubReviewId,
      'createdAt': createdAt.toJson(),
      if (finishedAt != null) 'finishedAt': finishedAt?.toJson(),
      if (comments != null)
        'comments': comments?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CodeReview',
      if (id != null) 'id': id,
      'taskId': taskId,
      if (task != null) 'task': task?.toJsonForProtocol(),
      if (reviewerAgentId != null) 'reviewerAgentId': reviewerAgentId,
      if (reviewerAgent != null)
        'reviewerAgent': reviewerAgent?.toJsonForProtocol(),
      'status': status.toJson(),
      if (summary != null) 'summary': summary,
      if (verdict != null) 'verdict': verdict?.toJson(),
      if (failureReason != null) 'failureReason': failureReason,
      if (githubReviewId != null) 'githubReviewId': githubReviewId,
      'createdAt': createdAt.toJson(),
      if (finishedAt != null) 'finishedAt': finishedAt?.toJson(),
      if (comments != null)
        'comments': comments?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  static CodeReviewInclude include({
    _iwn6t6fs.TaskInclude? task,
    _ijo8h3v4.AgentInclude? reviewerAgent,
    _itpwl327.ReviewCommentIncludeList? comments,
  }) {
    return CodeReviewInclude._(
      task: task,
      reviewerAgent: reviewerAgent,
      comments: comments,
    );
  }

  static CodeReviewIncludeList includeList({
    _is.WhereExpressionBuilder<CodeReviewTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CodeReviewTable>? orderBy,
    _is.OrderByListBuilder<CodeReviewTable>? orderByList,
    CodeReviewInclude? include,
  }) {
    return CodeReviewIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CodeReview.t),
      orderByList: orderByList?.call(CodeReview.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CodeReviewImpl extends CodeReview {
  _CodeReviewImpl({
    int? id,
    required int taskId,
    _iwn6t6fs.Task? task,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    _i4rgwvgz.CodeReviewStatus? status,
    String? summary,
    _ijks0ur1.CodeReviewVerdict? verdict,
    String? failureReason,
    int? githubReviewId,
    DateTime? createdAt,
    DateTime? finishedAt,
    List<_itpwl327.ReviewComment>? comments,
  }) : super._(
         id: id,
         taskId: taskId,
         task: task,
         reviewerAgentId: reviewerAgentId,
         reviewerAgent: reviewerAgent,
         status: status,
         summary: summary,
         verdict: verdict,
         failureReason: failureReason,
         githubReviewId: githubReviewId,
         createdAt: createdAt,
         finishedAt: finishedAt,
         comments: comments,
       );

  /// Returns a shallow copy of this [CodeReview]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CodeReview copyWith({
    Object? id = _Undefined,
    int? taskId,
    Object? task = _Undefined,
    Object? reviewerAgentId = _Undefined,
    Object? reviewerAgent = _Undefined,
    _i4rgwvgz.CodeReviewStatus? status,
    Object? summary = _Undefined,
    Object? verdict = _Undefined,
    Object? failureReason = _Undefined,
    Object? githubReviewId = _Undefined,
    DateTime? createdAt,
    Object? finishedAt = _Undefined,
    Object? comments = _Undefined,
  }) {
    return CodeReview(
      id: id is int? ? id : this.id,
      taskId: taskId ?? this.taskId,
      task: task is _iwn6t6fs.Task? ? task : this.task?.copyWith(),
      reviewerAgentId: reviewerAgentId is int?
          ? reviewerAgentId
          : this.reviewerAgentId,
      reviewerAgent: reviewerAgent is _ijo8h3v4.Agent?
          ? reviewerAgent
          : this.reviewerAgent?.copyWith(),
      status: status ?? this.status,
      summary: summary is String? ? summary : this.summary,
      verdict: verdict is _ijks0ur1.CodeReviewVerdict? ? verdict : this.verdict,
      failureReason: failureReason is String?
          ? failureReason
          : this.failureReason,
      githubReviewId: githubReviewId is int?
          ? githubReviewId
          : this.githubReviewId,
      createdAt: createdAt ?? this.createdAt,
      finishedAt: finishedAt is DateTime? ? finishedAt : this.finishedAt,
      comments: comments is List<_itpwl327.ReviewComment>?
          ? comments
          : this.comments?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class CodeReviewUpdateTable extends _is.UpdateTable<CodeReviewTable> {
  CodeReviewUpdateTable(super.table);

  _is.ColumnValue<int, int> taskId(int value) => _is.ColumnValue(
    table.taskId,
    value,
  );

  _is.ColumnValue<int, int> reviewerAgentId(int? value) => _is.ColumnValue(
    table.reviewerAgentId,
    value,
  );

  _is.ColumnValue<_i4rgwvgz.CodeReviewStatus, _i4rgwvgz.CodeReviewStatus>
  status(_i4rgwvgz.CodeReviewStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> summary(String? value) => _is.ColumnValue(
    table.summary,
    value,
  );

  _is.ColumnValue<_ijks0ur1.CodeReviewVerdict, _ijks0ur1.CodeReviewVerdict>
  verdict(_ijks0ur1.CodeReviewVerdict? value) => _is.ColumnValue(
    table.verdict,
    value,
  );

  _is.ColumnValue<String, String> failureReason(String? value) =>
      _is.ColumnValue(
        table.failureReason,
        value,
      );

  _is.ColumnValue<int, int> githubReviewId(int? value) => _is.ColumnValue(
    table.githubReviewId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> finishedAt(DateTime? value) =>
      _is.ColumnValue(
        table.finishedAt,
        value,
      );
}

class CodeReviewTable extends _is.Table<int?> {
  CodeReviewTable({super.tableRelation}) : super(tableName: 'code_review') {
    updateTable = CodeReviewUpdateTable(this);
    taskId = _is.ColumnInt(
      'taskId',
      this,
    );
    reviewerAgentId = _is.ColumnInt(
      'reviewerAgentId',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    summary = _is.ColumnString(
      'summary',
      this,
    );
    verdict = _is.ColumnEnum(
      'verdict',
      this,
      _is.EnumSerialization.byName,
    );
    failureReason = _is.ColumnString(
      'failureReason',
      this,
    );
    githubReviewId = _is.ColumnInt(
      'githubReviewId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    finishedAt = _is.ColumnDateTime(
      'finishedAt',
      this,
    );
  }

  late final CodeReviewUpdateTable updateTable;

  late final _is.ColumnInt taskId;

  /// onDelete=Cascade: a review has no meaning independent of its task.
  _iwn6t6fs.TaskTable? _task;

  late final _is.ColumnInt reviewerAgentId;

  /// onDelete=SetNull: keep the review (and its comments) as history when the reviewer is deleted.
  _ijo8h3v4.AgentTable? _reviewerAgent;

  late final _is.ColumnEnum<_i4rgwvgz.CodeReviewStatus> status;

  /// The reviewer's overall verdict, in its own words.
  late final _is.ColumnString summary;

  /// The reviewer's decision; null for reviews from before verdicts existed.
  late final _is.ColumnEnum<_ijks0ur1.CodeReviewVerdict> verdict;

  late final _is.ColumnString failureReason;

  /// Id of the mirrored GitHub PR review, when mirroring succeeded.
  late final _is.ColumnInt githubReviewId;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime finishedAt;

  _itpwl327.ReviewCommentTable? ___comments;

  _is.ManyRelation<_itpwl327.ReviewCommentTable>? _comments;

  _iwn6t6fs.TaskTable get task {
    if (_task != null) return _task!;
    _task = _is.createRelationTable(
      relationFieldName: 'task',
      field: CodeReview.t.taskId,
      foreignField: _iwn6t6fs.Task.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iwn6t6fs.TaskTable(tableRelation: foreignTableRelation),
    );
    return _task!;
  }

  _ijo8h3v4.AgentTable get reviewerAgent {
    if (_reviewerAgent != null) return _reviewerAgent!;
    _reviewerAgent = _is.createRelationTable(
      relationFieldName: 'reviewerAgent',
      field: CodeReview.t.reviewerAgentId,
      foreignField: _ijo8h3v4.Agent.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ijo8h3v4.AgentTable(tableRelation: foreignTableRelation),
    );
    return _reviewerAgent!;
  }

  _itpwl327.ReviewCommentTable get __comments {
    if (___comments != null) return ___comments!;
    ___comments = _is.createRelationTable(
      relationFieldName: '__comments',
      field: CodeReview.t.id,
      foreignField: _itpwl327.ReviewComment.t.reviewId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _itpwl327.ReviewCommentTable(tableRelation: foreignTableRelation),
    );
    return ___comments!;
  }

  _is.ManyRelation<_itpwl327.ReviewCommentTable> get comments {
    if (_comments != null) return _comments!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'comments',
      field: CodeReview.t.id,
      foreignField: _itpwl327.ReviewComment.t.reviewId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _itpwl327.ReviewCommentTable(tableRelation: foreignTableRelation),
    );
    _comments = _is.ManyRelation<_itpwl327.ReviewCommentTable>(
      tableWithRelations: relationTable,
      table: _itpwl327.ReviewCommentTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _comments!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    taskId,
    reviewerAgentId,
    status,
    summary,
    verdict,
    failureReason,
    githubReviewId,
    createdAt,
    finishedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'task') {
      return task;
    }
    if (relationField == 'reviewerAgent') {
      return reviewerAgent;
    }
    if (relationField == 'comments') {
      return __comments;
    }
    return null;
  }
}

class CodeReviewInclude extends _is.IncludeObject {
  CodeReviewInclude._({
    _iwn6t6fs.TaskInclude? task,
    _ijo8h3v4.AgentInclude? reviewerAgent,
    _itpwl327.ReviewCommentIncludeList? comments,
  }) {
    _task = task;
    _reviewerAgent = reviewerAgent;
    _comments = comments;
  }

  _iwn6t6fs.TaskInclude? _task;

  _ijo8h3v4.AgentInclude? _reviewerAgent;

  _itpwl327.ReviewCommentIncludeList? _comments;

  @override
  Map<String, _is.Include?> get includes => {
    'task': _task,
    'reviewerAgent': _reviewerAgent,
    'comments': _comments,
  };

  @override
  _is.Table<int?> get table => CodeReview.t;
}

class CodeReviewIncludeList extends _is.IncludeList {
  CodeReviewIncludeList._({
    _is.WhereExpressionBuilder<CodeReviewTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(CodeReview.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => CodeReview.t;
}

class CodeReviewRepository {
  const CodeReviewRepository._();

  final attach = const CodeReviewAttachRepository._();

  final attachRow = const CodeReviewAttachRowRepository._();

  final detachRow = const CodeReviewDetachRowRepository._();

  /// Returns a list of [CodeReview]s matching the given query parameters.
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
  Future<List<CodeReview>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CodeReviewTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CodeReviewTable>? orderBy,
    _is.OrderByListBuilder<CodeReviewTable>? orderByList,
    _is.Transaction? transaction,
    CodeReviewInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<CodeReview>(
      where: where?.call(CodeReview.t),
      orderBy: orderBy?.call(CodeReview.t),
      orderByList: orderByList?.call(CodeReview.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [CodeReview] matching the given query parameters.
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
  Future<CodeReview?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CodeReviewTable>? where,
    int? offset,
    _is.OrderByBuilder<CodeReviewTable>? orderBy,
    _is.OrderByListBuilder<CodeReviewTable>? orderByList,
    _is.Transaction? transaction,
    CodeReviewInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<CodeReview>(
      where: where?.call(CodeReview.t),
      orderBy: orderBy?.call(CodeReview.t),
      orderByList: orderByList?.call(CodeReview.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [CodeReview] by its [id] or null if no such row exists.
  Future<CodeReview?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    CodeReviewInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<CodeReview>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [CodeReview]s in the list and returns the inserted rows.
  ///
  /// The returned [CodeReview]s will have their `id` fields set.
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
  Future<List<CodeReview>> insert(
    _is.DatabaseSession session,
    List<CodeReview> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<CodeReview>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [CodeReview] and returns the inserted row.
  ///
  /// The returned [CodeReview] will have its `id` field set.
  Future<CodeReview> insertRow(
    _is.DatabaseSession session,
    CodeReview row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<CodeReview>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [CodeReview]s in the list and returns the resulting rows.
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
  /// The returned [CodeReview]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CodeReview>> upsert(
    _is.DatabaseSession session,
    List<CodeReview> rows, {
    required _is.ColumnSelections<CodeReviewTable> conflictColumns,
    _is.ColumnSelections<CodeReviewTable>? updateColumns,
    _is.WhereExpressionBuilder<CodeReviewTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<CodeReview>(
      rows,
      conflictColumns: conflictColumns(CodeReview.t),
      updateColumns: updateColumns?.call(CodeReview.t),
      updateWhere: updateWhere?.call(CodeReview.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [CodeReview] and returns the resulting row.
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
  /// The returned [CodeReview] will have its `id` field set.
  Future<CodeReview?> upsertRow(
    _is.DatabaseSession session,
    CodeReview row, {
    required _is.ColumnSelections<CodeReviewTable> conflictColumns,
    _is.ColumnSelections<CodeReviewTable>? updateColumns,
    _is.WhereExpressionBuilder<CodeReviewTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<CodeReview>(
      row,
      conflictColumns: conflictColumns(CodeReview.t),
      updateColumns: updateColumns?.call(CodeReview.t),
      updateWhere: updateWhere?.call(CodeReview.t),
      transaction: transaction,
    );
  }

  /// Updates all [CodeReview]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CodeReview>> update(
    _is.DatabaseSession session,
    List<CodeReview> rows, {
    _is.ColumnSelections<CodeReviewTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<CodeReview>(
      rows,
      columns: columns?.call(CodeReview.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [CodeReview]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<CodeReview> updateRow(
    _is.DatabaseSession session,
    CodeReview row, {
    _is.ColumnSelections<CodeReviewTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<CodeReview>(
      row,
      columns: columns?.call(CodeReview.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CodeReview] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<CodeReview?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<CodeReviewUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<CodeReview>(
      id,
      columnValues: columnValues(CodeReview.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [CodeReview]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CodeReview>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<CodeReviewUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<CodeReviewTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CodeReviewTable>? orderBy,
    _is.OrderByListBuilder<CodeReviewTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<CodeReview>(
      columnValues: columnValues(CodeReview.t.updateTable),
      where: where(CodeReview.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CodeReview.t),
      orderByList: orderByList?.call(CodeReview.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [CodeReview]s in the list and returns the deleted rows.
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
  Future<List<CodeReview>> delete(
    _is.DatabaseSession session,
    List<CodeReview> rows, {
    _is.OrderByBuilder<CodeReviewTable>? orderBy,
    _is.OrderByListBuilder<CodeReviewTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<CodeReview>(
      rows,
      orderBy: orderBy?.call(CodeReview.t),
      orderByList: orderByList?.call(CodeReview.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [CodeReview].
  Future<CodeReview> deleteRow(
    _is.DatabaseSession session,
    CodeReview row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<CodeReview>(
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
  Future<List<CodeReview>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CodeReviewTable> where,
    _is.OrderByBuilder<CodeReviewTable>? orderBy,
    _is.OrderByListBuilder<CodeReviewTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<CodeReview>(
      where: where(CodeReview.t),
      orderBy: orderBy?.call(CodeReview.t),
      orderByList: orderByList?.call(CodeReview.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CodeReviewTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<CodeReview>(
      where: where?.call(CodeReview.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [CodeReview] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CodeReviewTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<CodeReview>(
      where: where(CodeReview.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class CodeReviewAttachRepository {
  const CodeReviewAttachRepository._();

  /// Creates a relation between this [CodeReview] and the given [ReviewComment]s
  /// by setting each [ReviewComment]'s foreign key `reviewId` to refer to this [CodeReview].
  Future<void> comments(
    _is.DatabaseSession session,
    CodeReview codeReview,
    List<_itpwl327.ReviewComment> reviewComment, {
    _is.Transaction? transaction,
  }) async {
    if (reviewComment.any((e) => e.id == null)) {
      throw ArgumentError.notNull('reviewComment.id');
    }
    if (codeReview.id == null) {
      throw ArgumentError.notNull('codeReview.id');
    }

    var $reviewComment = reviewComment
        .map((e) => e.copyWith(reviewId: codeReview.id))
        .toList();
    await session.db.update<_itpwl327.ReviewComment>(
      $reviewComment,
      columns: [_itpwl327.ReviewComment.t.reviewId],
      transaction: transaction,
    );
  }
}

class CodeReviewAttachRowRepository {
  const CodeReviewAttachRowRepository._();

  /// Creates a relation between the given [CodeReview] and [Task]
  /// by setting the [CodeReview]'s foreign key `taskId` to refer to the [Task].
  Future<void> task(
    _is.DatabaseSession session,
    CodeReview codeReview,
    _iwn6t6fs.Task task, {
    _is.Transaction? transaction,
  }) async {
    if (codeReview.id == null) {
      throw ArgumentError.notNull('codeReview.id');
    }
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $codeReview = codeReview.copyWith(taskId: task.id);
    await session.db.updateRow<CodeReview>(
      $codeReview,
      columns: [CodeReview.t.taskId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [CodeReview] and [Agent]
  /// by setting the [CodeReview]'s foreign key `reviewerAgentId` to refer to the [Agent].
  Future<void> reviewerAgent(
    _is.DatabaseSession session,
    CodeReview codeReview,
    _ijo8h3v4.Agent reviewerAgent, {
    _is.Transaction? transaction,
  }) async {
    if (codeReview.id == null) {
      throw ArgumentError.notNull('codeReview.id');
    }
    if (reviewerAgent.id == null) {
      throw ArgumentError.notNull('reviewerAgent.id');
    }

    var $codeReview = codeReview.copyWith(reviewerAgentId: reviewerAgent.id);
    await session.db.updateRow<CodeReview>(
      $codeReview,
      columns: [CodeReview.t.reviewerAgentId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [CodeReview] and the given [ReviewComment]
  /// by setting the [ReviewComment]'s foreign key `reviewId` to refer to this [CodeReview].
  Future<void> comments(
    _is.DatabaseSession session,
    CodeReview codeReview,
    _itpwl327.ReviewComment reviewComment, {
    _is.Transaction? transaction,
  }) async {
    if (reviewComment.id == null) {
      throw ArgumentError.notNull('reviewComment.id');
    }
    if (codeReview.id == null) {
      throw ArgumentError.notNull('codeReview.id');
    }

    var $reviewComment = reviewComment.copyWith(reviewId: codeReview.id);
    await session.db.updateRow<_itpwl327.ReviewComment>(
      $reviewComment,
      columns: [_itpwl327.ReviewComment.t.reviewId],
      transaction: transaction,
    );
  }
}

class CodeReviewDetachRowRepository {
  const CodeReviewDetachRowRepository._();

  /// Detaches the relation between this [CodeReview] and the [Agent] set in `reviewerAgent`
  /// by setting the [CodeReview]'s foreign key `reviewerAgentId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> reviewerAgent(
    _is.DatabaseSession session,
    CodeReview codeReview, {
    _is.Transaction? transaction,
  }) async {
    if (codeReview.id == null) {
      throw ArgumentError.notNull('codeReview.id');
    }

    var $codeReview = codeReview.copyWith(reviewerAgentId: null);
    await session.db.updateRow<CodeReview>(
      $codeReview,
      columns: [CodeReview.t.reviewerAgentId],
      transaction: transaction,
    );
  }
}
