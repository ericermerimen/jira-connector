# CLAUDE.md

Instructions for developers and AI assistants working on this project.

## What This Is

jira-connector is a Claude Code plugin that connects git workflows to Jira Cloud. Pure bash, no dependencies beyond curl/git/jq. Runs on macOS, Linux, and Windows (WSL2/Git Bash).

## Running Tests

```bash
for f in tests/test-*.sh; do bash "$f"; done
```

Tests create temp `$HOME` dirs and never touch real config or keychain.

## How to Release

1. Bump version in both `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
2. Update `CHANGELOG.md`
3. Commit and push: `git commit -m "chore: bump to X.Y.Z" && git push origin master`

## Conventions

- **Commits**: `type(scope): description` (feat, fix, chore, refactor, docs, test, ci)
- **No sensitive data**: Public repo. Use generic examples only (e.g., `acme.atlassian.net`, `PROJ-100`).
- **POSIX compatibility**: Use `[[:space:]]` not `\s`. Use `sed -E`. Test on both macOS and Linux.
- **Exit codes**: Follow established patterns in `bin/jira-api` and `bin/jira-cred`.
- **Credential security**: Never pass tokens as CLI arguments. Pipe via stdin or curl `--config`.
