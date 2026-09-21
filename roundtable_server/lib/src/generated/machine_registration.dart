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
import 'package:roundtable_server/src/generated/protocol.dart' as _iikm6kmi;
import 'package:serverpod/serverpod.dart' as _is;
import 'machine.dart' as _i0hti3f2;

/// Returned once from Machine registration: the persisted Machine plus the raw
/// registration token, shown to the dev exactly this one time (design doc §6.8).
/// Not a database table — a transient wrapper for the endpoint response.
abstract class MachineRegistration
    implements _is.SerializableModel, _is.ProtocolSerialization {
  MachineRegistration._({
    required this.machine,
    required this.token,
  });

  factory MachineRegistration({
    required _i0hti3f2.Machine machine,
    required String token,
  }) = _MachineRegistrationImpl;

  factory MachineRegistration.fromJson(Map<String, dynamic> jsonSerialization) {
    return MachineRegistration(
      machine: _iikm6kmi.Protocol().deserialize<_i0hti3f2.Machine>(
        jsonSerialization['machine'],
      ),
      token: jsonSerialization['token'] as String,
    );
  }

  _i0hti3f2.Machine machine;

  String token;

  /// Returns a shallow copy of this [MachineRegistration]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MachineRegistration copyWith({
    _i0hti3f2.Machine? machine,
    String? token,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MachineRegistration',
      'machine': machine.toJson(),
      'token': token,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MachineRegistration',
      'machine': machine.toJsonForProtocol(),
      'token': token,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _MachineRegistrationImpl extends MachineRegistration {
  _MachineRegistrationImpl({
    required _i0hti3f2.Machine machine,
    required String token,
  }) : super._(
         machine: machine,
         token: token,
       );

  /// Returns a shallow copy of this [MachineRegistration]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MachineRegistration copyWith({
    _i0hti3f2.Machine? machine,
    String? token,
  }) {
    return MachineRegistration(
      machine: machine ?? this.machine.copyWith(),
      token: token ?? this.token,
    );
  }
}
