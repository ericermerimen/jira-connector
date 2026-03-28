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

echo "=== jira-api tests ==="

# Setup env mode with test creds
"$BIN_DIR/jira-config" set credential_method "env"
"$BIN_DIR/jira-config" set jira_url "https://test.atlassian.net"
"$BIN_DIR/jira-config" set jira_email "test@example.com"
export JIRA_API_TOKEN="test-token"
export JIRA_EMAIL="test@example.com"

# Test: missing endpoint shows usage
echo "-- argument validation --"
exit_code=0
"$BIN_DIR/jira-api" 2>/dev/null || exit_code=$?
assert_exit_code "no args shows usage" 1 "$exit_code"

# Test: unreachable URL returns error
echo "-- network errors --"
"$BIN_DIR/jira-config" set jira_url "https://nonexistent-99999.atlassian.net"
exit_code=0
"$BIN_DIR/jira-api" "/rest/api/3/myself" 2>/dev/null || exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    echo "  PASS: unreachable URL returns nonzero ($exit_code)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: unreachable URL should fail"
    FAIL=$((FAIL + 1))
fi

# Test: missing token returns exit 5
echo "-- missing credentials --"
"$BIN_DIR/jira-config" set jira_url "https://test.atlassian.net"
unset JIRA_API_TOKEN
exit_code=0
"$BIN_DIR/jira-api" "/rest/api/3/myself" 2>/dev/null || exit_code=$?
assert_exit_code "missing token exits 5" 5 "$exit_code"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
