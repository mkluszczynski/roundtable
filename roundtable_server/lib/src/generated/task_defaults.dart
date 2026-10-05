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

/// The advanced options a new task starts with in a project: the project's
/// overrides on top of the workspace defaults.
abstract class TaskDefaults
    implements _is.SerializableModel, _is.ProtocolSerialization {
  TaskDefaults._({
    required this.skipPlanning,
    required this.autoReview,
    this.reviewerAgentId,
    required this.autoFixReview,
    required this.maxReviewFixRounds,
    required this.autoMerge,
  });

  factory TaskDefaults({
    required bool skipPlanning,
    required bool autoReview,
    int? reviewerAgentId,
    required bool autoFixReview,
    required int maxReviewFixRounds,
    required bool autoMerge,
  }) = _TaskDefaultsImpl;

  factory TaskDefaults.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaskDefaults(
      skipPlanning: _is.BoolJsonExtension.fromJson(
        jsonSerialization['skipPlanning'],
      ),
      autoReview: _is.BoolJsonExtension.fromJson(
        jsonSerialization['autoReview'],
      ),
      reviewerAgentId: jsonSerialization['reviewerAgentId'] as int?,
      autoFixReview: _is.BoolJsonExtension.fromJson(
        jsonSerialization['autoFixReview'],
      ),
      maxReviewFixRounds: jsonSerialization['maxReviewFixRounds'] as int,
      autoMerge: _is.BoolJsonExtension.fromJson(jsonSerialization['autoMerge']),
    );
  }

  bool skipPlanning;

  bool autoReview;

  int? reviewerAgentId;

  bool autoFixReview;

  int maxReviewFixRounds;

  bool autoMerge;

  /// Returns a shallow copy of this [TaskDefaults]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TaskDefaults copyWith({
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TaskDefaults',
      'skipPlanning': skipPlanning,
      'autoReview': autoReview,
      if (reviewerAgentId != null) 'reviewerAgentId': reviewerAgentId,
      'autoFixReview': autoFixReview,
      'maxReviewFixRounds': maxReviewFixRounds,
      'autoMerge': autoMerge,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TaskDefaults',
      'skipPlanning': skipPlanning,
      'autoReview': autoReview,
      if (reviewerAgentId != null) 'reviewerAgentId': reviewerAgentId,
      'autoFixReview': autoFixReview,
      'maxReviewFixRounds': maxReviewFixRounds,
      'autoMerge': autoMerge,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaskDefaultsImpl extends TaskDefaults {
  _TaskDefaultsImpl({
    required bool skipPlanning,
    required bool autoReview,
    int? reviewerAgentId,
    required bool autoFixReview,
    required int maxReviewFixRounds,
    required bool autoMerge,
  }) : super._(
         skipPlanning: skipPlanning,
         autoReview: autoReview,
         reviewerAgentId: reviewerAgentId,
         autoFixReview: autoFixReview,
         maxReviewFixRounds: maxReviewFixRounds,
         autoMerge: autoMerge,
       );

  /// Returns a shallow copy of this [TaskDefaults]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TaskDefaults copyWith({
    bool? skipPlanning,
    bool? autoReview,
    Object? reviewerAgentId = _Undefined,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
  }) {
    return TaskDefaults(
      skipPlanning: skipPlanning ?? this.skipPlanning,
      autoReview: autoReview ?? this.autoReview,
      reviewerAgentId: reviewerAgentId is int?
          ? reviewerAgentId
          : this.reviewerAgentId,
      autoFixReview: autoFixReview ?? this.autoFixReview,
      maxReviewFixRounds: maxReviewFixRounds ?? this.maxReviewFixRounds,
      autoMerge: autoMerge ?? this.autoMerge,
    );
  }
}
