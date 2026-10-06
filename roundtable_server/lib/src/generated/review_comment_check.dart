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

/// The reviewer's verdict on a comment from an earlier review of the same task.
/// Not a database table — only the daemon → server upload format.
abstract class ReviewCommentCheck
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ReviewCommentCheck._({
    required this.commentId,
    required this.fixed,
    this.note,
  });

  factory ReviewCommentCheck({
    required int commentId,
    required bool fixed,
    String? note,
  }) = _ReviewCommentCheckImpl;

  factory ReviewCommentCheck.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReviewCommentCheck(
      commentId: jsonSerialization['commentId'] as int,
      fixed: _is.BoolJsonExtension.fromJson(jsonSerialization['fixed']),
      note: jsonSerialization['note'] as String?,
    );
  }

  int commentId;

  bool fixed;

  /// Why it's not fixed yet, in the reviewer's words; becomes the carried-over comment's body.
  String? note;

  /// Returns a shallow copy of this [ReviewCommentCheck]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ReviewCommentCheck copyWith({
    int? commentId,
    bool? fixed,
    String? note,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReviewCommentCheck',
      'commentId': commentId,
      'fixed': fixed,
      if (note != null) 'note': note,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReviewCommentCheck',
      'commentId': commentId,
      'fixed': fixed,
      if (note != null) 'note': note,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReviewCommentCheckImpl extends ReviewCommentCheck {
  _ReviewCommentCheckImpl({
    required int commentId,
    required bool fixed,
    String? note,
  }) : super._(
         commentId: commentId,
         fixed: fixed,
         note: note,
       );

  /// Returns a shallow copy of this [ReviewCommentCheck]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ReviewCommentCheck copyWith({
    int? commentId,
    bool? fixed,
    Object? note = _Undefined,
  }) {
    return ReviewCommentCheck(
      commentId: commentId ?? this.commentId,
      fixed: fixed ?? this.fixed,
      note: note is String? ? note : this.note,
    );
  }
}
