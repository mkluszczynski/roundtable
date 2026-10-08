# Architecture

## Components

| Package | What it is | Runs where |
|---|---|---|
| `roundtable_server/` | Serverpod backend: endpoints, models (`.spy.yaml`), migrations, background future calls, GitHub API client, web routes serving the install scripts and runner binaries | central server (local `serverpod start`, or Docker via `docker-compose.yml`) |
| `roundtable_client/` | **Generated** client for the server's endpoints. Never edit it by hand | imported by the panel and the runner |
| `roundtable_flutter/` | The panel (desktop/web), dark-only, `flutter_bloc` | developer's browser/desktop |
| `roundtable_agent_runner/` | Dart daemon compiled to two binaries: `roundtable_agent_runner` (the service) and `permission_prompt_tool` (an MCP stdio server that Claude Code calls) | each registered machine, as the `agent-runner` systemd service |
| `scripts/` | `install-agent.sh` / `uninstall-agent.sh` for a machine. Also served by the server at `/install-agent.sh` and `/uninstall-agent.sh` | target machine (Linux + systemd only) |

### Communication

Serverpod methods returning a `Future` are plain HTTP RPC. Methods returning a
`Stream` are multiplexed over one WebSocket. Live updates are **not** done with
`db.watch()`. Each endpoint posts to a named channel with
`session.messages.postMessage(...)`, and the `watch*` streams listen on those
channels. Most streams first **replay** current state and then yield live
updates.

Channels (in `TaskEndpoint`, `CodeReviewEndpoint`, `task_review_support.dart`):

| Channel | Carries | Consumed by |
|---|---|---|
| `machine-<id>-tasks` | `Task` to start/resume/clean up | runner `watchAssignedTasks` |
| `machine-<id>-reviews` | `CodeReview` to run | runner `watchAssignedReviews` |
| `task-<id>-reviews` | `CodeReview` (with comments) changes | panel `watchReviews` |
| `task-<id>` | `Task` updates | panel task detail, runner (cancel detection) |
| `all-tasks` | every `Task` update | dashboard/project/machine kanbans |
| `task-deletions` | `TaskDeleted` | kanbans |
| `task-<id>-logs` | `TaskLogEntry` | task detail log tail |
| `task-<id>-checks` | `PrChecks` snapshot (GitHub Actions jobs + state) | panel `watchChecks` |
| `task-question-<id>` | answered `TaskQuestion` | permission tool, blocked on `AskUserQuestion` |
| `task-<id>-plan-decision` | plan approve/reject | permission tool, blocked on `ExitPlanMode` |

The server also does work in the background with **five recurring future
calls**, registered in `roundtable_server/lib/server.dart`. On every boot it
deletes the existing rows and schedules them again, so they don't pile up:

- `MachineOfflineFutureCall` (every 30 s): a machine whose `lastSeenAt` is
  older than 60 s goes `offline`. All non-terminal tasks of its agents go to
  `failed` ("Machine went offline mid-task").
- `StalledTaskFutureCall` (every 30 s): a task in an agent-driven state
  (`queued`, `cloning`, `planning`, `running`) with no progress
  (`lastProgressAt`) for 15 min goes to `failed` — except a `queued` one
  whose agent is busy with other work or whose machine is usage limited,
  which the runner holds back on purpose.
- `MachineMetricCleanupFutureCall` (every 10 min): deletes `MachineMetric`
  rows older than 1 h.
- `PausedTaskResumeFutureCall` (every 30 s): a task `paused` by a Claude
  usage limit whose `pausedUntil` has passed is queued again, so its daemon
  resumes the same session.
- `PrChecksFutureCall` (every 30 s; settled checks only every 5 min): for
  each `awaitingReview` task with a PR and a project token, mirrors the
  GitHub Actions jobs of the PR's head commit (`syncChecks` in `lib/src/pr_checks.dart`). Polling, not a webhook:
  the server needn't be reachable from GitHub. See docs/FLOWS.md §4 "CI checks".

Both failure paths, plus `MachineEndpoint.reportStartup`, go through
`failTasks` in `lib/src/task_lifecycle.dart`.

## Server endpoints (`roundtable_server/lib/src/endpoints/`)

| Endpoint | Panel-facing | Runner-facing |
|---|---|---|
| `ProjectEndpoint` | `create/get/list`, `update` (name/repoUrl/dockerImage only), `updateRepoAccessToken` (write-only token), `updateTools` (validated toolchain list), `detectTools` (suggests toolchains from the repo's manifests via the GitHub API — pubspec.yaml, package.json, .nvmrc, .fvmrc, go.mod, a root `.mise.toml`/`.tool-versions`…), `delete` (blocked by non-terminal tasks) | `getCloneUrl`: HTTPS URL with the token injected as `x-access-token` |
| `MachineEndpoint` | `createEnrollment` (one-time install token valid 1 h + install command data; no machine yet), `enrolledMachine` (polled by the dialog), `enroll` (called by install-agent.sh: redeems the install token, creates the machine, returns its token; a retry before the machine first connects re-issues its token), `list/get/delete`, `update` (name/hostInfo only), `setClaudeToken` (write-only), `getScriptUrl`, `latestRunnerVersion`, `requestRunnerUpdate`, `watchLatestMetric` | token-authenticated: `identify`, `reportStartup` (fails tasks/reviews orphaned by a restart, resets agents to idle), `heartbeat`, `checkIn` (heartbeat + version, returns "update requested"; a daemon that doesn't pass `drainsForUpdate` is told only while its agents have no agent-driven task or running review), `reportMetric`, `reportClaudeStatus` (also where the daemon's Claude credentials come from: `ClaudeAuthSource`), `takeClaudeToken` / `confirmClaudeToken` (hand over a token set in the panel; cleared only once saved), `reportToolchain`, `reportOsVersion` (OS detected at startup from `/etc/os-release` / `sw_vers`, e.g. "Ubuntu 24.04"), `deregister` (uninstall: deletes the machine, or marks it offline + revokes the token if unfinished tasks block that) |
| `AgentEndpoint` | `create/get/list`, `update` (name/role/model/effort only), `delete` (blocked by non-terminal tasks) | `setStatus` (`idle`/`busy`/`waitingForResponse`) |
| `TaskEndpoint` | `createTask`, `cancelTask` (back to the backlog as an agent-less draft), `retryTask`, `reassignAgent`, `deleteTask`, `answerQuestion`, `approvePlan`, `submitPlanFeedback`, `submitFeedback`, `continueTask`, `acceptTask` (squash-merge, only with passing CI unless `force`), `getMergeStatus`, `resolveConflicts`, `getChecks`, `watchChecks`, `refreshChecks`, `fixFailingChecks`, `getChangedFiles`, `getFileContent`, `watchAllTasks`, `watchTask`, `watchLogs`, `watchTaskDeletions`, `latestQuestion` | `watchAssignedTasks`, `update` (runner-owned columns only; status limited to planning/running/awaitingReview/failed/cancelled; a write to an already-finished task or a draft is ignored), `appendLog`, `latestFeedback`, `findTasks` (worktree cleanup), and for the permission tool: `createQuestion`, `watchAnswer`, `setPlanReady`, `watchPlanDecision` |
| `CodeReviewEndpoint` | `requestReview`, `watchReviews`, `setCommentState`, `sendCommentsToFix` | `watchAssignedReviews`, `startReview`, `completeReview`, `failReview` |

Server-only helpers: `github_repo_client.dart` (PR files, file content,
create review, resolve thread, merge, mergeability, PR head, Actions runs,
jobs and job logs; every request times out after 30 s), `pr_checks.dart`
(CI checks sync, merge gate, fix-run prompt),
`task_review_support.dart` (shared review/feedback helpers kept out of the
endpoints so they aren't exposed as RPC), `agent_runner_binaries.dart`
(builds the runner binaries, serves them and hashes their version).

`greetings/` is leftover Serverpod scaffold. It isn't used by the app.

## Data model (`roundtable_server/lib/src/models/`)

```mermaid
erDiagram
  Machine ||--o{ Agent : hosts
  Machine ||--o{ MachineMetric : reports
  Project ||--o{ Task : has
  Agent |o--o{ Task : "assigned (optional)"
  Task ||--o{ TaskLogEntry : logs
  Task ||--o{ TaskQuestion : asks
  Task ||--o{ TaskFeedback : receives
  Task ||--o{ CodeReview : reviewed_by
  Task ||--o{ PrCheckRun : "CI jobs"
  Agent |o--o{ CodeReview : "reviewer (optional)"
  CodeReview ||--o{ ReviewComment : contains
```

| Entity | Notable fields |
|---|---|
| `Project` | `repoUrl`, `repoAccessToken` (**serverOnly**), `repoAccessTokenUpdatedAt`, `dockerImage` (docker-mode container image, default `buildpack-deps:bookworm-scm`), `tools` (`List<ProjectTool>` — mise tool id + version spec, e.g. `flutter 3.24`; the runner installs them with mise before each task and puts them first on `claude`'s PATH, docs/FLOWS.md §7; null/empty: only what the machine has), task-default overrides (`skipPlanning`, `autoReview`, `reviewerAgent`, `autoFixReview`, `maxReviewFixRounds`, `autoMerge`, `autoFixFailingChecks`, `maxCheckFixAttempts` — null inherits `WorkspaceSettings`; changing them updates the unfinished tasks' options not listed in `Task.overriddenOptions`, `propagateTaskDefaults`) |
| `MachineEnrollment` | (**serverOnly**) `tokenHash` (unique), `name` (null: hostname), `expiresAt`, `machineId` (set once redeemed); rows an hour past expiry are dropped on the next `createEnrollment` |
| `Machine` | `tokenHash` (**serverOnly**, unique index), `status` online/offline, `lastSeenAt`, `claudeExecutableOk/Error`, `runnerVersion`, `updateRequestedAt` |
| `Agent` | `machine` (cascade on delete), `name`, `role` (→ `AgentRoleDefinition`: `name`, `description`, `prompt`; editable in Settings, deleting one in use is blocked), `defaultModel`, `defaultEffort`, `executionMode` (`native`, or `docker`: task runs in a rootless Podman container, docs/FLOWS.md §8; switchable while the agent has no open task), `status` |
| `Task` | `project` (cascade), `agent` (optional, set null on delete), `prompt`, `title` (optional; suggested by the agent, editable by the dev), `skipPlanning`, advanced options (`autoReview`…`maxCheckFixAttempts`, with `overriddenOptions`: the ones the dev set on the task — the rest follow the project/workspace defaults), `status`, `currentPlan`, `failureReason`, `claudeSessionId`, `branchName`, `prUrl`, `startedAt/finishedAt/lastProgressAt`, CI: `prHeadSha`, `prHeadSeenAt`, `checkState` none/pending/success/failure, `checkError`, `checkFixAttempts`, `checkFixSentForSha` |
| `PrCheckRun` | one GitHub Actions job of the PR's head commit: `headSha`, `workflowRunId`, `runAttempt`, `workflowName`, `jobId`, `jobName`, `status`, `conclusion`, `failedStep`, `htmlUrl`; replaced when the head commit changes |
| `TaskLogEntry` | `content`, `source` agent/system |
| `TaskQuestion` | `question`, `options`, `answer`, `answeredAt` |
| `TaskFeedback` | `message`, `phase` plan/review |
| `CodeReview` | `reviewerAgent`, `status` queued/running/completed/failed, `summary`, `githubReviewId` |
| `ReviewComment` | `path`, `line`, `body`, `severity` blocker/issue/nit, `state` open/dismissed/sentToFix/resolved, `githubCommentId` |
| `MachineMetric` | `cpuPercent`, `memoryUsedMb/TotalMb`, index on `(machineId, recordedAt)` |

Non-table DTOs: `MachineInstallCommand`, `DiffFile`, `PrMergeStatus`, `PrChecks`,
`ReviewCommentDraft`, `TaskDeleted`.

Typed exceptions (their `message` reaches the panel; a plain `Exception`
would arrive as a generic internal server error): `NotFoundException`,
`InvalidStateException`, `GitHubException` (`statusCode`, 504 = timeout),
`DeletionBlockedException` (`machineOnline` / `nonTerminalTasks`) and
`InvalidTokenException`. Endpoints never throw a bare `Exception`.

Multi-row writes run in `session.db.transaction`. Delete guards
(check-then-delete) run as one serializable transaction (`guardedDelete` in
`endpoints/non_terminal_task_statuses.dart`).

Indexes: `task(projectId)`, `task(agentId)`, `task(status, lastProgressAt)`,
`agent(machineId)`, `(taskId, createdAt)` on
`task_log_entry`/`task_feedback`/`task_question`/`code_review`,
`review_comment(reviewId)`, `pr_check_run(taskId, jobId)`, unique `machine(tokenHash)`,
`machine_metric(machineId, recordedAt)`.

**Non-terminal task statuses** (`endpoints/non_terminal_task_statuses.dart`):
`draft, queued, cloning, planning, waitingForAnswer, planReady, running,
awaitingReview`. These block deleting a machine, agent or project. They also
get failed when the machine goes offline. `cloning` is defined but never set
by the runner today.

Design choices worth keeping:

- `Machine` is infrastructure and `Agent` is a persona. A machine hosts many
  agents. "Offline" exists only on the machine.
- Diffs are not stored. The server fetches them from the GitHub API on
  demand. GitHub can't be iframed (`X-Frame-Options: deny`), so the panel
  renders diffs itself.
- `Task.agent` is optional. A task survives its agent being deleted, and can
  start as an agent-less `draft`.

## Agent runner (`roundtable_agent_runner/`)

- `lib/roundtable_agent_runner.dart`: `AgentRunnerConfig` reads env vars
  (`REGISTRATION_TOKEN`, `SERVER_URL`, `CLAUDE_CODE_OAUTH_TOKEN`,
  `WORKSPACE_ROOT`, `CLAUDE_EXECUTABLE`, permission-tool path, update flag
  path). `AgentRunnerService` runs `identify` (exponential backoff up to 30 s
  while the server is down), then `reportStartup`, subscribes to the
  assigned task and review streams (resubscribes after 5 s on error), runs
  `checkIn` every 20 s, reports metrics every 8 s, sweeps worktrees every
  30 min, and checks that `claude` can be launched.
- `src/task_dispatcher.dart`: runs one task: worktree → Claude
  (planning or execution/resume) → commit/push → open PR → final status.
- `src/review_dispatcher.dart`: runs one code review in a read-only
  detached worktree. It parses the reviewer's final ```json block.
- `src/claude_code_executor.dart`: spawns `claude -p` (`run`,
  `runPlanning`, `runReview`) and parses NDJSON.
- `src/permission_prompt_tool.dart` + `bin/permission_prompt_tool.dart`: a
  hand-rolled MCP stdio server. It handles `AskUserQuestion` and
  `ExitPlanMode` through the server and auto-allows every other tool.
- `src/worktree_manager.dart`: one bare clone per project at
  `<WORKSPACE_ROOT>/<projectId>/repo.git`, and one worktree per task at
  `worktrees/<taskId>` on branch `task-<taskId>`. Every git call goes
  through `_git` (hooks and fsmonitor off, credentials as a header from the
  environment, never in `repo.git/config`) — see FLOWS.md §8.
- `src/worktree_janitor.dart`: removes worktrees of tasks that were deleted,
  are `done`, or ended `failed`/`cancelled` without pushing a branch (kept
  otherwise, since a retry pushes onto the existing PR branch). It never
  touches a task the dispatcher is running (`TaskDispatcher.isActive`).
- `src/github_pull_request_opener.dart` (30 s timeout), `src/metrics_collector.dart`
  (reads `/proc`, Linux only), `src/stream_json_formatter.dart` (turns NDJSON
  into readable log lines), `src/role_prompts.dart` (fills the role's
  prompt prefix, edited in Settings), `src/runner_update.dart` (version hash and update flag).

## Panel (`roundtable_flutter/lib/`)

- `screens/`: `panel_shell.dart` (nav rail with **Dashboard, Projects,
  Machines**; provides the one shared `DashboardCubit`), `dashboard_screen.dart`
  (kanban filterable by project + machines panel), `projects_screen.dart` →
  `project_detail_screen.dart`, `machines_screen.dart` (machines with their
  agents folded in; there is no separate Agents screen) →
  `machine_detail_screen.dart`, `task_detail_screen.dart`.
- State (per the Cubit-by-default rule): `repositories/` wrap the generated
  `client`. `cubits/` wrap one stream or one form each. `blocs/task_detail_bloc.dart`
  is the only full Bloc. It combines task status, logs, PR files and merge
  status, code reviews, CI checks (`watchChecks`, shown by
  `widgets/pr_checks_view.dart`), and user actions. Long-lived streams go through
  `utils/closeable_streams.dart` (`CloseableStreams.untilClosed`), so
  closing a Bloc/Cubit cancels its server subscriptions.
- Kanban columns (`cubits/dashboard_cubit.dart`): **Backlog** (draft, queued,
  cloning, failed) · **In progress** (planning, waitingForAnswer, planReady,
  running) · **Review** (awaitingReview) · **Done** (done and legacy
  cancelled). Cancelling a task moves it back to **Backlog** as a draft.
- `utils/`: `task_status_label.dart` (human-readable status labels),
  `error_message.dart` (shows a typed server exception's `message`),
  `closeable_streams.dart`, `relative_time.dart`, `code_language.dart`,
  `pr_checks.dart` (CI job/state helpers).

## Auth and secrets

- **Machine ↔ server:** the panel gets a one-time install token
  (`createEnrollment`, 1 h); install-agent.sh redeems it with `enroll`, which
  creates the machine with its own random token. Only hashes are stored. Runner-facing `MachineEndpoint` methods look up the machine by
  token. `deregister` deletes the machine (or clears the hash if unfinished
  tasks still block deletion).
- **Panel ↔ server: no authentication.** Serverpod's email IdP is initialized
  in `server.dart` and `client.dart`, but no endpoint calls `requireLogin` and
  the panel has no sign-in screen. Anyone who can reach the API can do
  anything. See [KNOWN-ISSUES.md](KNOWN-ISSUES.md).
- **GitHub token** (`Project.repoAccessToken`): `serverOnly`, never returned
  to the panel. The runner gets it only inside the clone URL at task start and
  uses that URL as a one-off push target, never as a saved remote.
  `getFileContent` refuses URLs that don't point at `api.github.com`.
- **Claude token** (`CLAUDE_CODE_OAUTH_TOKEN`, from `claude setup-token`):
  set at install (`/etc/agent-runner/config.env`, mode 600) or later in the
  panel ("Set Claude token" on the machine). A panel token is held in
  `Machine.pendingClaudeToken` (**serverOnly**) only until the daemon
  confirms it saved it (`takeClaudeToken`, then `confirmClaudeToken`), at
  most 10 minutes; the daemon
  saves it to `~/.roundtable/claude-oauth-token` (mode 600), which takes
  precedence over config.env. The panel can replace the token but never
  read it. All agents on one machine share one Pro/Max subscription's
  limits.
