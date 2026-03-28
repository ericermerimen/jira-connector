#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$(cd "$SCRIPT_DIR/../bin" && pwd)"
FIXTURE_DIR="$SCRIPT_DIR/fixtures"
PASS=0
FAIL=0

# Use a temp dir for test config to avoid touching real config
TEST_HOME="$(mktemp -d)"
export HOME="$TEST_HOME"

cleanup() {
    rm -rf "$TEST_HOME"
}
trap cleanup EXIT

assert_eq() {
    local label="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $label (expected '$expected', got '$actual')"
        FAIL=$((FAIL + 1))
    fi
}

assert_exit_code() {
    local label="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$expected" -eq "$actual" ]]; then
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $label (expected exit $expected, got $actual)"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== jira-config tests ==="

# Test: set and get
echo "-- set and get --"
"$BIN_DIR/jira-config" set jira_url "https://test.atlassian.net"
result="$("$BIN_DIR/jira-config" get jira_url)"
assert_eq "set then get jira_url" "https://test.atlassian.net" "$result"

"$BIN_DIR/jira-config" set jira_email "test@example.com"
result="$("$BIN_DIR/jira-config" get jira_email)"
assert_eq "set then get jira_email" "test@example.com" "$result"

# Test: overwrite existing key
"$BIN_DIR/jira-config" set jira_url "https://updated.atlassian.net"
result="$("$BIN_DIR/jira-config" get jira_url)"
assert_eq "overwrite existing key" "https://updated.atlassian.net" "$result"

# Test: get missing key returns empty
result="$("$BIN_DIR/jira-config" get nonexistent_key || true)"
assert_eq "get missing key" "" "$result"

# Test: validate valid config
echo "-- validate --"
"$BIN_DIR/jira-config" set credential_method "keychain"
"$BIN_DIR/jira-config" set docs_path "docs"
exit_code=0
"$BIN_DIR/jira-config" validate >/dev/null 2>&1 || exit_code=$?
assert_exit_code "validate valid config" 0 "$exit_code"

# Test: validate invalid jira_url
"$BIN_DIR/jira-config" set jira_url "http://not-https.example.com"
exit_code=0
"$BIN_DIR/jira-config" validate >/dev/null 2>&1 || exit_code=$?
assert_exit_code "reject non-https url" 1 "$exit_code"

# Restore valid url
"$BIN_DIR/jira-config" set jira_url "https://test.atlassian.net"

# Test: validate invalid credential_method
"$BIN_DIR/jira-config" set credential_method "plaintext"
exit_code=0
"$BIN_DIR/jira-config" validate >/dev/null 2>&1 || exit_code=$?
assert_exit_code "reject invalid credential_method" 1 "$exit_code"
"$BIN_DIR/jira-config" set credential_method "keychain"

# Test: validate docs_path with traversal
"$BIN_DIR/jira-config" set docs_path "../../etc"
exit_code=0
"$BIN_DIR/jira-config" validate >/dev/null 2>&1 || exit_code=$?
assert_exit_code "reject docs_path with .." 1 "$exit_code"
"$BIN_DIR/jira-config" set docs_path "docs"

# Test: validate docs_path absolute
"$BIN_DIR/jira-config" set docs_path "/etc/passwd"
exit_code=0
"$BIN_DIR/jira-config" validate >/dev/null 2>&1 || exit_code=$?
assert_exit_code "reject absolute docs_path" 1 "$exit_code"
"$BIN_DIR/jira-config" set docs_path "docs"

# Test: validate email with shell metacharacters
"$BIN_DIR/jira-config" set jira_email 'user@test.com;rm -rf /'
exit_code=0
"$BIN_DIR/jira-config" validate >/dev/null 2>&1 || exit_code=$?
assert_exit_code "reject email with metacharacters" 1 "$exit_code"
"$BIN_DIR/jira-config" set jira_email "test@example.com"

# Test: config path
echo "-- path --"
result="$("$BIN_DIR/jira-config" path)"
assert_eq "config path" "$TEST_HOME/.jira-connector/config.yaml" "$result"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
