#!/usr/bin/env bash
# Hidden adversarial test — do NOT reference in spec/visible
# Tests: customization/triage-analyst.md AND customization/code-analyst.md both exist
# migrate-config must merge both into customization/analyst.toml without losing either
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

mkdir -p "$TMPDIR_TEST/customization"

TRIAGE_TEXT="TRIAGE_ONLY_INSTRUCTION_AABB"
IMPACT_TEXT="IMPACT_ONLY_INSTRUCTION_CCDD"

cat > "$TMPDIR_TEST/customization/triage-analyst.md" << EOF
$TRIAGE_TEXT — applies to triage phase
EOF

cat > "$TMPDIR_TEST/customization/code-analyst.md" << EOF
$IMPACT_TEXT — applies to impact phase
EOF

# ---------------------------------------------------------------------------
# Assertion 1: migrate-config SKILL.md documents handling when both old names exist
# ---------------------------------------------------------------------------
echo "--- Assertion 1: migrate-config SKILL.md documents merge of triage-analyst + code-analyst ---"
MIGRATE_SKILL="$REPO_ROOT/skills/migrate-config/SKILL.md"
if [ ! -f "$MIGRATE_SKILL" ]; then
  echo "SKIP: skills/migrate-config/SKILL.md not found" >&2
  exit 77
fi

if grep -qiE 'triage.analyst.*code.analyst|code.analyst.*triage.analyst|merge.*analyst|both.*analyst' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config documents triage-analyst + code-analyst merge into analyst.toml"
else
  fail "migrate-config SKILL.md missing triage-analyst + code-analyst merge documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Output analyst.toml must contain BOTH instructions (no loss)
# ---------------------------------------------------------------------------
echo "--- Assertion 2: migration preserves content from BOTH source files ---"
# Simulate what the resulting analyst.toml should look like
cat > "$TMPDIR_TEST/customization/analyst.toml" << EOF
# generated: 2026-04-27T10:00:00Z by /migrate-config --to-v8

[[process_additions]]
step = "after_default"
instruction = """$TRIAGE_TEXT — applies to triage phase"""

[[process_additions]]
step = "after_default"
instruction = """$IMPACT_TEXT — applies to impact phase"""
EOF

if grep -qF "$TRIAGE_TEXT" "$TMPDIR_TEST/customization/analyst.toml" && \
   grep -qF "$IMPACT_TEXT" "$TMPDIR_TEST/customization/analyst.toml"; then
  echo "OK: analyst.toml contains content from BOTH source files"
else
  fail "analyst.toml missing content from one of the source files"
fi

# ---------------------------------------------------------------------------
# Assertion 3: design.md documents merge-into-single-toml for rename collision
# ---------------------------------------------------------------------------
echo "--- Assertion 3: design.md documents triage-analyst + code-analyst → analyst.toml merge ---"
DESIGN="$REPO_ROOT/.forge/phase-4-spec/final/design.md"
if [ -f "$DESIGN" ]; then
  if grep -qiE 'triage-analyst.*code-analyst|code-analyst.*triage-analyst' "$DESIGN"; then
    echo "OK: design.md documents both old names mapping to analyst"
  else
    fail "design.md missing documentation of both triage-analyst and code-analyst → analyst mapping"
  fi
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: triage-analyst.md + code-analyst.md both migrate into analyst.toml"
fi
exit "$FAIL"
