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

/// Whether a machine's daemon is currently connected and sending a heartbeat.
enum MachineStatus implements _isc.SerializableModel {
  offline,
  online;

  static MachineStatus fromJson(String name) {
    switch (name) {
      case 'offline':
        return MachineStatus.offline;
      case 'online':
        return MachineStatus.online;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "MachineStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
