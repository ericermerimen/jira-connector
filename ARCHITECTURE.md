# Architecture

## Overview

jira-connector is a Claude Code plugin built entirely in bash. It has no runtime dependencies beyond `curl`, `git`, and `jq`.

```
User (Claude Code)
  |
  |-- /jira:setup    --> bin/jira-config, bin/jira-cred
  |-- /jira:commit   --> bin/jira-config, bin/jira-cred, bin/jira-api, bin/docs-check
  |-- /jira:docs     --> bin/jira-config, bin/docs-check
  |-- jira-reader    --> bin/jira-config, bin/jira-cred, bin/jira-api, bin/jira-issues
```

## 3-Layer Configuration

Configuration is resolved at runtime by merging three layers:

1. **Global config** (`~/.jira-connector/config.yaml`) -- created by `/jira:setup`, stores Jira URL, email, credential method, workflow rules, and preferences.
2. **Per-project config** (`.jira-connector.yaml` at git root) -- optional overrides for multi-project setups. Only allowed keys are merged (`jira_url`, `jira_email`, `workflows`, `docs_path`, `ticket_prefixes`, `projects`). Security-sensitive keys like `credential_method` cannot be overridden.
3. **Environment variables** (`JIRA_EMAIL`, `JIRA_API_TOKEN`) -- fallback credential source when keychain is unavailable.

Resolution order: global config is loaded first, per-project config overlays allowed keys, env vars provide credential fallback. The `jira-config resolve` command outputs the final merged config.

Config files use `chmod 600` permissions. YAML is parsed with sed/grep (no yq dependency).

## Credential Flow

```
jira-cred detect-env
  |
  |-- macos-desktop    --> macOS Keychain (security command)
  |-- linux-desktop    --> GNOME Keyring (secret-tool)
  |-- everything else  --> Environment variables
```

Credentials are never passed as CLI arguments. The `jira-api` script pipes them to curl via `--config -` to avoid visibility in `ps` output.

Validation flow (`jira-cred validate`):
1. Retrieve email and token from the configured method
2. Call `GET /rest/api/3/myself` with the credentials
3. Return exit code: 0=OK, 1=expired, 2=keychain locked, 3=network, 4=forbidden, 5=not found

## Skill Checkpoint Pattern

Each skill follows a checkpoint pattern where the user must approve every action:

```
Preamble (validate config + credentials + git state)
  |
  v
Checkpoint 1: Review proposed action (AskUserQuestion with A/B/C options)
  |  User approves or edits
  v
Checkpoint 2: Review next action
  |  User approves or skips
  v
...
  |
  v
Execute: Run only the confirmed actions
  |
  v
Report: Show what was done with links
```

This pattern ensures:
- Nothing executes without explicit user approval
- Each step can be edited, skipped, or aborted
- If Jira is unreachable, git operations still work (graceful degradation)

The preamble (defined in `references/preamble.md`) runs at the start of every skill and agent invocation. It validates config, merges per-project overrides, checks credentials, and detects git state.

## bin/ Scripts

| Script | Purpose | Exit Codes |
|---|---|---|
| `jira-config` | Config CRUD, validation, resolution, version diagnostics | 0=OK, 1=error |
| `jira-cred` | Credential storage, retrieval, validation, environment detection | 0=OK, 1=expired, 2=keychain, 3=network, 4=forbidden, 5=not found |
| `jira-api` | Authenticated Jira REST wrapper with retry and backoff | 0=OK, 1=error, 3=timeout, 4=forbidden, 5=no creds |
| `jira-issues` | High-level Jira queries (mine, project, issue, sprint, status) | 0=OK, 1=error |
| `docs-check` | Scan docs for references to changed files, find stale refs | 0=matches, 1=no matches, 2=error |

## Test Architecture

Tests are self-contained bash scripts in `tests/`. Each test:
- Creates a temp `$HOME` to isolate from real config
- Creates temp git repos when needed (e.g., `test-docs-check.sh`)
- Uses `assert_eq` and `assert_exit_code` helpers
- Cleans up via `trap cleanup EXIT`
- Never touches real Jira APIs or credentials
