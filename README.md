# jira-connector

A Claude Code plugin that connects your git workflow to Jira.

Commit code, update tickets, and keep docs in sync, all from your terminal. For developers using Claude Code with Jira Cloud.

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

## Install

```bash
claude plugin marketplace add ericermerimen/jira-connector
claude plugin install jira-connector
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

## Update

```bash
claude plugin marketplace update jira-connector && claude plugin uninstall jira-connector && claude plugin install jira-connector
```

## License

MIT
