# CLAUDE.md

Instructions for developers and AI assistants working on this project.

## What This Is

jira-connector is a Claude Code plugin that connects git workflows to Jira Cloud. It provides three skills (`/jira:commit`, `/jira:docs`, `/jira:setup`) and an agent (`jira-reader`) that auto-fetches ticket details when mentioned in conversation.

The entire plugin is pure bash -- no Node.js, no Python, no compiled binaries. It runs on macOS, Linux, and Windows (WSL2/Git Bash).

## Project Structure

```
.claude-plugin/       Plugin metadata (plugin.json, marketplace.json)
bin/                  Executable scripts (the core logic)
  jira-config         Config CRUD + validation + version diagnostics
  jira-cred           Cross-platform credential management
  jira-api            Authenticated Jira REST wrapper with retry
  jira-issues         High-level query commands with pagination
  docs-check          Documentation reference scanner
skills/               Skill definitions (SKILL.md per skill)
  commit/             /jira:commit -- commit + Jira update flow
  docs/               /jira:docs -- documentation sync
  setup/              /jira:setup -- setup wizard
agents/               Agent definitions
  reader.md           jira-reader -- auto-fetch ticket details
references/           Shared reference docs loaded by skills
  preamble.md         Validation steps run at skill/agent start
  credential-helper.md  Per-platform credential commands
  jira-cloud-api.md   Jira REST API v3 reference
tests/                Test scripts (one per bin/ script + security)
  fixtures/           Mock data for tests
```

## Running Tests

All tests are self-contained bash scripts that use temp directories (no real Jira connection needed):

```bash
# Run all tests
bash tests/test-config.sh && bash tests/test-cred.sh && bash tests/test-api.sh && bash tests/test-docs-check.sh && bash tests/test-security.sh

# Run a single test
bash tests/test-config.sh
```

Tests create temp `$HOME` dirs and clean up after themselves. They never touch your real config or keychain.

## How to Release

1. Bump the version in both files (must match):
   - `.claude-plugin/plugin.json` -- `"version"` field
   - `.claude-plugin/marketplace.json` -- `"version"` field inside `plugins[0]`
2. Update `CHANGELOG.md` with the new version and changes.
3. Commit: `git commit -m "chore: bump to X.Y.Z"`
4. Push: `git push origin master`

## Conventions

- **Commits**: Use conventional commit format: `type(scope): description`
  - Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `ci`
  - Example: `feat(config): add version subcommand`
- **No sensitive data**: This is a public repo. Never commit real Jira URLs, emails, tokens, project keys, or team member names. Use generic examples only (e.g., `acme.atlassian.net`, `PROJ-100`, `user@example.com`).
- **POSIX compatibility**: All bash scripts must work on macOS (BSD tools) and Linux (GNU tools). Use POSIX character classes (`[[:space:]]`) instead of `\s`. Test `sed` with `-E` flag.
- **Exit codes**: Follow established patterns. See `bin/jira-api` and `bin/jira-cred` for the exit code contracts.
- **Credential security**: Never pass tokens as CLI arguments. Always pipe via stdin or curl `--config`.

## Key Design Decisions

- **No dependencies beyond curl/git/jq**: Keeps the install footprint at zero. No package manager needed.
- **3-layer config**: Global (`~/.jira-connector/config.yaml`) + per-project (`.jira-connector.yaml` at git root) + env vars. Resolved at runtime by `jira-config resolve`.
- **Checkpoint pattern**: Skills use AskUserQuestion at each step. Nothing executes without user approval.
- **Graceful degradation**: If Jira is unreachable, commit still works. If no ticket found, Jira step is skipped.
