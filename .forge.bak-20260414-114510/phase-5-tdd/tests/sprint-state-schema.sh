#!/usr/bin/env bash
# Test: state/schema.md includes sprint and backlog RUN-ID formats
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SCHEMA_FILE="$REPO_ROOT/state/schema.md"

# 1. state/schema.md must exist
if [ ! -f "$SCHEMA_FILE" ]; then
  fail "state/schema.md does not exist"
  exit 1
fi

# 2. Sprint RUN-ID format is defined
# Acceptable patterns: sprint-*, SPRINT-*, sprint_plan-*, sprint-plan-*
if ! grep -qi "sprint.*run.id\|run.id.*sprint\|sprint-[0-9]\|sprint_plan\|SPRINT-" "$SCHEMA_FILE"; then
  fail "state/schema.md missing sprint RUN-ID format definition"
fi

# 3. Backlog RUN-ID format is defined
# Acceptable patterns: backlog-*, BACKLOG-*, create-backlog-*, backlog_creator-*
if ! grep -qi "backlog.*run.id\|run.id.*backlog\|backlog-[0-9]\|create.backlog\|backlog_creator\|BACKLOG-" "$SCHEMA_FILE"; then
  fail "state/schema.md missing backlog RUN-ID format definition"
fi

# 4. schema_version is defined (basic schema health check)
if ! grep -q "schema_version" "$SCHEMA_FILE"; then
  fail "state/schema.md missing schema_version field"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: state/schema.md includes sprint and backlog RUN-ID formats with schema_version"
exit "$FAIL"
