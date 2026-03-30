---
name: commit
description: >
  Commit changes to git and optionally update Jira ticket. Confirmed flow: draft commit message,
  update Jira (if ticket found), check docs, then execute. Nothing fires without user approval.
  Use when user says "/jira:commit" or asks to commit their changes.
---

# /jira:commit -- Commit with Jira Integration

## When to Use

Trigger on: "/jira:commit", "commit my changes", "commit and update Jira", "commit this to PROJ-100", "done with this ticket, commit it"

Do NOT trigger on: "git commit" without Jira context, "push to remote", past-tense references

## CRITICAL RULES

1. **USE AskUserQuestion** for every checkpoint. Proper A/B/C selection UI, not plain text.
2. **WAIT FOR ANSWERS.** After each AskUserQuestion, STOP. Do NOT continue until the user answers.
3. **NEVER SHOW THE API TOKEN.**
4. **NO TICKET = STILL WORKS.** Skip Jira update, continue with git commit + docs check.
5. **COMMIT MESSAGES MUST HAVE A BODY.** Subject line AND `- ` bullet points listing specific changes. No exceptions.

## Plugin Root

```bash
PLUGIN_ROOT=""
for dir in "$HOME/.claude/plugins/marketplaces/jira-connector" "$HOME/.claude/plugins/cache/jira-connector"/*/; do
    [[ -f "$dir/bin/jira-config" ]] && { PLUGIN_ROOT="$dir"; break; }
done
[[ -z "$PLUGIN_ROOT" ]] && { echo "ERROR: Cannot find jira-connector plugin."; exit 1; }
```

## Preamble

Run validation per `references/preamble.md`. Set JIRA_AVAILABLE=true/false based on credential validation exit code. If false, skip Step 2 entirely. Check for merge/rebase in progress (abort if found).

---

## Step 1: Git Commit

Run `git status`, `git diff --staged`, `git diff`. Show summary of changes.

Detect ticket ID from branch name (`[A-Z][A-Z0-9]+-[0-9]+`), then conversation context. If none found, set TICKET_FOUND=false.

Draft commit message using `commit_style` from config (default: conventional commits). If ticket found: `type(TICKET): description`, else `type: description`.

**Always include a body with bullet points.** Example:
```
refactor(PROJ-100): rename legacy model to new convention

- Rename OldModel class to NewModel across all references
- Update imports in 4 consuming components
- Update type definitions in shared types module
```

Show commit details as plain text above AskUserQuestion:
- A) "Commit as shown"
- B) "Edit message"
- C) "Abort"

**STOP and wait.**

---

## Step 2: Jira Update

**If JIRA_AVAILABLE=false OR TICKET_FOUND=false:**
Tell user: "No Jira ticket detected. Skipping Jira update." **STOP and wait** for response.

**If both available:**
Fetch ticket, extract issue type, look up workflow rule from config (fall back to `workflows.default`). Check available transitions. Draft Jira comment using `jira_comment_style` from config:
- **Title**: summary of changes
- **Root Cause** (bugs only): why it occurred
- **Changes**: bullet points
- **Result**: new behavior

Show plan, then AskUserQuestion:
- A) "Post as shown"
- B) "Edit comment"
- C) "Skip Jira"

If transition_to unconfigured for this type, show available transitions as options instead. After user picks, ask: "Remember this choice for all [type] tickets?" If yes, save to config.

**STOP and wait.**

---

## Step 3: Documentation Check

Run `$PLUGIN_ROOT/bin/docs-check --quick`.

**If exit 0 (matches):** AskUserQuestion -- review and suggest updates, or skip.
**If exit 1 (no matches):** AskUserQuestion -- skip docs, or generate a doc entry (learning/gotcha or decision record).

**STOP and wait.**

---

## Step 4: Execute

Run confirmed actions in order:

1. **Git commit** (always, use heredoc for multi-line body)
2. **Jira update** (if confirmed): post comment, transition, reassign. If fails: "Commit succeeded. Jira update failed: [error]."
3. **Doc updates** (if confirmed)

Report with clickable Jira link (`{jira_url}/browse/{TICKET_ID}`):
```
Done:
- Committed: feat(PROJ-100): add user profile caching (abc1234)
- Jira: PROJ-100 commented + transitioned to QA
  https://example.atlassian.net/browse/PROJ-100
- Docs: updated docs/architecture/overview.md
```

## Edge Cases

- No ticket: skip Jira, proceed with commit + docs
- Network fails mid-flow: git succeeds, Jira shows specific error
- No docs/ folder: step 3 reports "No docs found"
- Detached HEAD: no ticket from branch, use no-ticket flow
- Merge/rebase in progress: abort before step 1
