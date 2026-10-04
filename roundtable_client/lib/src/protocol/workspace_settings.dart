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

/// Workspace-wide settings — a single row while the app is single-tenant.
/// Holds the defaults a project inherits unless it overrides them.
abstract class WorkspaceSettings
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceSettings._({
    this.id,
    bool? skipPlanning,
    DateTime? updatedAt,
  }) : skipPlanning = skipPlanning ?? false,
       updatedAt = updatedAt ?? DateTime.now();

  factory WorkspaceSettings({
    int? id,
    bool? skipPlanning,
    DateTime? updatedAt,
  }) = _WorkspaceSettingsImpl;

  factory WorkspaceSettings.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceSettings(
      id: jsonSerialization['id'] as int?,
      skipPlanning: jsonSerialization['skipPlanning'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['skipPlanning']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Default for Task.skipPlanning on new tasks.
  bool skipPlanning;

  DateTime updatedAt;

  /// Returns a shallow copy of this [WorkspaceSettings]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceSettings copyWith({
    int? id,
    bool? skipPlanning,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceSettings',
      if (id != null) 'id': id,
      'skipPlanning': skipPlanning,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceSettings',
      if (id != null) 'id': id,
      'skipPlanning': skipPlanning,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceSettingsImpl extends WorkspaceSettings {
  _WorkspaceSettingsImpl({
    int? id,
    bool? skipPlanning,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         skipPlanning: skipPlanning,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [WorkspaceSettings]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceSettings copyWith({
    Object? id = _Undefined,
    bool? skipPlanning,
    DateTime? updatedAt,
  }) {
    return WorkspaceSettings(
      id: id is int? ? id : this.id,
      skipPlanning: skipPlanning ?? this.skipPlanning,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
