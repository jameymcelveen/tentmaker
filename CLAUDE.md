@AGENTS.md

## Claude Code notes

- Shared permissions live in `.claude/settings.json`. Personal overrides go in
  `.claude/settings.local.json`, which is gitignored.
- `/add-source` is the project skill for adding an employer to the registry.
- The `reviewer` subagent is read-only. Run it on a finished slice before opening the PR.
  It must not be the same session that wrote the code.
- `git push` always asks first. The owner merges.
