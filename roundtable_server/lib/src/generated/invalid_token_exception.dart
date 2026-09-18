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
import 'package:serverpod/serverpod.dart' as _is;

/// Thrown when a machine's registration token doesn't match any known,
/// currently-valid Machine — unknown, wrong, or already revoked via
/// MachineEndpoint.deregister (design doc §6.8).
abstract class InvalidTokenException
    implements
        _is.SerializableException,
        _is.SerializableModel,
        _is.ProtocolSerialization {
  InvalidTokenException._({required this.message});

  factory InvalidTokenException({required String message}) =
      _InvalidTokenExceptionImpl;

  factory InvalidTokenException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return InvalidTokenException(
      message: jsonSerialization['message'] as String,
    );
  }

  String message;

  /// Returns a shallow copy of this [InvalidTokenException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  InvalidTokenException copyWith({String? message});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InvalidTokenException',
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'InvalidTokenException',
      'message': message,
    };
  }

  @override
  String toString() {
    return 'InvalidTokenException(message: $message)';
  }
}

class _InvalidTokenExceptionImpl extends InvalidTokenException {
  _InvalidTokenExceptionImpl({required String message})
    : super._(message: message);

  /// Returns a shallow copy of this [InvalidTokenException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  InvalidTokenException copyWith({String? message}) {
    return InvalidTokenException(message: message ?? this.message);
  }
}
