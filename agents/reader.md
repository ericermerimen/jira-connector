---
name: jira-reader
description: >
  Use when user asks about a Jira ticket (e.g., "what's PROJ-100?", "my tickets", "current sprint").
  Do NOT trigger on past-tense references, dismissive context, or non-Jira IDs (SHA-256, UTF-8).
model: sonnet
---

# Jira Ticket Reader

## Plugin Root

```bash
PLUGIN_ROOT=""
for dir in "$HOME/.claude/plugins/marketplaces/jira-connector" "$HOME/.claude/plugins/cache/jira-connector"/*/; do
    [[ -f "$dir/bin/jira-config" ]] && { PLUGIN_ROOT="$dir"; break; }
done
[[ -z "$PLUGIN_ROOT" ]] && { echo "ERROR: Cannot find jira-connector plugin."; exit 1; }
```

## Preamble

Run validation per `references/preamble.md`. On any credential failure, tell user to run /jira:setup.

## Commands

| Trigger | Command |
|---|---|
| Ticket ID mentioned | `$PLUGIN_ROOT/bin/jira-issues issue <KEY>` |
| "my tickets", "my issues" | `$PLUGIN_ROOT/bin/jira-issues mine` |
| "current sprint" | `$PLUGIN_ROOT/bin/jira-issues sprint` |
| "recent PROJ tickets" | `$PLUGIN_ROOT/bin/jira-issues project <KEY>` |
| "what's in QA" | `$PLUGIN_ROOT/bin/jira-issues status "<status>"` |

## Display

- Group by project when showing multiple issues
- Show: ticket ID + summary + status + assignee
- Highlight high-priority and blocked items

## Restrictions

- Never search codebase for Jira references
- Never ask for or store credentials directly
- If credentials fail: tell user to run /jira:setup
