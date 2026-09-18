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

/// Deliberately no "offline" — that follows from Machine.status, we don't duplicate it on the agent.
/// waitingForResponse is a purely cosmetic distinction from busy — the agent doesn't pick up another
/// task in either state anyway (one task per agent in the MVP).
enum AgentStatus implements _is.SerializableModel {
  idle,
  waitingForResponse,
  busy;

  static AgentStatus fromJson(String name) {
    switch (name) {
      case 'idle':
        return AgentStatus.idle;
      case 'waitingForResponse':
        return AgentStatus.waitingForResponse;
      case 'busy':
        return AgentStatus.busy;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "AgentStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
