# Job-board platforms: how each one is read

Findings from 2026-10-05. Each claim is labeled:

- **verified**: fetched that day and seen to work.
- **documented**: the vendor's own docs describe it; not exercised.
- **reported**: third-party write-ups only. Treat as a lead and verify in the spec.

Robots findings are for the one host named. Robots rules are per host, so check each
tenant before clearing it for publish (ADR 0002).

## Phase 1: documented public feeds, no key

| Platform | Key in registry | How | Notes |
|---|---|---|---|
| Greenhouse | board token | verified: `GET https://boards-api.greenhouse.io/v1/boards/{token}/jobs?content=true` returns `{jobs, meta.total}` | Fields: `id`, `title`, `location.name`, `departments[].name`, `offices[].name`, `updated_at`, `first_published`, `absolute_url`, `content`. No work-mode field: infer from location text. Pay is documented behind `pay_transparency=true` (not exercised). Docs: https://developers.greenhouse.io/job-board.html |
| Lever | company | verified: `GET https://api.lever.co/v0/postings/{company}?mode=json` returns an array | Fields: `id`, `text`, `categories.{location,team,department,commitment,allLocations}`, `workplaceType`, `createdAt` (epoch ms), `descriptionPlain`, `hostedUrl`, `applyUrl`. No updated date. `salaryRange` is documented but was absent in the sample. Hosted pages ask for `Crawl-delay: 1`. Docs: https://github.com/lever/postings-api |
| Ashby | board name | verified: `GET https://api.ashbyhq.com/posting-api/job-board/{board}?includeCompensation=true` returns `{jobs}` | Fields: `id`, `title`, `department`, `team`, `employmentType`, `location`, `isRemote`, `workplaceType`, `publishedAt`, `compensation.compensationTierSummary`, `descriptionPlain`, `jobUrl`, `applyUrl`. `isRemote` can be null. Docs: https://developers.ashbyhq.com/docs/public-job-posting-api |
| Pinpoint | subdomain | verified and documented: `GET https://{sub}.pinpointhq.com/postings.json` returns `{data}` | Fields include `workplace_type`, `compensation_minimum`, `compensation_maximum`, `location.{city,province}`. No published date seen. Docs: https://developers.pinpointhq.com/docs/jobs-json-endpoint |
| Gem | vanity path | verified and documented: `GET https://api.gem.com/job_board/v0/{path}/job_posts/` returns an array | Fields: `id`, `title`, `absolute_url`, `content_plain`, `created_at`, `first_published_at`, `updated_at`, `location.name`, `location_type`. Docs: https://api.gem.com/job_board/v0/reference |
| SmartRecruiters | company id | documented: `GET https://api.smartrecruiters.com/v1/companies/{id}/postings` | Not exercised. |

## Phase 2: plain HTTP, unofficial or HTML

| Platform | Key in registry | How | Notes |
|---|---|---|---|
| Workday | `host/site` | verified: `GET https://{host}/{site}/siteMap.xml` lists every job URL. verified: `GET https://{host}/wday/cxs/{tenant}/{site}/job/{path}` returns JSON `jobPostingInfo` with `id`, `title`, `jobDescription`, `location`, `postedOn` (relative text), `startDate`, `timeType`, `jobReqId`, `externalUrl`. `{tenant}` is the first label of the host. | reported: a list endpoint, `POST https://{host}/wday/cxs/{tenant}/{site}/jobs` with body `{"appliedFacets":{},"limit":20,"offset":0,"searchText":""}`; a limit above 20 is said to return nothing. Robots differ by tenant: Ministry Brands allows its site path, Thrivent disallows `/External/`. |
| Jobvite career sites | host | verified: `GET https://{host}/search/jobs` is plain HTML, 25 per page, links `/jobs/{id}-{slug}`. `/sitemap.xml` lists every job with a last-modified date. | Robots allow all on the two hosts checked. |
| JazzHR | subdomain | verified: `GET https://{sub}.applytojob.com/apply` is plain HTML with titles, locations and links. | Robots allow `/apply` on the host checked. |
| iCIMS | host | verified: `GET https://{host}/jobs/search?ss=1&in_iframe=1` is HTML with titles, ids, locations. Without `in_iframe=1` the page is an empty wrapper. | reported: paging with `pr={page}`. Robots allow search and job pages on the host checked. |
| Rippling | slug | verified: `GET https://ats.rippling.com/api/v2/board/{slug}/jobs?page=0&pageSize=N` returns `{items,totalItems,totalPages}` | List has no description or dates. Detail endpoint unknown. |
| ADP Workforce Now | cid | verified: `GET https://workforcenow.adp.com/mascsr/default/careercenter/public/events/staffing/v1/job-requisitions?cid={cid}&lang=en_US&locale=en_US&$top=20` returns `{jobRequisitions, meta.totalNumber}` | Fields: `itemID`, `requisitionTitle`, `postDate`, `requisitionLocations`, `payGradeRange`. reported: paging with `$skip`, detail at `.../job-requisitions/{itemID}?cid=`. |
| Phenom | host | verified: `GET https://{host}/us/en/sitemap.xml` lists job URLs with last-modified dates; job pages carry the title and location in HTML. | reported: search pages embed the job list as JSON in the page source. |
| Paylocity | guid | documented: `GET https://recruiting.paylocity.com/recruiting/v2/api/feed/jobs/{guid}`. Whether the careers-page guid works as the feed key is not confirmed. | reported: the careers page embeds all jobs as JSON in the page source. Docs: https://recruiting.paylocity.com/Recruiting/v2/api/feed/documentation |
| PageUp, Hirebridge, ApplicantPro | id | reported: server-rendered HTML or a JSON list. | Verify in the spec. |
| Custom HTML | none | verified for the Thrivent careers site: `GET https://careers.thrivent.com/jobs/` is plain HTML, paged, robots allow all. | Each custom site needs its own small parser. Do the valuable ones only. |

## Phase 3: needs a session or a browser

| Platform | Notes |
|---|---|
| Dayforce | reported: a CSRF token call, then a JSON search call with cookies. Reports conflict on whether a plain client is accepted. |
| UKG (UltiPro) | reported: a JSON search call under the board path. Our fetch of its robots file was refused; a third party reports the search path is disallowed. |
| IBM BrassRing | reported: a token from the search page, then a JSON call. Stateful. |
| ADP myjobs | reported: needs a token from a discovery call. |
| Paycom, Infor | Nothing confirmed. Assume a browser. |

## Phase 4: paid data

Not researched yet. This is the route for platforms in phase 3 that we cannot or should
not read ourselves.

## Never collected

LinkedIn, Indeed, Glassdoor. Link out only.
