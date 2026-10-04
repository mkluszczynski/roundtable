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
import 'package:roundtable_server/src/generated/protocol.dart' as _iikm6kmi;
import 'package:serverpod/serverpod.dart' as _is;
import 'pr_check_run.dart' as _idxabcvw;
import 'pr_check_state.dart' as _ivypql97;

/// A snapshot of a task's CI checks, streamed to the panel by
/// `TaskEndpoint.watchChecks`. Not a database table.
abstract class PrChecks
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PrChecks._({
    required this.taskId,
    this.headSha,
    required this.state,
    this.error,
    required this.runs,
  });

  factory PrChecks({
    required int taskId,
    String? headSha,
    required _ivypql97.PrCheckState state,
    String? error,
    required List<_idxabcvw.PrCheckRun> runs,
  }) = _PrChecksImpl;

  factory PrChecks.fromJson(Map<String, dynamic> jsonSerialization) {
    return PrChecks(
      taskId: jsonSerialization['taskId'] as int,
      headSha: jsonSerialization['headSha'] as String?,
      state: _ivypql97.PrCheckState.fromJson(
        (jsonSerialization['state'] as String),
      ),
      error: jsonSerialization['error'] as String?,
      runs: _iikm6kmi.Protocol().deserialize<List<_idxabcvw.PrCheckRun>>(
        jsonSerialization['runs'],
      ),
    );
  }

  int taskId;

  /// The head commit [runs] belong to; null until the PR was first checked.
  String? headSha;

  _ivypql97.PrCheckState state;

  /// Why the checks can't be read (`Task.checkError`), e.g. the project
  /// token lacks "Actions: Read".
  String? error;

  /// Oldest workflow first, jobs in GitHub's order.
  List<_idxabcvw.PrCheckRun> runs;

  /// Returns a shallow copy of this [PrChecks]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PrChecks copyWith({
    int? taskId,
    String? headSha,
    _ivypql97.PrCheckState? state,
    String? error,
    List<_idxabcvw.PrCheckRun>? runs,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PrChecks',
      'taskId': taskId,
      if (headSha != null) 'headSha': headSha,
      'state': state.toJson(),
      if (error != null) 'error': error,
      'runs': runs.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PrChecks',
      'taskId': taskId,
      if (headSha != null) 'headSha': headSha,
      'state': state.toJson(),
      if (error != null) 'error': error,
      'runs': runs.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrChecksImpl extends PrChecks {
  _PrChecksImpl({
    required int taskId,
    String? headSha,
    required _ivypql97.PrCheckState state,
    String? error,
    required List<_idxabcvw.PrCheckRun> runs,
  }) : super._(
         taskId: taskId,
         headSha: headSha,
         state: state,
         error: error,
         runs: runs,
       );

  /// Returns a shallow copy of this [PrChecks]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PrChecks copyWith({
    int? taskId,
    Object? headSha = _Undefined,
    _ivypql97.PrCheckState? state,
    Object? error = _Undefined,
    List<_idxabcvw.PrCheckRun>? runs,
  }) {
    return PrChecks(
      taskId: taskId ?? this.taskId,
      headSha: headSha is String? ? headSha : this.headSha,
      state: state ?? this.state,
      error: error is String? ? error : this.error,
      runs: runs ?? this.runs.map((e0) => e0.copyWith()).toList(),
    );
  }
}
