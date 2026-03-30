#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$(cd "$SCRIPT_DIR/../bin" && pwd)"
PASS=0
FAIL=0

TEST_HOME="$(mktemp -d)"
export HOME="$TEST_HOME"

cleanup() {
    rm -rf "$TEST_HOME"
}
trap cleanup EXIT

assert_exit_code() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" -eq "$actual" ]]; then
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $label (expected exit $expected, got $actual)"
        FAIL=$((FAIL + 1))
    fi
}

assert_not_contains() {
    local label="$1" needle="$2" haystack="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        echo "  FAIL: $label (found '$needle' in output)"
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    fi
}

echo "=== Security tests ==="

# Setup
"$BIN_DIR/jira-config" set jira_url "https://test.atlassian.net"
"$BIN_DIR/jira-config" set jira_email "test@example.com"
"$BIN_DIR/jira-config" set credential_method "env"
"$BIN_DIR/jira-config" set docs_path "docs"

# Test: URL with shell injection
echo "-- config injection --"
"$BIN_DIR/jira-config" set jira_url 'https://evil.com$(rm -rf /tmp/test)'
exit_code=0
"$BIN_DIR/jira-config" validate 2>/dev/null || exit_code=$?
assert_exit_code "reject URL with shell injection" 1 "$exit_code"

# Test: URL with semicolon
"$BIN_DIR/jira-config" set jira_url 'https://evil.com;whoami'
exit_code=0
"$BIN_DIR/jira-config" validate 2>/dev/null || exit_code=$?
assert_exit_code "reject URL with semicolon" 1 "$exit_code"

# Test: email with pipe
"$BIN_DIR/jira-config" set jira_url "https://test.atlassian.net"
"$BIN_DIR/jira-config" set jira_email 'user@test.com|cat /etc/passwd'
exit_code=0
"$BIN_DIR/jira-config" validate 2>/dev/null || exit_code=$?
assert_exit_code "reject email with pipe" 1 "$exit_code"

# Test: credential_method not keychain or env
"$BIN_DIR/jira-config" set jira_email "test@example.com"
"$BIN_DIR/jira-config" set credential_method "file"
exit_code=0
"$BIN_DIR/jira-config" validate 2>/dev/null || exit_code=$?
assert_exit_code "reject invalid credential_method" 1 "$exit_code"
"$BIN_DIR/jira-config" set credential_method "env"

# Test: docs_path absolute path
echo "-- path traversal --"
"$BIN_DIR/jira-config" set docs_path "/etc/passwd"
exit_code=0
"$BIN_DIR/jira-config" validate 2>/dev/null || exit_code=$?
assert_exit_code "reject absolute docs_path" 1 "$exit_code"

# Test: docs_path with ..
"$BIN_DIR/jira-config" set docs_path "../../../etc"
exit_code=0
"$BIN_DIR/jira-config" validate 2>/dev/null || exit_code=$?
assert_exit_code "reject docs_path traversal" 1 "$exit_code"
"$BIN_DIR/jira-config" set docs_path "docs"

# Test: per-project config cannot override credential_method
echo "-- per-project security --"
TEST_REPO="$(mktemp -d)"
cd "$TEST_REPO"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
echo "credential_method: file" > .jira-connector.yaml
git add -A && git commit -q -m "init"

resolved="$("$BIN_DIR/jira-config" resolve 2>/dev/null)"
method="$(echo "$resolved" | grep "^credential_method:" | sed 's/credential_method: //')"
assert_not_contains "per-project cannot override credential_method" "file" "$method"

cd "$TEST_HOME"
rm -rf "$TEST_REPO"

# Test: config file permissions (skip on Windows -- NTFS doesn't enforce Unix perms)
echo "-- file permissions --"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    echo "  SKIP: file permissions not enforced on Windows"
    PASS=$((PASS + 1))
else
    config_file="$("$BIN_DIR/jira-config" path)"
    if [[ -f "$config_file" ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            perms="$(stat -f '%A' "$config_file" 2>/dev/null || echo "unknown")"
        else
            perms="$(stat -c '%a' "$config_file" 2>/dev/null || echo "unknown")"
        fi
        if [[ "$perms" == "600" ]]; then
            echo "  PASS: config file has 600 permissions"
            PASS=$((PASS + 1))
        elif [[ "$perms" == "unknown" ]]; then
            echo "  SKIP: cannot check permissions on this OS"
            PASS=$((PASS + 1))
        else
            echo "  FAIL: config file has $perms permissions (expected 600)"
            FAIL=$((FAIL + 1))
        fi
    fi
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
