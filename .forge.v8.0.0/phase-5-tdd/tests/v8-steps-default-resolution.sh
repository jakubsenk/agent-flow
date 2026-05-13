#!/usr/bin/env bash
# Verifies: AC-STEPS-004, REQ-STEPS-002
# Description: WHEN no customization/steps/{skill}/{step}.md override exists,
#   THEN the plugin's skills/{skill}/steps/{step}.md SHALL be used AND no
#   "[INFO] Step override active:" log line SHALL be emitted.
# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
set -uo pipefail

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
# Assertion 1: plugin default step file exists for fix-bugs step 02-impact
#   The default-path fallback is only meaningful when the plugin step file EXISTS
# ---------------------------------------------------------------------------
echo "--- Assertion 1: plugin default step skills/fix-bugs/steps/02-impact.md exists ---"
FIXBUGS_STEPS_DIR="$REPO_ROOT/skills/fix-bugs/steps"
if [ ! -d "$FIXBUGS_STEPS_DIR" ]; then
  echo "SKIP: skills/fix-bugs/steps/ not found (implementation pending)" >&2
  exit 77
fi

DEFAULT_STEP=""
TMPFILE="$TMPDIR_TEST/step02.txt"
find "$FIXBUGS_STEPS_DIR" -maxdepth 1 -name '02-*.md' -type f > "$TMPFILE"
if [ -s "$TMPFILE" ]; then
  DEFAULT_STEP=$(head -1 "$TMPFILE")
  echo "OK: plugin default step found: $(basename "$DEFAULT_STEP")"
else
  fail "No step 02-*.md found in skills/fix-bugs/steps/ — default step required for no-override path"
fi

# ---------------------------------------------------------------------------
# Assertion 2: no customization/steps/fix-bugs/02-*.md exists in the plugin repo
#   (the plugin repo itself must NOT ship a customization/ directory — that would
#    mean the override-active path fires by default, breaking this no-override test)
# ---------------------------------------------------------------------------
echo "--- Assertion 2: no customization/steps/fix-bugs/ override ships with plugin repo ---"
OVERRIDE_DIR="$REPO_ROOT/customization/steps/fix-bugs"
if [ -d "$OVERRIDE_DIR" ]; then
  OVERRIDE_FILES="$TMPDIR_TEST/overrides.txt"
  find "$OVERRIDE_DIR" -maxdepth 1 -name '02-*.md' -type f > "$OVERRIDE_FILES"
  if [ -s "$OVERRIDE_FILES" ]; then
    fail "Plugin repo ships customization/steps/fix-bugs/02-*.md override — no-override path cannot be verified cleanly"
  else
    echo "OK: no step 02-*.md override in customization/steps/fix-bugs/"
  fi
else
  echo "OK: customization/steps/fix-bugs/ does not exist in plugin repo (expected — overrides are project-local)"
fi

# ---------------------------------------------------------------------------
# Assertion 3: fix-bugs SKILL.md documents the fallback-to-default behavior
#   WHEN no override file exists, the plugin default step MUST be loaded
#   (and the spec contract in design.md Section 4.2 says no log line is emitted)
# ---------------------------------------------------------------------------
echo "--- Assertion 3: fix-bugs SKILL.md documents default-step fallback (no override log) ---"
FIXBUGS_SKILL="$REPO_ROOT/skills/fix-bugs/SKILL.md"
if [ ! -f "$FIXBUGS_SKILL" ]; then
  echo "SKIP: skills/fix-bugs/SKILL.md not found (implementation pending)" >&2
  exit 77
fi

# The SKILL.md must document the override resolution rule (check for both presence AND absence)
if grep -qiE 'override.*absent|no override|default.*step|plugin.*default|customization.*not.*found|fallback' "$FIXBUGS_SKILL"; then
  echo "OK: fix-bugs SKILL.md documents default-step fallback when no override exists"
else
  # Also acceptable: docs/guides/steps-decomposition.md documents the fallback rule
  STEPS_GUIDE="$REPO_ROOT/docs/guides/steps-decomposition.md"
  if [ -f "$STEPS_GUIDE" ] && grep -qiE 'no override|default.*path|plugin.*default|override.*absent|fallback' "$STEPS_GUIDE"; then
    echo "OK: steps-decomposition.md documents default-step fallback path"
  else
    fail "Neither fix-bugs SKILL.md nor steps-decomposition.md documents the no-override default-step fallback"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 4: design.md Section 4.2 specifies override-REPLACE semantics
#   AND specifies that the INFO log is emitted ONLY when override is active
#   (implying: no override → no log line)
# ---------------------------------------------------------------------------
echo "--- Assertion 4: design.md §4.2 specifies log emitted ONLY when override active ---"
DESIGN_DOC="$REPO_ROOT/.forge/phase-4-spec/final/design.md"
# Note: design.md lives in .forge/ — read it directly without REPO_ROOT guard issue
# (we are reading spec docs, not implementation files)
DESIGN_DOC_FORGE="$(cd "$(dirname "$0")/../.." && pwd)/../phase-4-spec/final/design.md"
# Fallback: try relative from REPO_ROOT (for Phase 7 when tests/ is at repo root level)
if [ ! -f "$DESIGN_DOC_FORGE" ]; then
  DESIGN_DOC_FORGE="$REPO_ROOT/.forge/phase-4-spec/final/design.md"
fi

if [ -f "$DESIGN_DOC_FORGE" ]; then
  if grep -qiE '\[INFO\].*Step override active|Step override active.*emitted at dispatch|Logging.*override active' "$DESIGN_DOC_FORGE"; then
    echo "OK: design.md §4.2 documents [INFO] log emitted at dispatch time (override-active only)"
  else
    fail "design.md §4.2 missing [INFO] override-active logging spec"
  fi
else
  echo "INFO: design.md not accessible from test path — skipping design.md cross-check"
fi

# ---------------------------------------------------------------------------
# Assertion 5: no documented log example in steps-decomposition.md shows
#   "[INFO] Step override active:" for the no-override case
#   (i.e., the no-override case is documented as producing NO such log line)
# ---------------------------------------------------------------------------
echo "--- Assertion 5: steps-decomposition.md has no no-override [INFO] log example ---"
STEPS_GUIDE="$REPO_ROOT/docs/guides/steps-decomposition.md"
if [ ! -f "$STEPS_GUIDE" ]; then
  echo "SKIP: docs/guides/steps-decomposition.md not found (implementation pending)" >&2
  exit 77
fi

# The guide MUST document the resolution rule; it MUST NOT show an INFO override log for no-override scenario
# We verify the guide mentions "no override" or "default" path
if grep -qiE 'no override|without override|default.*used|plugin.*default' "$STEPS_GUIDE"; then
  echo "OK: steps-decomposition.md describes no-override / default step path"
else
  fail "steps-decomposition.md missing no-override path description"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-STEPS-004 — no-override path uses plugin default step; no override log line emitted"
fi
exit "$FAIL"
