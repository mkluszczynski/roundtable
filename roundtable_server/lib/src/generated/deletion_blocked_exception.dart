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

/// Thrown when deleting a Machine or Agent is blocked by a guard condition
/// (non-terminal tasks, or an online machine).
abstract class DeletionBlockedException
    implements
        _is.SerializableException,
        _is.SerializableModel,
        _is.ProtocolSerialization {
  DeletionBlockedException._({required this.message});

  factory DeletionBlockedException({required String message}) =
      _DeletionBlockedExceptionImpl;

  factory DeletionBlockedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeletionBlockedException(
      message: jsonSerialization['message'] as String,
    );
  }

  String message;

  /// Returns a shallow copy of this [DeletionBlockedException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DeletionBlockedException copyWith({String? message});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeletionBlockedException',
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeletionBlockedException',
      'message': message,
    };
  }

  @override
  String toString() {
    return 'DeletionBlockedException(message: $message)';
  }
}

class _DeletionBlockedExceptionImpl extends DeletionBlockedException {
  _DeletionBlockedExceptionImpl({required String message})
    : super._(message: message);

  /// Returns a shallow copy of this [DeletionBlockedException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DeletionBlockedException copyWith({String? message}) {
    return DeletionBlockedException(message: message ?? this.message);
  }
}
