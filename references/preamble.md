# Shared Preamble

Run this validation at the start of every skill and agent invocation.

## Steps

1. Check config exists and is valid:
   ```bash
   bin/jira-config validate
   ```
   If exit code is nonzero, show the error and tell user: "Run /jira:setup to configure."

2. Merge per-project config:
   ```bash
   bin/jira-config resolve
   ```
   Use the resolved config for all subsequent operations.

3. Validate credentials:
   ```bash
   bin/jira-cred validate
   ```
   Handle exit codes:
   - 0: OK, continue
   - 1: "Jira token is invalid. Regenerate at https://id.atlassian.com/manage-profile/security/api-tokens and run /jira:setup"
   - 2: "Keychain access denied. Unlock your keychain or switch to env vars via /jira:setup"
   - 3: "Can't reach Jira. Check your connection. Git operations will still work, Jira updates will be skipped."
   - 4: "Authenticated but access denied. Check your Jira permissions."
   - 5: "No credentials stored. Run /jira:setup"

4. Detect git state:
   ```bash
   git rev-parse --abbrev-ref HEAD
   ```
   - If output is "HEAD": detached HEAD state. Warn user, prompt for ticket ID.
   - Check `git status` for merge/rebase in progress.

## Error Handling

If credentials fail (exit 1-5), skills should degrade gracefully:
- /jira:commit: git commit still works, Jira step skipped with error message
- /jira:docs: can still scan docs, but cannot fetch ticket context
- jira-reader agent: show error, suggest /jira:setup
