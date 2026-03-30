#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$(cd "$SCRIPT_DIR/../bin" && pwd)"
PASS=0
FAIL=0

TEST_HOME="$(mktemp -d)"
export HOME="$TEST_HOME"

# Create a test git repo with docs
TEST_REPO="$(mktemp -d)"

cleanup() {
    rm -rf "$TEST_HOME" "$TEST_REPO"
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

echo "=== docs-check tests ==="

# Setup config
"$BIN_DIR/jira-config" set docs_path "docs"

# Setup test repo
cd "$TEST_REPO"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
mkdir -p docs src
echo "# Docs\nSee [architecture](architecture/)" > docs/README.md
echo "# Architecture\nThe main file is src/app.ts" > docs/architecture.md
echo "console.log('hello')" > src/app.ts
git add -A
git commit -q -m "initial"

# Test: no changes = no matches (exit 1)
echo "-- no changes --"
exit_code=0
"$BIN_DIR/docs-check" --quick 2>/dev/null || exit_code=$?
assert_exit_code "no changes = no matches" 1 "$exit_code"

# Test: change a referenced file = match found (exit 0)
echo "-- referenced file changed --"
echo "console.log('updated')" > src/app.ts
git add src/app.ts
exit_code=0
"$BIN_DIR/docs-check" --quick 2>/dev/null || exit_code=$?
assert_exit_code "changed file referenced in docs = match" 0 "$exit_code"
git checkout -- src/app.ts 2>/dev/null || true

# Test: docs_path traversal blocked
echo "-- security --"
"$BIN_DIR/jira-config" set docs_path "../../etc"
exit_code=0
"$BIN_DIR/docs-check" --quick 2>/dev/null || exit_code=$?
assert_exit_code "docs_path traversal blocked" 2 "$exit_code"
"$BIN_DIR/jira-config" set docs_path "docs"

# Test: no docs dir = no matches
echo "-- no docs dir --"
"$BIN_DIR/jira-config" set docs_path "nonexistent"
exit_code=0
"$BIN_DIR/docs-check" --quick 2>/dev/null || exit_code=$?
assert_exit_code "missing docs dir = no matches" 1 "$exit_code"
"$BIN_DIR/jira-config" set docs_path "docs"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
