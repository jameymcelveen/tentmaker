# Tentmaker

Tech jobs at Christian and church-serving employers, read straight from each employer's
own careers portal.

Paul made tents. Tentmaker is for people who practice a technical trade and want to do it
somewhere the mission matters.

## Status

Scaffold only. No application code yet. The plan is in [docs/PLAN.md](docs/PLAN.md) and
the first slice is [docs/specs/001-skeleton.md](docs/specs/001-skeleton.md).

## What it will do

- Collect postings on a schedule from the source registry in
  [sources/sources.yml](sources/sources.yml), one adapter per job-board platform.
- Track every posting over time: first seen, last seen, closed, reopened.
- Filter by work mode, employer type, stack and more, with each active filter shown as a
  removable pill.
- Link out for anything it does not collect.

## How it is built

- Rules for people and coding agents: [AGENTS.md](AGENTS.md)
- Architecture decisions: [docs/adr/](docs/adr/)
- How each job-board platform is read, and what was verified: [docs/platforms.md](docs/platforms.md)

## Ground rules

Tentmaker reads public pages only, at a polite pace, and identifies itself. The public
build serves facts and a link back to the employer, and only for sources that have been
cleared for it. See [ADR 0002](docs/adr/0002-collect-broadly-publish-gated.md).

Tentmaker is not affiliated with any employer or job board it links to.
