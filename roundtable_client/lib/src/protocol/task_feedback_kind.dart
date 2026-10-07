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

/// Why a review-phase [TaskFeedback] was sent — the task's timeline names
/// the run it starts after it.
enum TaskFeedbackKind implements _isc.SerializableModel {
  /// the dev's own message
  dev,

  /// AI review comments (by hand or auto fix)
  reviewComments,

  /// failing CI checks
  checks,

  /// merge conflicts with the base branch
  conflicts;

  static TaskFeedbackKind fromJson(String name) {
    switch (name) {
      case 'dev':
        return TaskFeedbackKind.dev;
      case 'reviewComments':
        return TaskFeedbackKind.reviewComments;
      case 'checks':
        return TaskFeedbackKind.checks;
      case 'conflicts':
        return TaskFeedbackKind.conflicts;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "TaskFeedbackKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
