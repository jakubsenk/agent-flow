#!/usr/bin/env bash
# Test: State management infrastructure exists with required structure
# Validates: state/schema.md exists with schema_version, core/state-manager.md exists with
#            Purpose, Input Contract, Output Contract, Failure Handling sections
# PR 1: State management
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# AC-2.4: state/ directory and schema.md exist with schema_version
if [ ! -d "$REPO_ROOT/state" ]; then
  fail "state/ directory does not exist"
fi

if [ ! -f "$REPO_ROOT/state/schema.md" ]; then
  fail "state/schema.md does not exist"
fi

if ! grep -q "schema_version" "$REPO_ROOT/state/schema.md"; then
  fail "state/schema.md does not contain 'schema_version' field"
fi

# core/state-manager.md exists with required contract sections
STATE_MGR="$REPO_ROOT/core/state-manager.md"
if [ ! -f "$STATE_MGR" ]; then
  fail "core/state-manager.md does not exist"
else
  for section in "## Purpose" "## Input" "## Output" "## Failure"; do
    if ! grep -q "$section" "$STATE_MGR"; then
      fail "core/state-manager.md missing section: $section"
    fi
  done

  # AC-4.4: state-manager.md specifies atomic write protocol (tmp + rename)
  if ! grep -q "\.tmp" "$STATE_MGR"; then
    fail "core/state-manager.md missing .tmp atomic write pattern"
  fi
  if ! grep -qi "rename" "$STATE_MGR"; then
    fail "core/state-manager.md missing rename step in atomic write protocol"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: State management infrastructure (state/schema.md + core/state-manager.md) is valid"
exit "$FAIL"
