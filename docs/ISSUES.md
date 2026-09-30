# Known issues

Gaps discovered during implementation that are out of scope for the change
that surfaced them, tracked here instead of silently left undocumented.

Entries are tagged with a priority:
- **P0** — will actively mislead manual/demo testing, fix first.
- **P1** — real bug or gap, fix soon but not blocking testing.
- **P2** — polish / correctness nice-to-have.
- **P3** — low priority / doc hygiene.
- **Accepted** — known limitation, deliberately not being fixed right now.

## Deleting a project with task history fails with a raw DB error

**Priority:** P1 (see also "No transactions around delete guards" below,
same family of delete-guard issues).

**Where:** `roundtable_server/lib/src/endpoints/project_endpoint.dart`,
`ProjectEndpoint.delete`.

`Task.projectId` is a required (non-nullable) foreign key with no cascade
or `SET NULL` behavior. `ProjectEndpoint.delete` has a guard that blocks
deletion with a friendly `DeletionBlockedException` while the project has
**non-terminal** tasks (queued/planning/running/etc., mirroring
`AgentEndpoint`/`MachineEndpoint`'s existing pattern) — but a project that
has **any** task at all, including old `done`/`failed`/`cancelled` ones,
still fails deletion: the guard passes, then the raw `Project.db.deleteRow`
call hits a Postgres foreign-key violation
(`DatabaseForeignKeyViolationException`, `task_fk_0`), which is a much
less friendly failure than the guard's message.

This differs from `Agent`, where `Task.agentId` is nullable, so an
agent with only terminal tasks can be deleted cleanly today (confirmed by
`agent_endpoint_test.dart`'s "whose tasks are all terminal" case). The
equivalent "delete a project whose tasks are all terminal" test was
written and then removed during this change because it failed against the
current schema — see `roundtable_server/test/integration/project_endpoint_test.dart`
git history for the reverted test if useful as a starting point.

**Why not fixed yet:** the right fix is a product decision, not just a
bug fix — cascading the delete to a project's tasks (and their logs/
feedback/questions) discards audit history; nulling `Task.projectId`
would need the field to become optional, changing scope like the Task
model's design doc §5 already reasons about for `Task.agentId`; a third
option is an explicit "archive" step instead of hard deletion. None of
these should be picked silently.

**Possible directions:**
- Make `Task.projectId` nullable and `SET NULL` on delete (same shape as
  `Agent`), losing the task→project link on old tasks.
- Cascade-delete a project's tasks (and their `TaskLogEntry`/
  `TaskFeedback`/`TaskQuestion` rows) when the project itself is deleted.
- Replace "Delete project" with an archive/soft-delete flag instead of a
  real row delete, keeping full history.
- At minimum, catch `DatabaseForeignKeyViolationException` in
  `ProjectEndpoint.delete` and rethrow as a friendlier
  `DeletionBlockedException` (or a new reason on
  `DeletionBlockReason`) so the panel doesn't show a raw DB error string
  even if the underlying limitation stays.

**User-facing impact today:** `project_detail_screen.dart`'s
"Delete project" button will surface a raw database error message (via
the existing `ProjectListError` snackbar path) for any project that has
ever had a task, rather than a clear explanation.

---

## Generic `update` endpoints bypass task/entity state-machine guards

**Priority:** P1

**Where:** `TaskEndpoint.update`, `ProjectEndpoint.update`,
`MachineEndpoint.update`, `AgentEndpoint.update` (all in
`roundtable_server/lib/src/endpoints/`).

Each of these accepts an arbitrary client-supplied row of its entity and
writes it verbatim (`update` just calls `.updateRow` on whatever
`Task`/`Project`/`Machine`/`Agent` object is passed in). Nothing
constrains the write to a legal state transition, so a caller could set
`Task.status: done` directly on a `queued` task, bypassing every guard
built into `cancelTask`/`approvePlan`/`submitPlanFeedback`, or write
`Machine.tokenHash` directly via `MachineEndpoint.update`, bypassing the
generation/hashing done in `register`.

**Why not fixed yet:** surfaced during this review; note this is a
correctness gap independent of the authentication decision below — even
in a fully trusted single-tenant environment, an accidental or buggy
caller (e.g. the daemon itself, or a future UI bug) could corrupt task
state via this path.

**Possible directions:**
- Narrow each `update` method to only the fields it's actually meant to
  support externally (most callers seem to only need a rename/relabel),
  and route all status transitions exclusively through the dedicated,
  guarded methods.
- If a generic update is still needed internally, restrict it to
  server-internal callers rather than exposing it on the endpoint.

**User-facing impact today:** none observed yet (nothing in the current
UI calls these methods this way), but it's a live foot-gun for future
daemon/panel code and a genuine bypass of the task lifecycle invariants
the rest of the codebase carefully enforces.

---

## Missing indexes on hot query paths

**Priority:** P1

**Where:** `roundtable_server/migrations/*/definition.sql` (`task`,
`agent`, `task_log_entry`, `task_feedback`, `task_question` tables).

`task` has no indexes beyond its primary key, despite being queried by
`projectId`, `agentId`, and `(status, lastProgressAt)` constantly —
including by `MachineOfflineFutureCall` and `StalledTaskFutureCall` on
every 30-second tick, which currently do a full table scan each time.
`agent.machineId` (queried by `watchAssignedTasks` and both future calls),
and `task_log_entry.taskId`/`task_feedback.taskId`/`task_question.taskId`
(queried/sorted by `watchLogs`/`latestFeedback`/`latestQuestion`) are
similarly unindexed.

**Why not fixed yet:** surfaced during this review; low impact at current
data volumes, but degrades as task/log history grows.

**Possible directions:**
- Add indexes on `task.projectId`, `task.agentId`, `task.status`
  (or a composite `(status, lastProgressAt)`), `agent.machineId`, and the
  `taskId` FK columns on `task_log_entry`/`task_feedback`/`task_question`,
  via `.spy.yaml` `indexes:` blocks + a migration.

**User-facing impact today:** none yet at current scale; will show up as
slow dashboard loads / slow future-call ticks once task and log volume
grows.

---

## No periodic cleanup of `MachineMetric` rows

**Priority:** P1

**Where:** `roundtable_server/lib/src/models/machine_metric.spy.yaml`
(doc comment on line 2: "Grows over time — needs periodic cleanup of old
entries"); `roundtable_server/lib/server.dart` (future call registration).

Only two future calls are registered (`MachineOfflineFutureCall`,
`StalledTaskFutureCall`) — no metric-retention job exists, even though
the model's own doc comment flags the need. `reportMetric` is called on
a tight per-machine polling interval from the daemon, so this table has
no bound on growth.

**Why not fixed yet:** noted as needed at model-design time but not yet
implemented; design doc §6.9 correctly scopes a real-time metrics chart
as Could/deferred, but doesn't defer the retention cleanup itself, which
is needed even for the plain "snapshot" (Should-scope) use case.

**Possible directions:**
- Add a third recurring future call (e.g. every few minutes) that
  deletes `MachineMetric` rows older than a fixed retention window,
  following the same pattern as the other two future calls — but route
  it in a way that doesn't repeat the broadcast-bypass mistake noted
  above (metrics don't need live broadcast on delete, so a direct
  `deleteWhere` is fine here).

**User-facing impact today:** none yet; will become a real storage/perf
issue the longer the app runs with machines reporting metrics.

---

## Inconsistent exception handling across endpoints

**Priority:** P1

**Where:** all files under `roundtable_server/lib/src/endpoints/`.

Roughly 15+ call sites throw a bare `Exception('...')` for "not found" /
invalid-state guards (e.g. `task_endpoint.dart` lines ~33, 112, 116, 144,
148, 152, 156, 231, 234, 304, 330, 369, 408, 412, 416, 420, and similar
in the other endpoints), while only two cases
(`DeletionBlockedException`, `InvalidTokenException`) use the proper
Serverpod pattern of a typed exception declared in `.spy.yaml`.

**Why not fixed yet:** surfaced during this review.

**Possible directions:**
- Declare typed exceptions (e.g. `NotFoundException`,
  `InvalidStateException`) in `.spy.yaml` for the recurring guard
  patterns, and switch the bare `Exception(...)` throws over to them.

**User-facing impact today:** the Flutter client can't distinguish these
failure modes from any other unexpected error — it only ever sees a
generic error string, so it can't show a targeted message or offer a
targeted recovery action the way it does for `DeletionBlockedException`.

---

## Missing transactions around multi-write sequences and delete guards

**Priority:** P1

**Where:** `TaskEndpoint.createQuestion`, `TaskEndpoint.submitPlanFeedback`
(insert + update as two separate statements); `ProjectEndpoint.delete`,
`MachineEndpoint.delete`, `AgentEndpoint.delete` (check-then-delete across
multiple un-transacted queries).

None of these are wrapped in `session.db.transaction(...)`. For the
insert+update pairs, a failure on the second write leaves the first
orphaned with no compensating rollback. For the delete guards, the
guard-check and the final `deleteRow` are separate round trips, so a
task/heartbeat racing in between can invalidate the guard's assumption
(TOCTOU).

**Why not fixed yet:** surfaced during this review.

**Possible directions:**
- Wrap each multi-write sequence in `session.db.transaction((transaction)
  async { ... })`, which Serverpod supports but which isn't used anywhere
  in the codebase currently.

**User-facing impact today:** low likelihood in practice (requires a
tight race), but a real correctness gap, not just theoretical.

---

## Stream-subscription leaks in `TaskDetailBloc` and `DashboardCubit`

**Priority:** P1

**Where:** `roundtable_flutter/lib/blocs/task_detail_bloc.dart`
(`_onSubscribed`, `_onLogsSubscribed`), `roundtable_flutter/lib/cubits/dashboard_cubit.dart`
(`subscribe`).

Both drive `await for` loops over long-lived Serverpod streams
(`watchTask`, `watchLogs`, `watchAllTasks`). Neither has a `close()`
override to cancel the loop, and Bloc/Cubit's default `close()` does not
cancel an already-running `await for` body — it only stops new events
from being dispatched to `on<Event>` handlers. Separately,
`DashboardCubit` is instantiated fresh (via `BlocProvider(create: ...)`)
on four different screens (`dashboard_screen.dart`, `projects_screen.dart`,
`project_detail_screen.dart`, `machine_detail_screen.dart`), each opening
its own independent full `watchAllTasks()` subscription instead of
sharing one.

**Why not fixed yet:** surfaced during this review.

**Possible directions:**
- Store the `StreamSubscription` explicitly (via `.listen()` instead of
  `await for`) and cancel it in an overridden `close()`.
- Consider promoting `DashboardCubit` (or the underlying task stream) to
  an app-level singleton provided above the screens that need it, so
  there's one `watchAllTasks()` subscription instead of four.

**User-facing impact today:** likely a growing number of orphaned
server-side stream subscriptions the longer a session runs and the more
the user navigates between task detail / dashboard / project / machine
screens — not immediately visible in the UI, but a resource leak.

---

## Test coverage gaps on non-trivial logic

**Priority:** P1

**Where:** server: `MachineEndpoint.reportMetric`/`watchLatestMetric`,
`MachineEndpoint.identify`, `TaskEndpoint.getChangedFiles`/
`getFileContent` and `GitHubRepoClient` generally, `TaskEndpoint.watchAllTasks`,
and the unrestricted-`update` behavior noted above. Flutter:
`widgets/diff_view.dart` (real diff-line parsing logic) and the kanban
widgets (`kanban_card.dart`, `kanban_column.dart`) — 16 of 21 shared
widgets in `roundtable_flutter/lib/widgets/` have no test at all.

**Why not fixed yet:** surfaced during this review.

**Possible directions:**
- Prioritize tests for the GitHub-proxy path (it touches secrets and an
  external API) and `diff_view.dart` (real parsing logic, not just
  layout) first; the rest can follow incrementally.

**User-facing impact today:** none directly; this is a regression-risk
gap rather than a known bug.

---

## Duplicated machine-metrics rendering code

**Priority:** P2

**Where:** `roundtable_flutter/lib/screens/machines_screen.dart`
(`_MachineCard`, ~lines 207-349) vs.
`roundtable_flutter/lib/widgets/machine_summary_card.dart` (~lines
60-91).

The CPU/RAM `MachineMetricCubit` + `MetricBar` rendering block (including
the exact same formatting logic, `cpuPercent.toStringAsFixed(0)`,
`memoryUsedMb / 1024`) is duplicated near-verbatim in both places instead
of being a single shared widget.

**Why not fixed yet:** surfaced during this review.

**Possible directions:**
- Extract a shared `MachineMetricsSection` widget and use it from both
  `_MachineCard` and `machine_summary_card.dart`.

**User-facing impact today:** none directly; a maintenance/consistency
risk (a formatting fix applied to one copy is easy to forget in the
other).

---

## Raw enum values shown unhumanized in the UI

**Priority:** P2

**Where:** `roundtable_flutter/lib/screens/task_detail_screen.dart`
(~line 151), `roundtable_flutter/lib/widgets/kanban_card.dart` (~line
48), `roundtable_flutter/lib/screens/machine_detail_screen.dart` (~line
366).

`task.status.name` (e.g. `waitingForAnswer`, `planReady`,
`awaitingReview`) is displayed directly as a pill label instead of being
formatted into a human-readable string. `machine_detail_screen.dart`'s
own `_AgentsCard` already does humanize `AgentStatus` (e.g. "Idle" /
"Busy" / "Waiting"), so the pattern exists but is applied inconsistently.

**Why not fixed yet:** surfaced during this review.

**Possible directions:**
- Add a `TaskStatus` → display-label helper (mirroring what
  `_AgentsCard` already does for `AgentStatus`) and use it everywhere
  `task.status` is rendered.

**User-facing impact today:** camelCase enum names are shown directly to
the user instead of readable labels.

---

## Missing FK-existence validation before insert

**Priority:** P2

**Where:** `TaskEndpoint.createTask` (validates `agentId` but not
`projectId`), `AgentEndpoint.create` (doesn't validate `machineId`).

Both rely on the database's `NOT NULL`/FK constraint to reject a bad id,
which surfaces as a raw Postgres FK-violation exception rather than a
clean domain-level error — inconsistent with the agent-existence check
`createTask` does perform right above the missing project check.

**Why not fixed yet:** surfaced during this review.

**Possible directions:**
- Add the same existence check pattern already used for `agentId` in
  `createTask` to `projectId`, and to `machineId` in `AgentEndpoint.create`.

**User-facing impact today:** a bad `projectId`/`machineId` (shouldn't
normally happen from the UI, since both are chosen from live lists, but
possible via any other caller) surfaces as a raw DB error.

---

## Detail screens have no error/not-found state

**Priority:** P2

**Where:** `roundtable_flutter/lib/screens/project_detail_screen.dart`,
`roundtable_flutter/lib/screens/machine_detail_screen.dart` — both use
`FutureBuilder` and only branch on `snapshot.data == null`.

Neither screen checks `snapshot.hasError`, so a genuine fetch error and a
"record not found" case both degrade to an infinite loading spinner with
no retry option or error message.

**Why not fixed yet:** surfaced during this review.

**Possible directions:**
- Add an explicit error branch (and a "not found" branch, if
  distinguishable) to both `FutureBuilder`s.

**User-facing impact today:** a dead-end spinner if the fetch ever fails
or the record no longer exists (e.g. deleted by another client).

---

## No timeout on the GitHub HTTP client

**Priority:** P2

**Where:** `roundtable_server/lib/src/services/github_repo_client.dart`
(or equivalent — the `http.Client()` used for GitHub API calls).

The underlying `package:http` client is used with its default (i.e. no)
timeout.

**Why not fixed yet:** surfaced during this review.

**Possible directions:**
- Add an explicit timeout (e.g. `.timeout(Duration(seconds: 10))`) around
  the GitHub API calls in `getChangedFiles`/`getFileContent`.

**User-facing impact today:** a hung GitHub API call could hang the
corresponding panel request indefinitely.

---

## Accessibility gaps: missing tooltips/semantics, possible contrast issues

**Priority:** P3

**Where:** icon-only `IconButton`s across `roundtable_flutter/lib/screens/`
and `roundtable_flutter/lib/widgets/app_modal.dart` (back-arrow buttons,
the modal's close button) have no `tooltip`/`Semantics`, so they read as
unlabeled to assistive technology. Caption-sized text
(`AppTypography.caption`/`code`) using `AppColors.text2` on `bg1`/`bg2`
backgrounds is close to/potentially under WCAG AA contrast (4.5:1) —
this needs a rendered/measured check to confirm precisely, source
inspection alone isn't conclusive.

**Why not fixed yet:** surfaced during this review; not yet measured
against a rendered page.

**Possible directions:**
- Add `tooltip:` to icon-only buttons app-wide.
- Run a contrast check against rendered screens for `text2`-on-`bg1`/`bg2`
  usages and adjust the palette if any fall under 4.5:1 for their text
  size.

**User-facing impact today:** unclear without a screen-reader/contrast
audit; flagged as a likely gap based on source inspection.

---

## Misleading non-functional affordances

**Priority:** P3

**Where:** `roundtable_flutter/lib/screens/project_detail_screen.dart`
— the `Icons.open_in_new` icon next to the repo URL has no `onTap`;
`roundtable_flutter/lib/screens/dashboard_screen.dart` (~lines 129-130)
— the disabled "New task" button (shown when there's no project yet) has
no tooltip explaining why it's disabled.

**Why not fixed yet:** surfaced during this review.

**Possible directions:**
- Wrap the repo-URL icon in a tappable widget that opens the URL, or
  remove the icon if it's not meant to be interactive.
- Wrap the disabled "New task" button in a `Tooltip` explaining that a
  project is required first.

**User-facing impact today:** minor UX confusion — an icon that looks
clickable isn't, and a disabled button gives no explanation.

---

## Dead "Settings" nav entry; agent has no update/delete UI

**Priority:** P3

**Where:** `roundtable_flutter/lib/widgets/nav_rail.dart` (Settings tile,
`onSettingsTap` defaults to a no-op); `roundtable_flutter/lib/repositories/agent_repository.dart`
(only exposes `listAgents`/`getAgent`/`createAgent`, no update/delete).

The nav rail's "Settings" entry does nothing — no settings screen exists
anywhere in `lib/screens/`. Separately, once an agent is created there's
no UI path to rename, reconfigure, or delete it (unlike `Project` and
`Machine`, which both support deletion from their respective screens).

**Why not fixed yet:** surfaced during this review; unclear whether the
missing agent update/delete is intentional scope-limiting or an
oversight.

**Possible directions:**
- Remove the Settings nav entry until there's a screen behind it, or
  build a minimal settings screen.
- Confirm whether agent update/delete is in scope; if so, add the
  repository methods and a UI affordance (mirroring `MachineListCubit`'s
  `deleteMachine`/`machines_screen.dart` pattern).

**User-facing impact today:** clicking "Settings" does nothing; agents
are create-only once added.

---

## Stale doc comments contradicting the current implementation

**Priority:** P3

**Where:** `roundtable_agent_runner/lib/src/worktree_manager.dart` and
`roundtable_agent_runner/lib/roundtable_agent_runner.dart`
(`AgentRunnerService`) both have class-level doc comments claiming
task-assignment/planning/PR-flow are "not-yet-implemented," despite
`TaskDispatcher` and `PermissionPromptTool` fully implementing them.
`docs/UI-DESIGN.md`'s opening similarly states "nothing described below
is wired up yet," despite `roundtable_flutter/lib/theme/` and the shared
widget library already existing and being in active use.

**Why not fixed yet:** surfaced during this review; these are leftover
comments from an earlier development stage that weren't updated as the
features landed.

**Possible directions:**
- Update or remove the stale doc comments/doc sections to reflect current
  implementation status.

**User-facing impact today:** none directly; risk is misleading the next
person (or agent) who reads these files and assumes the described gaps
still exist.

---

## `AGENTS.md` contradicts the design doc's "no user login" decision

**Priority:** P1 (documentation fix — should be corrected even though
the underlying auth gap itself is accepted, see below)

**Where:** `AGENTS.md` (repo root): "Build for multiple users, use
Serverpod's built-in authentication, which is already set up in
`lib/server.dart`." vs. `docs/DESIGN-DOC.md` §4, which explicitly lists
"User login / registration" under **Won't**, and states the Must-scope
auth item is "Agent↔server authorization via token | not to be confused
with user login (we're not doing that)."

This is leftover `serverpod create` scaffold boilerplate, never updated
for this project. Recent commits have been actively *removing* the
login UI (`sign_in_screen.dart`, `greetings_screen.dart` deleted), moving
the codebase toward the design doc's decision even as `AGENTS.md` still
instructs the opposite. `roundtable_server/lib/server.dart`'s
`initializeAuthServices(...)` call (with `serverpod_auth_idp_server` and
a `ServerpodCloudEmailIdpConfig`) and `roundtable_flutter/lib/client.dart`'s
`FlutterAuthSessionManager`/`client.auth.initialize()` bootstrapping,
plus the `serverpod_auth_idp_*` dependencies in both `pubspec.yaml`
files, are now orphaned scaffolding — initialized but never exercised by
any UI or gated by any endpoint.

**Decision:** multi-user support is out of scope for now. The
functional gap this implies (no per-request authentication/authorization
on any endpoint, and the fully generic `update` endpoints having no
access control) is **accepted** as a known limitation of a single-tenant,
locally-run app — not being implemented at this time.

**What should still change:** `AGENTS.md`'s "build for multiple users"
sentence should be corrected so a future agent isn't misled into adding
auth unprompted, and the orphaned `serverpod_auth_idp_*` scaffolding
(server init, Flutter client bootstrap, dependencies) is worth removing
as dead weight, independent of the "no auth" decision itself.

**User-facing impact today:** none from the contradiction itself; the
risk is entirely about misleading future development (human or agent).

---

## No authentication/authorization on any application endpoint

**Priority:** Accepted (single-tenant scope) — see the `AGENTS.md`
contradiction entry above for the related documentation fix that should
still happen.

**Where:** every method on `TaskEndpoint`, `ProjectEndpoint`,
`AgentEndpoint`, and all of `MachineEndpoint` except the token-gated
daemon-facing methods (`heartbeat`, `deregister`, `identify`,
`reportMetric`, which do validate a machine registration token).

No endpoint calls `requireLogin` or checks a session scope, despite
`serverpod_auth_idp_server` being fully initialized in `server.dart`.
Anyone who can reach the API can create/cancel tasks, read any project's
PR diffs/file contents (proxied server-side, so the PAT itself isn't
leaked, but access to it is unrestricted), register/deregister machines,
and read/write all `Agent`/`Machine`/`Project` records.

**Why not fixed:** multi-user support is explicitly out of scope for now
(see decision above); this is accepted as appropriate for a
single-tenant, locally-run hackathon-scoped app.

**Possible directions (if this changes later):** add `requireLogin`/scope
checks per the design doc's actual auth item (agent↔server token auth is
separate and already implemented correctly via `Machine.tokenHash`); or,
if user-facing auth is ever wanted, wire the already-initialized
`serverpod_auth_idp_server` module into the panel-facing endpoints
properly instead of leaving it orphaned.

**User-facing impact today:** none in a trusted, local-only deployment;
would matter immediately if the server were ever exposed beyond
localhost/a trusted network.

---

## No rate limiting on any endpoint

**Priority:** Accepted (same reasoning as the authentication gap above)

**Where:** all endpoints, notably `MachineEndpoint.register` and
`TaskEndpoint.getChangedFiles`/`getFileContent` (which proxy GitHub API
calls using the project's PAT).

Combined with the lack of authentication, `register` could be spammed to
create unlimited machine rows, or the GitHub-proxy endpoints could be
hit repeatedly enough to exhaust the project's GitHub API rate limit.

**Why not fixed:** accepted alongside the no-auth decision above; not
worth addressing independently while the app is single-tenant and
locally run.

**Possible directions (if this changes later):** add basic per-caller
rate limiting once/if the server is ever exposed beyond a trusted local
environment.

**User-facing impact today:** none in the current deployment model.
