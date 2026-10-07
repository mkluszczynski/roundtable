import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../agent_runner_binaries.dart';
import '../agent_status.dart';
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
  /// The update restarts the daemon, which kills its `claude` runs, so it
  /// waits for the machine's agents to finish their current work. A daemon
  /// passing [drainsForUpdate] holds back new work and hands the update off
  /// once it's idle itself, so it's told about a pending request right away.
  /// For older daemons, which update as soon as they're told, the request is
  /// reported only while none of the machine's agents has an agent-driven
  /// task or a running code review.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<bool> checkIn(
    Session session,
    String token,
    String? runnerVersion, {
    // Nullable rather than defaulted: the generated test tools would make a
    // defaulted named parameter required.
    bool? drainsForUpdate,
  }) async {
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
    if (updateRequestedAt == null) return false;
    if (drainsForUpdate ?? false) return true;
    return !await _hasActiveWork(session, machine.id!);
  }

  /// Whether any of machine [machineId]'s agents has a `claude` run going:
  /// an agent-driven task or a running code review, which a daemon restart
  /// would fail (see [reportStartup]).
  Future<bool> _hasActiveWork(Session session, int machineId) async {
    final agentIds = (await Agent.db.find(
      session,
      where: (t) => t.machineId.equals(machineId),
    )).map((agent) => agent.id!).toSet();
    if (agentIds.isEmpty) return false;
    final tasks = await Task.db.count(
      session,
      where: (t) =>
          t.agentId.inSet(agentIds) & t.status.inSet(agentDrivenTaskStatuses),
    );
    if (tasks > 0) return true;
    final reviews = await CodeReview.db.count(
      session,
      where: (t) =>
          t.reviewerAgentId.inSet(agentIds) &
          t.status.equals(CodeReviewStatus.running),
    );
    return reviews > 0;
  }

  /// Called by the daemon when a run hits the Claude usage limit: the
  /// machine starts no new work until [until] (docs/FLOWS.md §4).
  Future<void> reportUsageLimit(
    Session session,
    String token,
    DateTime until,
  ) async {
    final machine = await _findByToken(session, token);
    await Machine.db.updateRow(
      session,
      machine.copyWith(usageLimitedUntil: until.toUtc()),
      columns: (m) => [m.usageLimitedUntil],
    );
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

  /// Called by the uninstall script once it has stopped the daemon
  /// (docs/FLOWS.md §3). The uninstall is the dev's deliberate removal of the
  /// machine, so it's deleted right away. The dev doesn't have to click
  /// "Delete" again in the panel.
  ///
  /// The machine is first marked offline and [Machine.tokenHash] is cleared,
  /// so the raw token can never match again even if the delete doesn't go
  /// through. Then the agent runs lost with the daemon are failed, as in
  /// [reportStartup], along with `queued` code reviews: no daemon is left to
  /// pick them up, and they would block their task forever.
  ///
  /// If the machine's agents still have other non-terminal tasks (queued,
  /// awaiting review, …), deleting it is blocked as in [delete], and the
  /// machine stays offline. The dev deletes it from the panel once those
  /// tasks are resolved. The same happens if the delete keeps losing a
  /// serialization conflict.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<void> deregister(Session session, String token) async {
    final registered = await _findByToken(session, token);
    final machine = await Machine.db.updateRow(
      session,
      registered.copyWith(status: MachineStatus.offline, tokenHash: null),
    );
    await _failOrphanedWork(
      session,
      machine,
      taskReason:
          'The agent runner was uninstalled mid-task, so the Claude Code run '
          'was lost',
      reviewReason:
          'The agent runner was uninstalled before the review finished',
      reviewStatuses: activeCodeReviewStatuses,
    );

    // A serializable transaction can be aborted by a concurrent write (e.g.
    // a task created for one of its agents); retry once, then leave the
    // machine offline and revoked for the dev to delete from the panel.
    final failedReviewIds = <int>[];
    for (var attempt = 1; ; attempt++) {
      try {
        await guardedDelete(session, (transaction) async {
          failedReviewIds.clear();
          final blockingTasks = await _nonTerminalTaskCount(
            session,
            machine.id!,
            transaction,
          );
          if (blockingTasks > 0) return;
          failedReviewIds.addAll(
            await _deleteMachine(session, machine, transaction),
          );
        });
        break;
      } on Exception catch (e, stackTrace) {
        failedReviewIds.clear();
        if (attempt >= 2) {
          session.log(
            'Deregistered machine ${machine.id} could not be deleted; it '
            'stays offline with its token revoked',
            level: LogLevel.warning,
            exception: e,
            stackTrace: stackTrace,
          );
          break;
        }
      }
    }
    for (final reviewId in failedReviewIds) {
      await postReviewChanged(session, reviewId);
    }
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
    await _failOrphanedWork(
      session,
      machine,
      taskReason:
          'The agent runner restarted mid-task, so the Claude Code run was '
          'lost',
      reviewReason: 'The agent runner restarted mid-review',
      reviewStatuses: const {CodeReviewStatus.running},
    );
  }

  /// Fails the agent-driven tasks of [machine]'s agents, whose `claude`
  /// processes died with the daemon, and their code reviews in
  /// [reviewStatuses], and resets the agents to `idle`. Shared by
  /// [reportStartup] and [deregister].
  Future<void> _failOrphanedWork(
    Session session,
    Machine machine, {
    required String taskReason,
    required String reviewReason,
    required Set<CodeReviewStatus> reviewStatuses,
  }) async {
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
    await failTasks(session, orphaned, taskReason);

    final failedReviewIds = await _failReviews(
      session,
      agents.map((a) => a.id!).toSet(),
      reviewStatuses,
      reviewReason,
    );
    for (final reviewId in failedReviewIds) {
      await postReviewChanged(session, reviewId);
    }

    final reset = await Agent.db.update(
      session,
      [for (final agent in agents) agent.copyWith(status: AgentStatus.idle)],
      columns: (t) => [t.status],
    );
    for (final agent in reset) {
      await postAgentChanged(session, agent.id!);
    }
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

  /// Called by the daemon at startup with the tools it found on its PATH
  /// (see [Machine.toolchain]).
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<void> reportToolchain(
    Session session,
    String token,
    List<String> toolchain,
  ) async {
    final machine = await _findByToken(session, token);
    await Machine.db.updateRow(
      session,
      machine.copyWith(toolchain: toolchain),
      columns: (t) => [t.toolchain],
    );
  }

  /// Called by the daemon at startup with the OS it runs on (see
  /// [Machine.osVersion]).
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<void> reportOsVersion(
    Session session,
    String token,
    String osVersion,
  ) async {
    final machine = await _findByToken(session, token);
    await Machine.db.updateRow(
      session,
      machine.copyWith(osVersion: osVersion),
      columns: (t) => [t.osVersion],
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

  /// Deletes an offline machine whose agents have no non-terminal tasks.
  /// Its agents go with it, so their still-active code reviews are failed
  /// (see [_deleteMachine]).
  Future<void> delete(Session session, int id) async {
    final failedReviewIds = <int>[];
    await guardedDelete(session, (transaction) async {
      failedReviewIds.clear();
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

      if (await _nonTerminalTaskCount(session, id, transaction) > 0) {
        throw DeletionBlockedException(
          message: 'Cannot delete a machine with non-terminal tasks',
          reason: DeletionBlockReason.nonTerminalTasks,
        );
      }

      failedReviewIds.addAll(
        await _deleteMachine(session, machine, transaction),
      );
    });
    for (final reviewId in failedReviewIds) {
      await postReviewChanged(session, reviewId);
    }
  }

  /// Deletes [machine] (its agents cascade) within [transaction]. Code
  /// reviews still `queued`/`running` for its agents would otherwise be left
  /// without a reviewer (`reviewerAgent` is SetNull) and block their task
  /// forever, so they're failed first. Returns the failed reviews' ids for the
  /// caller to broadcast once the transaction has committed.
  Future<List<int>> _deleteMachine(
    Session session,
    Machine machine,
    Transaction transaction,
  ) async {
    final agentIds = (await Agent.db.find(
      session,
      where: (t) => t.machineId.equals(machine.id!),
      transaction: transaction,
    )).map((agent) => agent.id!).toSet();
    final failedReviewIds = await _failReviews(
      session,
      agentIds,
      activeCodeReviewStatuses,
      'The reviewer agent was removed along with its machine',
      transaction: transaction,
    );
    await Machine.db.deleteRow(session, machine, transaction: transaction);
    return failedReviewIds;
  }

  /// Marks the code reviews of [agentIds] whose status is in [statuses] as
  /// `failed` with [reason], and returns their ids. Doesn't broadcast; the
  /// caller posts [postReviewChanged] (after committing, if in a
  /// [transaction]).
  Future<List<int>> _failReviews(
    Session session,
    Set<int> agentIds,
    Set<CodeReviewStatus> statuses,
    String reason, {
    Transaction? transaction,
  }) async {
    if (agentIds.isEmpty) return const [];
    final reviews = await CodeReview.db.find(
      session,
      where: (t) =>
          t.reviewerAgentId.inSet(agentIds) & t.status.inSet(statuses),
      transaction: transaction,
    );
    for (final review in reviews) {
      await CodeReview.db.updateRow(
        session,
        review.copyWith(
          status: CodeReviewStatus.failed,
          failureReason: reason,
          finishedAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
    }
    return [for (final review in reviews) review.id!];
  }

  /// Number of non-terminal tasks assigned to the agents of machine
  /// [machineId] — the guard shared by [delete] and [deregister].
  Future<int> _nonTerminalTaskCount(
    Session session,
    int machineId,
    Transaction transaction,
  ) async {
    final agentIds = (await Agent.db.find(
      session,
      where: (t) => t.machineId.equals(machineId),
      transaction: transaction,
    )).map((agent) => agent.id!).toSet();
    return Task.db.count(
      session,
      where: (t) =>
          t.agentId.inSet(agentIds) & t.status.inSet(nonTerminalTaskStatuses),
      transaction: transaction,
    );
  }
}
