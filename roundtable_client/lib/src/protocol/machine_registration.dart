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

/// Returned once from Machine registration: the persisted Machine plus the raw
/// registration token, shown to the dev exactly this one time (design doc §6.8).
/// Not a database table — a transient wrapper for the endpoint response.
///
/// serverUrl and scriptUrl can differ: serverUrl is the API server the
/// installed agent-runner connects to, scriptUrl is where the install
/// script itself is hosted (the web server).
abstract class MachineRegistration
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MachineRegistration._({
    required this.machine,
    required this.token,
    required this.serverUrl,
    required this.scriptUrl,
  });

  factory MachineRegistration({
    required _i0hti3f2.Machine machine,
    required String token,
    required String serverUrl,
    required String scriptUrl,
  }) = _MachineRegistrationImpl;

  factory MachineRegistration.fromJson(Map<String, dynamic> jsonSerialization) {
    return MachineRegistration(
      machine: _i35hmugi.Protocol().deserialize<_i0hti3f2.Machine>(
        jsonSerialization['machine'],
      ),
      token: jsonSerialization['token'] as String,
      serverUrl: jsonSerialization['serverUrl'] as String,
      scriptUrl: jsonSerialization['scriptUrl'] as String,
    );
  }

  _i0hti3f2.Machine machine;

  String token;

  String serverUrl;

  String scriptUrl;

  /// Returns a shallow copy of this [MachineRegistration]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MachineRegistration copyWith({
    _i0hti3f2.Machine? machine,
    String? token,
    String? serverUrl,
    String? scriptUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MachineRegistration',
      'machine': machine.toJson(),
      'token': token,
      'serverUrl': serverUrl,
      'scriptUrl': scriptUrl,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MachineRegistration',
      'machine': machine.toJsonForProtocol(),
      'token': token,
      'serverUrl': serverUrl,
      'scriptUrl': scriptUrl,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _MachineRegistrationImpl extends MachineRegistration {
  _MachineRegistrationImpl({
    required _i0hti3f2.Machine machine,
    required String token,
    required String serverUrl,
    required String scriptUrl,
  }) : super._(
         machine: machine,
         token: token,
         serverUrl: serverUrl,
         scriptUrl: scriptUrl,
       );

  /// Returns a shallow copy of this [MachineRegistration]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MachineRegistration copyWith({
    _i0hti3f2.Machine? machine,
    String? token,
    String? serverUrl,
    String? scriptUrl,
  }) {
    return MachineRegistration(
      machine: machine ?? this.machine.copyWith(),
      token: token ?? this.token,
      serverUrl: serverUrl ?? this.serverUrl,
      scriptUrl: scriptUrl ?? this.scriptUrl,
    );
  }
}
