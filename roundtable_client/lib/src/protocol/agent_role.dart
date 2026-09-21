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

/// An agent's specialty, used as a static prompt prefix. Context, not a permission restriction.
enum AgentRole implements _isc.SerializableModel {
  frontend,
  backend,
  devops,
  fullstack,
  generalist;

  static AgentRole fromJson(String name) {
    switch (name) {
      case 'frontend':
        return AgentRole.frontend;
      case 'backend':
        return AgentRole.backend;
      case 'devops':
        return AgentRole.devops;
      case 'fullstack':
        return AgentRole.fullstack;
      case 'generalist':
        return AgentRole.generalist;
      default:
        throw ArgumentError('Value "$name" cannot be converted to "AgentRole"');
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
