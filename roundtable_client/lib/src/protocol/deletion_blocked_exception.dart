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
import 'deletion_block_reason.dart' as _iwa1mea8;

/// Thrown when deleting a Machine or Agent is blocked by a guard condition
/// (non-terminal tasks, or an online machine).
abstract class DeletionBlockedException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  DeletionBlockedException._({
    required this.message,
    required this.reason,
  });

  factory DeletionBlockedException({
    required String message,
    required _iwa1mea8.DeletionBlockReason reason,
  }) = _DeletionBlockedExceptionImpl;

  factory DeletionBlockedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeletionBlockedException(
      message: jsonSerialization['message'] as String,
      reason: _iwa1mea8.DeletionBlockReason.fromJson(
        (jsonSerialization['reason'] as String),
      ),
    );
  }

  String message;

  _iwa1mea8.DeletionBlockReason reason;

  /// Returns a shallow copy of this [DeletionBlockedException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DeletionBlockedException copyWith({
    String? message,
    _iwa1mea8.DeletionBlockReason? reason,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeletionBlockedException',
      'message': message,
      'reason': reason.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeletionBlockedException',
      'message': message,
      'reason': reason.toJson(),
    };
  }

  @override
  String toString() {
    return 'DeletionBlockedException(message: $message, reason: $reason)';
  }
}

class _DeletionBlockedExceptionImpl extends DeletionBlockedException {
  _DeletionBlockedExceptionImpl({
    required String message,
    required _iwa1mea8.DeletionBlockReason reason,
  }) : super._(
         message: message,
         reason: reason,
       );

  /// Returns a shallow copy of this [DeletionBlockedException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DeletionBlockedException copyWith({
    String? message,
    _iwa1mea8.DeletionBlockReason? reason,
  }) {
    return DeletionBlockedException(
      message: message ?? this.message,
      reason: reason ?? this.reason,
    );
  }
}
