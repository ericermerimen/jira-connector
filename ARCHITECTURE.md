# Architecture

jira-connector is a Claude Code plugin built entirely in bash. No runtime dependencies beyond `curl`, `git`, and `jq`.

```
User (Claude Code)
  |-- /jira:setup    --> bin/jira-config, bin/jira-cred
  |-- /jira:commit   --> bin/jira-config, bin/jira-cred, bin/jira-api, bin/docs-check
  |-- /jira:docs     --> bin/jira-config, bin/docs-check
  |-- jira-reader    --> bin/jira-config, bin/jira-cred, bin/jira-api, bin/jira-issues
```

## Configuration

Three layers merged at runtime by `jira-config resolve`:

1. **Global** (`~/.jira-connector/config.yaml`) -- Jira URL, email, credential method, workflow rules
2. **Per-project** (`.jira-connector.yaml` at git root) -- optional overrides for allowed keys only (`jira_url`, `jira_email`, `workflows`, `docs_path`, `ticket_prefixes`, `projects`). Security keys like `credential_method` cannot be overridden.
3. **Environment variables** (`JIRA_EMAIL`, `JIRA_API_TOKEN`) -- fallback when keychain unavailable

Config files use `chmod 600`. YAML parsed with sed/grep (no yq dependency).

## Credential Flow

```
jira-cred detect-env
  |-- macos-desktop    --> macOS Keychain (security command)
  |-- linux-desktop    --> GNOME Keyring (secret-tool)
  |-- everything else  --> Environment variables
```

Credentials never passed as CLI arguments. `jira-api` pipes them to curl via `--config -`.

Validation exit codes: 0=OK, 1=expired, 2=keychain locked, 3=network, 4=forbidden, 5=not found.

## Skill Checkpoint Pattern

Every skill follows: preamble (validate config + creds + git state) then a series of checkpoints using AskUserQuestion. Nothing executes without user approval. If Jira is unreachable, git operations still work.

## bin/ Scripts

| Script | Purpose | Exit Codes |
|---|---|---|
| `jira-config` | Config CRUD, validation, resolution, version | 0=OK, 1=error |
| `jira-cred` | Credential storage, retrieval, validation, env detection | 0=OK, 1=expired, 2=keychain, 3=network, 4=forbidden, 5=not found |
| `jira-api` | Authenticated Jira REST wrapper with retry/backoff | 0=OK, 1=error, 3=timeout, 4=forbidden, 5=no creds |
| `jira-issues` | High-level queries (mine, project, issue, sprint, status) | 0=OK, 1=error |
| `docs-check` | Scan docs for references to changed files | 0=matches, 1=no matches, 2=error |
