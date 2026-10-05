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

/// Workspace-wide settings — a single row while the app is single-tenant.
/// Holds the defaults a project inherits unless it overrides them.
abstract class WorkspaceSettings
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceSettings._({
    this.id,
    bool? skipPlanning,
    bool? autoReview,
    this.reviewerAgentId,
    this.reviewerAgent,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    DateTime? updatedAt,
  }) : skipPlanning = skipPlanning ?? false,
       autoReview = autoReview ?? false,
       autoFixReview = autoFixReview ?? false,
       maxReviewFixRounds = maxReviewFixRounds ?? 2,
       autoMerge = autoMerge ?? false,
       updatedAt = updatedAt ?? DateTime.now();

  factory WorkspaceSettings({
    int? id,
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    DateTime? updatedAt,
  }) = _WorkspaceSettingsImpl;

  factory WorkspaceSettings.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceSettings(
      id: jsonSerialization['id'] as int?,
      skipPlanning: jsonSerialization['skipPlanning'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['skipPlanning']),
      autoReview: jsonSerialization['autoReview'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['autoReview']),
      reviewerAgentId: jsonSerialization['reviewerAgentId'] as int?,
      reviewerAgent: jsonSerialization['reviewerAgent'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<_ijo8h3v4.Agent>(
              jsonSerialization['reviewerAgent'],
            ),
      autoFixReview: jsonSerialization['autoFixReview'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['autoFixReview']),
      maxReviewFixRounds: jsonSerialization['maxReviewFixRounds'] as int?,
      autoMerge: jsonSerialization['autoMerge'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['autoMerge']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Default for Task.skipPlanning on new tasks.
  bool skipPlanning;

  /// Default for Task.autoReview on new tasks.
  bool autoReview;

  int? reviewerAgentId;

  /// Default reviewer for new tasks.
  _ijo8h3v4.Agent? reviewerAgent;

  /// Defaults for Task.autoFixReview / maxReviewFixRounds.
  bool autoFixReview;

  int maxReviewFixRounds;

  /// Default for Task.autoMerge on new tasks.
  bool autoMerge;

  DateTime updatedAt;

  /// Returns a shallow copy of this [WorkspaceSettings]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceSettings copyWith({
    int? id,
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceSettings',
      if (id != null) 'id': id,
      'skipPlanning': skipPlanning,
      'autoReview': autoReview,
      if (reviewerAgentId != null) 'reviewerAgentId': reviewerAgentId,
      if (reviewerAgent != null) 'reviewerAgent': reviewerAgent?.toJson(),
      'autoFixReview': autoFixReview,
      'maxReviewFixRounds': maxReviewFixRounds,
      'autoMerge': autoMerge,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceSettings',
      if (id != null) 'id': id,
      'skipPlanning': skipPlanning,
      'autoReview': autoReview,
      if (reviewerAgentId != null) 'reviewerAgentId': reviewerAgentId,
      if (reviewerAgent != null)
        'reviewerAgent': reviewerAgent?.toJsonForProtocol(),
      'autoFixReview': autoFixReview,
      'maxReviewFixRounds': maxReviewFixRounds,
      'autoMerge': autoMerge,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceSettingsImpl extends WorkspaceSettings {
  _WorkspaceSettingsImpl({
    int? id,
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         skipPlanning: skipPlanning,
         autoReview: autoReview,
         reviewerAgentId: reviewerAgentId,
         reviewerAgent: reviewerAgent,
         autoFixReview: autoFixReview,
         maxReviewFixRounds: maxReviewFixRounds,
         autoMerge: autoMerge,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [WorkspaceSettings]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceSettings copyWith({
    Object? id = _Undefined,
    bool? skipPlanning,
    bool? autoReview,
    Object? reviewerAgentId = _Undefined,
    Object? reviewerAgent = _Undefined,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    DateTime? updatedAt,
  }) {
    return WorkspaceSettings(
      id: id is int? ? id : this.id,
      skipPlanning: skipPlanning ?? this.skipPlanning,
      autoReview: autoReview ?? this.autoReview,
      reviewerAgentId: reviewerAgentId is int?
          ? reviewerAgentId
          : this.reviewerAgentId,
      reviewerAgent: reviewerAgent is _ijo8h3v4.Agent?
          ? reviewerAgent
          : this.reviewerAgent?.copyWith(),
      autoFixReview: autoFixReview ?? this.autoFixReview,
      maxReviewFixRounds: maxReviewFixRounds ?? this.maxReviewFixRounds,
      autoMerge: autoMerge ?? this.autoMerge,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
