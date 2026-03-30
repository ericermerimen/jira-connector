# jira-connector

![Version](https://img.shields.io/badge/version-0.4.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20WSL2-lightgrey)
![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-blueviolet)

A Claude Code plugin that connects your git workflow to Jira.

Commit code, update tickets, and keep docs in sync, all from your terminal.

## Quick Start

```bash
# Install
claude plugin marketplace add ericermerimen/jira-connector
claude plugin install jira-connector

# Configure (~2 minutes)
/jira:setup

# Use
/jira:commit          # commit + update Jira
/jira:docs            # check docs before PR
# "what's PROJ-100?"  # auto-fetches ticket details
```

## What It Does

**`/jira:commit`** -- Four-step interactive flow: review diff, update Jira (comment + transition + reassign), check docs, execute. No ticket? Skips Jira, gives you a clean commit. Nothing fires until you approve.

**`/jira:docs`** -- Compares your branch against base, finds docs referencing changed files, proposes updates.

**Jira Reader** -- Mention a ticket and it shows up: "what's PROJ-100?", "my tickets", "current sprint".

## Prerequisites

**curl**, **git**, **jq** must be in PATH.
- macOS/Linux: usually pre-installed (`brew install jq` or `apt install jq`)
- Windows (Git Bash): `choco install jq` or `winget install jqlang.jq`

## Install from Source

```bash
git clone https://github.com/ericermerimen/jira-connector.git
cd jira-connector
for f in tests/test-*.sh; do bash "$f"; done
```

## Platforms

| Platform | Credentials | Status |
|---|---|---|
| macOS | Keychain or env vars | Yes |
| Linux (desktop) | secret-tool or env vars | Yes |
| Linux (server/container) | Env vars | Yes |
| Windows (WSL2 / Git Bash) | Env vars | Yes |
| Windows (PowerShell) | -- | No |

## Multi-Project

Global config at `~/.jira-connector/config.yaml`, per-project overrides via `.jira-connector.yaml` at repo root.

## Diagnostics

```bash
bin/jira-config version
```

## Update

```bash
claude plugin marketplace update jira-connector && claude plugin uninstall jira-connector && claude plugin install jira-connector
```

## License

MIT
