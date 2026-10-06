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
import 'package:roundtable_client/src/protocol/protocol.dart' as _i35hmugi;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'code_review.dart' as _icksttbv;
import 'review_comment_severity.dart' as _iml08ymk;
import 'review_comment_state.dart' as _igczzv9q;

/// One comment left by a reviewer agent on a task's PR.
abstract class ReviewComment
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ReviewComment._({
    this.id,
    required this.reviewId,
    this.review,
    required this.path,
    this.line,
    required this.body,
    _iml08ymk.ReviewCommentSeverity? severity,
    _igczzv9q.ReviewCommentState? state,
    this.carriedOverFromId,
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
    int? carriedOverFromId,
    int? githubCommentId,
    DateTime? createdAt,
  }) = _ReviewCommentImpl;

  factory ReviewComment.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReviewComment(
      id: jsonSerialization['id'] as int?,
      reviewId: jsonSerialization['reviewId'] as int,
      review: jsonSerialization['review'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<_icksttbv.CodeReview>(
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
      carriedOverFromId: jsonSerialization['carriedOverFromId'] as int?,
      githubCommentId: jsonSerialization['githubCommentId'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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

  /// The earlier comment this one carries over, when a later review found it not fixed yet.
  int? carriedOverFromId;

  /// Id of the mirrored GitHub review comment, when it could be placed on the diff.
  int? githubCommentId;

  DateTime createdAt;

  /// Returns a shallow copy of this [ReviewComment]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ReviewComment copyWith({
    int? id,
    int? reviewId,
    _icksttbv.CodeReview? review,
    String? path,
    int? line,
    String? body,
    _iml08ymk.ReviewCommentSeverity? severity,
    _igczzv9q.ReviewCommentState? state,
    int? carriedOverFromId,
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
      if (carriedOverFromId != null) 'carriedOverFromId': carriedOverFromId,
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
      if (carriedOverFromId != null) 'carriedOverFromId': carriedOverFromId,
      if (githubCommentId != null) 'githubCommentId': githubCommentId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
    int? carriedOverFromId,
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
         carriedOverFromId: carriedOverFromId,
         githubCommentId: githubCommentId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ReviewComment]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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
    Object? carriedOverFromId = _Undefined,
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
      carriedOverFromId: carriedOverFromId is int?
          ? carriedOverFromId
          : this.carriedOverFromId,
      githubCommentId: githubCommentId is int?
          ? githubCommentId
          : this.githubCommentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
