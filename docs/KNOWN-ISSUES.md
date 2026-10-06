# Known issues

Last checked against the code on 2026-10-04. The 2026-10-04 cleanup fixed
these issues (see git history for details): generic `update` endpoints
bypassing the state machine, missing indexes, unbounded `MachineMetric`
growth, missing transactions, untyped exceptions, missing FK checks, no
GitHub timeouts, leftover worktrees, tasks stuck after a runner restart,
leaked stream subscriptions, detail screens without an error state,
duplicated metric widgets, the misleading dashboard title, the New task
dialog lookup bug, the dead Settings tile, no agent edit/delete, the
unclickable repo link, missing tooltips, `text2` contrast, and stale "design
doc" comments.

Priorities: **P2** polish/correctness · **P3** hygiene · **Accepted** a known
limitation that's deliberately not being fixed (yet).

## Open

### P2: Task detail can take a few seconds to open
Seen in the 2026-09-30 E2E run (~10 s while the WebSocket connects). Not
re-measured since.

### P2: A failed action on the task detail screen replaces the whole screen
`TaskDetailBloc` action handlers (answer, approve, feedback, cancel, …) emit
`TaskDetailError` on failure. The next task update restores the screen, but
until then the dev sees only the error. Review actions already use an
inline `reviewError`. The other actions should work the same way.

### P3: Test gaps
There are widget tests for the shared components, `errorMessage`, and the
kanban grouping, but none for the screens or dialogs.

### P3: Docker mode containers have no CPU/memory limits
A docker-mode run (docs/FLOWS.md §8) can use all of the machine's CPU and
RAM, so one heavy build slows every other task on it. Planned: per-agent (or
per-machine) limits passed as `podman run --cpus/--memory`.

## Accepted

### No user authentication, rate limiting or per-user data
User login comes after the MVP (see `AGENTS.md`). Anyone who can reach the
API can use every panel-facing endpoint. That's fine on localhost or a
trusted network, and has to change before public exposure. Only the
runner-facing `MachineEndpoint` methods are token-gated. The permission-tool
methods on `TaskEndpoint` (`createQuestion`, `setPlanReady`, …) and
`AgentEndpoint.setStatus` are not. The `serverpod_auth_idp_*` setup stays
initialized so it can be wired up later. `lib/src/greetings/` is unused
scaffold.

### No concurrency limit per machine
Each assigned task starts its own `claude` process. All agents on a machine
share one Claude Pro/Max token and its usage limits.

### The `cloning` status is not implemented
`TaskStatus.cloning` exists in the schema but nothing uses it.

### Docker mode: code reviews run on the machine, the network is open
Docker mode (docs/FLOWS.md §8) isolates task runs only. Code reviews still
run on the machine (the reviewer only reads). The container's network stays
open on purpose: the agent needs the Claude API and package registries, and
does web research. A dev runner started from source (`dart run`) can't
mount its permission-prompt-tool into the container; use the compiled
binaries.

### Cancel is offered while a task is in review
`cancelTask` accepts `awaitingReview`. It's the way to abandon a task whose
PR you don't want; the PR itself stays open on GitHub.

### A late runner write to a finished task is dropped
If a task was cancelled, failed by a future call, or merged while the runner
was still finishing, the runner's final `update` is ignored (see
`TaskEndpoint.update`). A PR the runner opened in that window stays on
GitHub but isn't linked to the task.
