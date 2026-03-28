---
name: commit
description: >
  Commit changes to git and update Jira ticket. 4-step confirmed flow: draft commit message,
  update Jira (comment + transition), check docs, then execute. Nothing fires without user approval.
  Use when user says "/jira:commit" or asks to commit their changes.
---

# /jira:commit -- Commit with Jira Integration

## Plugin Root

```bash
PLUGIN_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")"/../../.. && pwd)"
```

## Preamble

1. Load and validate config (with per-project merge):
   ```bash
   $PLUGIN_ROOT/bin/jira-config validate
   ```
   If fails: show error, tell user "Run /jira:setup to configure."

2. Validate credentials:
   ```bash
   $PLUGIN_ROOT/bin/jira-cred validate
   ```
   Handle by exit code:
   - 0: continue
   - 1: "Jira token is invalid. Regenerate at id.atlassian.com and run /jira:setup"
   - 2: "Keychain access denied. Unlock your keychain or switch to env vars via /jira:setup"
   - 3: "Can't reach Jira. Git commit will still work, Jira update will be skipped."
   - 4: "Authenticated but access denied. Check your Jira permissions."
   - 5: "No credentials stored. Run /jira:setup"

   If exit 3 (network): set JIRA_AVAILABLE=false. Continue with git-only flow.

3. Detect git state:
   ```bash
   git rev-parse --abbrev-ref HEAD
   git status --porcelain
   ```
   - If branch is "HEAD": detached HEAD. Warn user, set DETACHED=true.
   - If `git status` shows "UU" (unmerged): "Merge in progress. Resolve conflicts before committing." Stop.
   - If `.git/rebase-merge` or `.git/rebase-apply` exists: "Rebase in progress. Complete or abort." Stop.

## Step 1: Git Commit [checkpoint]

Run:
```bash
git status
git diff --staged
git diff
```

Show the user a summary: files changed, insertions/deletions.

Detect ticket ID (in order):
1. Parse branch name with regex from config (default: `[A-Z][A-Z0-9]+-[0-9]+`)
   ```bash
   git rev-parse --abbrev-ref HEAD 2>/dev/null | grep -oE '[A-Z][A-Z0-9]+-[0-9]+'
   ```
2. Check conversation context for recently mentioned ticket IDs
3. If DETACHED=true or no ID found: ask user "No ticket ID detected. Enter one or skip?"

Draft commit message using `commit_style` from config:
- If null: use conventional commits format: `type(TICKET): description`
- If set: follow the natural language instruction to format the message

Present to user:
```
Here's what I'll commit:

  feat(PROJ-100): add user profile caching

  Files: 3 changed, 47 insertions(+), 12 deletions(-)
    src/components/UserCache.tsx
    src/hooks/useUserCache.ts
    src/api/user-cache.ts
```

Wait for user: confirm / edit message / abort.
If abort: stop entirely, nothing happens.

## Step 2: Jira Update [checkpoint]

Skip this step entirely if JIRA_AVAILABLE=false (network issue from preamble).

If no ticket ID: ask "No ticket found. Enter one or skip Jira?"
If skip: go to Step 3.

Fetch ticket:
```bash
$PLUGIN_ROOT/bin/jira-api /rest/api/3/issue/TICKET_ID?fields=summary,status,issuetype,assignee,reporter
```
If this fails (rate limit, network): "Couldn't fetch ticket. Skipping Jira update." Go to Step 3.

Extract issue type from response. Look up workflow rule in config:
```bash
$PLUGIN_ROOT/bin/jira-config get-nested "workflows.ISSUE_TYPE.transition_to"
$PLUGIN_ROOT/bin/jira-config get-nested "workflows.ISSUE_TYPE.reassign_to"
```
If no rule for this type, check `workflows.default`.
If transition_to is null: ask user what to do.

Check available transitions:
```bash
$PLUGIN_ROOT/bin/jira-api /rest/api/3/issue/TICKET_ID/transitions
```
If configured transition not in available list: "Transition to 'QA' not available. Available: [list]. Pick one or skip."

Draft Jira comment using `jira_comment_style` from config:
- If null: use structured format with Title, Changes (bullets), Result
- If set: follow the natural language instruction

Present to user:
```
Here's what I'll post to Jira PROJ-100:

  Comment:
    Title: Add user profile caching
    Changes:
    - Added UserCache component with configurable thresholds
    - Created useUserCache hook for data fetching
    - Wired up user-cache API endpoint

  Action: Transition to QA, Reassign to John (reporter)
```

Wait for user: confirm / edit comment / edit action / skip Jira.

## Step 3: Documentation Check [checkpoint]

Run:
```bash
$PLUGIN_ROOT/bin/docs-check --quick
```

If exit 0 (matches found): show affected docs and the matching reference.
```
These docs reference files you changed:

  docs/architecture/overview.md:47
    references: src/api/user-cache.ts

Want me to review and propose updates?
```

If exit 1 (no matches): "No docs reference your changed files. Skip or review anyway?"

If user wants updates: read the affected doc, propose specific edits showing a diff, ask for confirmation per edit.

Wait for user: approve edits / edit / skip.

## Step 4: Execute

Run all confirmed actions:

1. Git commit:
   ```bash
   git add <confirmed files>
   git commit -m "<confirmed message>"
   ```

2. Jira update (if confirmed):
   ```bash
   # Post comment
   $PLUGIN_ROOT/bin/jira-api /rest/api/3/issue/TICKET_ID/comment -X POST -d '<comment JSON>'
   # Transition
   $PLUGIN_ROOT/bin/jira-api /rest/api/3/issue/TICKET_ID/transitions -X POST -d '{"transition":{"id":"<id>"}}'
   # Reassign (if applicable)
   $PLUGIN_ROOT/bin/jira-api /rest/api/3/issue/TICKET_ID/assignee -X PUT -d '{"accountId":"<id>"}'
   ```
   If any Jira call fails: "Commit succeeded. Jira update failed: [error]. You can retry manually."

3. Doc updates (if confirmed): write the approved edits.

Report results:
```
Done:
  Committed: feat(PROJ-100): add user profile caching
  Jira PROJ-100: commented + transitioned to QA + reassigned to reporter
  Updated: docs/architecture/overview.md
```

## Edge Cases

- Abort at step 1: nothing happens
- Skip Jira (step 2): git commit + doc check only
- Skip docs (step 3): git commit + Jira only
- Network fails mid-flow: git commit succeeds, Jira shows specific error
- No docs/ folder: step 3 shows "No docs/ found. Skip."
- Detached HEAD: prompt for ticket ID in step 1
- Merge/rebase in progress: abort before step 1 with clear message
