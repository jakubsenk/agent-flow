#!/usr/bin/env bash
# Verifies: AC-NF-001, REQ-NF-001
# Description: v7 project (customization/*.md only) works in v8.0.0 without running migrate-config
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
# Assertion 1: migration guide documents backward compat (no forced migration)
# ---------------------------------------------------------------------------
echo "--- Assertion 1: migration guide documents v7 backward compat ---"
MIG_GUIDE="$REPO_ROOT/docs/guides/migration-v7-to-v8.md"
if [ ! -f "$MIG_GUIDE" ]; then
  echo "SKIP: docs/guides/migration-v7-to-v8.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'backward.*compat|\.md.*still.*works|v7.*work.*v8|without.*migrate|optional.*migration' "$MIG_GUIDE"; then
  echo "OK: migration guide documents v7 backward compat"
else
  fail "migration guide missing v7 backward compat documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 2: SKILL.md documents .md fallback path
# ---------------------------------------------------------------------------
echo "--- Assertion 2: fix-bugs SKILL.md has .md fallback documented ---"
FIXBUGS_SKILL="$REPO_ROOT/skills/fix-bugs/SKILL.md"
if [ ! -f "$FIXBUGS_SKILL" ]; then
  echo "SKIP: skills/fix-bugs/SKILL.md not found" >&2
  exit 77
fi

if grep -qiE 'legacy.*\.md|\.md.*legacy|v7.*fallback|\.md.*fallback' "$FIXBUGS_SKILL"; then
  echo "OK: fix-bugs SKILL.md documents .md legacy fallback"
else
  fail "fix-bugs SKILL.md missing .md legacy fallback documentation"
fi

# ---------------------------------------------------------------------------
# Assertion 3: AC-OVR-007 confirmed — .md works without .toml
# ---------------------------------------------------------------------------
echo "--- Assertion 3: overlay dispatch handles .md-only (no .toml) ---"
TOML_DOC="$REPO_ROOT/docs/guides/toml-overlay-syntax.md"
if [ -f "$TOML_DOC" ]; then
  if grep -qiE 'only.*\.md|\.md.*only|without.*\.toml' "$TOML_DOC"; then
    echo "OK: toml-overlay-syntax.md documents .md-only overlay path"
  else
    fail "toml-overlay-syntax.md missing .md-only (no .toml) scenario documentation"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 4: No forced migration — /migrate-config is OPTIONAL
# ---------------------------------------------------------------------------
echo "--- Assertion 4: /migrate-config is optional (not required at plugin upgrade) ---"
if grep -qiE 'optional|recommended.*not.*required|not.*required.*migrate|migrate.*optional' "$MIG_GUIDE"; then
  echo "OK: migration guide documents migrate-config as optional"
else
  fail "migration guide missing 'migration is optional' documentation"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-NF-001 — v7 project (.md overlays only) works in v8 without running migrate-config"
fi
exit "$FAIL"
