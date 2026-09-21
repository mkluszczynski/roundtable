# Agent runner install scripts

Scripts for installing/uninstalling the `agent-runner` daemon as a systemd
service on a machine (laptop or VPS) that will host one or more agents. See
`install-agent.sh --help` / `uninstall-agent.sh --help` for full flag lists.

## Claude Code authorization

Claude Code runs under your own Pro/Max subscription, not API billing, so
each machine needs to be authorized once before agents on it can run tasks:

```bash
claude setup-token
```

This prints a URL — open it in **any** browser, even one on a different
device than the machine running the install script (your laptop, say). Log
in there, and a long-lived `CLAUDE_CODE_OAUTH_TOKEN` is printed back in the
terminal on the machine.

> **Why `setup-token` and not `claude login`?** Some VPS providers (e.g.
> Hetzner) sit behind Cloudflare protection that blocks the OAuth redirect
> `claude login` tries to perform directly from the server, returning a 403.
> `claude setup-token` avoids this entirely — the browser step happens off
> the machine, and only the resulting token comes back over the terminal.

Pass that token to the installer with `--claude-token`, alongside the
machine registration token and server URL:

```bash
sudo ./scripts/install-agent.sh \
  --token <REGISTRATION_TOKEN> \
  --server https://your-server.example.com \
  --claude-token <CLAUDE_CODE_OAUTH_TOKEN>
```

The installer writes it into `/etc/agent-runner/config.env` (mode `600`)
alongside the registration token, and the daemon reads it from there when
launching Claude Code subprocesses. It never reaches the central server or
database — unlike the repo access token, this one is tied to a specific
`claude` installation on this specific host and stays local.

If you forgot to pass `--claude-token` on first install, re-run
`install-agent.sh` with the same flags plus `--claude-token` — it's safe to
run again (it stops the existing service before reinstalling).

**Known limitation:** the token is pinned to one human subscription, sized
for one person's interactive use. Several agents on the same machine firing
off Claude Code subprocesses concurrently will hit Pro/Max usage limits
sooner than a single developer working by hand — worth keeping in mind
before running many agents in parallel on one machine.
