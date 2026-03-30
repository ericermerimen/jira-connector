# jira-connector

![Version](https://img.shields.io/badge/version-0.3.10-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20WSL2-lightgrey)
![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-blueviolet)

A Claude Code plugin that connects your git workflow to Jira.

Commit code, update tickets, and keep docs in sync, all from your terminal. For developers using Claude Code with Jira Cloud.

## Quick Start

```bash
# 1. Install
claude plugin marketplace add ericermerimen/jira-connector
claude plugin install jira-connector

# 2. Configure (takes ~2 minutes)
# In Claude Code, type:
/jira:setup

# 3. Use
# Commit with Jira integration:
/jira:commit

# Check docs before a PR:
/jira:docs

# Ask about any ticket:
# "what's PROJ-100?"
```

## What It Does

### `/jira:commit`

Commit your changes with an interactive flow. Four steps, each with your approval:

1. **Review** -- see the diff, approve or edit the commit message
2. **Jira** -- post a comment, transition the ticket, reassign if needed
3. **Docs** -- check if documentation references your changed files
4. **Done** -- summary with a clickable link to the ticket

No ticket? It skips Jira and gives you a clean commit with docs check. Nothing fires until you say go.

### `/jira:docs`

Catch stale documentation before a PR. Compares your branch against the base, finds docs that reference changed files, and proposes updates.

### Jira Reader

Mention a ticket in conversation and it shows up automatically:

- "what's PROJ-100?" -- ticket details
- "my tickets" -- your open issues
- "current sprint" -- sprint board

## Prerequisites

- **curl**, **git**, **jq** -- must be in your PATH
- macOS/Linux: usually pre-installed (install `jq` via `brew install jq` or `apt install jq`)
- Windows (Git Bash): install `jq` via `choco install jq` or `winget install jqlang.jq`

## Install

From the Claude Code marketplace:

```bash
claude plugin marketplace add ericermerimen/jira-connector
claude plugin install jira-connector
```

From source (for development):

```bash
git clone https://github.com/ericermerimen/jira-connector.git
cd jira-connector
# Run tests to verify
bash tests/test-config.sh && bash tests/test-cred.sh && bash tests/test-api.sh && bash tests/test-docs-check.sh && bash tests/test-security.sh
```

Then run `/jira:setup` in Claude Code. Takes about 2 minutes.

## Setup

`/jira:setup` walks you through everything:

1. Jira URL (paste your board URL, it extracts what it needs)
2. Email
3. API token ([create one here](https://id.atlassian.com/manage-profile/security/api-tokens))
4. Credential storage (Keychain on macOS, env vars elsewhere)
5. Optional: workflow rules, commit style, docs structure

Sensible defaults so you can start fast. Re-run anytime to change settings.

## Platforms

| Platform | Credentials | Works? |
|---|---|---|
| macOS | Keychain or env vars | Yes |
| Linux (desktop) | secret-tool or env vars | Yes |
| Linux (server/container) | Env vars | Yes |
| Windows (WSL2 / Git Bash) | Env vars | Yes |
| Windows (PowerShell) | -- | No |

## Multi-Project

Works across Jira instances. Global config at `~/.jira-connector/config.yaml`, per-project overrides via `.jira-connector.yaml` in any repo root (git-ignored automatically).

## Diagnostics

Check your setup at any time:

```bash
bin/jira-config version
```

Prints the plugin version, config path, credential method, and connected projects.

## Update

```bash
claude plugin marketplace update jira-connector && claude plugin uninstall jira-connector && claude plugin install jira-connector
```

## License

MIT
