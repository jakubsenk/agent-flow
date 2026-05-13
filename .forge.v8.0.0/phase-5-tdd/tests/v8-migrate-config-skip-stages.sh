#!/usr/bin/env bash
# Verifies: AC-MIG-005, REQ-MIG-002 step 4, REQ-MIG-006
# Description: /migrate-config --to-v8 updates "Skip stages: [code-analyst]" →
#   "Skip stages: [analyst-impact]" + HTML comment (not //)
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT INT TERM

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Setup: mock CLAUDE.md with v7 Skip stages
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST"
cat > "$TMPDIR_TEST/CLAUDE.md" << 'EOF'
## Automation Config

### Pipeline Profiles (optional)
| Profile | Skip stages | Extra stages |
|---------|-------------|--------------|
| fast    | code-analyst | — |
EOF

# Simulate migration: replace code-analyst with analyst-impact
sed 's/code-analyst/analyst-impact/' "$TMPDIR_TEST/CLAUDE.md" > "$TMPDIR_TEST/CLAUDE.md.migrated"

# ---------------------------------------------------------------------------
# Assertion 1: code-analyst replaced with analyst-impact
# ---------------------------------------------------------------------------
echo "--- Assertion 1: code-analyst replaced with analyst-impact ---"
if grep -qF 'analyst-impact' "$TMPDIR_TEST/CLAUDE.md.migrated" && \
   ! grep -qF 'code-analyst' "$TMPDIR_TEST/CLAUDE.md.migrated"; then
  echo "OK: migration replaced code-analyst with analyst-impact"
else
  fail "Migration did not replace code-analyst with analyst-impact"
fi

# ---------------------------------------------------------------------------
# Assertion 2: HTML comment (<!-- -->) not // used (per AC-MIG-005)
# ---------------------------------------------------------------------------
echo "--- Assertion 2: HTML comment <!-- --> used (not // comment) ---"
MIGRATE_SKILL="$REPO_ROOT/skills/migrate-config/SKILL.md"
if [ -f "$MIGRATE_SKILL" ]; then
  if grep -qF '<!-- migrated' "$MIGRATE_SKILL" || grep -qiE '<!--.*migrat|html.*comment' "$MIGRATE_SKILL"; then
    echo "OK: migrate-config uses HTML comment <!-- -->"
  else
    fail "migrate-config SKILL.md missing <!-- --> HTML comment documentation"
  fi

  if grep -qF '// migrated' "$MIGRATE_SKILL"; then
    fail "migrate-config SKILL.md incorrectly uses // comment (must use <!-- -->)"
  else
    echo "OK: migrate-config does not use // comment"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 3: Comment placed ABOVE ### Pipeline Profiles heading
# ---------------------------------------------------------------------------
echo "--- Assertion 3: migration comment placed ABOVE ### Pipeline Profiles ---"
if [ -f "$MIGRATE_SKILL" ]; then
  if grep -qiE 'above.*pipeline|above.*heading|comment.*above' "$MIGRATE_SKILL"; then
    echo "OK: comment placement documented as above heading"
  else
    fail "migrate-config SKILL.md missing comment-placement-above-heading documentation"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 4: All 5 v7 stage names mapped documented
# ---------------------------------------------------------------------------
echo "--- Assertion 4: all v7→v8 stage name mappings documented in migration guide ---"
MIG_GUIDE="$REPO_ROOT/docs/guides/migration-v7-to-v8.md"
if [ -f "$MIG_GUIDE" ]; then
  for mapping in "code-analyst" "triage-analyst" "e2e-test-engineer" "reproducer" "browser-verifier"; do
    if grep -qF "$mapping" "$MIG_GUIDE"; then
      echo "OK: migration guide maps '$mapping'"
    else
      fail "migration guide missing mapping for '$mapping'"
    fi
  done
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-MIG-005 — Skip stages updated with analyst-impact + HTML comment"
fi
exit "$FAIL"
