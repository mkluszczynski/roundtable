import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../agent_runner_binaries.dart';
import 'non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import '../task_lifecycle.dart';
import '../task_review_support.dart';
import 'package:serverpod/serverpod.dart';

/// Generates a cryptographically secure, high-entropy registration token.
String _generateRegistrationToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Hashes a raw token for storage; only the hash is ever persisted.
String _hashToken(String token) {
  return sha256.convert(utf8.encode(token)).toString();
}

/// Registration and CRUD for [Machine]. Deletion is blocked while the machine
/// is `online`, or while any of its agents has a non-terminal task
/// (docs/ARCHITECTURE.md).
class MachineEndpoint extends Endpoint {
  static String _channelForMachineMetrics(int machineId) =>
      'machine-$machineId-metrics';

  Future<MachineRegistration> register(
    Session session,
    String name, {
    String? hostInfo,
  }) async {
    final token = _generateRegistrationToken();
    final machine = await Machine.db.insertRow(
      session,
      Machine(name: name, hostInfo: hostInfo, tokenHash: _hashToken(token)),
    );
    final apiServer = session.serverpod.config.apiServer;
    return MachineRegistration(
      machine: machine,
      token: token,
      serverUrl: Uri(
        scheme: apiServer.publicScheme,
        host: apiServer.publicHost,
        port: apiServer.publicPort,
      ).toString(),
      scriptUrl: _scriptUrl(session),
    );
  }

  /// Base URL the install/uninstall scripts (and the agent-runner binary
  /// install-agent.sh downloads) are served from — the panel's "Delete"
  /// dialog for an online machine uses this to render a working
  /// `curl | sudo bash` uninstall command (docs/FLOWS.md §1–3).
  Future<String> getScriptUrl(Session session) async => _scriptUrl(session);

  String _scriptUrl(Session session) {
    final apiServer = session.serverpod.config.apiServer;
    // Falls back to the API server if this monolith wasn't configured with a
    // separate web server role (webServer is only set up for that role).
    final webServer = session.serverpod.config.webServer ?? apiServer;
    return Uri(
      scheme: webServer.publicScheme,
      host: webServer.publicHost,
      port: webServer.publicPort,
    ).toString();
  }

  Future<Machine?> get(Session session, int id) async {
    return Machine.db.findById(session, id);
  }

  Future<List<Machine>> list(Session session) async {
    return Machine.db.find(session);
  }

  /// Renames a machine. Everything else on it (token, status, versions)
  /// is owned by the daemon-facing methods and can't be written here.
  Future<Machine> update(Session session, Machine machine) async {
    if (await Machine.db.findById(session, machine.id!) == null) {
      throw NotFoundException(message: 'Machine ${machine.id} not found');
    }
    return Machine.db.updateRow(
      session,
      machine,
      columns: (t) => [t.name, t.hostInfo],
    );
  }

  /// Called periodically by the agent-runner daemon on a registered
  /// machine. Marks the machine online and refreshes [Machine.lastSeenAt].
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine (unknown, or revoked via [deregister]).
  Future<void> heartbeat(Session session, String token) async {
    final machine = await _findByToken(session, token);
    await Machine.db.updateRow(
      session,
      machine.copyWith(
        status: MachineStatus.online,
        lastSeenAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// Heartbeat for daemons that support in-panel updates: does what
  /// [heartbeat] does, records the daemon's installed [runnerVersion], and
  /// returns whether the dev requested an update via [requestRunnerUpdate].
  /// A pending request is cleared once the daemon reports a version other
  /// than the one it was requested from, i.e. after the update restarted it.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<bool> checkIn(
    Session session,
    String token,
    String? runnerVersion,
  ) async {
    final machine = await _findByToken(session, token);
    final updated = machine.runnerVersion != runnerVersion;
    final updateRequestedAt = updated ? null : machine.updateRequestedAt;
    await Machine.db.updateRow(
      session,
      machine.copyWith(
        status: MachineStatus.online,
        lastSeenAt: DateTime.now().toUtc(),
        runnerVersion: runnerVersion,
        updateRequestedAt: updateRequestedAt,
      ),
    );
    return updateRequestedAt != null;
  }

  /// The version of the agent-runner binaries the server currently serves —
  /// a machine whose [Machine.runnerVersion] differs is out of date. Null if
  /// the binaries can't be resolved (e.g. the dev-mode build failed).
  Future<String?> latestRunnerVersion(Session session) =>
      AgentRunnerBinaries.instance.version();

  /// Asks machine [id]'s daemon to update itself to the binaries the server
  /// currently serves, on its next check-in.
  Future<Machine> requestRunnerUpdate(Session session, int id) async {
    final machine = await Machine.db.findById(session, id);
    if (machine == null) {
      throw NotFoundException(message: 'Machine $id not found');
    }
    return Machine.db.updateRow(
      session,
      machine.copyWith(updateRequestedAt: DateTime.now().toUtc()),
    );
  }

  /// Called by the uninstall script as a deliberate deregistration, so the
  /// server doesn't have to wait for the heartbeat timeout to notice the
  /// machine is gone (docs/FLOWS.md §1–3). Marks the machine offline and clears
  /// [Machine.tokenHash] so the raw token can never match again.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<void> deregister(Session session, String token) async {
    final machine = await _findByToken(session, token);
    await Machine.db.updateRow(
      session,
      machine.copyWith(status: MachineStatus.offline, tokenHash: null),
    );
  }

  /// Called by the daemon once at startup, right after [identify]. A fresh
  /// daemon process has no `claude` subprocesses, so any task of this
  /// machine's agents still in an agent-driven state (planning, waiting on a
  /// question/plan decision, running) lost its process in the restart —
  /// fail it with a clear reason instead of leaving it stuck. Code reviews
  /// that were `running` on it are failed the same way (a stuck review would
  /// block merging), and the agents are reset to `idle`, since nothing is
  /// running on them anymore.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<void> reportStartup(Session session, String token) async {
    final machine = await _findByToken(session, token);
    final agents = await Agent.db.find(
      session,
      where: (t) => t.machineId.equals(machine.id!),
    );
    if (agents.isEmpty) return;

    final orphaned = await Task.db.find(
      session,
      where: (t) =>
          t.agentId.inSet(agents.map((a) => a.id!).toSet()) &
          t.status.inSet(agentDrivenTaskStatuses),
    );
    await failTasks(
      session,
      orphaned,
      'The agent runner restarted mid-task, so the Claude Code run was lost',
    );

    final orphanedReviews = await CodeReview.db.find(
      session,
      where: (t) =>
          t.reviewerAgentId.inSet(agents.map((a) => a.id!).toSet()) &
          t.status.equals(CodeReviewStatus.running),
    );
    for (final review in orphanedReviews) {
      await CodeReview.db.updateRow(
        session,
        review.copyWith(
          status: CodeReviewStatus.failed,
          failureReason: 'The agent runner restarted mid-review',
          finishedAt: DateTime.now().toUtc(),
        ),
      );
      await postReviewChanged(session, review.id!);
    }

    await Agent.db.update(
      session,
      [for (final agent in agents) agent.copyWith(status: AgentStatus.idle)],
      columns: (t) => [t.status],
    );
  }

  /// Resolves the [Machine] a registration token belongs to, without
  /// mutating heartbeat state. Used by the agent-runner daemon at startup to
  /// learn its own machine id before subscribing to
  /// [TaskEndpoint.watchAssignedTasks] (docs/FLOWS.md §4).
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<Machine> identify(Session session, String token) async {
    return _findByToken(session, token);
  }

  /// Called periodically by the agent-runner daemon (docs/FLOWS.md §4). Stores
  /// a new [MachineMetric] row and notifies [watchLatestMetric] subscribers.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<void> reportMetric(
    Session session,
    String token,
    double cpuPercent,
    int memoryUsedMb,
    int memoryTotalMb,
  ) async {
    final machine = await _findByToken(session, token);
    final metric = await MachineMetric.db.insertRow(
      session,
      MachineMetric(
        machineId: machine.id!,
        cpuPercent: cpuPercent,
        memoryUsedMb: memoryUsedMb,
        memoryTotalMb: memoryTotalMb,
      ),
    );
    await session.messages.postMessage(
      _channelForMachineMetrics(machine.id!),
      metric,
    );
  }

  /// Called by the daemon at startup and on every heartbeat tick to report
  /// whether its configured `claude` executable can actually be launched —
  /// surfaced as a warning banner on the machine's card in the panel instead
  /// of only in `journalctl -u agent-runner`. [message] should be null when
  /// [ok] is true, and an actionable error description otherwise.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<void> reportClaudeStatus(
    Session session,
    String token,
    bool ok,
    String? message,
  ) async {
    final machine = await _findByToken(session, token);
    await Machine.db.updateRow(
      session,
      machine.copyWith(claudeExecutableOk: ok, claudeExecutableError: message),
    );
  }

  /// Streams the latest [MachineMetric] for [machineId] (docs/FLOWS.md §6
  /// snapshot) — replays the current latest row on subscribe, then yields
  /// each new one as [reportMetric] stores it.
  Stream<MachineMetric> watchLatestMetric(
    Session session,
    int machineId,
  ) async* {
    final latest = await MachineMetric.db.findFirstRow(
      session,
      where: (t) => t.machineId.equals(machineId),
      orderBy: (t) => t.recordedAt.desc(),
    );
    if (latest != null) yield latest;

    final updates = session.messages.createStream<MachineMetric>(
      _channelForMachineMetrics(machineId),
    );
    await for (final metric in updates) {
      yield metric;
    }
  }

  Future<Machine> _findByToken(Session session, String token) async {
    final machine = await Machine.db.findFirstRow(
      session,
      where: (t) => t.tokenHash.equals(_hashToken(token)),
    );
    if (machine == null) {
      throw InvalidTokenException(
        message: 'Unknown or revoked registration token',
      );
    }
    return machine;
  }

  Future<void> delete(Session session, int id) async {
    await guardedDelete(session, (transaction) async {
      var machine = await Machine.db.findById(
        session,
        id,
        transaction: transaction,
      );
      if (machine == null) {
        throw NotFoundException(message: 'Machine $id not found');
      }

      if (machine.status == MachineStatus.online) {
        throw DeletionBlockedException(
          message: 'Cannot delete an online machine',
          reason: DeletionBlockReason.machineOnline,
        );
      }

      var agentIds = (await Agent.db.find(
        session,
        where: (t) => t.machineId.equals(id),
        transaction: transaction,
      )).map((agent) => agent.id!).toSet();

      var nonTerminalTaskCount = await Task.db.count(
        session,
        where: (t) =>
            t.agentId.inSet(agentIds) & t.status.inSet(nonTerminalTaskStatuses),
        transaction: transaction,
      );
      if (nonTerminalTaskCount > 0) {
        throw DeletionBlockedException(
          message: 'Cannot delete a machine with non-terminal tasks',
          reason: DeletionBlockReason.nonTerminalTasks,
        );
      }

      await Machine.db.deleteRow(session, machine, transaction: transaction);
    });
  }
}
