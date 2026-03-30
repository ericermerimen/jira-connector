# Credential Helper Reference

Per-environment credential commands for debugging.

## macOS (Keychain)

```bash
# Store
security add-generic-password -s "jira-connector-token" -a "$USER" -w "<token>"
# Retrieve
security find-generic-password -s "jira-connector-token" -a "$USER" -w
# Delete
security delete-generic-password -s "jira-connector-token" -a "$USER"
```

## Linux (secret-tool)

Requires: `libsecret` + running D-Bus secret service (GNOME Keyring, KDE Wallet, KeePassXC)

```bash
# Store
echo "<token>" | secret-tool store --label "jira-connector token" service "jira-connector" key "token"
# Retrieve
secret-tool lookup service "jira-connector" key "token"
# Delete
secret-tool clear service "jira-connector" key "token"
```

## Environment Variables

```bash
export JIRA_EMAIL="user@company.com"
export JIRA_API_TOKEN="your-api-token"
```

Recommend `.env` file with `chmod 600` over shell profile export. Env vars are visible to child processes and may appear in logs with `set -x`.

## Environment Detection

| Check | Environment |
|---|---|
| `$OSTYPE == darwin*` + `$DISPLAY` or `$TERM_PROGRAM` | macOS desktop |
| `$OSTYPE == darwin*` + no display | macOS headless |
| `$MSYSTEM` set | Windows Git Bash |
| `uname -r` contains microsoft/WSL | Windows WSL2 |
| `$DISPLAY` or `$WAYLAND_DISPLAY` + `secret-tool` available | Linux desktop |
| None of above | Linux headless |
