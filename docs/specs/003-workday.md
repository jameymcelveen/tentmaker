# 003: Workday adapter

Status: draft
Branch: `slice/003-workday`

## Gate

1. `git remote -v` shows `github.com:jameymcelveen/tentmaker`. Stop if not.
2. Read `AGENTS.md` and the Workday row in `docs/platforms.md`.
3. Spec 002 is merged.

## Goal

Every Workday source in the registry is collected daily. This is the largest platform in
the registry and holds most of the .NET shops.

## In scope

- `WorkdayAdapter` using the two calls that were verified on 2026-10-05:
  1. `GET https://{host}/{site}/siteMap.xml` for the list of job URLs.
  2. `GET https://{host}/wday/cxs/{tenant}/{site}/job/{path}` for each job's JSON.
  `{tenant}` is the first label of `{host}`. The registry key is `host/site`.
- Fetch detail only for URLs not seen before or not refreshed in the last seven days. A
  job is open while its URL is in the sitemap.
- Normalizer: title, location, `timeType`, `jobReqId` as the external id, `externalUrl`,
  description. `postedOn` is relative text such as "Posted 4 Days Ago": store it as raw
  text and do not convert it to a date. Our first seen is the date we trust.
- Work mode: Remote when the location text or a remote-type field says remote, otherwise
  Unknown.
- Fixtures for one small tenant: sitemap, three job details, one job that has left the
  sitemap.

## Out of scope

- The Thrivent Workday site. Its robots file disallows `/External/`; Thrivent is read from
  its own careers site in spec 005.
- The search-results POST endpoint, unless the investigation below clears it.

## Design notes

- **Investigate first, then decide, and write down what you find in `docs/platforms.md`:**
  a list endpoint is reported, `POST https://{host}/wday/cxs/{tenant}/{site}/jobs` with
  body `{"appliedFacets":{},"limit":20,"offset":0,"searchText":""}`, page size capped at
  20. If it works for our tenants it replaces one detail call per job with one list call
  per twenty jobs. Try it against one tenant by hand. If it works, propose using it for
  the list and keep the sitemap as the fallback. Ask the owner before switching.
- Tenants vary. Some sitemaps are large. Cap a single run at 500 detail calls per source
  and carry the rest to the next day; log when the cap is hit.
- Robots differ per tenant. Record each tenant's finding on its registry entry as you
  touch it. That feeds the publish gate later; it does not stop personal collection.

## Acceptance

- [ ] The adapter passes the conformance suite against its fixtures.
- [ ] A job that leaves the sitemap is closed on the next successful run.
- [ ] A second run the same day makes no detail calls for jobs already stored.
- [ ] The 500-call cap is honored and logged (test with a fixture sitemap of 600 URLs).
- [ ] `docs/platforms.md` records what the list-endpoint investigation found.
- [ ] A run against `ministry-brands` stores jobs. Report the count in the PR.

## Verify by running

```
docker compose exec worker dotnet Tentmaker.Worker.dll collect --source ministry-brands
curl -s "localhost:8080/api/jobs?source=ministry-brands&open=true" | head -c 600
```
