# roundtable_agent_runner

The daemon that runs on each registered machine as the `agent-runner`
systemd service. It connects **outbound** to the Roundtable server, picks up
assigned tasks and code reviews, runs Claude Code headlessly in a git
worktree per task, pushes the branch, opens the PR, and streams logs, status
and CPU/RAM metrics back to the server.

It ships as two compiled binaries, which the server serves at
`/agent-runner-bin` and `/permission-prompt-tool-bin`:

- `bin/roundtable_agent_runner.dart`: the daemon
- `bin/permission_prompt_tool.dart`: the MCP stdio server Claude Code calls for
  `AskUserQuestion` / `ExitPlanMode` (plan mode)

Install, update and uninstall go through `scripts/` and the panel's Machines
screen. How it works: `docs/ARCHITECTURE.md` (Agent runner) and
`docs/FLOWS.md`.

Configuration comes from `/etc/agent-runner/config.env` (written by
`scripts/install-agent.sh`): `REGISTRATION_TOKEN`, `SERVER_URL`,
`CLAUDE_CODE_OAUTH_TOKEN`, `WORKSPACE_ROOT`, `CLAUDE_EXECUTABLE`, …

Run from a checkout for development (no systemd, no self-update):

```
AGENT_RUNNER_CONFIG_PATH=/path/to/config.env dart run bin/roundtable_agent_runner.dart
```

Tests: `dart test`.
