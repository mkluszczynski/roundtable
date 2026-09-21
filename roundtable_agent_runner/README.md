# roundtable_agent_runner

The outbound daemon that runs on a registered machine. It reads its
configuration from `/etc/agent-runner/config.env` (written by
`scripts/install-agent.sh`, see the repo root) and reports a periodic
heartbeat to the roundtable server using the generated `roundtable_client`.

This is currently a heartbeat-only stub — picking up tasks, running Claude
Code, and managing git worktrees are separate, not-yet-implemented pieces of
the full daemon described in the design doc (§6.1, §6.2, §6.10).

Run locally for development:

```
AGENT_RUNNER_CONFIG_PATH=/path/to/config.env dart run bin/roundtable_agent_runner.dart
```
