---
name: add-source
description: Add an employer to sources/sources.yml, or move one to a platform that already has an adapter. Use when asked to add, fix or re-point a source.
---

# Add a source

A source is one employer's careers portal. Adding one is a data change, not a code change,
as long as its platform already has an adapter.

1. **Find the real portal.** Start from the employer's own site, not an aggregator. Follow
   the careers link to the job board and note the host.
2. **Identify the platform** from the host and URL shape. `docs/platforms.md` lists the
   shapes and what the `key` is for each platform.
3. **Read the host's robots.txt** and note what it says about job listing and job detail
   paths. Record it on the entry as `robots:` with one of allowed, partial, disallowed,
   none, unknown.
4. **Add the entry** to `sources/sources.yml` in the right section, one line, same field
   order as its neighbors. Do not set `publish`. Only the owner sets that.
5. **If the platform has an adapter:** record a fixture for this source under
   `tests/fixtures/<platform>/`, run the conformance tests, and run one collection for the
   new source in personal mode. Report how many jobs came back.
6. **If the platform has no adapter:** set nothing else. Stop and tell the owner a spec is
   needed for that platform. Do not write the adapter.
7. Run `python3 scripts/check_ascii.py`.

Never add LinkedIn, Indeed or Glassdoor as a source. Never add a source that needs a login.
