---
name: setup
description: >
  Set up Jira credentials and project configuration. Guides you through connecting to your Jira Cloud instance,
  storing credentials securely, and configuring workflow rules. Idempotent: safe to re-run anytime.
  Use when user says "/jira:setup" or needs to configure Jira credentials.
---

# /jira:setup -- Jira Connector Setup Wizard

Interactive setup wizard. Each step uses AskUserQuestion for proper selection UI.

## CRITICAL RULES

1. **ONE STEP AT A TIME.** Never combine steps or skip ahead.
2. **USE AskUserQuestion ONLY for real choices** (A/B/C/D selections like credential storage, workflow rules, defaults). This gives proper selection UI.
3. **USE plain text for free-text inputs** (URL, email, token). Ask the question, then STOP your response and wait. Do NOT answer for the user.
4. **STOP AND WAIT after every question.** Whether AskUserQuestion or plain text, end your message after asking. Do NOT continue until the user replies.
5. **NEVER SHOW THE API TOKEN.** Never in bash commands, messages, or output. Pipe via stdin only.
6. **NEVER AUTO-DECIDE.** Do not say "I'll default to X" or "I'll go with X while you confirm." Present the question and WAIT.

## Plugin Root

Find the plugin root by locating `bin/jira-config`:
```bash
PLUGIN_ROOT=""
for dir in "$HOME/.claude/plugins/marketplaces/jira-connector" "$HOME/.claude/plugins/cache/jira-connector"/*/; do
    [[ -f "$dir/bin/jira-config" ]] && { PLUGIN_ROOT="$dir"; break; }
done
[[ -z "$PLUGIN_ROOT" ]] && { echo "ERROR: Cannot find jira-connector plugin."; exit 1; }
echo "Plugin root: $PLUGIN_ROOT"
```

---

## Step 1: Prerequisites

Run silently:
```bash
bash --version | head -1
which curl jq git 2>/dev/null
$PLUGIN_ROOT/bin/jira-cred detect-env
```

If any tool missing, show install suggestions. If native Windows, tell user to install WSL2 and stop.

If all good, tell user: "Prerequisites OK. Detected environment: [env type]." Then immediately proceed to Step 2.

---

## Step 2: Jira URL

Ask the user in plain text:

"What's your Jira URL? You can paste your full board URL (e.g. https://mycompany.atlassian.net/jira/software/projects/PE/boards/33) or just the base URL (https://mycompany.atlassian.net)."

**STOP your response here. Wait for the user to type their URL.**

When they answer:
- **Parse the URL intelligently:**
  - If they pasted a full board/project URL like `https://example.atlassian.net/jira/software/projects/PE/boards/33`:
    - Extract the base URL: `https://example.atlassian.net`
    - Extract the project key if present in the path (e.g., `PE` from `/projects/PE/`)
    - Tell user: "Got it. Base URL: https://example.atlassian.net, detected project: PE."
    - Save the project key: `$PLUGIN_ROOT/bin/jira-config set projects "[PE]"`
  - If they pasted just the base URL like `https://mycompany.atlassian.net`:
    - Use as-is
- Validate the base URL format: must contain `.atlassian.net`
- Check the host resolves: `curl -s -o /dev/null --connect-timeout 10 --head "$BASE_URL" 2>&1`
  - If curl exits 0: "URL looks good." (We'll verify it works with your credentials in Step 5.)
  - If curl exits non-zero: "Can't reach that URL. Check the address and your network/VPN."
- Save: `$PLUGIN_ROOT/bin/jira-config set jira_url "$BASE_URL"`

---

## Step 3: Email

Ask the user in plain text:

"What's your Jira email address?"

**STOP your response here. Wait for the user to type their email.**

When they answer: save the email for later. Proceed to Step 4.

---

## Step 4: API Token

First, show these instructions as a message (NOT as a question):

"You'll need a Jira API token. Here's how to create one:

1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click 'Create API token'
3. Name it 'claude-code' and copy the token

Note: This token grants full access to your Atlassian account. Consider using a dedicated account with restricted permissions."

Then ask in plain text:

"Paste your API token:"

**STOP your response here. Wait for the user to paste their token.**

When they answer: save the token in memory. NEVER display it again. Proceed to Step 5.

---

## Step 5: Validate Credentials

Store credentials and validate (run silently):
```bash
$PLUGIN_ROOT/bin/jira-config set jira_email "$EMAIL"
echo "$TOKEN" | $PLUGIN_ROOT/bin/jira-cred set "$EMAIL"
$PLUGIN_ROOT/bin/jira-cred validate
```

SECURITY: NEVER pass the token as a CLI argument to any external command. Always pipe via stdin.

- Exit 0: "Authenticated successfully." Proceed to Step 6.
- Exit 1: "Authentication failed." Use AskUserQuestion:
  - Question: "Authentication failed. What would you like to do?"
  - A) "Re-enter email and token" -- go back to Step 3
  - B) "Check my Jira URL" -- go back to Step 2
  - C) "Skip for now" -- skip auth, proceed with partial setup
- Exit 3: "Network timeout." Same retry options.

---

## Step 6: Credential Storage

Run: `$PLUGIN_ROOT/bin/jira-cred detect-env`

**For `macos-desktop`, use AskUserQuestion:**
- Question: "Where should I store your Jira credentials?"
- A) "macOS Keychain" with description "Recommended. Encrypted system storage, persists across sessions."
- B) "Environment variables" with description "Less secure. Visible in process listings. You'll need to set them in your shell profile."

**For `linux-desktop`, use AskUserQuestion:**
- Question: "Where should I store your Jira credentials?"
- A) "GNOME Keyring / secret-tool" with description "Recommended. Encrypted system storage."
- B) "Environment variables" with description "Less secure. Set in .bashrc or .env file."

**For headless/WSL/Git Bash:**
- No question needed. Tell user: "Your environment doesn't support a system keychain. Using environment variables."

After choice is made, save and store:
```bash
$PLUGIN_ROOT/bin/jira-config set credential_method "$METHOD"
echo "$TOKEN" | $PLUGIN_ROOT/bin/jira-cred set "$EMAIL"
$PLUGIN_ROOT/bin/jira-cred validate
```

Proceed to Step 7.

---

## Step 7: Optional Configuration

Use AskUserQuestion:
- Question: "How would you like to configure the remaining settings (commit style, workflow rules, docs scaffold)?"
- A) "Use sensible defaults" with description "Recommended. Conventional commits, learns your Jira workflow preferences on first use, no docs scaffold. You can change any of these later."
- B) "Let me configure each one" with description "Walk through commit style, workflow rules, and docs structure step by step."

**STOP and wait.**

**If A:** Set defaults and skip to Step 8:
```bash
$PLUGIN_ROOT/bin/jira-config set commit_style "null"
$PLUGIN_ROOT/bin/jira-config set jira_comment_style "null"
$PLUGIN_ROOT/bin/jira-config set docs_scaffold "skip"
```

With no workflow rules set, /jira:commit will ask what to do the first time it encounters each issue type (Bug, Story, Task, etc.) and offer to save your choice. After that, it remembers and applies the same action automatically.

**If B:** Go through 7a, 7b, 7c, 7d.

---

### Step 7a: Workflow Rules

Try to fetch issue types: `$PLUGIN_ROOT/bin/jira-api /rest/api/3/issuetype`

If API fails: "Couldn't fetch issue types. Using 'ask each time' as default." Skip to 7b.

Do NOT show a big status table. Handle ONE issue type at a time with its own AskUserQuestion.

**7a-i: Bug workflow**

Use AskUserQuestion:
- Question: "When you commit against a Bug, what should happen?"
- A) "Move to QA and reassign to reporter" with description "Common for bug fixes. Transitions the ticket to QA status and reassigns to whoever reported it."
- B) "Move to QA, keep assignee" with description "Transitions to QA but doesn't change who it's assigned to."
- C) "Just add a comment" with description "Posts what you did to the ticket. No status change."
- D) "Ask me each time" with description "Prompt during /jira:commit so you can decide per-ticket."

**STOP and wait.**

**7a-ii: Story workflow**

Use AskUserQuestion:
- Question: "When you commit against a Story, what should happen?"
- A) "Move to Done" with description "Marks the story as complete."
- B) "Move to Code Review" with description "Signals the story is ready for review."
- C) "Just add a comment" with description "Posts what you did. No status change."
- D) "Ask me each time" with description "Prompt during /jira:commit."

**STOP and wait.**

**7a-iii: Task workflow**

Use AskUserQuestion:
- Question: "When you commit against a Task, what should happen?"
- A) "Move to Done" with description "Marks the task as complete."
- B) "Just add a comment" with description "Posts what you did. No status change."
- C) "Ask me each time" with description "Prompt during /jira:commit."

**STOP and wait.**

Note: If a user picks a transition status that doesn't exist on their board, /jira:commit will detect this at runtime and show available options. The setup doesn't need to validate every status name.

### Step 7b: Commit Style

Use AskUserQuestion:
- Question: "How should commit messages be formatted?"
- A) "Conventional commits" with description "Recommended. Format: feat(TICKET): description, fix(TICKET): description"
- B) "Custom format" with description "Describe your format in plain English (e.g., 'English summary followed by Chinese translation')"

If B: ask in plain text and STOP. Wait for the user to type their custom format instruction.

### Step 7c: Jira Comment Style

Use AskUserQuestion:
- Question: "How should Jira comments be formatted when you commit?"
- A) "Structured" with description "Recommended. Title, changes list, and result/new behavior"
- B) "Custom format" with description "Describe your preferred format in plain English"

If B: ask in plain text and STOP. Wait for the user to type their custom format.

### Step 7d: Docs Scaffold

Use AskUserQuestion:
- Question: "Want to set up a docs structure for this project?"
- A) "Minimal" with description "Creates docs/ with architecture/, decisions/, learnings/ folders"
- B) "Standard" with description "Minimal + guides/ and operations/ folders"
- C) "Skip" with description "I already have docs or don't want this"

If A or B: create the folders and a README.md index.

---

## Step 8: Finalize

Run silently:
```bash
$PLUGIN_ROOT/bin/jira-config set os "$(uname -s | tr '[:upper:]' '[:lower:]')"
$PLUGIN_ROOT/bin/jira-config validate
```

Show a summary table of all configured values (NEVER show the token, just show "stored in [keychain/env vars]").

Tell user: "Setup complete! Here's what you can do next:
- `/jira:commit` after making changes to commit + update Jira
- `/jira:docs` before PRs to sync documentation
- Mention a ticket ID (like PROJ-100) and the jira-reader agent fetches it automatically
- Re-run `/jira:setup` anytime to change settings"
