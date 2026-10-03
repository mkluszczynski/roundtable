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
import 'review_comment_severity.dart' as _iml08ymk;

/// A comment as produced by the reviewer agent, before it's stored as a [ReviewComment].
/// Not a database table — only the daemon → server upload format.
abstract class ReviewCommentDraft
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ReviewCommentDraft._({
    required this.path,
    this.line,
    required this.body,
    required this.severity,
  });

  factory ReviewCommentDraft({
    required String path,
    int? line,
    required String body,
    required _iml08ymk.ReviewCommentSeverity severity,
  }) = _ReviewCommentDraftImpl;

  factory ReviewCommentDraft.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReviewCommentDraft(
      path: jsonSerialization['path'] as String,
      line: jsonSerialization['line'] as int?,
      body: jsonSerialization['body'] as String,
      severity: _iml08ymk.ReviewCommentSeverity.fromJson(
        (jsonSerialization['severity'] as String),
      ),
    );
  }

  String path;

  int? line;

  String body;

  _iml08ymk.ReviewCommentSeverity severity;

  /// Returns a shallow copy of this [ReviewCommentDraft]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ReviewCommentDraft copyWith({
    String? path,
    int? line,
    String? body,
    _iml08ymk.ReviewCommentSeverity? severity,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReviewCommentDraft',
      'path': path,
      if (line != null) 'line': line,
      'body': body,
      'severity': severity.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReviewCommentDraft',
      'path': path,
      if (line != null) 'line': line,
      'body': body,
      'severity': severity.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReviewCommentDraftImpl extends ReviewCommentDraft {
  _ReviewCommentDraftImpl({
    required String path,
    int? line,
    required String body,
    required _iml08ymk.ReviewCommentSeverity severity,
  }) : super._(
         path: path,
         line: line,
         body: body,
         severity: severity,
       );

  /// Returns a shallow copy of this [ReviewCommentDraft]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ReviewCommentDraft copyWith({
    String? path,
    Object? line = _Undefined,
    String? body,
    _iml08ymk.ReviewCommentSeverity? severity,
  }) {
    return ReviewCommentDraft(
      path: path ?? this.path,
      line: line is int? ? line : this.line,
      body: body ?? this.body,
      severity: severity ?? this.severity,
    );
  }
}
