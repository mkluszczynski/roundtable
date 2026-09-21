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

/// Which point in the task lifecycle a piece of feedback was given at.
enum TaskFeedbackPhase implements _isc.SerializableModel {
  /// feedback on the plan, during planReady
  plan,

  /// feedback after the PR, during awaitingReview
  review;

  static TaskFeedbackPhase fromJson(String name) {
    switch (name) {
      case 'plan':
        return TaskFeedbackPhase.plan;
      case 'review':
        return TaskFeedbackPhase.review;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "TaskFeedbackPhase"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
