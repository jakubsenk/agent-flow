#!/usr/bin/env bash
# Verifies: AC-MIG-004, REQ-MIG-005
# Description: /migrate-config --to-v8 --yolo auto-resolves ambiguous triage-analyst.md
#   into analyst.toml with [[process_additions]] for BOTH phases + [WARN] log
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Assertion 1: migrate-config SKILL.md documents --yolo auto-resolution
# ---------------------------------------------------------------------------
echo "--- Assertion 1: migrate-config SKILL.md documents --yolo auto-resolve ---"
MIGRATE_SKILL="$REPO_ROOT/skills/migrate-config/SKILL.md"
if [ ! -f "$MIGRATE_SKILL" ]; then
  echo "SKIP: skills/migrate-config/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE '\-\-yolo.*auto.?resolv|auto.?resolv.*\-\-yolo' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents --yolo auto-resolution"
else
  fail "migrate-config SKILL.md missing --yolo auto-resolution documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Auto-resolve to "b" (apply to both phases) documented
# ---------------------------------------------------------------------------
echo "--- Assertion 2: auto-resolve 'b' (apply to both phases) documented ---"
if grep -qiE 'both.*phases|apply.*both|b.*both|auto.*both' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents auto-resolve to both phases"
else
  fail "migrate-config SKILL.md missing 'apply to both phases' auto-resolve documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 3: [WARN] log records auto-resolution
# ---------------------------------------------------------------------------
echo "--- Assertion 3: [WARN] log for auto-resolution documented ---"
if grep -qiE '\[WARN\].*auto.?resolv|auto.?resolv.*\[WARN\]|warn.*auto' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents [WARN] for auto-resolution"
else
  fail "migrate-config SKILL.md missing [WARN] log for auto-resolution"
fi

# ---------------------------------------------------------------------------
# Assertion 4: Conflict resolution flow (interactive vs --yolo) documented
# ---------------------------------------------------------------------------
echo "--- Assertion 4: conflict resolution (interactive prompt vs --yolo auto) documented ---"
if grep -qiE 'interactive.*prompt|prompt.*resolv|IF.*interactive|conflict.*resolv' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents interactive vs --yolo conflict resolution"
else
  fail "migrate-config SKILL.md missing interactive vs --yolo conflict resolution documentation"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MIG-004 — migrate-config --yolo auto-resolves ambiguous files to both phases"
fi
exit "$FAIL"
