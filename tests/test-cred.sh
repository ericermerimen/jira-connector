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

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $label (expected '$expected', got '$actual')"
        FAIL=$((FAIL + 1))
    fi
}

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

echo "=== jira-cred tests ==="

# Setup config for env mode (avoids touching real keychain)
"$BIN_DIR/jira-config" set credential_method "env"
"$BIN_DIR/jira-config" set jira_url "https://test.atlassian.net"

# Test: detect-env returns a known environment type
echo "-- detect-env --"
result="$("$BIN_DIR/jira-cred" detect-env)"
case "$result" in
    macos-desktop|macos-headless|linux-desktop|linux-desktop-no-secretool|linux-headless|windows-wsl|windows-gitbash)
        echo "  PASS: detect-env returned known type ($result)"
        PASS=$((PASS + 1))
        ;;
    *)
        echo "  FAIL: detect-env returned unknown type ($result)"
        FAIL=$((FAIL + 1))
        ;;
esac

# Test: get token from env var
echo "-- env var mode --"
export JIRA_EMAIL="test@example.com"
export JIRA_API_TOKEN="test-token-123"

result="$("$BIN_DIR/jira-cred" get email)"
assert_eq "get email from env" "test@example.com" "$result"

result="$("$BIN_DIR/jira-cred" get token)"
assert_eq "get token from env" "test-token-123" "$result"

# Test: missing env var returns exit 5
unset JIRA_API_TOKEN
exit_code=0
"$BIN_DIR/jira-cred" get token 2>/dev/null || exit_code=$?
assert_exit_code "missing token exits 5" 5 "$exit_code"

# Restore for other tests
export JIRA_API_TOKEN="test-token-123"

# Test: set in env mode prints instructions
echo "-- set in env mode --"
result="$(echo "tok-123" | "$BIN_DIR/jira-cred" set "user@test.com")"
echo "$result" | grep -q "JIRA_EMAIL" && {
    echo "  PASS: set in env mode shows env var instructions"
    PASS=$((PASS + 1))
} || {
    echo "  FAIL: set in env mode should show env var instructions"
    FAIL=$((FAIL + 1))
}

# Test: validate with unreachable server returns exit 3
echo "-- validate --"
"$BIN_DIR/jira-config" set jira_url "https://nonexistent-12345.atlassian.net"
exit_code=0
"$BIN_DIR/jira-cred" validate 2>/dev/null || exit_code=$?
# Should be 3 (timeout) or 1 (DNS fail maps to various codes)
if [[ $exit_code -ne 0 ]]; then
    echo "  PASS: validate with bad URL returns nonzero ($exit_code)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: validate with bad URL should fail"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
