# Task execution bugs (found 2026-09-29, from Task #7 run)

## Confirmed
1. **Task reported successful with no real change.** `task-7` commit d186af5
   contains only `.roundtable-mcp-config.json`; README untouched, yet status
   went to `awaitingReview` with branch + PR. `task_dispatcher.dart:249` trusts
   `result.success` alone.
2. **MCP config committed and pushed.** `_writeMcpConfig`
   (`task_dispatcher.dart:317`) writes into the worktree; `commitAndPush`
   commits it (leaks `SERVER_URL`, binary path). Move it outside the worktree
   or add to `.git/info/exclude`.
3. **Runner logs nothing during execution.** Journal only shows
   `assigned task 7 (status=queued)`, then heartbeats.
4. **Runner crash-loops when server is down.** Unhandled
   `ServerpodClientNetworkException` at `roundtable_agent_runner.dart:207`
   (`machine/identify`); systemd restart counter hit 10378. Needs retry/backoff.
5. **Future calls duplicated.** `MachineOfflineCheckFutureCall` /
   `StalledTaskCheckFutureCall` fire ~6-8x in the same ms every 5s — likely
   re-scheduled on each hot reload/restart without dedupe.

## Suspected
6. **Planning → execution never edits.** `runPlanning` uses
   `claude -p --permission-mode plan`; after `ExitPlanMode` approval the
   session may stay in plan mode or exit, so no Edit/Write happens. Need the
   task's logs to confirm.
7. **UI shows raw enum `awaitingReview`** instead of a label.

## Found in live E2E run (Task #8, 2026-09-29 23:56)
8. **Answering a question never unblocks the UI.** `answerQuestion`
   (`task_endpoint.dart:326`) only updates the `TaskQuestion` row; nothing
   moves the task from `waitingForAnswer` back to `planning`. The runner got
   the answer (`watchAnswer` fired, logs kept appending) but the detail
   screen stays on the question forever, with no feedback on click.
9. **Run dies silently, task stuck forever.** ~20s after the answer the
   `claude` process was gone (no `roundtable-agent` child processes), README
   untouched, yet no `task.update` was ever sent and the runner logged
   nothing — the dispatcher appears hung (never reached success or the
   `catch` path). Task stays `waitingForAnswer` indefinitely; the stalled
   check doesn't rescue it.
10. **Duplicated future calls keep growing** — ~20 per 5s tick by 23:58
    (was ~8 earlier). Confirms #5 is a leak, not a fixed multiplier.
11. **`task.watchTaskDeletions` streams fail** (3x `success: false` right
    after `createTask`).
12. **Task detail shows a blank spinner for ~10s** on open; agent picker in
    New task dialog appears ~3s late with no loading state.
13. The ambiguous prompt made the agent ask "which README" — repo has no
    root README.md; fine behaviour, just note for test prompts.

## Status after fixes (Task #10 E2E, 2026-09-30)
Fixed and verified live: 1, 2, 3, 4, 5/10, 7, 8, 9, 11, 12 (agent picker).
Task #10 ran plan → approve → edit → commit → PR; diff contained only
`roundtable_flutter/README.md`; runner logged every step; MCP config temp dir
cleaned up; future calls now fire once per 30s.

## Still open
18. **Answers to questions ignored** ("The user did not answer the questions"):
    the permission tool put the answer in `questions[0].answer`; Claude Code reads
    a top-level `answers` map. FIXED in `permission_prompt_tool.dart`.
14. **Plan-ready screen shows an empty plan.** Root cause: the agent user's
    `$HOME` is `/home/roundtable-agent`, which doesn't exist (the user was
    created by an old install), so `claude` gets EACCES creating
    `~/.claude/plans`. FIXED in `install-agent.sh` (usermod + `Environment=HOME`).
    Original notes: The agent logged that the plan
    directory isn't writable, so it couldn't save the plan file, and it called
    `ExitPlanMode` with no plan text. `/var/lib/agent-runner/.claude/plans`
    doesn't exist. Fix: have `install-agent.sh` create that directory (owned by
    `roundtable-agent`), and have the permission tool fall back to the plan
    file when `input['plan']` is empty.
19. **"Task is not planReady (planning)" when approving the plan.** A race
    that loses an update: `appendLog` did read-modify-write on the whole task
    row, so the log line written at the same moment as `ExitPlanMode` wrote
    back the old `planning` status and empty plan over `setPlanReady`'s
    update. FIXED: `appendLog` now writes only `lastProgressAt`.
15. FIXED: `task.update` writes only the fields the runner owns. **The
    runner's final `updateTask` writes back the task record as it was at
    start**, which can overwrite fields the server changed during the run
    (e.g. `currentPlan`).
16. **The New task dialog didn't close after Create** from the Projects list
    (the task was created; the "Task created" toast showed later).
17. The task detail screen still takes about 10s to open (the websocket
    connects first). The "Cancel task" button still shows while the task is
    in review.

## Tooling
- `flutter_driver` on the web build: screenshot throws RangeError; tap/get_text
  time out even with frame sync off.
