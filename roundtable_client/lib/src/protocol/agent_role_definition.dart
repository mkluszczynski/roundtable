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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// An agent's specialty, edited in the panel's Settings. Its [prompt] is
/// the static prefix of every task and review prompt the agent gets.
/// Context, not a permission restriction.
abstract class AgentRoleDefinition
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Shown on agent cards, e.g. "backend".
  String name;

  /// One line for the role pickers.
  String? description;

  /// Prompt prefix; `{name}` is replaced with the agent's own name.
  String prompt;

  DateTime createdAt;

  /// Returns a shallow copy of this [AgentRoleDefinition]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
  @_isc.useResult
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
