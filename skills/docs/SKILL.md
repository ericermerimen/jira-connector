---
name: docs
description: >
  Full documentation sync. Scans docs for references to changed files, detects stale references
  and dead links, proposes updates with user confirmation. Use before PRs for thorough doc review.
  Use when user says "/jira:docs" or asks to check documentation.
---

# /jira:docs -- Documentation Sync

## When to Use

Trigger on: "/jira:docs", "check docs", "scan docs", "are my docs up to date?", "review docs before PR"

Do NOT trigger on: "write documentation", "update the README", questions about reading docs

## Plugin Root

```bash
PLUGIN_ROOT=""
for dir in "$HOME/.claude/plugins/marketplaces/jira-connector" "$HOME/.claude/plugins/cache/jira-connector"/*/; do
    [[ -f "$dir/bin/jira-config" ]] && { PLUGIN_ROOT="$dir"; break; }
done
[[ -z "$PLUGIN_ROOT" ]] && { echo "ERROR: Cannot find jira-connector plugin."; exit 1; }
```

## Step 1: Scope [checkpoint]

Ask scope via AskUserQuestion:
- A) Current branch vs base (auto-detect main/master/development)
- B) Last N commits (default: 5)
- C) Specific commit range

Detect base: `git symbolic-ref refs/remotes/origin/HEAD`, fallback main/master/development.
Warn if shallow clone.

## Step 2: Analysis

**Phase 1 (script):** `$PLUGIN_ROOT/bin/docs-check --full --base <ref>` -- finds path matches, stale references, dead links.

**Phase 2 (LLM, flagged docs only):** Read doc + changed code. Check if names, behavior descriptions, and paths still match.

## Step 3: Report [checkpoint]

```
Documentation scan complete (12 docs checked):

Needs update (2):
  docs/architecture/overview.md
    Line 47: references src/api/user-cache.ts (renamed function)

Possibly stale (1):
  docs/operations/regions.md
    references src/config/regions.ts (deleted)

Up to date (9)
```

If >20 flagged: "Large refactor detected. Review top 10 by relevance?"

## Step 4: Fix [checkpoint per doc]

For each doc, propose specific diff. Wait for user: approve / edit / skip.

## Step 5: Summary + Optional Commit

Report what was updated/skipped. Ask: "Commit doc changes as a separate commit?"
