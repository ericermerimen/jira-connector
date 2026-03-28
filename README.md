# jira-connector

A Claude Code plugin that combines Jira ticket reading, git commit workflows, and documentation maintenance.

## Requirements

- Claude Code
- bash 3.2+
- curl, jq, git
- Jira Cloud account with API token
- macOS, Linux, or Windows (WSL2 / Git Bash)

## Install

```bash
# Step 1: Add the marketplace
claude plugin marketplace add ericermerimen/jira-connector

# Step 2: Install
claude plugin install jira-connector
```

To update later:
```bash
claude plugin marketplace update jira-connector
claude plugin uninstall jira-connector
claude plugin install jira-connector
```

## Setup

Run `/jira:setup` in Claude Code. The wizard walks you through:

1. Connecting to your Jira Cloud instance
2. Creating and storing an API token
3. Configuring workflow rules (what happens when you commit against a Bug vs Story)
4. Optional: commit message style, docs structure

## Usage

### `/jira:commit` -- Commit with Jira Integration

After making changes, run `/jira:commit`. It walks through 4 checkpoints:

1. **Git commit** -- review staged changes, confirm commit message
2. **Jira update** -- review comment and status transition, confirm
3. **Doc check** -- see if any docs reference changed files, update if needed
4. **Execute** -- all confirmed actions fire at once

Skip any step. Abort anytime. Nothing happens until you confirm.

### `/jira:docs` -- Documentation Sync

Before a PR, run `/jira:docs` to check if your docs are in sync with code changes. Scans for stale references, dead links, and outdated content.

### `jira-reader` Agent

Mention a ticket ID in conversation ("what's PROJ-100?") and the agent fetches it automatically. Also handles "my tickets", "current sprint", etc.

## Multi-Project Support

Global config at `~/.jira-connector/config.yaml` provides defaults. Per-project overrides via `.jira-connector.yaml` in your project root (git-ignored).

## Platform Support

| Platform | Credential Storage | Status |
|---|---|---|
| macOS (desktop) | Keychain | Supported |
| macOS (SSH) | Env vars | Supported |
| Linux (desktop) | secret-tool | Supported |
| Linux (headless) | Env vars | Supported |
| Windows (WSL2) | Env vars | Supported |
| Windows (Git Bash) | Env vars | Supported |
| Windows (PowerShell) | -- | Not supported |

## License

MIT
