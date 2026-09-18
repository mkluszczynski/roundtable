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
import 'machine_metric.dart' as _ixivwx7g;
import 'machine_status.dart' as _i6yugb3s;

/// A registered host (laptop, VPS) running the agent daemon. Pure infrastructure — an Agent is the
/// persona living on it.
abstract class Machine
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Machine._({
    this.id,
    required this.name,
    _i6yugb3s.MachineStatus? status,
    this.lastSeenAt,
    DateTime? createdAt,
    this.agents,
    this.metrics,
  }) : status = status ?? _i6yugb3s.MachineStatus.offline,
       createdAt = createdAt ?? DateTime.now();

  factory Machine({
    int? id,
    required String name,
    _i6yugb3s.MachineStatus? status,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    List<_ijo8h3v4.Agent>? agents,
    List<_ixivwx7g.MachineMetric>? metrics,
  }) = _MachineImpl;

  factory Machine.fromJson(Map<String, dynamic> jsonSerialization) {
    return Machine(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      status: jsonSerialization['status'] == null
          ? null
          : _i6yugb3s.MachineStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      lastSeenAt: jsonSerialization['lastSeenAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastSeenAt'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      agents: jsonSerialization['agents'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<List<_ijo8h3v4.Agent>>(
              jsonSerialization['agents'],
            ),
      metrics: jsonSerialization['metrics'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<List<_ixivwx7g.MachineMetric>>(
              jsonSerialization['metrics'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The machine's display name.
  String name;

  _i6yugb3s.MachineStatus status;

  /// Last time a heartbeat was received from this machine's daemon.
  DateTime? lastSeenAt;

  DateTime createdAt;

  List<_ijo8h3v4.Agent>? agents;

  List<_ixivwx7g.MachineMetric>? metrics;

  /// Returns a shallow copy of this [Machine]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Machine copyWith({
    int? id,
    String? name,
    _i6yugb3s.MachineStatus? status,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    List<_ijo8h3v4.Agent>? agents,
    List<_ixivwx7g.MachineMetric>? metrics,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Machine',
      if (id != null) 'id': id,
      'name': name,
      'status': status.toJson(),
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt?.toJson(),
      'createdAt': createdAt.toJson(),
      if (agents != null)
        'agents': agents?.toJson(valueToJson: (v) => v.toJson()),
      if (metrics != null)
        'metrics': metrics?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Machine',
      if (id != null) 'id': id,
      'name': name,
      'status': status.toJson(),
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt?.toJson(),
      'createdAt': createdAt.toJson(),
      if (agents != null)
        'agents': agents?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (metrics != null)
        'metrics': metrics?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MachineImpl extends Machine {
  _MachineImpl({
    int? id,
    required String name,
    _i6yugb3s.MachineStatus? status,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    List<_ijo8h3v4.Agent>? agents,
    List<_ixivwx7g.MachineMetric>? metrics,
  }) : super._(
         id: id,
         name: name,
         status: status,
         lastSeenAt: lastSeenAt,
         createdAt: createdAt,
         agents: agents,
         metrics: metrics,
       );

  /// Returns a shallow copy of this [Machine]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Machine copyWith({
    Object? id = _Undefined,
    String? name,
    _i6yugb3s.MachineStatus? status,
    Object? lastSeenAt = _Undefined,
    DateTime? createdAt,
    Object? agents = _Undefined,
    Object? metrics = _Undefined,
  }) {
    return Machine(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      lastSeenAt: lastSeenAt is DateTime? ? lastSeenAt : this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      agents: agents is List<_ijo8h3v4.Agent>?
          ? agents
          : this.agents?.map((e0) => e0.copyWith()).toList(),
      metrics: metrics is List<_ixivwx7g.MachineMetric>?
          ? metrics
          : this.metrics?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
