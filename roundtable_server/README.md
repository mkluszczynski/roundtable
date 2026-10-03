# roundtable_server

Serverpod backend for Roundtable: endpoints (`lib/src/endpoints/`), models
(`lib/src/models/*.spy.yaml`), migrations, background future calls, and web
routes serving the machine install scripts and agent-runner binaries.

- Run everything from the repo root with `serverpod start`.
- Tests: `dart test` (uses an embedded Postgres via `config/test.yaml`, no
  Docker needed).
- Packaged run: `docker compose up --build` from the repo root.

See `docs/` at the repo root, starting with `docs/README.md`.
