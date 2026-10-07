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
import 'package:roundtable_client/src/protocol/protocol.dart' as _i35hmugi;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'agent.dart' as _ijo8h3v4;
import 'claude_auth_source.dart' as _it4knivm;
import 'machine_metric.dart' as _ixivwx7g;
import 'machine_status.dart' as _i6yugb3s;

/// A registered host (laptop, VPS) running the agent daemon. Pure infrastructure — an Agent is the
/// persona living on it.
abstract class Machine
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Machine._({
    this.id,
    required this.name,
    this.hostInfo,
    this.osVersion,
    _i6yugb3s.MachineStatus? status,
    this.lastSeenAt,
    this.claudeExecutableOk,
    this.claudeExecutableError,
    this.runnerVersion,
    this.updateRequestedAt,
    this.toolchain,
    this.usageLimitedUntil,
    this.claudeTokenRequestedAt,
    this.claudeTokenSetAt,
    this.claudeAuthSource,
    DateTime? createdAt,
    this.agents,
    this.metrics,
  }) : status = status ?? _i6yugb3s.MachineStatus.offline,
       createdAt = createdAt ?? DateTime.now();

  factory Machine({
    int? id,
    required String name,
    String? hostInfo,
    String? osVersion,
    _i6yugb3s.MachineStatus? status,
    DateTime? lastSeenAt,
    bool? claudeExecutableOk,
    String? claudeExecutableError,
    String? runnerVersion,
    DateTime? updateRequestedAt,
    List<String>? toolchain,
    DateTime? usageLimitedUntil,
    DateTime? claudeTokenRequestedAt,
    DateTime? claudeTokenSetAt,
    _it4knivm.ClaudeAuthSource? claudeAuthSource,
    DateTime? createdAt,
    List<_ijo8h3v4.Agent>? agents,
    List<_ixivwx7g.MachineMetric>? metrics,
  }) = _MachineImpl;

  factory Machine.fromJson(Map<String, dynamic> jsonSerialization) {
    return Machine(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      hostInfo: jsonSerialization['hostInfo'] as String?,
      osVersion: jsonSerialization['osVersion'] as String?,
      status: jsonSerialization['status'] == null
          ? null
          : _i6yugb3s.MachineStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      lastSeenAt: jsonSerialization['lastSeenAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastSeenAt'],
            ),
      claudeExecutableOk: jsonSerialization['claudeExecutableOk'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['claudeExecutableOk'],
            ),
      claudeExecutableError:
          jsonSerialization['claudeExecutableError'] as String?,
      runnerVersion: jsonSerialization['runnerVersion'] as String?,
      updateRequestedAt: jsonSerialization['updateRequestedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['updateRequestedAt'],
            ),
      toolchain: jsonSerialization['toolchain'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<List<String>>(
              jsonSerialization['toolchain'],
            ),
      usageLimitedUntil: jsonSerialization['usageLimitedUntil'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['usageLimitedUntil'],
            ),
      claudeTokenRequestedAt:
          jsonSerialization['claudeTokenRequestedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['claudeTokenRequestedAt'],
            ),
      claudeTokenSetAt: jsonSerialization['claudeTokenSetAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['claudeTokenSetAt'],
            ),
      claudeAuthSource: jsonSerialization['claudeAuthSource'] == null
          ? null
          : _it4knivm.ClaudeAuthSource.fromJson(
              (jsonSerialization['claudeAuthSource'] as String),
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      agents: jsonSerialization['agents'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<List<_ijo8h3v4.Agent>>(
              jsonSerialization['agents'],
            ),
      metrics: jsonSerialization['metrics'] == null
          ? null
          : _i35hmugi.Protocol().deserialize<List<_ixivwx7g.MachineMetric>>(
              jsonSerialization['metrics'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The machine's display name.
  String name;

  /// Legacy free-text host/OS description entered by the dev (e.g. "Hetzner · Ubuntu 22.04"),
  /// display only. The panel shows [osVersion] instead once the daemon reports it.
  String? hostInfo;

  /// OS name + version detected by the daemon at startup (e.g. "Ubuntu 24.04").
  /// Null for daemons that predate OS detection.
  String? osVersion;

  _i6yugb3s.MachineStatus status;

  /// Last time a heartbeat was received from this machine's daemon.
  DateTime? lastSeenAt;

  /// Whether the daemon's last check of its configured `claude` executable
  /// succeeded (`Process.run(claudeExecutable, ['--version'])`) — null until
  /// the first check reports in. Surfaced as a warning banner in the panel
  /// instead of only in `journalctl -u agent-runner`, since a broken
  /// CLAUDE_EXECUTABLE otherwise silently fails every task on this machine.
  bool? claudeExecutableOk;

  /// Actionable error message set when `claudeExecutableOk` is false (e.g. a
  /// `ProcessException` launching `claude`, with fix instructions).
  String? claudeExecutableError;

  /// Version of the agent-runner binaries installed on this machine (see
  /// `agentRunnerVersion` on the server), reported by the daemon on every
  /// check-in. Null for daemons that predate in-panel updates.
  String? runnerVersion;

  /// Set when the dev clicks "Update runner" in the panel; the daemon picks
  /// it up on its next check-in and hands off to the root-side updater.
  /// Cleared once the daemon reports a different [runnerVersion].
  DateTime? updateRequestedAt;

  /// Tools the daemon found on its PATH at startup, as "name: version"
  /// (e.g. "dart: Dart SDK version: 3.13.3"). Shown on the machine's card
  /// so the dev can see what agents here can build and test with. Null
  /// for daemons that predate toolchain detection.
  List<String>? toolchain;

  /// Until when the machine's Claude account is rate limited, as reported by
  /// the daemon when a run hits the usage limit. The daemon starts no new
  /// work until then; the panel shows it while it's in the future.
  DateTime? usageLimitedUntil;

  /// When the dev set a token in the panel that the daemon hasn't picked up
  /// yet. Null once it has.
  DateTime? claudeTokenRequestedAt;

  /// When the daemon last saved a token set in the panel.
  DateTime? claudeTokenSetAt;

  /// Where the daemon gets its Claude credentials from. Null for daemons
  /// that predate the check.
  _it4knivm.ClaudeAuthSource? claudeAuthSource;

  DateTime createdAt;

  List<_ijo8h3v4.Agent>? agents;

  List<_ixivwx7g.MachineMetric>? metrics;

  /// Returns a shallow copy of this [Machine]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Machine copyWith({
    int? id,
    String? name,
    String? hostInfo,
    String? osVersion,
    _i6yugb3s.MachineStatus? status,
    DateTime? lastSeenAt,
    bool? claudeExecutableOk,
    String? claudeExecutableError,
    String? runnerVersion,
    DateTime? updateRequestedAt,
    List<String>? toolchain,
    DateTime? usageLimitedUntil,
    DateTime? claudeTokenRequestedAt,
    DateTime? claudeTokenSetAt,
    _it4knivm.ClaudeAuthSource? claudeAuthSource,
    DateTime? createdAt,
    List<_ijo8h3v4.Agent>? agents,
    List<_ixivwx7g.MachineMetric>? metrics,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Machine',
      if (id != null) 'id': id,
      'name': name,
      if (hostInfo != null) 'hostInfo': hostInfo,
      if (osVersion != null) 'osVersion': osVersion,
      'status': status.toJson(),
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt?.toJson(),
      if (claudeExecutableOk != null) 'claudeExecutableOk': claudeExecutableOk,
      if (claudeExecutableError != null)
        'claudeExecutableError': claudeExecutableError,
      if (runnerVersion != null) 'runnerVersion': runnerVersion,
      if (updateRequestedAt != null)
        'updateRequestedAt': updateRequestedAt?.toJson(),
      if (toolchain != null) 'toolchain': toolchain?.toJson(),
      if (usageLimitedUntil != null)
        'usageLimitedUntil': usageLimitedUntil?.toJson(),
      if (claudeTokenRequestedAt != null)
        'claudeTokenRequestedAt': claudeTokenRequestedAt?.toJson(),
      if (claudeTokenSetAt != null)
        'claudeTokenSetAt': claudeTokenSetAt?.toJson(),
      if (claudeAuthSource != null)
        'claudeAuthSource': claudeAuthSource?.toJson(),
      'createdAt': createdAt.toJson(),
      if (agents != null)
        'agents': agents?.toJson(valueToJson: (v) => v.toJson()),
      if (metrics != null)
        'metrics': metrics?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Machine',
      if (id != null) 'id': id,
      'name': name,
      if (hostInfo != null) 'hostInfo': hostInfo,
      if (osVersion != null) 'osVersion': osVersion,
      'status': status.toJson(),
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt?.toJson(),
      if (claudeExecutableOk != null) 'claudeExecutableOk': claudeExecutableOk,
      if (claudeExecutableError != null)
        'claudeExecutableError': claudeExecutableError,
      if (runnerVersion != null) 'runnerVersion': runnerVersion,
      if (updateRequestedAt != null)
        'updateRequestedAt': updateRequestedAt?.toJson(),
      if (toolchain != null) 'toolchain': toolchain?.toJson(),
      if (usageLimitedUntil != null)
        'usageLimitedUntil': usageLimitedUntil?.toJson(),
      if (claudeTokenRequestedAt != null)
        'claudeTokenRequestedAt': claudeTokenRequestedAt?.toJson(),
      if (claudeTokenSetAt != null)
        'claudeTokenSetAt': claudeTokenSetAt?.toJson(),
      if (claudeAuthSource != null)
        'claudeAuthSource': claudeAuthSource?.toJson(),
      'createdAt': createdAt.toJson(),
      if (agents != null)
        'agents': agents?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (metrics != null)
        'metrics': metrics?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MachineImpl extends Machine {
  _MachineImpl({
    int? id,
    required String name,
    String? hostInfo,
    String? osVersion,
    _i6yugb3s.MachineStatus? status,
    DateTime? lastSeenAt,
    bool? claudeExecutableOk,
    String? claudeExecutableError,
    String? runnerVersion,
    DateTime? updateRequestedAt,
    List<String>? toolchain,
    DateTime? usageLimitedUntil,
    DateTime? claudeTokenRequestedAt,
    DateTime? claudeTokenSetAt,
    _it4knivm.ClaudeAuthSource? claudeAuthSource,
    DateTime? createdAt,
    List<_ijo8h3v4.Agent>? agents,
    List<_ixivwx7g.MachineMetric>? metrics,
  }) : super._(
         id: id,
         name: name,
         hostInfo: hostInfo,
         osVersion: osVersion,
         status: status,
         lastSeenAt: lastSeenAt,
         claudeExecutableOk: claudeExecutableOk,
         claudeExecutableError: claudeExecutableError,
         runnerVersion: runnerVersion,
         updateRequestedAt: updateRequestedAt,
         toolchain: toolchain,
         usageLimitedUntil: usageLimitedUntil,
         claudeTokenRequestedAt: claudeTokenRequestedAt,
         claudeTokenSetAt: claudeTokenSetAt,
         claudeAuthSource: claudeAuthSource,
         createdAt: createdAt,
         agents: agents,
         metrics: metrics,
       );

  /// Returns a shallow copy of this [Machine]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Machine copyWith({
    Object? id = _Undefined,
    String? name,
    Object? hostInfo = _Undefined,
    Object? osVersion = _Undefined,
    _i6yugb3s.MachineStatus? status,
    Object? lastSeenAt = _Undefined,
    Object? claudeExecutableOk = _Undefined,
    Object? claudeExecutableError = _Undefined,
    Object? runnerVersion = _Undefined,
    Object? updateRequestedAt = _Undefined,
    Object? toolchain = _Undefined,
    Object? usageLimitedUntil = _Undefined,
    Object? claudeTokenRequestedAt = _Undefined,
    Object? claudeTokenSetAt = _Undefined,
    Object? claudeAuthSource = _Undefined,
    DateTime? createdAt,
    Object? agents = _Undefined,
    Object? metrics = _Undefined,
  }) {
    return Machine(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      hostInfo: hostInfo is String? ? hostInfo : this.hostInfo,
      osVersion: osVersion is String? ? osVersion : this.osVersion,
      status: status ?? this.status,
      lastSeenAt: lastSeenAt is DateTime? ? lastSeenAt : this.lastSeenAt,
      claudeExecutableOk: claudeExecutableOk is bool?
          ? claudeExecutableOk
          : this.claudeExecutableOk,
      claudeExecutableError: claudeExecutableError is String?
          ? claudeExecutableError
          : this.claudeExecutableError,
      runnerVersion: runnerVersion is String?
          ? runnerVersion
          : this.runnerVersion,
      updateRequestedAt: updateRequestedAt is DateTime?
          ? updateRequestedAt
          : this.updateRequestedAt,
      toolchain: toolchain is List<String>?
          ? toolchain
          : this.toolchain?.map((e0) => e0).toList(),
      usageLimitedUntil: usageLimitedUntil is DateTime?
          ? usageLimitedUntil
          : this.usageLimitedUntil,
      claudeTokenRequestedAt: claudeTokenRequestedAt is DateTime?
          ? claudeTokenRequestedAt
          : this.claudeTokenRequestedAt,
      claudeTokenSetAt: claudeTokenSetAt is DateTime?
          ? claudeTokenSetAt
          : this.claudeTokenSetAt,
      claudeAuthSource: claudeAuthSource is _it4knivm.ClaudeAuthSource?
          ? claudeAuthSource
          : this.claudeAuthSource,
      createdAt: createdAt ?? this.createdAt,
      agents: agents is List<_ijo8h3v4.Agent>?
          ? agents
          : this.agents?.map((e0) => e0.copyWith()).toList(),
      metrics: metrics is List<_ixivwx7g.MachineMetric>?
          ? metrics
          : this.metrics?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
