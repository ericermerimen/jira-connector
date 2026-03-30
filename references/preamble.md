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

## User-Friendly Error Formatting

When `jira-api` or `jira-cred` returns an error, NEVER show raw curl output, HTTP status codes, or stack traces to the user. Translate exit codes into clear, actionable messages:

| Exit Code | Raw Error | Show to User |
|---|---|---|
| 1 (401) | `ERROR: Authentication failed (401)` | "Your Jira token is invalid or expired. Regenerate it at https://id.atlassian.com/manage-profile/security/api-tokens and run `/jira:setup`." |
| 3 | `ERROR: Network timeout` | "Cannot reach Jira. Check your internet connection or VPN. Git operations will still work." |
| 4 (403) | `ERROR: Access denied (403)` | "Permission denied. Your Jira account does not have access to this resource. Check your project permissions in Jira admin." |
| 5 | `ERROR: Credential 'token' not found` | "No Jira credentials found. Run `/jira:setup` to connect your account." |

Rules:
- Always include the next step the user should take
- Never expose HTTP status codes, curl flags, or response bodies
- If multiple errors occur, show only the most relevant one
- If a Jira operation fails mid-flow, confirm what DID succeed (e.g., "Commit succeeded. Jira update failed: permission denied.")
