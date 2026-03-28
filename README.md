# jira-connector

A Claude Code plugin that connects your git workflow to Jira. Commit code, update tickets, and keep docs in sync, all from your terminal.

## Quick Start

```bash
claude plugin marketplace add ericermerimen/jira-connector
claude plugin install jira-connector
```

Then run `/jira:setup` in Claude Code. It takes about 2 minutes.

## What It Does

### `/jira:commit`

Commit your changes with an interactive flow that handles everything:

1. **Review your commit** -- see the diff, approve or edit the message
2. **Update Jira** -- post a comment, transition the ticket, reassign if needed
3. **Check docs** -- see if any documentation references your changed files
4. **Done** -- get a summary with a clickable link to the Jira ticket

No ticket? No problem. It skips Jira and gives you a clean commit with docs check.

Every step asks for your approval. Nothing fires until you say go.

### `/jira:docs`

Run before a PR to catch stale documentation. Compares your branch against the base, finds docs that reference changed files, and proposes updates.

### Jira Reader Agent

Mention a ticket in conversation and it shows up automatically:

- "what's PROJ-100?" -- fetches ticket details
- "my tickets" -- your open issues
- "current sprint" -- sprint board view

## Setup

`/jira:setup` walks you through everything step by step:

1. Your Jira URL (paste your board URL, it extracts what it needs)
2. Your email
3. An API token (the wizard shows you exactly where to create one)
4. Where to store credentials (Keychain on macOS, env vars elsewhere)
5. Optional: workflow rules, commit style, docs structure

Picks sensible defaults so you can start fast. Learns your preferences as you use it. Re-run anytime to change settings.

## Multi-Project

Works across different Jira instances. Global config at `~/.jira-connector/config.yaml` provides defaults. Drop a `.jira-connector.yaml` in any project root to override per-project (git-ignored automatically).

## Platforms

| Platform | Credentials | Works? |
|---|---|---|
| macOS | Keychain or env vars | Yes |
| Linux (desktop) | secret-tool or env vars | Yes |
| Linux (server/container) | Env vars | Yes |
| Windows (WSL2 / Git Bash) | Env vars | Yes |
| Windows (PowerShell) | -- | No |

## Update

```bash
claude plugin marketplace update jira-connector && claude plugin uninstall jira-connector && claude plugin install jira-connector
```

## License

MIT
