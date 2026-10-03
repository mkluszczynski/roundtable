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
import 'agent.dart' as _ijo8h3v4;
import 'code_review_status.dart' as _i4rgwvgz;
import 'review_comment.dart' as _itpwl327;
import 'task.dart' as _iwn6t6fs;

/// One AI code review of a task's PR, done by a reviewer agent (possibly on another machine).
abstract class CodeReview
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CodeReview._({
    this.id,
    required this.taskId,
    this.task,
    this.reviewerAgentId,
    this.reviewerAgent,
    _i4rgwvgz.CodeReviewStatus? status,
    this.summary,
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
          : _i35hmugi.Protocol().deserialize<_iwn6t6fs.Task>(
              jsonSerialization['task'],
            ),
      reviewerAgentId: jsonSerialization['reviewerAgentId'] as int?,
      reviewerAgent: jsonSerialization['reviewerAgent'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<_ijo8h3v4.Agent>(
              jsonSerialization['reviewerAgent'],
            ),
      status: jsonSerialization['status'] == null
          ? null
          : _i4rgwvgz.CodeReviewStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      summary: jsonSerialization['summary'] as String?,
      failureReason: jsonSerialization['failureReason'] as String?,
      githubReviewId: jsonSerialization['githubReviewId'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      finishedAt: jsonSerialization['finishedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['finishedAt'],
            ),
      comments: jsonSerialization['comments'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<List<_itpwl327.ReviewComment>>(
              jsonSerialization['comments'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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

  String? failureReason;

  /// Id of the mirrored GitHub PR review, when mirroring succeeded.
  int? githubReviewId;

  DateTime createdAt;

  DateTime? finishedAt;

  List<_itpwl327.ReviewComment>? comments;

  /// Returns a shallow copy of this [CodeReview]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CodeReview copyWith({
    int? id,
    int? taskId,
    _iwn6t6fs.Task? task,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    _i4rgwvgz.CodeReviewStatus? status,
    String? summary,
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
      if (failureReason != null) 'failureReason': failureReason,
      if (githubReviewId != null) 'githubReviewId': githubReviewId,
      'createdAt': createdAt.toJson(),
      if (finishedAt != null) 'finishedAt': finishedAt?.toJson(),
      if (comments != null)
        'comments': comments?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
         failureReason: failureReason,
         githubReviewId: githubReviewId,
         createdAt: createdAt,
         finishedAt: finishedAt,
         comments: comments,
       );

  /// Returns a shallow copy of this [CodeReview]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CodeReview copyWith({
    Object? id = _Undefined,
    int? taskId,
    Object? task = _Undefined,
    Object? reviewerAgentId = _Undefined,
    Object? reviewerAgent = _Undefined,
    _i4rgwvgz.CodeReviewStatus? status,
    Object? summary = _Undefined,
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
