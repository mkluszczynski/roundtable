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

/// The lifecycle of a single task, from creation to a terminal state.
enum TaskStatus implements _isc.SerializableModel {
  queued,
  cloning,

  /// skipped entirely when Task.skipPlanning = true
  planning,

  /// task is waiting for an answer to a plan-mode question (AskUserQuestion)
  waitingForAnswer,

  /// plan ready, waiting for the dev to approve or give feedback (ExitPlanMode)
  planReady,
  running,
  awaitingReview,
  done,
  failed,
  cancelled;

  static TaskStatus fromJson(String name) {
    switch (name) {
      case 'queued':
        return TaskStatus.queued;
      case 'cloning':
        return TaskStatus.cloning;
      case 'planning':
        return TaskStatus.planning;
      case 'waitingForAnswer':
        return TaskStatus.waitingForAnswer;
      case 'planReady':
        return TaskStatus.planReady;
      case 'running':
        return TaskStatus.running;
      case 'awaitingReview':
        return TaskStatus.awaitingReview;
      case 'done':
        return TaskStatus.done;
      case 'failed':
        return TaskStatus.failed;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "TaskStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
