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
import 'agent_effort.dart' as _iexg9pz4;
import 'agent_execution_mode.dart' as _i4babe00;
import 'agent_role.dart' as _idfmm35v;
import 'agent_status.dart' as _i69bozh7;
import 'machine.dart' as _i0hti3f2;
import 'task.dart' as _iwn6t6fs;

/// A named persona hosted on a machine, with a role and its own status.
abstract class Agent
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
          : _i35hmugi.Protocol().deserialize<_i0hti3f2.Machine>(
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

  /// Returns a shallow copy of this [Agent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
  @_isc.useResult
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
