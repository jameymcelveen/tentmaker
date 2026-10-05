#!/usr/bin/env bash
# Read-only check of this machine. It changes nothing. Run from the repo root:
#   bash scripts/doctor.sh
set -u

n_ok=0; n_warn=0; n_fail=0
ok()   { printf '  ok    %s\n' "$1"; n_ok=$((n_ok + 1)); }
warn() { printf '  warn  %s\n' "$1"; n_warn=$((n_warn + 1)); }
bad()  { printf '  FAIL  %s\n' "$1"; n_fail=$((n_fail + 1)); }
have() { command -v "$1" >/dev/null 2>&1; }
# Run a command with a time limit (macOS has no `timeout`).
limit() { perl -e 'alarm shift; exec @ARGV' "$@" </dev/null 2>&1; }
major() { printf '%s' "$1" | sed -E 's/^v//; s/\..*$//'; }

echo "Repo"
remote="$(git remote get-url origin 2>/dev/null || true)"
case "$remote" in
  *jameymcelveen/tentmaker*) ok "origin is $remote" ;;
  *) bad "origin is '$remote', expected github.com:jameymcelveen/tentmaker" ;;
esac

echo "Run locally"
if have dotnet; then
  v="$(dotnet --version 2>/dev/null)"
  if [ "$(major "$v")" -ge 10 ] 2>/dev/null; then
    case "$v" in
      *-*) bad ".NET SDK $v is a preview or release candidate; install the .NET 10 release SDK" ;;
      *)   ok ".NET SDK $v" ;;
    esac
  else
    bad ".NET SDK $v; need 10.0 or later"
  fi
else
  bad "dotnet not found"
fi

if have node; then
  v="$(node --version 2>/dev/null)"
  if [ "$(major "$v")" -ge 22 ] 2>/dev/null; then ok "Node $v"; else bad "Node $v; need a current LTS (22 or later)"; fi
else
  bad "node not found"
fi

if have docker; then
  v="$(docker compose version --short 2>/dev/null || true)"
  case "$v" in
    "")      bad "docker compose (v2) not available" ;;
    *beta*|*rc*) bad "docker compose $v is a pre-release; update Docker Desktop" ;;
    *)       ok "docker compose $v" ;;
  esac
  if limit 10 docker info >/dev/null; then ok "Docker is running"; else warn "Docker is installed but not running"; fi
else
  bad "docker not found"
fi

if have python3; then ok "$(python3 --version 2>&1)"; else bad "python3 not found (the ASCII gate needs it)"; fi

echo "Coding agents"
for tool in claude cursor rider; do
  if have "$tool"; then ok "$tool on PATH"; else warn "$tool not on PATH"; fi
done

echo "Cloud command lines (needed for spec 001a, not for running locally)"
if have gh; then
  if limit 15 gh auth status >/dev/null; then ok "gh logged in"; else warn "gh installed, not logged in: gh auth login"; fi
else
  warn "gh not found: brew install gh"
fi
if have vercel; then
  who="$(limit 15 vercel whoami | tail -1)"
  case "$who" in
    ""|*rror*|*login*|*credentials*) warn "vercel installed, not logged in: vercel login" ;;
    *) ok "vercel logged in as $who" ;;
  esac
else
  warn "vercel not found: npm install --global vercel"
fi
if have railway; then
  who="$(limit 15 railway whoami | tail -1)"
  case "$who" in
    ""|*nauthorized*|*login*) warn "railway installed, not logged in: railway login" ;;
    *) ok "railway: $who" ;;
  esac
else
  warn "railway not found: brew install railway"
fi
if have jq; then ok "jq on PATH"; else warn "jq not found: brew install jq"; fi
if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then ok "CLOUDFLARE_API_TOKEN is set"; else warn "CLOUDFLARE_API_TOKEN is not set in this shell"; fi

echo
echo "$n_ok ok, $n_warn warn, $n_fail fail"
[ "$n_fail" -eq 0 ]
