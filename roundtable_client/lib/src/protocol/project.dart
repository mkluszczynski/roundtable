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
import 'task.dart' as _iwn6t6fs;

/// A git repository that agents run tasks against.
abstract class Project
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Project._({
    this.id,
    required this.name,
    required this.repoUrl,
    this.repoAccessTokenUpdatedAt,
    this.dockerImage,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    this.skipPlanning,
    this.autoReview,
    this.reviewerAgentId,
    this.reviewerAgent,
    DateTime? createdAt,
    this.tasks,
  }) : autoFixFailingChecks = autoFixFailingChecks ?? false,
       maxCheckFixAttempts = maxCheckFixAttempts ?? 2,
       createdAt = createdAt ?? DateTime.now();

  factory Project({
    int? id,
    required String name,
    required String repoUrl,
    DateTime? repoAccessTokenUpdatedAt,
    String? dockerImage,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    DateTime? createdAt,
    List<_iwn6t6fs.Task>? tasks,
  }) = _ProjectImpl;

  factory Project.fromJson(Map<String, dynamic> jsonSerialization) {
    return Project(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      repoUrl: jsonSerialization['repoUrl'] as String,
      repoAccessTokenUpdatedAt:
          jsonSerialization['repoAccessTokenUpdatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['repoAccessTokenUpdatedAt'],
            ),
      dockerImage: jsonSerialization['dockerImage'] as String?,
      autoFixFailingChecks: jsonSerialization['autoFixFailingChecks'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['autoFixFailingChecks'],
            ),
      maxCheckFixAttempts: jsonSerialization['maxCheckFixAttempts'] as int?,
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
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      tasks: jsonSerialization['tasks'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<List<_iwn6t6fs.Task>>(
              jsonSerialization['tasks'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The project's display name.
  String name;

  /// The URL of the git repository.
  String repoUrl;

  /// When the token was last set/updated — not sensitive, safe to show in the panel.
  DateTime? repoAccessTokenUpdatedAt;

  /// Base image for agents in docker mode. Only relevant once docker execution mode is implemented.
  String? dockerImage;

  /// Send a task's failing CI checks to its agent automatically, without
  /// waiting for the dev to click "Send to agent".
  bool autoFixFailingChecks;

  /// How many fix runs auto-fix sends for a task before leaving the
  /// failure to the dev; reset once the checks pass.
  int maxCheckFixAttempts;

  /// Default for Task.skipPlanning on new tasks; null inherits WorkspaceSettings.
  bool? skipPlanning;

  /// Default for Task.autoReview; null inherits WorkspaceSettings.
  bool? autoReview;

  int? reviewerAgentId;

  /// Default reviewer for new tasks; null inherits WorkspaceSettings.
  _ijo8h3v4.Agent? reviewerAgent;

  DateTime createdAt;

  List<_iwn6t6fs.Task>? tasks;

  /// Returns a shallow copy of this [Project]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Project copyWith({
    int? id,
    String? name,
    String? repoUrl,
    DateTime? repoAccessTokenUpdatedAt,
    String? dockerImage,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
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
      if (repoAccessTokenUpdatedAt != null)
        'repoAccessTokenUpdatedAt': repoAccessTokenUpdatedAt?.toJson(),
      if (dockerImage != null) 'dockerImage': dockerImage,
      'autoFixFailingChecks': autoFixFailingChecks,
      'maxCheckFixAttempts': maxCheckFixAttempts,
      if (skipPlanning != null) 'skipPlanning': skipPlanning,
      if (autoReview != null) 'autoReview': autoReview,
      if (reviewerAgentId != null) 'reviewerAgentId': reviewerAgentId,
      if (reviewerAgent != null) 'reviewerAgent': reviewerAgent?.toJson(),
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
      if (repoAccessTokenUpdatedAt != null)
        'repoAccessTokenUpdatedAt': repoAccessTokenUpdatedAt?.toJson(),
      if (dockerImage != null) 'dockerImage': dockerImage,
      'autoFixFailingChecks': autoFixFailingChecks,
      'maxCheckFixAttempts': maxCheckFixAttempts,
      if (skipPlanning != null) 'skipPlanning': skipPlanning,
      if (autoReview != null) 'autoReview': autoReview,
      if (reviewerAgentId != null) 'reviewerAgentId': reviewerAgentId,
      if (reviewerAgent != null)
        'reviewerAgent': reviewerAgent?.toJsonForProtocol(),
      'createdAt': createdAt.toJson(),
      if (tasks != null)
        'tasks': tasks?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProjectImpl extends Project {
  _ProjectImpl({
    int? id,
    required String name,
    required String repoUrl,
    DateTime? repoAccessTokenUpdatedAt,
    String? dockerImage,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    _ijo8h3v4.Agent? reviewerAgent,
    DateTime? createdAt,
    List<_iwn6t6fs.Task>? tasks,
  }) : super._(
         id: id,
         name: name,
         repoUrl: repoUrl,
         repoAccessTokenUpdatedAt: repoAccessTokenUpdatedAt,
         dockerImage: dockerImage,
         autoFixFailingChecks: autoFixFailingChecks,
         maxCheckFixAttempts: maxCheckFixAttempts,
         skipPlanning: skipPlanning,
         autoReview: autoReview,
         reviewerAgentId: reviewerAgentId,
         reviewerAgent: reviewerAgent,
         createdAt: createdAt,
         tasks: tasks,
       );

  /// Returns a shallow copy of this [Project]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Project copyWith({
    Object? id = _Undefined,
    String? name,
    String? repoUrl,
    Object? repoAccessTokenUpdatedAt = _Undefined,
    Object? dockerImage = _Undefined,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    Object? skipPlanning = _Undefined,
    Object? autoReview = _Undefined,
    Object? reviewerAgentId = _Undefined,
    Object? reviewerAgent = _Undefined,
    DateTime? createdAt,
    Object? tasks = _Undefined,
  }) {
    return Project(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      repoUrl: repoUrl ?? this.repoUrl,
      repoAccessTokenUpdatedAt: repoAccessTokenUpdatedAt is DateTime?
          ? repoAccessTokenUpdatedAt
          : this.repoAccessTokenUpdatedAt,
      dockerImage: dockerImage is String? ? dockerImage : this.dockerImage,
      autoFixFailingChecks: autoFixFailingChecks ?? this.autoFixFailingChecks,
      maxCheckFixAttempts: maxCheckFixAttempts ?? this.maxCheckFixAttempts,
      skipPlanning: skipPlanning is bool? ? skipPlanning : this.skipPlanning,
      autoReview: autoReview is bool? ? autoReview : this.autoReview,
      reviewerAgentId: reviewerAgentId is int?
          ? reviewerAgentId
          : this.reviewerAgentId,
      reviewerAgent: reviewerAgent is _ijo8h3v4.Agent?
          ? reviewerAgent
          : this.reviewerAgent?.copyWith(),
      createdAt: createdAt ?? this.createdAt,
      tasks: tasks is List<_iwn6t6fs.Task>?
          ? tasks
          : this.tasks?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
