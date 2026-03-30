---
name: docs
description: >
  Full documentation sync. Scans docs for references to changed files, detects stale references
  and dead links, proposes updates with user confirmation. Use before PRs for thorough doc review.
  Use when user says "/jira:docs" or asks to check documentation.
---

# /jira:docs -- Documentation Sync

## When to Use

Trigger this skill when the user says or implies any of:
- "/jira:docs"
- "check docs" or "scan docs"
- "are my docs up to date?"
- "documentation sync"
- "check for stale docs"
- "review docs before PR"
- "which docs need updating?"
- "find broken doc references"

Do NOT trigger on:
- "write documentation" (that is a general writing task)
- "update the README" (that is a specific file edit)
- Questions about reading docs for understanding (e.g., "what do the docs say about X?")

## Plugin Root

```bash
PLUGIN_ROOT=""
for dir in "$HOME/.claude/plugins/marketplaces/jira-connector" "$HOME/.claude/plugins/cache/jira-connector"/*/; do
    [[ -f "$dir/bin/jira-config" ]] && { PLUGIN_ROOT="$dir"; break; }
done
[[ -z "$PLUGIN_ROOT" ]] && { echo "ERROR: Cannot find jira-connector plugin."; exit 1; }
```

## Step 1: Scope [checkpoint]

Ask the user which scope to analyze:

```
What should I compare against?
  A) Current branch vs base branch (auto-detect main/master/development)
  B) Last N commits (default: 5)
  C) Specific commit range
```

Detect base branch:
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```
Fallback: try main, then master, then development.

Check for shallow clone:
```bash
git rev-parse --is-shallow-repository
```
If true: warn "Shallow clone detected. Scope may be incomplete. Run 'git fetch --unshallow' for full history."

Get changed files based on scope:
- A: `git diff --name-only <base>...HEAD`
- B: `git diff --name-only HEAD~N`
- C: `git diff --name-only <range>`

## Step 2: Analysis

**Phase 1 (script, fast):**
```bash
$PLUGIN_ROOT/bin/docs-check --full --base <ref>
```
This finds:
- Exact file path matches (docs referencing changed files)
- Stale references (docs referencing files that no longer exist)
- Dead links in README.md index

**Phase 2 (LLM, on flagged docs only):**
For each doc flagged in phase 1, read the doc content and the changed code. Analyze:
- Do function/component names in the doc match what's in the code?
- Does the doc describe behavior that was modified?
- Is the doc's description still accurate?

Token budget: phase 1 identifies candidates (~100 tokens), phase 2 reads only those candidates.

## Step 3: Report [checkpoint]

Present findings in categories:

```
Documentation scan complete (12 docs checked):

Needs update (2):
  docs/architecture/overview.md
    Line 47: references src/api/user-cache.ts (you renamed a function)

  docs/guides/add-new-page-route.md
    Line 23: describes old middleware path (you moved it)

Possibly stale (1):
  docs/operations/regions.md
    references src/config/regions.ts (deleted in this branch)

Up to date (9): no changes needed
```

If >20 docs flagged: "Large refactor detected. Review top 10 by relevance?"

Wait for user: fix all / fix specific ones / review each / skip.

## Step 4: Fix [checkpoint per doc]

For each doc the user wants fixed, read the full doc and the relevant code changes. Propose a specific edit in diff format:

```
docs/architecture/overview.md:

- The user profiles API uses `getUserCache()` to fetch data.
+ The user profiles API uses `fetchUserCache()` to fetch data.
```

Wait for user per doc: approve / edit / skip.

## Step 5: Summary + Optional Commit

Report:
```
Done:
  Updated 2 docs
  Skipped 1 stale reference (user declined)
  9 docs unchanged
```

Ask: "Commit these doc changes as a separate commit?"
If yes:
```bash
git add <updated docs>
git commit -m "docs: update references for user profile feature"
```
