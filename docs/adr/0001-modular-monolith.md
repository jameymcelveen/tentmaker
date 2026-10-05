# 0001: A modular monolith with a separate worker, not microservices

Status: accepted, 2026-10-05

## Context

Tentmaker reads about a hundred careers portals once a day and serves a filtered list. The
pieces that fetch an RSS feed, a JSON API and an HTML page all have the same runtime, the
same schedule and the same failure mode. Splitting them into services would add network
hops, deployment units and failure cases with nothing gained.

## Decision

One solution, clear module boundaries, and separate processes only where the runtime
really differs:

- `Tentmaker.Api` serves HTTP.
- `Tentmaker.Worker` runs the schedule and is the only process that calls other sites.
- A browser collector, if it is ever needed, runs in its own container because it carries
  a browser and has a different resource profile.
- PostgreSQL.

Each job-board platform is an adapter behind one interface, `ISourceAdapter`, inside
`Tentmaker.Collectors`. Adding a platform adds a class and fixtures, not a service.

## Consequences

- One `docker compose up` runs everything.
- Module boundaries are enforced by project references: `Domain` depends on nothing,
  `Collectors` does not reference `Data` or `Api`.
- If one part ever needs to scale or deploy on its own, the worker boundary is the seam.
  That would be a new ADR.
