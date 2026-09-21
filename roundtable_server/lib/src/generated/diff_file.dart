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

/// One changed file from a task's PR (design doc §6.7). Not a database table
/// — fetched on demand from the GitHub API and never persisted.
abstract class DiffFile
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DiffFile._({
    required this.filename,
    required this.status,
    required this.additions,
    required this.deletions,
    this.patch,
    required this.contentsUrl,
  });

  factory DiffFile({
    required String filename,
    required String status,
    required int additions,
    required int deletions,
    String? patch,
    required String contentsUrl,
  }) = _DiffFileImpl;

  factory DiffFile.fromJson(Map<String, dynamic> jsonSerialization) {
    return DiffFile(
      filename: jsonSerialization['filename'] as String,
      status: jsonSerialization['status'] as String,
      additions: jsonSerialization['additions'] as int,
      deletions: jsonSerialization['deletions'] as int,
      patch: jsonSerialization['patch'] as String?,
      contentsUrl: jsonSerialization['contentsUrl'] as String,
    );
  }

  String filename;

  /// GitHub's own status vocabulary (added/modified/removed/renamed/...) —
  /// kept as String rather than an enum, same reasoning as Agent.defaultModel:
  /// it's GitHub's vocabulary to extend, not ours to migrate a schema for.
  String status;

  int additions;

  int deletions;

  /// Absent for binary files.
  String? patch;

  /// Passed back into TaskEndpoint.getFileContent to fetch this file's full
  /// content at this ref.
  String contentsUrl;

  /// Returns a shallow copy of this [DiffFile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DiffFile copyWith({
    String? filename,
    String? status,
    int? additions,
    int? deletions,
    String? patch,
    String? contentsUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DiffFile',
      'filename': filename,
      'status': status,
      'additions': additions,
      'deletions': deletions,
      if (patch != null) 'patch': patch,
      'contentsUrl': contentsUrl,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DiffFile',
      'filename': filename,
      'status': status,
      'additions': additions,
      'deletions': deletions,
      if (patch != null) 'patch': patch,
      'contentsUrl': contentsUrl,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DiffFileImpl extends DiffFile {
  _DiffFileImpl({
    required String filename,
    required String status,
    required int additions,
    required int deletions,
    String? patch,
    required String contentsUrl,
  }) : super._(
         filename: filename,
         status: status,
         additions: additions,
         deletions: deletions,
         patch: patch,
         contentsUrl: contentsUrl,
       );

  /// Returns a shallow copy of this [DiffFile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DiffFile copyWith({
    String? filename,
    String? status,
    int? additions,
    int? deletions,
    Object? patch = _Undefined,
    String? contentsUrl,
  }) {
    return DiffFile(
      filename: filename ?? this.filename,
      status: status ?? this.status,
      additions: additions ?? this.additions,
      deletions: deletions ?? this.deletions,
      patch: patch is String? ? patch : this.patch,
      contentsUrl: contentsUrl ?? this.contentsUrl,
    );
  }
}
