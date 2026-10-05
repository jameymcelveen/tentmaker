# 001a: Deploy pipeline

Status: draft
Branch: `slice/001a-deploy`

## Gate

1. `git remote -v` shows `github.com:jameymcelveen/tentmaker`. Stop if not.
2. Read `AGENTS.md`.
3. Spec 001 is merged and `docker compose up` works locally.

## Goal

Merging to `main` deploys the API and worker to Railway and the web shell to Vercel, behind
`tentmakerjobs.com`, with every setup step in a script the owner can run from a terminal.
This is a walking skeleton: it proves the path end to end before there is much to ship.

## Who runs what

**The agent writes the scripts and workflows and runs them only with `--dry-run`.** The
agent does not run anything that creates a cloud resource, sets a secret, changes repo
settings or spends money. The owner runs those, in the order `docs/deploy.md` gives.

## Topology

| Piece | Host | Address |
|---|---|---|
| Web (static React build from `web/`) | Vercel | `tentmakerjobs.com`, `www.tentmakerjobs.com` |
| API (`Tentmaker.Api` container) | Railway | `api.tentmakerjobs.com` |
| Worker (`Tentmaker.Worker` container) | Railway | none |
| PostgreSQL | Railway | private |
| DNS | Cloudflare | zone `tentmakerjobs.com` |
| CI and deploys | GitHub Actions | |

## Decisions already made

- **GitHub Actions drives the deploys**, not the platforms' own Git integrations. One
  workflow: the `ci` job runs on every push and pull request; deploy jobs run only on a
  push to `main` and `need` the `ci` job. No GitHub apps to install, and the order is ours.
- **The cloud runs in Publish mode.** `Mode=Publish` on both Railway services. In Publish
  mode the worker collects only sources marked `publish: cleared`. None are cleared today,
  so the public site starts as the employer directory with links. Personal mode stays local.
- **No `railway.json` or `railway.toml`.** Railway has deprecated config-as-code files
  (new services cannot opt in; hard cutoff 2026-12-01). Tell each service which Dockerfile
  to build with the service variable `RAILWAY_DOCKERFILE_PATH`.
- **Cloudflare is DNS, called through its HTTP API with curl.** `wrangler` has no DNS
  commands. Do not add Terraform.
- **Secrets live in GitHub Actions secrets and Railway variables.** Never in the repo,
  never echoed in logs.

## In scope

- `web/`: a minimal Vite, React and TypeScript shell. It shows the name, one line of
  text, and the result of calling `${VITE_API_BASE}/health`. The real UI is slice 004.
- API: CORS for the configured web origins. Accept the database connection from
  `DATABASE_URL` in Railway's URL form as well as a standard connection string. Apply
  migrations on start when `Database__MigrateOnStart=true`.
- Dockerfiles for the API and the worker that build from the repo root (confirm the ones
  from spec 001 do; fix if not).
- `.github/workflows/ci.yml` becomes the one workflow: job `ci` (the job name must be
  exactly `ci`, because branch protection matches on job name), then `deploy-api`,
  `deploy-worker`, `deploy-web`.
- `scripts/cloud-setup.sh`, `scripts/dns-setup.sh`, `scripts/github-setup.sh`: each is
  safe to run twice, supports `--dry-run` (prints every command, runs none), and stops
  with a clear message if a login or token it needs is missing.
- `docs/deploy.md`: the runbook. Browser steps first, then the scripts in order, then how
  to roll back and how to tear everything down.
- `scripts/doctor.sh` already exists. Extend it only if a new requirement appears.

## Out of scope

- Staging or preview environments. Terraform. Clearing any source for publish. Accounts.

## Steps only the owner can do, in a browser

`docs/deploy.md` must list these with their URLs, before the scripts:

1. Buy `tentmakerjobs.com` at Cloudflare.
2. Cloudflare: create one API token from the "Edit zone DNS" template, limited to that zone.
3. Railway: `railway login` (finishes in a browser), and move to the Hobby plan.
4. Railway: after the project exists, create a project token (project settings, Tokens).
5. Vercel: create one access token at `https://vercel.com/account/tokens`.

## Command reference

Checked against vendor docs on 2026-10-05. None of these were executed. Lines marked
**assembled** combine documented pieces that the docs do not show together: test them in
`--dry-run` review and say so in the PR if one needs changing.

Railway (`scripts/cloud-setup.sh`):

```
railway init --name tentmaker --json
railway add --database postgres
railway add --service api
railway add --service worker
railway variable set RAILWAY_DOCKERFILE_PATH=/src/Tentmaker.Api/Dockerfile Mode=Publish Database__MigrateOnStart=true --service api
railway variable set RAILWAY_DOCKERFILE_PATH=/src/Tentmaker.Worker/Dockerfile Mode=Publish --service worker
railway variable set 'DATABASE_URL=${{Postgres.DATABASE_URL}}' --service api        # assembled
railway variable set 'DATABASE_URL=${{Postgres.DATABASE_URL}}' --service worker     # assembled
railway domain api.tentmakerjobs.com --service api --port 8080
```

`railway domain` prints a CNAME and a TXT record. Both are required.

Vercel (`scripts/cloud-setup.sh`), run in `web/`:

```
vercel link --yes --project tentmaker
vercel project update tentmaker --framework vite --output-directory dist
vercel api /v9/projects/tentmaker -X PATCH -F rootDirectory=web                     # assembled
echo "https://api.tentmakerjobs.com" | vercel env add VITE_API_BASE production
vercel domains add tentmakerjobs.com tentmaker
vercel domains add www.tentmakerjobs.com tentmaker
vercel domains inspect tentmakerjobs.com
```

`vercel link` writes `.vercel/project.json`, which holds the org id and project id. That
folder stays gitignored.

Cloudflare (`scripts/dns-setup.sh`), with `CLOUDFLARE_API_TOKEN` in the environment:

```
curl -s "https://api.cloudflare.com/client/v4/zones?name=tentmakerjobs.com" -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" --request POST -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" --json '{"type":"CNAME","name":"www","content":"<value from vercel domains inspect>","ttl":1,"proxied":false}'
```

- Vercel records (apex A record and `www` CNAME): use the exact values
  `vercel domains inspect` prints, and set them **DNS only** (`"proxied": false`). Vercel
  advises against a proxy in front of it.
- Railway records (the `api` CNAME and its TXT): Railway's Cloudflare guidance says to
  proxy the CNAME and set the zone's SSL mode to Full, not Full (strict). Follow that, and
  record in `docs/deploy.md` what actually worked.

GitHub (`scripts/github-setup.sh`), run last, after the `ci` job has run once on `main`:

```
gh secret set RAILWAY_TOKEN --body "$RAILWAY_TOKEN"
gh secret set VERCEL_TOKEN --body "$VERCEL_TOKEN"
gh secret set VERCEL_ORG_ID --body "$(jq -r .orgId web/.vercel/project.json)"
gh secret set VERCEL_PROJECT_ID --body "$(jq -r .projectId web/.vercel/project.json)"
gh repo edit jameymcelveen/tentmaker --delete-branch-on-merge --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false
gh api -X PUT repos/jameymcelveen/tentmaker/branches/main/protection --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["ci"] },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null
}
JSON
```

The repo is public, so branch protection is available on a free account.

Deploy jobs in the workflow:

```
# deploy-api and deploy-worker, with RAILWAY_TOKEN in env
railway up --ci --service api
railway up --ci --service worker

# deploy-web, in web/, with VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID in env
vercel pull --yes --environment=production --token="$VERCEL_TOKEN"
vercel build --prod --token="$VERCEL_TOKEN"
vercel deploy --prebuilt --prod --token="$VERCEL_TOKEN"
```

## Acceptance

- [ ] Each script runs clean with `--dry-run` on a machine with no cloud logins and prints
      every command it would run.
- [ ] Running a script twice does not create a second project, service, record or secret.
- [ ] No secret value appears in the repo, in script output or in workflow logs.
- [ ] A pull request runs `ci` only. A merge to `main` runs `ci`, then the three deploys.
- [ ] `https://api.tentmakerjobs.com/health` returns 200 and
      `GET /api/sources` returns the registry.
- [ ] `https://tentmakerjobs.com` loads and shows the API as healthy.
- [ ] The cloud API reports `Mode=Publish`, and a test proves the worker skips a source
      that is not cleared when in Publish mode.
- [ ] A direct push to `main` is rejected after `scripts/github-setup.sh` has run.
- [ ] `docs/deploy.md` lets someone who has never seen the project repeat the whole setup.

## Verify by running

```
bash scripts/cloud-setup.sh --dry-run
bash scripts/dns-setup.sh --dry-run
bash scripts/github-setup.sh --dry-run
curl -s https://api.tentmakerjobs.com/health
```
