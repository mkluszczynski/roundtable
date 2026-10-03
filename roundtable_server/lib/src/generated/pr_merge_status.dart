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

/// Whether a task's PR can be merged into its base branch. Not a database
/// table — fetched on demand from the GitHub API and never persisted.
abstract class PrMergeStatus
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PrMergeStatus._({
    this.hasConflicts,
    required this.baseBranch,
  });

  factory PrMergeStatus({
    bool? hasConflicts,
    required String baseBranch,
  }) = _PrMergeStatusImpl;

  factory PrMergeStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return PrMergeStatus(
      hasConflicts: jsonSerialization['hasConflicts'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['hasConflicts']),
      baseBranch: jsonSerialization['baseBranch'] as String,
    );
  }

  /// True when the PR conflicts with its base branch; null while GitHub is
  /// still computing mergeability.
  bool? hasConflicts;

  /// The branch the PR merges into (e.g. `main`).
  String baseBranch;

  /// Returns a shallow copy of this [PrMergeStatus]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PrMergeStatus copyWith({
    bool? hasConflicts,
    String? baseBranch,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PrMergeStatus',
      if (hasConflicts != null) 'hasConflicts': hasConflicts,
      'baseBranch': baseBranch,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PrMergeStatus',
      if (hasConflicts != null) 'hasConflicts': hasConflicts,
      'baseBranch': baseBranch,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrMergeStatusImpl extends PrMergeStatus {
  _PrMergeStatusImpl({
    bool? hasConflicts,
    required String baseBranch,
  }) : super._(
         hasConflicts: hasConflicts,
         baseBranch: baseBranch,
       );

  /// Returns a shallow copy of this [PrMergeStatus]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PrMergeStatus copyWith({
    Object? hasConflicts = _Undefined,
    String? baseBranch,
  }) {
    return PrMergeStatus(
      hasConflicts: hasConflicts is bool? ? hasConflicts : this.hasConflicts,
      baseBranch: baseBranch ?? this.baseBranch,
    );
  }
}
