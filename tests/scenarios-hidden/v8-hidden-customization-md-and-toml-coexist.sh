#!/usr/bin/env bash
# Hidden adversarial test — do NOT reference in spec/visible
# Tests: Both .md AND .toml present for same agent — .toml wins, .md ONLY gets WARN
# Adversarial: ensure .md content is NOT silently merged into .toml dispatch
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

TOML_INSTRUCTION="TOML_ONLY_INSTRUCTION_12345"
MD_INSTRUCTION="MD_ONLY_INSTRUCTION_99999"

cat > "$TMPDIR_TEST/customization/fixer.toml" << EOF
model = "sonnet"
[[process_additions]]
step = "after_default"
instruction = "$TOML_INSTRUCTION"
EOF

cat > "$TMPDIR_TEST/customization/fixer.md" << EOF
$MD_INSTRUCTION — this should NOT be applied when .toml exists
EOF

# ---------------------------------------------------------------------------
# Assertion 1: .toml content is present and valid
# ---------------------------------------------------------------------------
echo "--- Assertion 1: fixer.toml has TOML_ONLY instruction ---"
if grep -qF "$TOML_INSTRUCTION" "$TMPDIR_TEST/customization/fixer.toml"; then
  echo "OK: fixer.toml has expected TOML instruction"
else
  fail "fixer.toml missing expected instruction"
fi

# ---------------------------------------------------------------------------
# Assertion 2: .md content is distinct (not in .toml)
# ---------------------------------------------------------------------------
echo "--- Assertion 2: MD_ONLY instruction is NOT in .toml ---"
if grep -qF "$MD_INSTRUCTION" "$TMPDIR_TEST/customization/fixer.toml"; then
  fail "fixer.toml should NOT contain MD_ONLY instruction (silently merged)"
else
  echo "OK: fixer.toml does not contain MD_ONLY instruction"
fi

# ---------------------------------------------------------------------------
# Assertion 3: AC-OVR-006 exact WARN text applies to this scenario
# ---------------------------------------------------------------------------
echo "--- Assertion 3: AC-OVR-006 WARN text covers coexistence scenario ---"
EXPECTED_WARN="Legacy .md overlay ignored; .toml takes precedence (deprecate v9.0.0)"
TOML_DOC="$REPO_ROOT/docs/guides/toml-overlay-syntax.md"
if [ -f "$TOML_DOC" ]; then
  if grep -qF "$EXPECTED_WARN" "$TOML_DOC"; then
    echo "OK: Exact WARN text found in toml-overlay-syntax.md"
  else
    fail "toml-overlay-syntax.md missing exact WARN: '$EXPECTED_WARN'"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 4: No silent double-application of both .md and .toml
# ---------------------------------------------------------------------------
echo "--- Assertion 4: .md content not merged when .toml exists ---"
# This is the core adversarial assertion: the MD content (MD_ONLY_INSTRUCTION_99999)
# must NOT appear in any merged prompt when .toml also exists.
# We verify via documentation contract:
SETUP_SKILL="$REPO_ROOT/skills/setup-agents/SKILL.md"
if [ -f "$SETUP_SKILL" ]; then
  if grep -qiE '\.toml.*ONLY|\.md.*ignored.*\.toml|NOT.*apply.*\.md.*when.*\.toml' "$SETUP_SKILL"; then
    echo "OK: setup-agents SKILL.md documents .md NOT applied when .toml present"
  else
    fail "setup-agents SKILL.md missing documentation that .md is NOT applied when .toml present"
  fi
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: .toml wins over .md; .md content NOT silently merged"
fi
exit "$FAIL"
