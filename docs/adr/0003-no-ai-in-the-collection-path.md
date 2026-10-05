# 0003: No AI in the collection path by default

Status: accepted, 2026-10-05

## Context

A model can read almost any page and return structured fields, which is tempting for the
platforms that have no clean feed. It also makes every run cost money, makes results vary
from run to run, and cannot be tested offline.

## Decision

Collection is plain code: HTTP, JSON, HTML parsing. It runs with no AI key present.

Where a platform is not yet understood, a spec may allow a temporary extractor behind
`IExtractor`: one call, a page in, fixed fields out, no tools and no browsing. Its outputs
are recorded as fixtures, and it is replaced by a plain adapter once the pattern is clear.
It is off unless a key is configured, and it never runs in tests or CI.

A model that drives a browser on its own is not used for collection.

AI is welcome outside the collection path, on demand: for example writing a company
profile from facts already collected, with every claim tied to a source.

## Consequences

- A run costs nothing but bandwidth and is repeatable.
- Using a model does not change what we are allowed to read. The limits in ADR 0002 apply
  to an extractor exactly as they apply to an adapter.
