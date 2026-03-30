---
name: setup
description: >
  Set up Jira credentials and project configuration. Guides you through connecting to your Jira Cloud instance,
  storing credentials securely, and configuring workflow rules. Idempotent: safe to re-run anytime.
  Use when user says "/jira:setup" or needs to configure Jira credentials.
---

# /jira:setup -- Jira Connector Setup Wizard

## When to Use

Trigger on: "/jira:setup", "set up Jira", "connect to Jira", "configure Jira credentials", "reconfigure Jira", "my Jira isn't working"

Do NOT trigger on: "what's my Jira config?" (use `jira-config version` instead)

## CRITICAL RULES

1. **ONE STEP AT A TIME.** Never combine steps or skip ahead.
2. **USE AskUserQuestion for choices** (A/B/C selections). Use plain text for free-text inputs (URL, email, token).
3. **STOP AND WAIT** after every question. Do NOT continue until the user replies.
4. **NEVER SHOW THE API TOKEN.** Pipe via stdin only.
5. **NEVER AUTO-DECIDE.** Present the question and wait.

## Plugin Root

```bash
PLUGIN_ROOT=""
for dir in "$HOME/.claude/plugins/marketplaces/jira-connector" "$HOME/.claude/plugins/cache/jira-connector"/*/; do
    [[ -f "$dir/bin/jira-config" ]] && { PLUGIN_ROOT="$dir"; break; }
done
[[ -z "$PLUGIN_ROOT" ]] && { echo "ERROR: Cannot find jira-connector plugin."; exit 1; }
```

---

## Step 1: Prerequisites

Run silently: `bash --version`, `which curl jq git`, `$PLUGIN_ROOT/bin/jira-cred detect-env`. If tools missing, show install suggestions. If native Windows, stop.

---

## Step 2: Jira URL

Ask: "What's your Jira URL? Paste your full board URL or base URL (e.g. https://mycompany.atlassian.net)."

**STOP and wait.**

Parse intelligently: extract base URL (up to `.atlassian.net`), extract project key if in path. Validate format and reachability via `curl --head`. Save via `jira-config set jira_url`.

---

## Step 3: Email

Ask: "What's your Jira email address?" **STOP and wait.**

---

## Step 4: API Token

Show instructions (not a question):
"You'll need a Jira API token:
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click 'Create API token', name it 'claude-code', copy it"

Ask: "Paste your API token:" **STOP and wait.**

---

## Step 5: Validate Credentials

```bash
$PLUGIN_ROOT/bin/jira-config set jira_email "$EMAIL"
echo "$TOKEN" | $PLUGIN_ROOT/bin/jira-cred set "$EMAIL"
$PLUGIN_ROOT/bin/jira-cred validate
```

- Exit 0: proceed
- Exit 1/3: AskUserQuestion -- re-enter credentials, check URL, or skip

---

## Step 6: Credential Storage

Run `$PLUGIN_ROOT/bin/jira-cred detect-env`.

- **macos-desktop/linux-desktop**: AskUserQuestion -- system keychain (recommended) or env vars
- **headless/WSL/Git Bash**: env vars only, inform user

Save method and store credentials.

---

## Step 7: Optional Configuration

AskUserQuestion:
- A) "Use sensible defaults" (conventional commits, learn workflow on first use)
- B) "Configure each one"

**STOP and wait.**

If B, walk through:
- **7a: Workflow rules** -- one AskUserQuestion per issue type (Bug, Story, Task): transition behavior
- **7b: Commit style** -- conventional commits or custom format
- **7c: Jira comment style** -- structured or custom
- **7d: Docs scaffold** -- minimal / standard / skip

---

## Step 8: Finalize

Save OS, run `jira-config validate`, show summary table (never show token). Tell user:
- `/jira:commit` -- commit + update Jira
- `/jira:docs` -- sync docs before PR
- Mention a ticket ID for auto-lookup
- Re-run `/jira:setup` anytime
