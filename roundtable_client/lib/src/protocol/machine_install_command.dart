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

/// Returned once from MachineEndpoint.createEnrollment: the raw one-time
/// enrollment token plus the URLs the panel folds into the install command
/// (docs/FLOWS.md §1). Not a database table.
///
/// serverUrl and scriptUrl can differ: serverUrl is the API server the
/// installed agent-runner connects to, scriptUrl is where the install
/// script itself is hosted (the web server).
abstract class MachineInstallCommand
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MachineInstallCommand._({
    required this.enrollmentId,
    required this.enrollmentToken,
    required this.expiresAt,
    required this.serverUrl,
    required this.scriptUrl,
  });

  factory MachineInstallCommand({
    required int enrollmentId,
    required String enrollmentToken,
    required DateTime expiresAt,
    required String serverUrl,
    required String scriptUrl,
  }) = _MachineInstallCommandImpl;

  factory MachineInstallCommand.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MachineInstallCommand(
      enrollmentId: jsonSerialization['enrollmentId'] as int,
      enrollmentToken: jsonSerialization['enrollmentToken'] as String,
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      serverUrl: jsonSerialization['serverUrl'] as String,
      scriptUrl: jsonSerialization['scriptUrl'] as String,
    );
  }

  int enrollmentId;

  String enrollmentToken;

  DateTime expiresAt;

  String serverUrl;

  String scriptUrl;

  /// Returns a shallow copy of this [MachineInstallCommand]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MachineInstallCommand copyWith({
    int? enrollmentId,
    String? enrollmentToken,
    DateTime? expiresAt,
    String? serverUrl,
    String? scriptUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MachineInstallCommand',
      'enrollmentId': enrollmentId,
      'enrollmentToken': enrollmentToken,
      'expiresAt': expiresAt.toJson(),
      'serverUrl': serverUrl,
      'scriptUrl': scriptUrl,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MachineInstallCommand',
      'enrollmentId': enrollmentId,
      'enrollmentToken': enrollmentToken,
      'expiresAt': expiresAt.toJson(),
      'serverUrl': serverUrl,
      'scriptUrl': scriptUrl,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _MachineInstallCommandImpl extends MachineInstallCommand {
  _MachineInstallCommandImpl({
    required int enrollmentId,
    required String enrollmentToken,
    required DateTime expiresAt,
    required String serverUrl,
    required String scriptUrl,
  }) : super._(
         enrollmentId: enrollmentId,
         enrollmentToken: enrollmentToken,
         expiresAt: expiresAt,
         serverUrl: serverUrl,
         scriptUrl: scriptUrl,
       );

  /// Returns a shallow copy of this [MachineInstallCommand]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MachineInstallCommand copyWith({
    int? enrollmentId,
    String? enrollmentToken,
    DateTime? expiresAt,
    String? serverUrl,
    String? scriptUrl,
  }) {
    return MachineInstallCommand(
      enrollmentId: enrollmentId ?? this.enrollmentId,
      enrollmentToken: enrollmentToken ?? this.enrollmentToken,
      expiresAt: expiresAt ?? this.expiresAt,
      serverUrl: serverUrl ?? this.serverUrl,
      scriptUrl: scriptUrl ?? this.scriptUrl,
    );
  }
}
