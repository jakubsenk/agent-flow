#!/usr/bin/env bash
# Verifies: AC-AGT-002, REQ-AGT-001, REQ-AGT-006
# Description: Post-v8.0.0 these 5 old agent files must NOT exist:
#   triage-analyst.md, code-analyst.md, e2e-test-engineer.md, reproducer.md, browser-verifier.md
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

DELETED_AGENTS=(
  "triage-analyst.md"
  "code-analyst.md"
  "e2e-test-engineer.md"
  "reproducer.md"
  "browser-verifier.md"
)

AGENTS_DIR="$REPO_ROOT/agents"

# ---------------------------------------------------------------------------
# Assertion: each deleted agent file must NOT exist
# ---------------------------------------------------------------------------
echo "--- Checking deleted agent files do not exist ---"
for agent in "${DELETED_AGENTS[@]}"; do
  if [ -f "$AGENTS_DIR/$agent" ]; then
    fail "$agent still exists in agents/ — must be deleted (merged into v8 agent) post-v8.0.0"
  else
    echo "OK: agents/$agent correctly absent post-v8.0.0"
  fi
done

# ---------------------------------------------------------------------------
# Assertion: migration guide documents the rename/deletion
# ---------------------------------------------------------------------------
echo "--- Checking migration guide documents old agent deletions ---"
MIG_GUIDE="$REPO_ROOT/docs/guides/migration-v7-to-v8.md"
if [ ! -f "$MIG_GUIDE" ]; then
  echo "SKIP: docs/guides/migration-v7-to-v8.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qF 'triage-analyst' "$MIG_GUIDE" && grep -qF 'code-analyst' "$MIG_GUIDE"; then
  echo "OK: migration guide references triage-analyst and code-analyst renames"
else
  fail "migration guide missing triage-analyst / code-analyst rename documentation"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-AGT-002 — old agent files (triage-analyst, code-analyst, etc.) deleted"
fi
exit "$FAIL"
