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

/// Where a review comment is in the dev's triage → fix loop.
enum ReviewCommentState implements _is.SerializableModel {
  open,

  /// the dev decided not to act on it
  dismissed,

  /// included in feedback sent to the task's agent, fix run pending
  sentToFix,

  /// fixed by the agent's follow-up run, or resolved by hand
  resolved,

  /// a later review found it still not fixed and carried it over as a new comment
  superseded;

  static ReviewCommentState fromJson(String name) {
    switch (name) {
      case 'open':
        return ReviewCommentState.open;
      case 'dismissed':
        return ReviewCommentState.dismissed;
      case 'sentToFix':
        return ReviewCommentState.sentToFix;
      case 'resolved':
        return ReviewCommentState.resolved;
      case 'superseded':
        return ReviewCommentState.superseded;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ReviewCommentState"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
