# Tentmaker plan

Written 2026-10-05. The order is set by one question: what gets useful postings in front
of a job seeker soonest.

## Before slice 001: machine prerequisites

Found on the owner's Mac on 2026-10-05:

| Tool | Found | Needed |
|---|---|---|
| .NET SDK | 10.0.100-rc.1 (plus 7, 8, 9) | .NET 10 release SDK. The release candidate is not the LTS build. |
| Node | 19.1.0 | A current LTS release. 19 is an old odd-numbered line and current Vite will not support it. |
| Docker | 20.10.7 | A current Docker Desktop with `docker compose` (v2). |
| Docker Compose | v2.0.0-beta.6 | A release build. Comes with the Docker Desktop update. |
| Agents | `claude`, `cursor`, `rider` all on PATH | Nothing to do. |
| `gh` | 2.89.0, logged in | Nothing to do. |
| `vercel` | 59.16.0, logged in | Nothing to do. |
| `railway` | installed, not logged in | `railway login` before spec 001a. |
| `wrangler` | will not start on Node 19 | Not needed. DNS goes through the Cloudflare API. |

`bash scripts/doctor.sh` re-checks all of this and changes nothing.

One manual step: the Claude Code project files (shared permissions, the `reviewer`
subagent, the `/add-source` skill) are staged in `setup/claude/`. Read them, then put
them in place yourself:

```
mkdir -p .claude && cp -R setup/claude/. .claude/ && git rm -r --cached -q setup 2>/dev/null; rm -rf setup
```

## Slices

Each slice has a spec in `docs/specs/`, is built on its own branch, and ends in a pull
request the owner merges. Specs 001, 001a, 002 and 003 are written. The rest get written when their
turn comes, with what the earlier slices taught us.

| # | Slice | What you can do when it lands |
|---|---|---|
| 001 | Skeleton | `docker compose up` starts the API, worker and database. The registry loads and validates. CI is green. |
| 001a | Deploy pipeline | A merge to `main` deploys the API and worker to Railway and the web shell to Vercel, behind `tentmakerjobs.com`. The cloud runs in Publish mode. Setup is scripted. |
| 002 | Phase 1 adapters | Greenhouse, Lever, Ashby, Pinpoint and Gem are collected daily. A "new since yesterday" report exists. Ten employers. |
| 003 | Workday | The largest single platform in the registry, about twenty employers, including most of the .NET shops. |
| 004 | List and filters | A web page: every posting, filter pills with an x, filter state in the URL, a "new" view, and the full employer directory with links for sources we do not collect. |
| 005 | Plain HTTP adapters | Jobvite, JazzHR, iCIMS, Rippling, ADP Workforce Now, Phenom, Paylocity, and the Thrivent careers site. |
| 006 | Session and browser collectors | Dayforce, UKG, BrassRing and the rest of phase 3, one at a time, only where the employer is worth it. |
| 007 | Company profiles | A page per employer: facts we hold, each with its source and date, plus a "look them up" row of outbound links (Glassdoor, LinkedIn, Best Christian Workplaces, the 990). |
| 008 | Views | Three charts that answer a question: a flow chart (all postings, then work mode, then stack, then pay) whose bands set the filters; a map with a radius around home; and req age, one bar per posting showing how long it has been open. |
| 009 | Publish | The publish gate proven by tests, per-host robots and terms review, a not-affiliated note, an employer opt-out, hosting. |

## Data model in one paragraph

A **source** is one employer's portal, defined in `sources/sources.yml`. A **job** is one
posting, identified by source and the platform's own id. Every run records what it saw, so
each job carries first seen, last seen, closed and reopened. That history is what makes
req age possible and it starts accumulating in slice 002, so the charts in slice 008 have
weeks of data by the time they are built.

## What was verified on 2026-10-05

- About a hundred employers and their real portals: `sources/sources.yml`.
- How each platform can be read, and what is only reported: `docs/platforms.md`.
- The name: "tentmaker" is a common word in missions and several organizations use it.
  No job board by that name turned up in a quick search. Domain and trademark were not
  checked. Do that before anything public carries the name.

## Open questions for the owner

- Paid data (phase 4): is there a monthly amount worth spending to cover the hard platforms?
- Hosting for the public build.
- Whether the public build needs accounts at all, or saved filters in the URL are enough.
