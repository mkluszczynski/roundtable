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

/// One toolchain a project needs, installed by the runner via mise.
abstract class ProjectTool
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ProjectTool._({
    required this.name,
    required this.version,
  });

  factory ProjectTool({
    required String name,
    required String version,
  }) = _ProjectToolImpl;

  factory ProjectTool.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProjectTool(
      name: jsonSerialization['name'] as String,
      version: jsonSerialization['version'] as String,
    );
  }

  /// The mise tool id, e.g. `flutter`, `node`, `python`.
  String name;

  /// A mise version spec: `3.24`, `20.11.1`, `lts` or `latest`.
  String version;

  /// Returns a shallow copy of this [ProjectTool]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ProjectTool copyWith({
    String? name,
    String? version,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProjectTool',
      'name': name,
      'version': version,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProjectTool',
      'name': name,
      'version': version,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ProjectToolImpl extends ProjectTool {
  _ProjectToolImpl({
    required String name,
    required String version,
  }) : super._(
         name: name,
         version: version,
       );

  /// Returns a shallow copy of this [ProjectTool]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ProjectTool copyWith({
    String? name,
    String? version,
  }) {
    return ProjectTool(
      name: name ?? this.name,
      version: version ?? this.version,
    );
  }
}
