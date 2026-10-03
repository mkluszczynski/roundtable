# Known issues

All items were checked against the code on 2026-10-04. This list merges the
old `ISSUES.md` and `TASK-EXECUTION-BUGS.md`. Items that have since been fixed
were dropped: project deletion with task history (now cascades), raw enum
labels (`utils/task_status_label.dart`), MCP config committed into the PR,
duplicated future calls, runner crash-loop when the server is down, answers
not reaching Claude, the empty plan screen, and the `appendLog`/`update`
races. See git history for the details.

Priorities: **P1** real bug or gap · **P2** polish/correctness · **P3**
hygiene · **Accepted** a known limitation that's deliberately not being
fixed.

## Server

### P1: Generic `update` endpoints bypass the state machine
`AgentEndpoint.update`, `MachineEndpoint.update` and `ProjectEndpoint.update`
write whatever row the client sends. For example, `Machine.tokenHash` could
be overwritten. `TaskEndpoint.update` is limited to runner-owned columns, but
it still accepts any `status`, so a caller can skip the guards in
`cancelTask`/`approvePlan`/`acceptTask`.
**Fix direction:** narrow each method to the fields it really edits, and move
runner status transitions into dedicated methods.

### P1: Missing indexes on hot query paths
Only `machine.tokenHash` and `machine_metric(machineId, recordedAt)` are
indexed. `task.projectId/agentId/(status,lastProgressAt)`, `agent.machineId`,
and the `taskId` FKs on `task_log_entry`/`task_feedback`/`task_question`/
`code_review` are not. Both future calls scan `task` every 30 s.

### P1: `MachineMetric` grows without bound
The daemon inserts a row every 8 s per machine (~10k rows/day). Nothing
deletes them.
**Fix direction:** add a third recurring future call that deletes rows older
than N minutes.

### P1: No transactions
`session.db.transaction` isn't used anywhere. Insert+update pairs
(`createQuestion`, `submitPlanFeedback`, `sendCommentsToFix`) and the
check-then-delete guards in the `delete` methods can be left half-done or
hit TOCTOU races.

### P1: Untyped exceptions
About 36 `throw Exception(...)` across the endpoints (19 in `task_endpoint.dart`,
11 in `code_review_endpoint.dart`). The panel can't tell "not found" from
"wrong state" from a crash. Only `DeletionBlockedException` and
`InvalidTokenException` are typed.

### P2: No FK-existence checks on insert
`TaskEndpoint.createTask` doesn't check `projectId`. `AgentEndpoint.create`
doesn't check `machineId`. A bad id surfaces as a raw Postgres error.

### P2: No timeout on GitHub HTTP calls
`roundtable_server/lib/src/github_repo_client.dart` (and the runner's
`github_pull_request_opener.dart`) use `package:http` with no timeout. A hung
GitHub call hangs the panel request.

## Agent runner

### P2: Worktrees are only removed on `done`
`TaskDispatcher.handle` removes the worktree only when it receives a `done`
task. Worktrees for `failed`/`cancelled`/deleted tasks stay on disk under
`WORKSPACE_ROOT` until someone removes them by hand.

### P2: Restart mid-planning isn't resumable
After a daemon restart, a task found in `planning`/`waitingForAnswer`/
`planReady` is skipped. The task then sits until `StalledTaskFutureCall`
fails it (15 min, agent-driven states only). A task left in
`waitingForAnswer`/`planReady` with no live process is never failed
automatically.

### Accepted: No concurrency limit per machine
Each assigned task starts its own `claude` process. All agents on a machine
share one Claude Pro/Max token and its usage limits.

### Accepted: `docker` execution mode and `cloning` status are not implemented
`AgentExecutionMode.docker`, `Project.dockerImage` and `TaskStatus.cloning`
exist in the schema but nothing uses them. The UI shows docker as "Coming
soon".

## Panel

### P1: Stream subscriptions never cancelled
`TaskDetailBloc` and `DashboardCubit` loop over long-lived streams with
`await for` / `emit.forEach` and don't override `close()`. `DashboardCubit`
is also created separately by four screens (dashboard, projects, project
detail, machine detail), and each one opens its own `watchAllTasks`.

### P2: Detail screens have no error / not-found state
`project_detail_screen.dart` and `machine_detail_screen.dart` only check
`snapshot.data == null`, so a fetch error or a deleted record means an
endless spinner.

### P2: Duplicated metric rendering
The CPU/RAM `MetricBar` block is copied between `machines_screen.dart` and
`widgets/machine_summary_card.dart`.

### P2: Dashboard shows only the first project
`dashboard_screen.dart` uses the first project the server returns. There's
no project switcher.

### P2: Leftovers from the 2026-09-30 E2E run (not re-verified)
The New task dialog opened from Projects sometimes doesn't close after
Create. Task detail can take ~10 s to open while the WebSocket connects.
Cancel is offered in `awaitingReview` (the server allows it, but the intent
is unclear).

### P3: Dead / misleading affordances
The Settings nav tile has no screen. Agents can't be edited or deleted from
the UI (`AgentRepository` has no update/delete). The `open_in_new` icon next
to the repo URL in project detail can't be clicked. The disabled New task
button (no project yet) has no tooltip.

### P3: Accessibility
Most icon-only buttons have no `tooltip`. `text2` caption text on `bg1`/`bg2`
may be below WCAG AA contrast. This hasn't been measured.

### P3: Test gaps
There are no tests for the kanban widgets, the dialogs or the screens.
`GitHubRepoClient` is only covered indirectly.

## Docs, auth and scaffolding

### Accepted: Auth scaffolding initialized but unused
User login and per-user data are deferred until after the MVP (see
`AGENTS.md`). The `serverpod_auth_idp_*` setup in `server.dart`/`client.dart`
stays so it can be wired up later. `lib/src/greetings/` is unused scaffold.

### Accepted: No authentication or rate limiting on panel-facing endpoints
Anyone who can reach the API can create/cancel/merge tasks, read diffs through
the server's GitHub token, and register machines. That's fine on localhost or
a trusted network, and has to change before any public exposure. Only the
runner-facing `MachineEndpoint` methods are token-gated. Note that the
permission-tool methods on `TaskEndpoint` (`createQuestion`, `setPlanReady`,
…) are not token-gated.

### P3: Stale doc comments in code
These still say the task loop, planning or the PR flow are "not yet
implemented":
- `AgentRunnerService` and `TaskDispatcher` class docs
  (`roundtable_agent_runner/lib/roundtable_agent_runner.dart`,
  `src/task_dispatcher.dart`)
- `WorktreeManager` class doc (`src/worktree_manager.dart`)

Many comments still cite "design doc §x.y". Read those as pointing to
[ARCHITECTURE.md](ARCHITECTURE.md)/[FLOWS.md](FLOWS.md).
