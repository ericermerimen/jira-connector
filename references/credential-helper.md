# Credential Helper Reference

Per-environment credential commands for debugging.

## macOS (Keychain)

Store:
```bash
security add-generic-password -s "jira-connector-token" -a "$USER" -w "<token>"
```

Retrieve:
```bash
security find-generic-password -s "jira-connector-token" -a "$USER" -w
```

Delete:
```bash
security delete-generic-password -s "jira-connector-token" -a "$USER"
```

## Linux (secret-tool)

Requires: `libsecret` + running D-Bus secret service (GNOME Keyring, KDE Wallet, KeePassXC)

Store:
```bash
echo "<token>" | secret-tool store --label "jira-connector token" service "jira-connector" key "token"
```

Retrieve:
```bash
secret-tool lookup service "jira-connector" key "token"
```

Delete:
```bash
secret-tool clear service "jira-connector" key "token"
```

## Environment Variables

Set in shell profile (.bashrc, .zshrc) or .env file:
```bash
export JIRA_EMAIL="user@company.com"
export JIRA_API_TOKEN="your-api-token"
```

Security notes:
- Visible in `ps aux` if used in command args (we pipe via stdin instead)
- Visible to child processes via /proc on Linux
- May appear in logs if `set -x` is enabled
- Recommend .env file with `chmod 600` over shell profile export

## Environment Detection Logic

| Check | Environment |
|---|---|
| `$OSTYPE == darwin*` + `$DISPLAY` or `$TERM_PROGRAM` | macOS desktop |
| `$OSTYPE == darwin*` + no display | macOS headless |
| `$MSYSTEM` set | Windows Git Bash |
| `uname -r` contains microsoft/WSL | Windows WSL2 |
| `$DISPLAY` or `$WAYLAND_DISPLAY` + `secret-tool` available | Linux desktop |
| `$DISPLAY` or `$WAYLAND_DISPLAY` + no `secret-tool` | Linux desktop (no secret-tool) |
| None of above | Linux headless |
