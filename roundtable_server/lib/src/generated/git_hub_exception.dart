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

/// Thrown when a GitHub API call made on the panel's behalf fails (non-2xx
/// response or timeout). [message] is meant to be shown as-is;
/// [statusCode] is GitHub's HTTP status (504 for a timeout).
abstract class GitHubException
    implements
        _is.SerializableException,
        _is.SerializableModel,
        _is.ProtocolSerialization {
  GitHubException._({
    required this.message,
    required this.statusCode,
  });

  factory GitHubException({
    required String message,
    required int statusCode,
  }) = _GitHubExceptionImpl;

  factory GitHubException.fromJson(Map<String, dynamic> jsonSerialization) {
    return GitHubException(
      message: jsonSerialization['message'] as String,
      statusCode: jsonSerialization['statusCode'] as int,
    );
  }

  String message;

  int statusCode;

  /// Returns a shallow copy of this [GitHubException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  GitHubException copyWith({
    String? message,
    int? statusCode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GitHubException',
      'message': message,
      'statusCode': statusCode,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GitHubException',
      'message': message,
      'statusCode': statusCode,
    };
  }

  @override
  String toString() {
    return 'GitHubException(message: $message, statusCode: $statusCode)';
  }
}

class _GitHubExceptionImpl extends GitHubException {
  _GitHubExceptionImpl({
    required String message,
    required int statusCode,
  }) : super._(
         message: message,
         statusCode: statusCode,
       );

  /// Returns a shallow copy of this [GitHubException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  GitHubException copyWith({
    String? message,
    int? statusCode,
  }) {
    return GitHubException(
      message: message ?? this.message,
      statusCode: statusCode ?? this.statusCode,
    );
  }
}
