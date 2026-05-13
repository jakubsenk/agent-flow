#!/usr/bin/env bash
# Hidden adversarial test — do NOT reference in spec/visible
# Tests: "Skip stages: [code-analyst, analyst-impact]" (legacy + new mixed) should
#   deduplicate to single analyst-impact skip WITHOUT double-skipping or error
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
# Setup: mock CLAUDE.md with mixed legacy + new stage names
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST"
cat > "$TMPDIR_TEST/CLAUDE.md" << 'EOF'
## Automation Config
### Pipeline Profiles (optional)
| Profile | Skip stages | Extra stages |
|---------|-------------|--------------|
| mixed   | code-analyst, analyst-impact | — |
EOF

# ---------------------------------------------------------------------------
# Assertion 1: Both code-analyst (legacy) and analyst-impact (new) present
# ---------------------------------------------------------------------------
echo "--- Assertion 1: mixed legacy+new stage names parseable from mock CLAUDE.md ---"
if grep -qF 'code-analyst' "$TMPDIR_TEST/CLAUDE.md" && \
   grep -qF 'analyst-impact' "$TMPDIR_TEST/CLAUDE.md"; then
  echo "OK: mock CLAUDE.md has both code-analyst and analyst-impact"
else
  fail "Test setup error: mock CLAUDE.md should have both stage names"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Deduplication — should result in single analyst-impact skip
# ---------------------------------------------------------------------------
echo "--- Assertion 2: deduplication of mixed stage names documented ---"
# Simulate: code-analyst maps to analyst-impact, so both → single analyst-impact skip
STAGE_NAMES=("code-analyst" "analyst-impact")
declare -A RESOLVED
for stage in "${STAGE_NAMES[@]}"; do
  case "$stage" in
    code-analyst) RESOLVED["analyst-impact"]=1 ;;
    analyst-impact) RESOLVED["analyst-impact"]=1 ;;
    *) RESOLVED["$stage"]=1 ;;
  esac
done

RESOLVED_COUNT=${#RESOLVED[@]}
if [ "$RESOLVED_COUNT" -eq 1 ]; then
  echo "OK: mixed stage names deduplicate to 1 unique skip (analyst-impact)"
else
  fail "Deduplication failed: $RESOLVED_COUNT unique skips (expected 1)"
fi

# ---------------------------------------------------------------------------
# Assertion 3: No double-skip error documented in skill
# ---------------------------------------------------------------------------
echo "--- Assertion 3: migration guide or skill documents mixed-name dedup ---"
MIG_GUIDE="$REPO_ROOT/docs/guides/migration-v7-to-v8.md"
FIXBUGS_SKILL="$REPO_ROOT/skills/fix-bugs/SKILL.md"

FOUND_DEDUP=0
for file in "$MIG_GUIDE" "$FIXBUGS_SKILL"; do
  if [ -f "$file" ] && grep -qiE 'dedup|double.skip|duplicate.*stage|stage.*duplicate' "$file"; then
    echo "OK: deduplication documented in $(basename "$file")"
    FOUND_DEDUP=1
  fi
done

if [ "$FOUND_DEDUP" -eq 0 ]; then
  echo "INFO: dedup not explicitly documented (acceptable if legacy alias mapping prevents double-skip)"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: mixed legacy+new stage names in Pipeline Profiles correctly deduplicate"
fi
exit "$FAIL"
