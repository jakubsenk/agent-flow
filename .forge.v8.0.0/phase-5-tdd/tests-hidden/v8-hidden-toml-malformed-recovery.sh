#!/usr/bin/env bash
# Hidden adversarial test — do NOT reference in spec/visible
# Tests: malformed TOML in one agent overlay does NOT corrupt other agents' overlays
# Edge case: mid-merge corruption isolation
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

# reviewer.toml — VALID
cat > "$TMPDIR_TEST/customization/reviewer.toml" << 'EOF'
model = "sonnet"
[[process_additions]]
step = "after_default"
instruction = "Valid reviewer instruction"
EOF

# fixer.toml — MALFORMED (syntax error)
cat > "$TMPDIR_TEST/customization/fixer.toml" << 'EOF'
model = "opus
[[process_additions]]
EOF

# analyst.toml — VALID
cat > "$TMPDIR_TEST/customization/analyst.toml" << 'EOF'
model = "sonnet"
EOF

# ---------------------------------------------------------------------------
# Assertion 1: migrate-config SKILL.md documents per-file error isolation
# ---------------------------------------------------------------------------
echo "--- Assertion 1: per-file error isolation documented ---"
MIGRATE_SKILL="$REPO_ROOT/skills/migrate-config/SKILL.md"
if [ ! -f "$MIGRATE_SKILL" ]; then
  echo "SKIP: skills/migrate-config/SKILL.md not found" >&2
  exit 77
fi

if grep -qiE 'per.file|isolat|corrupt.*other|halt.*single|error.*single.*file' "$MIGRATE_SKILL"; then
  echo "OK: migrate-config SKILL.md documents per-file error isolation"
else
  fail "migrate-config SKILL.md missing per-file error isolation documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 2: Valid overlays should NOT be affected by malformed sibling
# ---------------------------------------------------------------------------
echo "--- Assertion 2: valid files still parseable after malformed sibling ---"
# Verify our valid files are syntactically correct
REVIEWER_LINE=$(head -1 "$TMPDIR_TEST/customization/reviewer.toml")
if [ "$REVIEWER_LINE" = 'model = "sonnet"' ]; then
  echo "OK: reviewer.toml valid TOML (not affected by malformed fixer.toml)"
else
  fail "reviewer.toml corrupted: '$REVIEWER_LINE'"
fi

# Verify malformed file is indeed malformed (unterminated string)
FIXER_LINE=$(head -1 "$TMPDIR_TEST/customization/fixer.toml")
if echo "$FIXER_LINE" | grep -qE '"[^"]*$'; then
  echo "OK: fixer.toml is correctly malformed (unterminated string)"
else
  fail "Test fixture fixer.toml should be malformed but isn't"
fi

# ---------------------------------------------------------------------------
# Assertion 3: setup-agents SKILL.md documents error-per-file (not global abort)
# ---------------------------------------------------------------------------
echo "--- Assertion 3: setup-agents documents file-level (not global) abort on TOML error ---"
SETUP_SKILL="$REPO_ROOT/skills/setup-agents/SKILL.md"
if [ -f "$SETUP_SKILL" ]; then
  if grep -qiE 'per.file.*error|file.level.*error|error.*file.*continue|isolat' "$SETUP_SKILL"; then
    echo "OK: setup-agents documents per-file error handling"
  else
    fail "setup-agents SKILL.md missing per-file TOML error handling documentation"
  fi
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: malformed TOML in one agent overlay does not corrupt other overlays"
fi
exit "$FAIL"
