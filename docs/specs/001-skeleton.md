# 001: Skeleton

Status: draft
Branch: `slice/001-skeleton`

## Gate

1. `git remote -v` shows `github.com:jameymcelveen/tentmaker`. Stop if not.
2. Read `AGENTS.md`.
3. Confirm the prerequisites in `docs/PLAN.md` are installed: `dotnet --version` reports a
   10.0 release (not a release candidate), `node --version` reports a current LTS,
   `docker compose version` works. If any is missing, stop and say which.

## Goal

`docker compose up` starts an API, a worker and a database that do nothing useful yet but
are wired correctly, and CI proves it on every push.

## In scope

- Solution `Tentmaker.sln` with the projects listed in `AGENTS.md`. `global.json` pins the
  SDK. `Directory.Build.props` turns on nullable, implicit usings and warnings as errors.
- `Tentmaker.Domain`: `Source`, `Job`, `CollectionRun`, and the `WorkMode` enum
  (Remote, Hybrid, Onsite, Unknown).
- `Tentmaker.Data`: EF Core context for PostgreSQL and the first migration.
  - `jobs`: source id, external id (unique together), title, location text, work mode,
    department, url, pay min, pay max, pay currency, pay period, pay text, posted at
    (nullable), first seen, last seen, closed at (nullable), reopen count, content hash,
    description text.
  - `collection_runs`: source id, started, finished, status, counts (seen, new, changed,
    closed), error text.
- Registry loader: reads `sources/sources.yml` at startup, validates it (unique ids, known
  platform, known kind, key present where the platform needs one) and fails fast with a
  message that names the bad entry.
- `Tentmaker.Api`: `GET /health`, `GET /api/sources` (the registry, with phase and whether
  an adapter exists). A `Mode` setting, `Personal` or `Publish`, default `Personal`.
- `Tentmaker.Worker`: starts, logs the sources it would collect, and exits its loop
  cleanly on shutdown. No collection yet.
- `docker-compose.yml`: `db`, `api`, `worker`. Migrations apply on API start in
  development.
- `.github/workflows/ci.yml`: restore, build, test, `dotnet format --verify-no-changes`,
  `python3 scripts/check_ascii.py`.
- README quick start.

## Out of scope

- Any adapter, any network call to a job board, the web front end, authentication.

## Design notes

- `Collectors` must not reference `Data` or `Api`. Add an architecture test that fails if
  it does.
- The registry is data. Do not copy its entries into code or seed them into a migration.
  Sync sources into the database at startup, keyed by id.
- Use `TimeProvider` for every clock read so tests can control time.
- YAML parsing: YamlDotNet is approved for this slice.

## Acceptance

- [ ] `docker compose up` brings all three services to healthy from a clean clone.
- [ ] `GET /health` returns 200. `GET /api/sources` returns every registry entry.
- [ ] A registry with a duplicate id or an unknown platform stops startup with a clear error.
      A test covers each.
- [ ] The architecture test fails if `Collectors` references `Data`.
- [ ] CI passes on the pull request.
- [ ] `python3 scripts/check_ascii.py` passes.

## Verify by running

```
docker compose up --build -d
curl -s localhost:8080/health
curl -s localhost:8080/api/sources | head -c 400
dotnet test
```
