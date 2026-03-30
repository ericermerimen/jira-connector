# Shared Preamble

Run this validation at the start of every skill and agent invocation.

## Steps

1. Check config exists and is valid:
   ```bash
   bin/jira-config validate
   ```
   If nonzero: show error, tell user "Run /jira:setup to configure."

2. Merge per-project config:
   ```bash
   bin/jira-config resolve
   ```

3. Validate credentials:
   ```bash
   bin/jira-cred validate
   ```
   - 0: OK
   - 1: "Jira token is invalid. Regenerate at https://id.atlassian.com/manage-profile/security/api-tokens and run /jira:setup"
   - 2: "Keychain access denied. Unlock your keychain or switch to env vars via /jira:setup"
   - 3: "Can't reach Jira. Git operations still work, Jira updates skipped."
   - 4: "Authenticated but access denied. Check Jira permissions."
   - 5: "No credentials stored. Run /jira:setup"

4. Detect git state:
   ```bash
   git rev-parse --abbrev-ref HEAD
   ```
   If "HEAD": detached state, warn user. Check for merge/rebase in progress.

## Error Handling

If credentials fail, degrade gracefully:
- /jira:commit: git commit works, Jira step skipped
- /jira:docs: can scan docs, cannot fetch ticket context
- jira-reader: show error, suggest /jira:setup

Never show raw curl output, HTTP status codes, or stack traces. Always include the next step the user should take. If a Jira operation fails mid-flow, confirm what succeeded (e.g., "Commit succeeded. Jira update failed: permission denied.").
