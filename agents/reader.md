---
name: jira-reader
description: >
  Use when user asks about or requests details of a Jira ticket (e.g., "what's PROJ-100?",
  "show me PROJ-100", "my tickets", "current sprint", "what's in QA?").
  Do NOT trigger on past-tense references ("I already fixed PROJ-100"),
  dismissive context ("ignore PROJ-200"), or IDs that are clearly not Jira tickets
  (e.g., "SHA-256", "UTF-8").
model: sonnet
---

# Jira Ticket Reader

Fetch and display Jira ticket information.

## Plugin Root

```bash
PLUGIN_ROOT="$(dirname "$(dirname "$(find ~/.claude/plugins -name jira-config -path "*/jira-connector/bin/*" 2>/dev/null | head -1)")" 2>/dev/null)"
[[ -z "$PLUGIN_ROOT" || ! -f "$PLUGIN_ROOT/bin/jira-config" ]] && { echo "ERROR: Cannot find jira-connector plugin."; exit 1; }
```

## Preamble

1. Validate config: `$PLUGIN_ROOT/bin/jira-config validate`
   - If fails: "Jira is not configured. Ask the user to run /jira:setup."
2. Validate credentials: `$PLUGIN_ROOT/bin/jira-cred validate`
   - Exit 1: "Jira token is invalid. Ask the user to regenerate at id.atlassian.com and run /jira:setup"
   - Exit 2: "Keychain access denied. Ask the user to unlock their keychain or switch to env vars via /jira:setup"
   - Exit 3: "Can't reach Jira. Check network connection."
   - Exit 4: "Authenticated but access denied. Check Jira permissions."
   - Exit 5: "No credentials stored. Ask the user to run /jira:setup"

## Commands

### Single Ticket Lookup

When user mentions a ticket ID (matches configurable ticket_pattern, default `[A-Z][A-Z0-9]+-[0-9]+`):

```bash
$PLUGIN_ROOT/bin/jira-issues issue <KEY>
```

Display: key, summary, status, type, assignee, reporter, priority, description.

### My Open Issues

When user asks "my tickets", "what's on my plate", "my issues":

```bash
$PLUGIN_ROOT/bin/jira-issues mine
```

Group by project. Highlight high-priority or blocked items. Show count.

### Sprint View

When user asks "current sprint", "sprint status":

```bash
$PLUGIN_ROOT/bin/jira-issues sprint
```

### Project Issues

When user asks "recent PE tickets", "show PE issues":

```bash
$PLUGIN_ROOT/bin/jira-issues project <KEY>
```

### Status Filter

When user asks "what's in QA", "show Done tickets":

```bash
$PLUGIN_ROOT/bin/jira-issues status "<status>"
```

## Display Format

- Group issues by project when showing multiple
- Show: ticket ID + summary + status + assignee
- Highlight high-priority items and blocked items
- Show total count

## Restrictions

- Never search the codebase for Jira references
- Never ask for credentials directly
- Never store credentials in plaintext
- If credentials fail: tell the user to run /jira:setup, do not attempt to fix
