---
name: setup
description: >
  Set up Jira credentials and project configuration. Guides you through connecting to your Jira Cloud instance,
  storing credentials securely, and configuring workflow rules. Idempotent: safe to re-run anytime.
  Use when user says "/jira:setup" or needs to configure Jira credentials.
---

# /jira:setup -- Jira Connector Setup Wizard

Walk the user through configuring the jira-connector plugin step by step. This is idempotent: safe to re-run to change any setting.

## Plugin Root

Determine the plugin root directory (where bin/ scripts live):

```bash
PLUGIN_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")"/../../.. && pwd)"
echo "PLUGIN_ROOT: $PLUGIN_ROOT"
ls "$PLUGIN_ROOT/bin/jira-config" >/dev/null 2>&1 || { echo "ERROR: Cannot find bin/jira-config"; exit 1; }
```

Use `$PLUGIN_ROOT/bin/` to call all scripts.

## Step 1: Prerequisites

Run:
```bash
bash --version | head -1
which curl jq git 2>/dev/null
$PLUGIN_ROOT/bin/jira-cred detect-env
```

Check:
- bash version >= 3.2
- curl, jq, git all found
- If environment is `windows-native` (detected by absence of bash or presence of PowerShell): tell user "Windows requires WSL2 or Git Bash. Install WSL2: https://learn.microsoft.com/en-us/windows/wsl/install" and stop.
- If any tool missing, suggest install command based on OS:
  - macOS: `brew install jq`
  - Debian/Ubuntu: `sudo apt install jq curl`
  - Fedora/RHEL: `sudo dnf install jq curl`
  - Alpine: `apk add jq curl bash`
  - Arch: `sudo pacman -S jq curl`

## Step 2: Jira Instance

If re-running and config exists, show current value and ask "Keep [current] or enter new URL?"

Ask: "What's your Jira Cloud URL? (e.g., https://mycompany.atlassian.net)"

Validate format matches `https://*.atlassian.net`.

Validate connectivity:
```bash
curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$URL/rest/api/3/serverInfo"
```
- 200: OK
- Other: "Can't reach that URL. Check the address and your network/VPN."

Save: `$PLUGIN_ROOT/bin/jira-config set jira_url "$URL"`

## Step 3: Authentication

Tell user:
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Name it "claude-code" and copy the token

Show warning: "This API token grants full access to your Atlassian account. For security, consider using a dedicated account with restricted permissions."

Ask for email and token.

Validate:
```bash
echo "$TOKEN" | curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 -u "${EMAIL}:$(cat -)" -H "Accept: application/json" "${URL}/rest/api/3/myself"
```
- 200: OK
- 401: "Authentication failed. Double-check your email and token."
- 403: "Authenticated but access denied. Your Jira permissions may be restricted."
- Timeout: "Network timeout. Check your connection or VPN."

## Step 4: Credential Storage

Run: `$PLUGIN_ROOT/bin/jira-cred detect-env`

Based on environment:
- `macos-desktop`: Recommend Keychain. Offer env vars as alternative with warning.
- `macos-headless`: Default to env vars. Explain keychain may not work in SSH sessions.
- `linux-desktop`: Recommend secret-tool. Offer env vars as alternative.
- `linux-headless`, `windows-wsl`, `windows-gitbash`: Default to env vars. Explain why.

Save method: `$PLUGIN_ROOT/bin/jira-config set credential_method "$METHOD"`

Store credentials: `$PLUGIN_ROOT/bin/jira-cred set "$EMAIL" "$TOKEN"`

Verify: `$PLUGIN_ROOT/bin/jira-cred validate`

## Steps 5-8: Optional Configuration

Ask: "Use sensible defaults for the rest? You can reconfigure anytime by re-running /jira:setup."

**If yes:** Set defaults and skip to Step 8:
```bash
$PLUGIN_ROOT/bin/jira-config set commit_style "null"
$PLUGIN_ROOT/bin/jira-config set jira_comment_style "null"
$PLUGIN_ROOT/bin/jira-config set docs_scaffold "skip"
```
Write default workflow: `workflows: { default: { transition_to: null, reassign_to: skip } }`

**If no:** Walk through each:

### Step 5: Workflow Rules

Fetch issue types: `$PLUGIN_ROOT/bin/jira-api /rest/api/3/issuetype`

For each common type (Bug, Story, Task), ask:
- "When you commit against a [Type], what should happen?"
  - Transition to: [show available statuses]
  - Reassign to: reporter / author / specific person / skip
  - Just comment, no transition
  - Skip entirely

If API call fails: "Couldn't fetch issue types. Using 'ask each time' as default. You can configure this later."

### Step 6: Commit Style

Ask: "Want to customize your commit message format? Default is conventional commits (feat/fix/refactor)."

If yes: "Describe your preferred format in plain English. Example: 'conventional commit in English, followed by Chinese translation on next line'"

Save to config.

### Step 7: Docs Scaffold

Ask: "Want me to set up a docs structure for this project?"
- A) Minimal: architecture/, decisions/, learnings/
- B) Standard: + guides/, operations/
- C) Skip

If A or B: create the directories and a README.md index.

### Step 8: Write Config and Verify

Save all settings, detect OS:
```bash
$PLUGIN_ROOT/bin/jira-config set os "$(uname -s | tr '[:upper:]' '[:lower:]')"
```

Validate: `$PLUGIN_ROOT/bin/jira-config validate`

Show summary of all configured values.

Tell user: "Setup complete. Try '/jira:commit' after your next change, or mention a ticket ID and the jira-reader agent will pick it up automatically."
