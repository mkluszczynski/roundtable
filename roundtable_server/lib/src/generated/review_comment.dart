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
import 'code_review.dart' as _icksttbv;
import 'review_comment_severity.dart' as _iml08ymk;
import 'review_comment_state.dart' as _igczzv9q;

/// One comment left by a reviewer agent on a task's PR.
abstract class ReviewComment
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ReviewComment._({
    this.id,
    required this.reviewId,
    this.review,
    required this.path,
    this.line,
    required this.body,
    _iml08ymk.ReviewCommentSeverity? severity,
    _igczzv9q.ReviewCommentState? state,
    this.githubCommentId,
    DateTime? createdAt,
  }) : severity = severity ?? _iml08ymk.ReviewCommentSeverity.issue,
       state = state ?? _igczzv9q.ReviewCommentState.open,
       createdAt = createdAt ?? DateTime.now();

  factory ReviewComment({
    int? id,
    required int reviewId,
    _icksttbv.CodeReview? review,
    required String path,
    int? line,
    required String body,
    _iml08ymk.ReviewCommentSeverity? severity,
    _igczzv9q.ReviewCommentState? state,
    int? githubCommentId,
    DateTime? createdAt,
  }) = _ReviewCommentImpl;

  factory ReviewComment.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReviewComment(
      id: jsonSerialization['id'] as int?,
      reviewId: jsonSerialization['reviewId'] as int,
      review: jsonSerialization['review'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<_icksttbv.CodeReview>(
              jsonSerialization['review'],
            ),
      path: jsonSerialization['path'] as String,
      line: jsonSerialization['line'] as int?,
      body: jsonSerialization['body'] as String,
      severity: jsonSerialization['severity'] == null
          ? null
          : _iml08ymk.ReviewCommentSeverity.fromJson(
              (jsonSerialization['severity'] as String),
            ),
      state: jsonSerialization['state'] == null
          ? null
          : _igczzv9q.ReviewCommentState.fromJson(
              (jsonSerialization['state'] as String),
            ),
      githubCommentId: jsonSerialization['githubCommentId'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ReviewCommentTable();

  static const db = ReviewCommentRepository._();

  @override
  int? id;

  int reviewId;

  /// onDelete=Cascade: a comment has no meaning independent of its review.
  _icksttbv.CodeReview? review;

  /// Path of the commented file, relative to the repo root.
  String path;

  /// Line in the new version of [path]; null for a file-level comment.
  int? line;

  String body;

  _iml08ymk.ReviewCommentSeverity severity;

  _igczzv9q.ReviewCommentState state;

  /// Id of the mirrored GitHub review comment, when it could be placed on the diff.
  int? githubCommentId;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ReviewComment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ReviewComment copyWith({
    int? id,
    int? reviewId,
    _icksttbv.CodeReview? review,
    String? path,
    int? line,
    String? body,
    _iml08ymk.ReviewCommentSeverity? severity,
    _igczzv9q.ReviewCommentState? state,
    int? githubCommentId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReviewComment',
      if (id != null) 'id': id,
      'reviewId': reviewId,
      if (review != null) 'review': review?.toJson(),
      'path': path,
      if (line != null) 'line': line,
      'body': body,
      'severity': severity.toJson(),
      'state': state.toJson(),
      if (githubCommentId != null) 'githubCommentId': githubCommentId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReviewComment',
      if (id != null) 'id': id,
      'reviewId': reviewId,
      if (review != null) 'review': review?.toJsonForProtocol(),
      'path': path,
      if (line != null) 'line': line,
      'body': body,
      'severity': severity.toJson(),
      'state': state.toJson(),
      if (githubCommentId != null) 'githubCommentId': githubCommentId,
      'createdAt': createdAt.toJson(),
    };
  }

  static ReviewCommentInclude include({_icksttbv.CodeReviewInclude? review}) {
    return ReviewCommentInclude._(review: review);
  }

  static ReviewCommentIncludeList includeList({
    _is.WhereExpressionBuilder<ReviewCommentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ReviewCommentTable>? orderBy,
    _is.OrderByListBuilder<ReviewCommentTable>? orderByList,
    ReviewCommentInclude? include,
  }) {
    return ReviewCommentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ReviewComment.t),
      orderByList: orderByList?.call(ReviewComment.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReviewCommentImpl extends ReviewComment {
  _ReviewCommentImpl({
    int? id,
    required int reviewId,
    _icksttbv.CodeReview? review,
    required String path,
    int? line,
    required String body,
    _iml08ymk.ReviewCommentSeverity? severity,
    _igczzv9q.ReviewCommentState? state,
    int? githubCommentId,
    DateTime? createdAt,
  }) : super._(
         id: id,
         reviewId: reviewId,
         review: review,
         path: path,
         line: line,
         body: body,
         severity: severity,
         state: state,
         githubCommentId: githubCommentId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ReviewComment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ReviewComment copyWith({
    Object? id = _Undefined,
    int? reviewId,
    Object? review = _Undefined,
    String? path,
    Object? line = _Undefined,
    String? body,
    _iml08ymk.ReviewCommentSeverity? severity,
    _igczzv9q.ReviewCommentState? state,
    Object? githubCommentId = _Undefined,
    DateTime? createdAt,
  }) {
    return ReviewComment(
      id: id is int? ? id : this.id,
      reviewId: reviewId ?? this.reviewId,
      review: review is _icksttbv.CodeReview?
          ? review
          : this.review?.copyWith(),
      path: path ?? this.path,
      line: line is int? ? line : this.line,
      body: body ?? this.body,
      severity: severity ?? this.severity,
      state: state ?? this.state,
      githubCommentId: githubCommentId is int?
          ? githubCommentId
          : this.githubCommentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ReviewCommentUpdateTable extends _is.UpdateTable<ReviewCommentTable> {
  ReviewCommentUpdateTable(super.table);

  _is.ColumnValue<int, int> reviewId(int value) => _is.ColumnValue(
    table.reviewId,
    value,
  );

  _is.ColumnValue<String, String> path(String value) => _is.ColumnValue(
    table.path,
    value,
  );

  _is.ColumnValue<int, int> line(int? value) => _is.ColumnValue(
    table.line,
    value,
  );

  _is.ColumnValue<String, String> body(String value) => _is.ColumnValue(
    table.body,
    value,
  );

  _is.ColumnValue<
    _iml08ymk.ReviewCommentSeverity,
    _iml08ymk.ReviewCommentSeverity
  >
  severity(_iml08ymk.ReviewCommentSeverity value) => _is.ColumnValue(
    table.severity,
    value,
  );

  _is.ColumnValue<_igczzv9q.ReviewCommentState, _igczzv9q.ReviewCommentState>
  state(_igczzv9q.ReviewCommentState value) => _is.ColumnValue(
    table.state,
    value,
  );

  _is.ColumnValue<int, int> githubCommentId(int? value) => _is.ColumnValue(
    table.githubCommentId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ReviewCommentTable extends _is.Table<int?> {
  ReviewCommentTable({super.tableRelation})
    : super(tableName: 'review_comment') {
    updateTable = ReviewCommentUpdateTable(this);
    reviewId = _is.ColumnInt(
      'reviewId',
      this,
    );
    path = _is.ColumnString(
      'path',
      this,
    );
    line = _is.ColumnInt(
      'line',
      this,
    );
    body = _is.ColumnString(
      'body',
      this,
    );
    severity = _is.ColumnEnum(
      'severity',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    state = _is.ColumnEnum(
      'state',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    githubCommentId = _is.ColumnInt(
      'githubCommentId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final ReviewCommentUpdateTable updateTable;

  late final _is.ColumnInt reviewId;

  /// onDelete=Cascade: a comment has no meaning independent of its review.
  _icksttbv.CodeReviewTable? _review;

  /// Path of the commented file, relative to the repo root.
  late final _is.ColumnString path;

  /// Line in the new version of [path]; null for a file-level comment.
  late final _is.ColumnInt line;

  late final _is.ColumnString body;

  late final _is.ColumnEnum<_iml08ymk.ReviewCommentSeverity> severity;

  late final _is.ColumnEnum<_igczzv9q.ReviewCommentState> state;

  /// Id of the mirrored GitHub review comment, when it could be placed on the diff.
  late final _is.ColumnInt githubCommentId;

  late final _is.ColumnDateTime createdAt;

  _icksttbv.CodeReviewTable get review {
    if (_review != null) return _review!;
    _review = _is.createRelationTable(
      relationFieldName: 'review',
      field: ReviewComment.t.reviewId,
      foreignField: _icksttbv.CodeReview.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _icksttbv.CodeReviewTable(tableRelation: foreignTableRelation),
    );
    return _review!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    reviewId,
    path,
    line,
    body,
    severity,
    state,
    githubCommentId,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'review') {
      return review;
    }
    return null;
  }
}

class ReviewCommentInclude extends _is.IncludeObject {
  ReviewCommentInclude._({_icksttbv.CodeReviewInclude? review}) {
    _review = review;
  }

  _icksttbv.CodeReviewInclude? _review;

  @override
  Map<String, _is.Include?> get includes => {'review': _review};

  @override
  _is.Table<int?> get table => ReviewComment.t;
}

class ReviewCommentIncludeList extends _is.IncludeList {
  ReviewCommentIncludeList._({
    _is.WhereExpressionBuilder<ReviewCommentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ReviewComment.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ReviewComment.t;
}

class ReviewCommentRepository {
  const ReviewCommentRepository._();

  final attachRow = const ReviewCommentAttachRowRepository._();

  /// Returns a list of [ReviewComment]s matching the given query parameters.
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
  Future<List<ReviewComment>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ReviewCommentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ReviewCommentTable>? orderBy,
    _is.OrderByListBuilder<ReviewCommentTable>? orderByList,
    _is.Transaction? transaction,
    ReviewCommentInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ReviewComment>(
      where: where?.call(ReviewComment.t),
      orderBy: orderBy?.call(ReviewComment.t),
      orderByList: orderByList?.call(ReviewComment.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ReviewComment] matching the given query parameters.
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
  Future<ReviewComment?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ReviewCommentTable>? where,
    int? offset,
    _is.OrderByBuilder<ReviewCommentTable>? orderBy,
    _is.OrderByListBuilder<ReviewCommentTable>? orderByList,
    _is.Transaction? transaction,
    ReviewCommentInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ReviewComment>(
      where: where?.call(ReviewComment.t),
      orderBy: orderBy?.call(ReviewComment.t),
      orderByList: orderByList?.call(ReviewComment.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ReviewComment] by its [id] or null if no such row exists.
  Future<ReviewComment?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    ReviewCommentInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ReviewComment>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ReviewComment]s in the list and returns the inserted rows.
  ///
  /// The returned [ReviewComment]s will have their `id` fields set.
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
  Future<List<ReviewComment>> insert(
    _is.DatabaseSession session,
    List<ReviewComment> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ReviewComment>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ReviewComment] and returns the inserted row.
  ///
  /// The returned [ReviewComment] will have its `id` field set.
  Future<ReviewComment> insertRow(
    _is.DatabaseSession session,
    ReviewComment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ReviewComment>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ReviewComment]s in the list and returns the resulting rows.
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
  /// The returned [ReviewComment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ReviewComment>> upsert(
    _is.DatabaseSession session,
    List<ReviewComment> rows, {
    required _is.ColumnSelections<ReviewCommentTable> conflictColumns,
    _is.ColumnSelections<ReviewCommentTable>? updateColumns,
    _is.WhereExpressionBuilder<ReviewCommentTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ReviewComment>(
      rows,
      conflictColumns: conflictColumns(ReviewComment.t),
      updateColumns: updateColumns?.call(ReviewComment.t),
      updateWhere: updateWhere?.call(ReviewComment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ReviewComment] and returns the resulting row.
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
  /// The returned [ReviewComment] will have its `id` field set.
  Future<ReviewComment?> upsertRow(
    _is.DatabaseSession session,
    ReviewComment row, {
    required _is.ColumnSelections<ReviewCommentTable> conflictColumns,
    _is.ColumnSelections<ReviewCommentTable>? updateColumns,
    _is.WhereExpressionBuilder<ReviewCommentTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ReviewComment>(
      row,
      conflictColumns: conflictColumns(ReviewComment.t),
      updateColumns: updateColumns?.call(ReviewComment.t),
      updateWhere: updateWhere?.call(ReviewComment.t),
      transaction: transaction,
    );
  }

  /// Updates all [ReviewComment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ReviewComment>> update(
    _is.DatabaseSession session,
    List<ReviewComment> rows, {
    _is.ColumnSelections<ReviewCommentTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ReviewComment>(
      rows,
      columns: columns?.call(ReviewComment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ReviewComment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ReviewComment> updateRow(
    _is.DatabaseSession session,
    ReviewComment row, {
    _is.ColumnSelections<ReviewCommentTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ReviewComment>(
      row,
      columns: columns?.call(ReviewComment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ReviewComment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ReviewComment?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ReviewCommentUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ReviewComment>(
      id,
      columnValues: columnValues(ReviewComment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ReviewComment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ReviewComment>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ReviewCommentUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ReviewCommentTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ReviewCommentTable>? orderBy,
    _is.OrderByListBuilder<ReviewCommentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ReviewComment>(
      columnValues: columnValues(ReviewComment.t.updateTable),
      where: where(ReviewComment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ReviewComment.t),
      orderByList: orderByList?.call(ReviewComment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ReviewComment]s in the list and returns the deleted rows.
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
  Future<List<ReviewComment>> delete(
    _is.DatabaseSession session,
    List<ReviewComment> rows, {
    _is.OrderByBuilder<ReviewCommentTable>? orderBy,
    _is.OrderByListBuilder<ReviewCommentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ReviewComment>(
      rows,
      orderBy: orderBy?.call(ReviewComment.t),
      orderByList: orderByList?.call(ReviewComment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ReviewComment].
  Future<ReviewComment> deleteRow(
    _is.DatabaseSession session,
    ReviewComment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ReviewComment>(
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
  Future<List<ReviewComment>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ReviewCommentTable> where,
    _is.OrderByBuilder<ReviewCommentTable>? orderBy,
    _is.OrderByListBuilder<ReviewCommentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ReviewComment>(
      where: where(ReviewComment.t),
      orderBy: orderBy?.call(ReviewComment.t),
      orderByList: orderByList?.call(ReviewComment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ReviewCommentTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ReviewComment>(
      where: where?.call(ReviewComment.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ReviewComment] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ReviewCommentTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ReviewComment>(
      where: where(ReviewComment.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ReviewCommentAttachRowRepository {
  const ReviewCommentAttachRowRepository._();

  /// Creates a relation between the given [ReviewComment] and [CodeReview]
  /// by setting the [ReviewComment]'s foreign key `reviewId` to refer to the [CodeReview].
  Future<void> review(
    _is.DatabaseSession session,
    ReviewComment reviewComment,
    _icksttbv.CodeReview review, {
    _is.Transaction? transaction,
  }) async {
    if (reviewComment.id == null) {
      throw ArgumentError.notNull('reviewComment.id');
    }
    if (review.id == null) {
      throw ArgumentError.notNull('review.id');
    }

    var $reviewComment = reviewComment.copyWith(reviewId: review.id);
    await session.db.updateRow<ReviewComment>(
      $reviewComment,
      columns: [ReviewComment.t.reviewId],
      transaction: transaction,
    );
  }
}
