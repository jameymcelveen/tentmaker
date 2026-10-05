# 002: Phase 1 adapters

Status: draft
Branch: `slice/002-phase1-adapters`

## Gate

1. `git remote -v` shows `github.com:jameymcelveen/tentmaker`. Stop if not.
2. Read `AGENTS.md` and the Phase 1 table in `docs/platforms.md`.
3. Spec 001 is merged.

## Goal

The five platforms with documented public feeds are collected once a day, and one command
prints what is new since yesterday.

## In scope

- `ISourceAdapter` in `Tentmaker.Collectors`: given a source, yield raw postings. One
  implementation each for Greenhouse, Lever, Ashby, Pinpoint and Gem.
- A normalizer per platform that maps a raw posting to the `Job` fields. Mapping tables
  are in `docs/platforms.md`. Where a platform has no work-mode field (Greenhouse), infer
  Remote only when the location text contains the word "remote"; otherwise Unknown. Never
  guess Onsite.
- A shared polite HTTP client: named User-Agent, one second minimum between requests to a
  host, three retries with backoff on 5xx and timeouts, no retry on 4xx, stop the source
  on 403 or 429.
- The diff: for each source after a **successful** fetch, insert new jobs, update changed
  ones (by content hash), set last seen, close jobs not seen, reopen jobs seen again. A
  failed or empty-because-of-error fetch changes nothing.
- The scheduler in `Tentmaker.Worker`: each source once a day, spread across the hour, one
  run at a time per source, each run recorded in `collection_runs`.
- `GET /api/jobs` with filters: `workMode`, `kind`, `platform`, `source`, `q`, `since`,
  `open`. `GET /api/jobs/new?since=`.
- A report command: `dotnet run --project src/Tentmaker.Worker -- report --since 1d`
  prints new postings as plain text, grouped by employer.
- Fixtures: one recorded response per platform under `tests/fixtures/<platform>/`, plus a
  recorded empty board and a malformed response for each.
- A conformance suite every adapter must pass: stable ids, no duplicate ids in one run,
  non-empty title and url, dates parse or are null, an empty board yields zero jobs
  without error.

## Out of scope

- Workday and every other platform. The web front end. Pay parsing beyond storing what
  the platform gives as structured fields and the raw text.

## Design notes

- Sources covered when this lands: pushpay, planning-center, subsplash, aplos-velora,
  alliance-defending-freedom (Greenhouse); life-church (Lever); virtuous, overflow
  (Ashby); tithely (Pinpoint); hallow (Gem).
- Greenhouse `content` is HTML that arrives escaped. Unescape, then strip tags for the
  stored text. Never render it as HTML.
- Lever has no updated date and Ashby has only a published date. Do not invent one: the
  content hash and our own first seen and last seen carry change over time.
- Record fixtures with a small script, once, by hand. Tests never call the network.

## Acceptance

- [ ] Each adapter passes the conformance suite against its fixtures.
- [ ] A run against the ten sources above stores jobs and a `collection_runs` row each.
- [ ] Running twice in a row adds no jobs and closes none.
- [ ] A fixture with one job removed closes exactly that job; adding it back reopens it
      and increments the reopen count.
- [ ] A 500 from a source closes nothing.
- [ ] The report command lists a job inserted by a test with a first-seen time inside the
      window, and omits one outside it.
- [ ] No test opens a socket (a test asserts the HTTP handler is the stub).

## Verify by running

```
docker compose up --build -d
docker compose exec worker dotnet Tentmaker.Worker.dll collect --source virtuous
curl -s "localhost:8080/api/jobs?source=virtuous" | head -c 600
docker compose exec worker dotnet Tentmaker.Worker.dll report --since 1d
```
