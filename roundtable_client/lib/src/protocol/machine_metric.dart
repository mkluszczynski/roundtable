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
import 'machine.dart' as _i0hti3f2;

/// A single CPU/RAM reading reported by a machine's daemon. Grows over time — needs periodic
/// cleanup of old entries.
abstract class MachineMetric
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MachineMetric._({
    this.id,
    required this.machineId,
    this.machine,
    required this.cpuPercent,
    required this.memoryUsedMb,
    required this.memoryTotalMb,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  factory MachineMetric({
    int? id,
    required int machineId,
    _i0hti3f2.Machine? machine,
    required double cpuPercent,
    required int memoryUsedMb,
    required int memoryTotalMb,
    DateTime? recordedAt,
  }) = _MachineMetricImpl;

  factory MachineMetric.fromJson(Map<String, dynamic> jsonSerialization) {
    return MachineMetric(
      id: jsonSerialization['id'] as int?,
      machineId: jsonSerialization['machineId'] as int,
      machine: jsonSerialization['machine'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<_i0hti3f2.Machine>(
              jsonSerialization['machine'],
            ),
      cpuPercent: (jsonSerialization['cpuPercent'] as num).toDouble(),
      memoryUsedMb: jsonSerialization['memoryUsedMb'] as int,
      memoryTotalMb: jsonSerialization['memoryTotalMb'] as int,
      recordedAt: jsonSerialization['recordedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['recordedAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int machineId;

  _i0hti3f2.Machine? machine;

  double cpuPercent;

  int memoryUsedMb;

  int memoryTotalMb;

  DateTime recordedAt;

  /// Returns a shallow copy of this [MachineMetric]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MachineMetric copyWith({
    int? id,
    int? machineId,
    _i0hti3f2.Machine? machine,
    double? cpuPercent,
    int? memoryUsedMb,
    int? memoryTotalMb,
    DateTime? recordedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MachineMetric',
      if (id != null) 'id': id,
      'machineId': machineId,
      if (machine != null) 'machine': machine?.toJson(),
      'cpuPercent': cpuPercent,
      'memoryUsedMb': memoryUsedMb,
      'memoryTotalMb': memoryTotalMb,
      'recordedAt': recordedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MachineMetric',
      if (id != null) 'id': id,
      'machineId': machineId,
      if (machine != null) 'machine': machine?.toJsonForProtocol(),
      'cpuPercent': cpuPercent,
      'memoryUsedMb': memoryUsedMb,
      'memoryTotalMb': memoryTotalMb,
      'recordedAt': recordedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MachineMetricImpl extends MachineMetric {
  _MachineMetricImpl({
    int? id,
    required int machineId,
    _i0hti3f2.Machine? machine,
    required double cpuPercent,
    required int memoryUsedMb,
    required int memoryTotalMb,
    DateTime? recordedAt,
  }) : super._(
         id: id,
         machineId: machineId,
         machine: machine,
         cpuPercent: cpuPercent,
         memoryUsedMb: memoryUsedMb,
         memoryTotalMb: memoryTotalMb,
         recordedAt: recordedAt,
       );

  /// Returns a shallow copy of this [MachineMetric]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MachineMetric copyWith({
    Object? id = _Undefined,
    int? machineId,
    Object? machine = _Undefined,
    double? cpuPercent,
    int? memoryUsedMb,
    int? memoryTotalMb,
    DateTime? recordedAt,
  }) {
    return MachineMetric(
      id: id is int? ? id : this.id,
      machineId: machineId ?? this.machineId,
      machine: machine is _i0hti3f2.Machine?
          ? machine
          : this.machine?.copyWith(),
      cpuPercent: cpuPercent ?? this.cpuPercent,
      memoryUsedMb: memoryUsedMb ?? this.memoryUsedMb,
      memoryTotalMb: memoryTotalMb ?? this.memoryTotalMb,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}
