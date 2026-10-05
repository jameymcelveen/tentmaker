# 0002: Collect broadly for personal use, publish through a per-source gate

Status: accepted, 2026-10-05

## Context

The first job of Tentmaker is to help its owner find work, running on his own machine. The
second is to become a free public tool. Those two have different obligations. Reading a
public careers page once a day for yourself is one thing. Republishing what you read is
another, and each site's robots file and terms speak to it differently.

## Decision

Two modes, one codebase.

**Personal mode** collects from every source whose platform has an adapter, including
sources whose robots file or terms have not been reviewed. It stores the description text
so postings can be filtered and read locally.

**Publish mode** serves only sources marked `publish: cleared` in the registry, and only
facts (title, employer, location, work mode, pay as posted, dates, link). It never serves
description text. `cleared` means the owner has read that host's robots file and terms and
decided it is fine. The default is `unverified`. A third value, `blocked`, records a no.

Three limits apply in both modes, because they protect the owner and the sites:

- No logins and no paywalled content.
- No defeating bot protection: no CAPTCHA solving, proxy rotation or fingerprint spoofing.
  If a site blocks us, it becomes link-only.
- LinkedIn, Indeed and Glassdoor are never collected. They are linked to.

## Consequences

- The publish gate is enforced in one place in the API and covered by tests.
- The registry is the audit trail: every source carries its robots finding and its publish
  status.
- Robots rules are per host, not per platform. Two tenants of the same platform can
  differ, so clearing one does not clear the other.
