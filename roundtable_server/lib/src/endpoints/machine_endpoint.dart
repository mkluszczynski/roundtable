import 'dart:convert';
import 'dart:math';

import '../agent_runner_binaries.dart';
import '../agent_status.dart';
import 'non_terminal_task_statuses.dart';
import '../generated/protocol.dart';
import '../machine_tokens.dart';
import '../task_lifecycle.dart';
import '../task_review_support.dart';
import 'package:serverpod/serverpod.dart';

/// Generates a cryptographically secure, high-entropy registration token.
String _generateRegistrationToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Registration and CRUD for [Machine]. Deletion is blocked while the machine
/// is `online`, or while any of its agents has a non-terminal task
/// (docs/ARCHITECTURE.md).
class MachineEndpoint extends Endpoint {
  static String _channelForMachineMetrics(int machineId) =>
      'machine-$machineId-metrics';

  /// How long an install command from the panel stays redeemable.
  static const enrollmentTtl = Duration(hours: 1);

  /// Issues a one-time install token for the "Add machine" dialog. No
  /// machine exists until install-agent.sh redeems it with [enroll], so an
  /// abandoned dialog leaves nothing behind (docs/FLOWS.md §1). [name]
  /// overrides the hostname the machine would otherwise be named after.
  Future<MachineInstallCommand> createEnrollment(
    Session session, {
    String? name,
  }) async {
    final now = DateTime.now().toUtc();
    // Tokens an hour past their expiry can't be redeemed or retried, and
    // no dialog still waits on them; drop them here instead of running a
    // separate cleanup job.
    await MachineEnrollment.db.deleteWhere(
      session,
      where: (e) => e.expiresAt < now.subtract(enrollmentTtl),
    );
    final token = _generateRegistrationToken();
    final trimmed = name?.trim();
    final enrollment = await MachineEnrollment.db.insertRow(
      session,
      MachineEnrollment(
        tokenHash: hashMachineToken(token),
        name: trimmed == null || trimmed.isEmpty ? null : trimmed,
        expiresAt: now.add(enrollmentTtl),
      ),
    );
    final apiServer = session.serverpod.config.apiServer;
    return MachineInstallCommand(
      enrollmentId: enrollment.id!,
      enrollmentToken: token,
      expiresAt: enrollment.expiresAt,
      serverUrl: Uri(
        scheme: apiServer.publicScheme,
        host: apiServer.publicHost,
        port: apiServer.publicPort,
      ).toString(),
      scriptUrl: _scriptUrl(session),
    );
  }

  /// Called by install-agent.sh once the runner is installed: redeems
  /// [enrollmentToken], creates the machine and returns the machine's own
  /// registration token for config.env. The machine is named [name] (the
  /// script's `--name`), else as chosen in the panel, else after
  /// [hostname] — with a numeric suffix if that's taken.
  ///
  /// Redeeming a used token again before it expires, while its machine has
  /// never connected, issues that machine a new token instead of failing:
  /// the script retries when the first response was lost, and must not
  /// leave an orphaned machine behind.
  ///
  /// Throws [InvalidTokenException] if the token is unknown, expired or
  /// already used by a machine that has connected.
  Future<String> enroll(
    Session session,
    String enrollmentToken,
    String hostname, {
    String? name,
  }) async {
    return session.db.transaction((transaction) async {
      final enrollment = await MachineEnrollment.db.findFirstRow(
        session,
        where: (e) => e.tokenHash.equals(hashMachineToken(enrollmentToken)),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      final invalid = InvalidTokenException(
        message:
            'Unknown, expired or already used install token — generate '
            'a new install command in the panel',
      );
      if (enrollment == null ||
          enrollment.expiresAt.isBefore(DateTime.now().toUtc())) {
        throw invalid;
      }
      final token = _generateRegistrationToken();
      final enrolledId = enrollment.machineId;
      if (enrolledId != null) {
        final enrolled = await Machine.db.findById(
          session,
          enrolledId,
          transaction: transaction,
        );
        if (enrolled == null || enrolled.lastSeenAt != null) throw invalid;
        await Machine.db.updateRow(
          session,
          enrolled.copyWith(tokenHash: hashMachineToken(token)),
          columns: (t) => [t.tokenHash],
          transaction: transaction,
        );
        return token;
      }
      final machine = await Machine.db.insertRow(
        session,
        Machine(
          name: await _uniqueName(
            session,
            _nonEmpty(name) ?? enrollment.name ?? hostname.trim(),
            transaction,
          ),
          tokenHash: hashMachineToken(token),
        ),
        transaction: transaction,
      );
      await MachineEnrollment.db.updateRow(
        session,
        enrollment.copyWith(machineId: machine.id),
        transaction: transaction,
      );
      return token;
    });
  }

  /// The machine created from enrollment [enrollmentId], or null while its
  /// install command hasn't been run yet. Polled by the "Add machine"
  /// dialog so it can say once the machine shows up.
  Future<Machine?> enrolledMachine(Session session, int enrollmentId) async {
    final enrollment = await MachineEnrollment.db.findById(
      session,
      enrollmentId,
    );
    final machineId = enrollment?.machineId;
    return machineId == null ? null : Machine.db.findById(session, machineId);
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<String> _uniqueName(
    Session session,
    String base,
    Transaction transaction,
  ) async {
    final name = base.isEmpty ? 'machine' : base;
    final taken = {
      for (final m in await Machine.db.find(
        session,
        where: (m) => m.name.like('$name%'),
        transaction: transaction,
      ))
        m.name,
    };
    if (!taken.contains(name)) return name;
    var n = 2;
    while (taken.contains('$name-$n')) {
      n++;
    }
    return '$name-$n';
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
      columns: (t) => [t.status, t.lastSeenAt],
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
      // Only what the check-in owns: a full row read before a concurrent
      // write from the panel (a Claude token, an update request) would
      // undo it.
      columns: (t) => [
        t.status,
        t.lastSeenAt,
        t.runnerVersion,
        t.updateRequestedAt,
      ],
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
      columns: (t) => [t.updateRequestedAt],
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
      registered.copyWith(
        status: MachineStatus.offline,
        tokenHash: null,
        pendingClaudeToken: null,
        claudeTokenRequestedAt: null,
      ),
      columns: (t) => [
        t.status,
        t.tokenHash,
        t.pendingClaudeToken,
        t.claudeTokenRequestedAt,
      ],
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

    final idle = await Agent.db.update(
      session,
      [for (final agent in agents) agent.copyWith(status: AgentStatus.idle)],
      columns: (t) => [t.status],
    );
    for (final agent in idle) {
      await session.messages.postMessage(agentStatusChannel, agent);
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
  ///
  /// [authSource] is where the daemon gets its Claude credentials from;
  /// null from daemons that predate the check.
  Future<void> reportClaudeStatus(
    Session session,
    String token,
    bool ok,
    String? message, {
    ClaudeAuthSource? authSource,
  }) async {
    final machine = await _findByToken(session, token);
    await Machine.db.updateRow(
      session,
      machine.copyWith(
        claudeExecutableOk: ok,
        claudeExecutableError: message,
        claudeAuthSource: authSource,
      ),
      columns: (t) => [
        t.claudeExecutableOk,
        t.claudeExecutableError,
        t.claudeAuthSource,
      ],
    );
  }

  /// Sets the Claude Code OAuth token the daemon on machine [id] runs
  /// `claude` with, replacing the one from the install. Held on the server
  /// only until the daemon picks it up on its next check-in
  /// ([takeClaudeToken]); the panel can't read it back (docs/FLOWS.md §1).
  Future<Machine> setClaudeToken(
    Session session,
    int id,
    String claudeToken,
  ) async {
    final trimmed = claudeToken.trim();
    if (!trimmed.startsWith('sk-ant-') ||
        trimmed.length > 500 ||
        trimmed.contains(RegExp(r'\s'))) {
      throw InvalidStateException(
        message: 'Paste the token from `claude setup-token`',
      );
    }
    final machine = await Machine.db.findById(session, id);
    if (machine == null) {
      throw NotFoundException(message: 'Machine $id not found');
    }
    return Machine.db.updateRow(
      session,
      machine.copyWith(
        pendingClaudeToken: trimmed,
        claudeTokenRequestedAt: DateTime.now().toUtc(),
      ),
      columns: (t) => [t.pendingClaudeToken, t.claudeTokenRequestedAt],
    );
  }

  /// Called by the daemon on every check-in: the token set in the panel
  /// that it hasn't saved yet, or null. It stays on the server until the
  /// daemon confirms it saved it ([confirmClaudeToken]), so a failed save
  /// just retries at the next check-in.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<String?> takeClaudeToken(Session session, String token) async {
    final machine = await _findByToken(session, token);
    return machine.pendingClaudeToken;
  }

  /// Called by the daemon once it saved [claudeToken] from
  /// [takeClaudeToken]: clears it from the server. A newer token set in the
  /// panel meanwhile stays pending for the next check-in.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  Future<void> confirmClaudeToken(
    Session session,
    String token,
    String claudeToken,
  ) async {
    final registered = await _findByToken(session, token);
    await session.db.transaction((transaction) async {
      final machine = await Machine.db.findById(
        session,
        registered.id!,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (machine == null) return;
      final delivered = machine.pendingClaudeToken == claudeToken;
      await Machine.db.updateRow(
        session,
        machine.copyWith(
          pendingClaudeToken: delivered ? null : machine.pendingClaudeToken,
          claudeTokenRequestedAt: delivered
              ? null
              : machine.claudeTokenRequestedAt,
          claudeTokenSetAt: DateTime.now().toUtc(),
        ),
        columns: (t) => [
          t.pendingClaudeToken,
          t.claudeTokenRequestedAt,
          t.claudeTokenSetAt,
        ],
        transaction: transaction,
      );
    });
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

  Future<Machine> _findByToken(Session session, String token) =>
      findMachineByToken(session, token);

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
