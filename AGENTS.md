# Roundtable

Roundtable is an AI coding-agent command center (start at `docs/README.md`;
architecture and data model in `docs/ARCHITECTURE.md`, step-by-step flows in
`docs/FLOWS.md`, design system in `docs/UI-DESIGN.md`, open bugs in
`docs/KNOWN-ISSUES.md`). A developer registers machines (laptop, VPS) that host agents —
named personas with a role, model, and effort — assigns them tasks against a
git repo, and watches the work live (streamed logs, plan approval, diff
review, PR) from one panel, instead of SSH-ing in and babysitting a terminal.

This project is a Flutter app (frontend, `roundtable_flutter/`) backed by a
Serverpod server (backend, `roundtable_server/`). Always build the app's
backend with Serverpod. For now the app is single-tenant with **no user
login**: don't add authentication or per-user data yet. That comes after the
MVP, using Serverpod's built-in auth, which is already initialized in
`lib/server.dart`.

## App structure

- `roundtable_flutter/lib/screens/` — `panel_shell.dart` (nav rail: Dashboard,
  Projects, Machines), `dashboard_screen.dart` (live kanban board + machines
  panel), `task_detail_screen.dart` (one screen, 4 sub-states switched on
  `Task.status`: waiting for answer, plan approval, live execution log tail,
  diff review + AI code review), `projects_screen.dart` →
  `project_detail_screen.dart`, `machines_screen.dart` (agents are listed
  under their machine; no separate Agents screen) → `machine_detail_screen.dart`.
- `roundtable_flutter/lib/widgets/` — the shared design-system components
  (`status_pill.dart`, `app_card.dart`, `code_block.dart`, `pill_selector.dart`,
  `app_modal.dart`, `diff_view.dart`) plus the add-machine/add-project/
  add-agent/create-task dialogs built on them. Widget tests live under
  `roundtable_flutter/test/widgets/`.
- `roundtable_flutter/lib/theme/` — dark-only design tokens (`colors.dart`,
  `typography.dart`, `spacing.dart`) and `app_theme.dart`, per
  `docs/UI-DESIGN.md`.
- `roundtable_flutter/lib/{cubits,blocs,repositories}/` — state management
  per `docs/ARCHITECTURE.md`: a repository layer wraps the generated
  `client`, Cubits wrap a single stream, `TaskDetailBloc` is the one full Bloc
  (multiple event sources: task status, logs, diff, dev actions).
- `roundtable_server/lib/src/` — endpoints, `.spy.yaml` models, future calls,
  `github_repo_client.dart`; `roundtable_agent_runner/` — the machine daemon
  (see below and `docs/ARCHITECTURE.md`).

The user starts the server and Flutter app with `serverpod start`. There is no need to check if the server is running: make the changes and call the `serverpod` MCP tools as needed. If the server is not running, an informative error message will be received from the MCP server. Then STOP and ask the user to start it. NEVER start the server yourself. The Flutter app is started along with it, or can be launched from the MCP tool `spawn_flutter_app`.

While running, `serverpod start` watches for file changes to run incremental code generation and hot reload both the server and the Flutter app.

Calling `serverpod generate` directly is not needed, but might be useful to troubleshoot when an incremental generation fails.

ALWAYS use the MCP server instead of the command line. Use the MCP server to:

- `create_migration` and `apply_migrations` for database (after you change data models).
- `create_repair_migration` if the database has drifted out of sync with the migrations.
- `tail_server_logs` to read logs from the server.
- `tail_flutter_logs` to read the raw stdout/stderr of the Flutter app.
- `hot_reload` / `hot_restart` to reload or restart the server and the Flutter app. ALWAYS call `hot_restart` after doing changes in the Flutter app that may not work with normal hot reload (which is automatically applied).
- `spawn_flutter_app` to start a Flutter app declared under `serverpod: flutter_apps:` in the server `pubspec.yaml`.
- `get_flutter_app_dtd` (Dart tooling daemon) for connecting to the app through the `dart` MCP.

NEVER edit generated code. The server's `lib/src/generated/` directory and the whole `roundtable_client` package are rewritten by the code generator. Change the `.spy.yaml` models, the endpoints, or `lib/server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Only when the server cannot be started at all, fall back to the CLI in the server package:

- `serverpod generate` to regenerate the client and the generated server code.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). It only writes the migration; `serverpod start` applies pending migrations when it boots the server.

Tests need no Docker. `config/test.yaml` sets `database.dataPath`, so Serverpod starts and manages the test database (an embedded PostgreSQL) itself, and the project's `docker-compose.yaml` is not used for it. Just run `dart test` in the server package.

Checklist after doing changes, in this order:

- `dart analyze` (CLI)
- `dart format` (CLI)
- `create_migration` and `apply_migrations` (MCP - only if necessary)
- Do `serverpod` MCP `hot_restart` if required (hot reload is done automatically). Will also hot restart Flutter app
- Run tests, if applicable (`dart test` in the server package)
- Check `serverpod` MCP `tail_server_logs` and `tail_flutter_logs` for any issues.

## `roundtable_agent_runner` is not covered by hot reload

`serverpod start`'s hot reload/`hot_restart` only affects the server and the
Flutter app. `roundtable_agent_runner` (the daemon installed on a registered
machine) is never run in-process — it's distributed as two **compiled**
binaries (`roundtable_agent_runner.dart` and `permission_prompt_tool.dart`),
served at `/agent-runner-bin` and `/permission-prompt-tool-bin` by
`roundtable_server/lib/src/agent_runner_binaries.dart`.

In development those routes rebuild a binary on request whenever any file
under `roundtable_agent_runner/{bin,lib}`, `roundtable_client/lib`, or the
lockfile is newer than the cached build in
`roundtable_agent_runner/build/<target>/bundle/bin/` — no manual
`rm -rf build` needed.

To ship a runner change to a machine: the Machines screen compares each
machine's reported `runnerVersion` (content hashes of its installed
binaries) with `MachineEndpoint.latestRunnerVersion` and shows an "Update"
button. It sets `updateRequestedAt`; the daemon holds back new work and, at
the first `checkIn` (every 20 s) with no agent busy, writes
`/var/lib/agent-runner/update-requested` (`docs/FLOWS.md` §2), and the root-side
`agent-runner-update.path` systemd unit (installed by
`scripts/install-agent.sh`) re-downloads both binaries and restarts the
service. Machines installed before this existed must re-run the install
script once.

If the user asks you to test the app:

1. Use `get_flutter_app_dtd` (`serverpod` MCP) to get the Flutter app's DTD
2. Pass the DTD to `connect_dart_tooling_daemon` (`dart` MCP) to connect to the app
3. Use `flutter_driver` (`dart` MCP) to navigate through the app

The app is launched from `roundtable_flutter/lib/driver.dart`, which starts the Flutter driver extension with text entry emulation turned off so the app stays usable by hand. To let the driver type, set `enableTextEntryEmulation: true` there and `hot_restart` the app.

Several status dots (`StatusPill` with `pulsing: true`) animate continuously via a looping `AnimationController`. This can make `flutter_driver_command`'s default frame-sync wait never resolve (tap/waitFor time out even though the widget is right there). If a driver command times out on a screen with a pulsing pill, run `set_frame_sync` with `enabled: false` first, then retry.
