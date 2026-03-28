---
name: commit
description: >
  Commit changes to git and optionally update Jira ticket. Confirmed flow: draft commit message,
  update Jira (if ticket found), check docs, then execute. Nothing fires without user approval.
  Use when user says "/jira:commit" or asks to commit their changes.
---

# /jira:commit -- Commit with Jira Integration

## CRITICAL RULES

1. **USE AskUserQuestion** for every checkpoint. Proper A/B/C selection UI, not plain text.
2. **WAIT FOR ANSWERS.** After each AskUserQuestion, STOP. Do NOT continue until the user answers.
3. **NEVER SHOW THE API TOKEN** in any output.
4. **NO TICKET = STILL WORKS.** If no Jira ticket is found, skip Jira update gracefully and continue with git commit + docs check. The commit flow works perfectly without Jira.

## Plugin Root

Find the plugin root by locating `bin/jira-config`:
```bash
PLUGIN_ROOT=""
for dir in "$HOME/.claude/plugins/marketplaces/jira-connector" "$HOME/.claude/plugins/cache/jira-connector"/*/; do
    [[ -f "$dir/bin/jira-config" ]] && { PLUGIN_ROOT="$dir"; break; }
done
[[ -z "$PLUGIN_ROOT" ]] && { echo "ERROR: Cannot find jira-connector plugin."; exit 1; }
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
   - 0: continue, set JIRA_AVAILABLE=true
   - 1: "Jira token is invalid. Regenerate at id.atlassian.com and run /jira:setup." Set JIRA_AVAILABLE=false.
   - 2: "Keychain access denied." Set JIRA_AVAILABLE=false.
   - 3: "Can't reach Jira. Git commit will still work, Jira update will be skipped." Set JIRA_AVAILABLE=false.
   - 4: "Access denied." Set JIRA_AVAILABLE=false.
   - 5: "No credentials stored. Run /jira:setup." Set JIRA_AVAILABLE=false.

   If JIRA_AVAILABLE=false: continue with git-only flow (Steps 1, 3, 4). Skip Step 2 entirely.

3. Detect git state:
   ```bash
   git rev-parse --abbrev-ref HEAD
   git status --porcelain
   ```
   - If branch is "HEAD": detached HEAD. Warn user, set DETACHED=true.
   - If `git status` shows "UU" (unmerged): "Merge in progress. Resolve conflicts before committing." Stop.
   - If `.git/rebase-merge` or `.git/rebase-apply` exists: "Rebase in progress. Complete or abort." Stop.

---

## Step 1: Git Commit

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
3. If no ID found: set TICKET_FOUND=false (do NOT ask the user yet, handle in Step 2)

Draft commit message using `commit_style` from config:
- If null: use conventional commits format
- If ticket found: `type(TICKET): description`
- If no ticket: `type: description` (no scope)
- If custom style set: follow the natural language instruction

Use AskUserQuestion:
- Question: "Here's the commit I'll create. Look good?"
- Show the draft message and file summary in the question text
- A) "Commit as shown" with description showing the commit message
- B) "Edit message" with description "I'll suggest changes via Other"
- C) "Abort" with description "Cancel everything, no changes made"

**STOP and wait.**

If C (abort): stop entirely, nothing happens.
If B: let user type new message, then re-present.

---

## Step 2: Jira Update

**If JIRA_AVAILABLE=false OR TICKET_FOUND=false:**

Tell the user clearly:
"No Jira ticket was detected for this commit. Skipping Jira update. If you want to link a ticket, mention its ID now, otherwise we'll proceed with the git commit and docs check."

**STOP and wait for the user's response before continuing.**

**If JIRA_AVAILABLE=true AND TICKET_FOUND=true:**

Fetch ticket:
```bash
$PLUGIN_ROOT/bin/jira-api /rest/api/3/issue/TICKET_ID?fields=summary,status,issuetype,assignee,reporter
```
If this fails (rate limit, network): "Couldn't fetch ticket details. Skipping Jira update." Go to Step 3.

Extract issue type from response. Look up workflow rule in config:
```bash
$PLUGIN_ROOT/bin/jira-config get-nested "workflows.ISSUE_TYPE.transition_to"
$PLUGIN_ROOT/bin/jira-config get-nested "workflows.ISSUE_TYPE.reassign_to"
```
If no rule for this type, check `workflows.default`.

Check available transitions:
```bash
$PLUGIN_ROOT/bin/jira-api /rest/api/3/issue/TICKET_ID/transitions
```

Draft Jira comment using `jira_comment_style` from config:
- If null: use structured format with Title, Changes (bullets), Result
- If set: follow the natural language instruction

Use AskUserQuestion:
- Question: Show the full Jira update plan (comment text + transition + reassignment)
- A) "Post to Jira as shown" with description summarizing: comment + transition + reassign
- B) "Edit comment" with description "I'll modify the comment text"
- C) "Skip Jira update" with description "Just do the git commit, don't touch Jira"

If transition_to is null (unconfigured type), show available transitions as options instead:
- Question: "What should happen to TICKET_ID (Type: Bug, Status: In Progress)?"
- A) "Move to QA" (or whatever statuses are available)
- B) "Move to Done"
- C) "Just add a comment, no transition"
- D) "Skip Jira entirely"

**STOP and wait.**

---

## Step 3: Documentation Check

Run:
```bash
$PLUGIN_ROOT/bin/docs-check --quick
```

**If exit 0 (matches found):**

Use AskUserQuestion:
- Question: "These docs reference files you changed: [list files + line references]. Want me to review and propose updates?"
- A) "Review and suggest updates" with description "I'll read the docs and propose specific edits"
- B) "Skip docs" with description "I'll handle docs separately"

**STOP and wait.**

If A: read each affected doc, propose specific edits showing a diff, then use AskUserQuestion per doc:
- A) "Apply this edit"
- B) "Skip this doc"

**If exit 1 (no matches):**

Tell user: "No docs reference your changed files. Moving to commit."

Go to Step 4.

---

## Step 4: Execute

Run all confirmed actions in order:

1. **Git commit** (always):
   ```bash
   git add <confirmed files>
   git commit -m "<confirmed message>"
   ```

2. **Jira update** (only if confirmed in Step 2):
   ```bash
   # Post comment
   $PLUGIN_ROOT/bin/jira-api /rest/api/3/issue/TICKET_ID/comment -X POST -d '<comment JSON>'
   # Transition
   $PLUGIN_ROOT/bin/jira-api /rest/api/3/issue/TICKET_ID/transitions -X POST -d '{"transition":{"id":"<id>"}}'
   # Reassign (if applicable)
   $PLUGIN_ROOT/bin/jira-api /rest/api/3/issue/TICKET_ID/assignee -X PUT -d '{"accountId":"<id>"}'
   ```
   If any Jira call fails: "Commit succeeded. Jira update failed: [error]. You can retry manually."

3. **Doc updates** (only if confirmed in Step 3): write the approved edits.

Report results:
```
Done:
  Committed: feat(PROJ-100): add user profile caching
  Jira PROJ-100: commented + transitioned to QA + reassigned to reporter
  Updated: docs/architecture/overview.md
```

Or for no-ticket commits:
```
Done:
  Committed: fix: resolve button alignment on mobile
  Jira: skipped (no ticket)
  Docs: no affected docs found
```

## Edge Cases

- Abort at step 1: nothing happens
- No ticket found: skip Jira, proceed with commit + docs
- Skip Jira (step 2): git commit + doc check only
- Skip docs (step 3): git commit + Jira only
- Network fails mid-flow: git commit succeeds, Jira shows specific error
- No docs/ folder: step 3 reports "No docs found" and proceeds
- Detached HEAD: commit works, no ticket ID from branch (no-ticket flow)
- Merge/rebase in progress: abort before step 1 with clear message
