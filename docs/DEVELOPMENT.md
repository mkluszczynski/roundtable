# Development

Working rules for AI agents (MCP tools, never edit generated code, the
after-change checklist) are in [`/AGENTS.md`](../AGENTS.md). This page is the
human-oriented version plus the context behind those rules.

## Repo layout

```
roundtable/
├── roundtable_server/        Serverpod backend
│   ├── lib/server.dart       boot: auth init, web routes, future-call scheduling
│   ├── lib/src/endpoints/    RPC + stream endpoints
│   ├── lib/src/models/       *.spy.yaml models (source of truth for DB + client)
│   ├── lib/src/future_calls/ machine-offline + stalled-task checks
│   ├── lib/src/generated/    GENERATED, don't edit
│   ├── migrations/           generated migrations (migration.sql may be hand-edited, see AGENTS.md)
│   ├── config/               development/test/staging/production yaml, passwords.yaml (gitignored)
│   └── test/{integration,unit}/  endpoint + future-call tests (withServerpod), GitHub client
├── roundtable_client/        GENERATED client, don't edit
├── roundtable_flutter/       panel; lib/{screens,widgets,blocs,cubits,repositories,theme,utils}
│   └── test/widgets/         widget tests for shared components
├── roundtable_agent_runner/  daemon; bin/ (2 entrypoints), lib/src/, test/
├── roundtable_e2e/           E2E tests: fake GitHub, fake claude, harness
├── scripts/                  install-agent.sh / uninstall-agent.sh (+ README)
├── docs/                     you are here
└── docker-compose.yml        server + Postgres for a packaged run
```

## Running locally

- Run `serverpod start` from the repo root. It starts Postgres, the server,
  and the Flutter app (`flutter_apps.roundtable` in the server
  `pubspec.yaml`, `auto_launch: true`). It watches files, regenerates code
  incrementally, and hot-reloads both the server and the app.
- The app's entrypoint for development is `roundtable_flutter/lib/driver.dart`
  (it enables the Flutter driver extension).
- Packaged run: `docker compose up --build` (see the header comment in
  `docker-compose.yml`. You need a `.env` with `ROUNDTABLE_DB_PASSWORD`
  matching `config/passwords.yaml`). The Dockerfile bakes the runner
  binaries and install scripts into `web/static/`.

### Running an agent machine during development

- Real install: use Add machine in the panel and run the shown command on
  a Linux/systemd host. That host must be able to reach the server's public
  URL.
- From a checkout, without systemd:
  `AGENT_RUNNER_CONFIG_PATH=/path/to/config.env dart run bin/roundtable_agent_runner.dart`
  in `roundtable_agent_runner/`. In this mode the permission tool runs from
  source with the same Dart SDK, and self-update is off.
- The runner is **not** hot-reloaded. Ship changes through the Update button
  (FLOWS §2). In dev, the binary routes rebuild automatically when the
  runner/client sources or the lockfile change.

## Changing things

| You change… | Then… |
|---|---|
| a `.spy.yaml` model with a table | `create_migration` + `apply_migrations` (serverpod MCP, or the CLI if the server can't start) |
| an endpoint signature | code generation runs automatically. Fix the call sites in the panel **and** the runner |
| Flutter code that hot reload can't apply | `hot_restart` |
| runner code | rebuild/update the machine (above); `dart test` in `roundtable_agent_runner/` |

Checklist after changes: `dart analyze` → `dart format` → migrations if needed
→ hot restart if needed → tests → check server/Flutter logs.

## Tests

| Package | Command | What's covered |
|---|---|---|
| `roundtable_server` | `dart test` (embedded Postgres via `config/test.yaml`, no Docker) | all endpoints, both future calls, merge conflicts (`test/integration/`) |
| `roundtable_agent_runner` | `dart test` | dispatcher, review dispatcher, executor (fake `claude`), permission tool, worktrees (real git), PR opener, stream formatter, runner update |
| `roundtable_flutter` | `flutter test` | shared widgets (`test/widgets/`), utils, kanban grouping |
| `roundtable_e2e` | `dart test` | E2E: the real server and runner against a fake GitHub (see below) |

### E2E tests

`roundtable_e2e/` runs whole user flows offline, with no tokens:
- **Fake GitHub** (`lib/src/fake_github.dart`): a GitHub Enterprise-style
  host on localhost — real bare git repos served through `git
  http-backend` (clone/push), and the REST/GraphQL calls Roundtable makes
  (PRs, files with real `git diff`, reviews and threads, squash merge, no
  Actions runs). The server finds it through `ROUNDTABLE_GITHUB_URL`; the
  runner derives the API from the clone URL.
- **Fake claude** (`bin/fake_claude.dart`): plays the agents from a
  scenario (plan, per-run file edits, review verdicts). In plan mode it
  talks MCP to the real permission prompt tool, so plan approval goes
  through the server like with the real CLI. Every call is logged for
  assertions (`E2EHarness.claudeRuns`).
- **Harness** (`lib/src/harness.dart`): compiles the runner, its
  permission prompt tool and the fake claude; starts the real server
  (`--mode test`, a fresh embedded Postgres in a temp dir, ports and
  passwords from `SERVERPOD_*` env vars — no `passwords.yaml` needed) and
  the runner as processes; tests drive it through the generated client.

`E2E_VERBOSE=1` echoes the server's and runner's output; `E2E_KEEP=1`
keeps the temp dir (repos, worktrees, fake claude log) for a look after a
failure. A run takes ~20 s per test.

## Conventions

- **State:** use a Cubit by default. Use a Bloc only when there are several
  event sources (`TaskDetailBloc` is the only one). Widgets never call
  `client` directly; they go through `repositories/`.
- **Dependency injection in the runner:** dispatchers take plain functions,
  not the generated `Client`, so they can be unit-tested.
- **Server-only helpers** go in `lib/src/*.dart` outside `endpoints/`, so they
  aren't exposed as RPC methods.
- **Secrets** go in model fields marked `scope=serverOnly`. Never log clone
  URLs.
- **UI:** dark-only tokens from `lib/theme/`. Pill selectors instead of
  dropdowns for small option sets. See [UI-DESIGN.md](UI-DESIGN.md).
- **Statuses in the UI** go through `utils/task_status_label.dart`, never
  `.name`.
- **Server errors:** throw `NotFoundException` / `InvalidStateException` /
  `GitHubException` (or another model-declared exception), never a bare
  `Exception`, because Serverpod hides those from the client. In the panel,
  show errors with `utils/error_message.dart`.
- **Streams in Blocs/Cubits:** wrap them in `untilClosed(...)`
  (`CloseableStreams` mixin) so they're cancelled on `close()`.
- **Generated client looks broken** (missing endpoints right after editing an
  endpoint file)? The incremental generator sometimes runs on a half-written
  file. Run `serverpod generate` in `roundtable_server/` once.

## Testing the running app with Flutter driver

`get_flutter_app_dtd` (serverpod MCP) → `connect_dart_tooling_daemon`
(dart MCP) → `flutter_driver`. To type text, set
`enableTextEntryEmulation: true` in `driver.dart` and hot-restart. Pulsing
status pills can keep frame sync from settling. If driver commands time out,
run `set_frame_sync(enabled: false)`.
