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

/// The aggregated GitHub Actions result for a task PR's current head commit
/// (`Task.prHeadSha`), kept on the task so the kanban needs no extra query.
enum PrCheckState implements _is.SerializableModel {
  /// No workflow ran for the head commit (a repo without CI), or the PR
  /// hasn't been checked yet.
  none,

  /// At least one job is queued or running, or a new commit's workflows
  /// haven't started yet.
  pending,

  /// Every job finished successfully (or was skipped).
  success,

  /// At least one job failed, timed out or was cancelled.
  failure;

  static PrCheckState fromJson(String name) {
    switch (name) {
      case 'none':
        return PrCheckState.none;
      case 'pending':
        return PrCheckState.pending;
      case 'success':
        return PrCheckState.success;
      case 'failure':
        return PrCheckState.failure;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "PrCheckState"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
