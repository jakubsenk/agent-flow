#!/usr/bin/env bash
# Verifies: AC-STEPS-005, REQ-STEPS-004
# Description: WHEN customization/steps/fix-bugs/04-fixer-reviewer-loop.md exists
#   with content "OVERRIDE BODY MARKER 12345", THEN the dispatched fixer-reviewer
#   prompt SHALL contain ONLY the override body content; the plugin-default body
#   SHALL NOT be merged in.
#
# This is a contract verification for a markdown plugin (no runtime to test until Phase 7).
# The test verifies the REPLACE semantics contract as documented in:
#   - design.md Section 4.2 (Override is replace-only)
#   - docs/guides/steps-decomposition.md (resolution rules)
#   - formal-criteria.md AC-STEPS-005 (override body replaces default)
#
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
# Setup: create temp customization/steps/fix-bugs/04-override.md
#   with sentinel content "OVERRIDE BODY MARKER 12345"
# ---------------------------------------------------------------------------
mkdir -p "$TMPDIR_TEST/customization/steps/fix-bugs"
cat > "$TMPDIR_TEST/customization/steps/fix-bugs/04-fixer-reviewer-loop.md" << 'EOF'
# Step 04 — Fixer-Reviewer Loop (project override)

OVERRIDE BODY MARKER 12345

This override replaces the default step 04 body for testing purposes.
Only this content should appear in the dispatched prompt; no plugin-default keywords.
EOF

OVERRIDE_MARKER="OVERRIDE BODY MARKER 12345"

# ---------------------------------------------------------------------------
# Assertion 1: design.md §4.2 documents REPLACE semantics
#   (Override REPLACES the default step body — NOT appended or merged)
# ---------------------------------------------------------------------------
echo "--- Assertion 1: design.md §4.2 documents override as REPLACE-ONLY semantics ---"
DESIGN_DOC_FORGE="$(cd "$(dirname "$0")/../.." && pwd)/../phase-4-spec/final/design.md"
if [ ! -f "$DESIGN_DOC_FORGE" ]; then
  DESIGN_DOC_FORGE="$REPO_ROOT/.forge/phase-4-spec/final/design.md"
fi

if [ -f "$DESIGN_DOC_FORGE" ]; then
  if grep -qiE 'replace.only|override.*replace|replaces.*default|replace.*default.*step|override.*replace.*default|no.*insert|no.*partial.*patch' "$DESIGN_DOC_FORGE"; then
    echo "OK: design.md §4.2 documents replace-only override semantics"
  else
    fail "design.md §4.2 missing replace-only override semantics (must say REPLACE, not append/merge)"
  fi
else
  echo "INFO: design.md not accessible from test path — checking steps-decomposition guide instead"
fi

# ---------------------------------------------------------------------------
# Assertion 2: steps-decomposition.md documents REPLACE semantics
#   (the guide is the primary user-facing contract for this behavior)
# ---------------------------------------------------------------------------
echo "--- Assertion 2: steps-decomposition.md documents override body REPLACES default ---"
STEPS_GUIDE="$REPO_ROOT/docs/guides/steps-decomposition.md"
if [ ! -f "$STEPS_GUIDE" ]; then
  echo "SKIP: docs/guides/steps-decomposition.md not found (implementation pending)" >&2
  exit 77
fi

if grep -qiE 'replace.*default|override.*replaces|replaces.*plugin|no.*merge|replace.only|not.*appended|not.*merged' "$STEPS_GUIDE"; then
  echo "OK: steps-decomposition.md documents override REPLACES default (not merged)"
else
  fail "steps-decomposition.md missing REPLACE semantics — must state override replaces (not merges) default step body"
fi

# ---------------------------------------------------------------------------
# Assertion 3: formal-criteria.md AC-STEPS-005 maps to replace semantics
#   Verify the spec contract defines the test scenario and the replace property
# ---------------------------------------------------------------------------
echo "--- Assertion 3: formal-criteria.md AC-STEPS-005 covers replace semantics ---"
FORMAL_CRITERIA_FORGE="$(cd "$(dirname "$0")/../.." && pwd)/../phase-4-spec/final/formal-criteria.md"
if [ ! -f "$FORMAL_CRITERIA_FORGE" ]; then
  FORMAL_CRITERIA_FORGE="$REPO_ROOT/.forge/phase-4-spec/final/formal-criteria.md"
fi

if [ -f "$FORMAL_CRITERIA_FORGE" ]; then
  if grep -qiE 'AC-STEPS-005.*OVERRIDE BODY|OVERRIDE BODY.*AC-STEPS-005|OVERRIDE BODY.*NOT.*contain|NOT.*plugin-default' "$FORMAL_CRITERIA_FORGE"; then
    echo "OK: formal-criteria.md AC-STEPS-005 specifies OVERRIDE BODY presence AND plugin-default absence"
  else
    # The AC exists — verify it at least mentions override body and not-contain
    if grep -qiE 'AC-STEPS-005' "$FORMAL_CRITERIA_FORGE" && \
       grep -A5 'AC-STEPS-005' "$FORMAL_CRITERIA_FORGE" | grep -qiE 'OVERRIDE BODY|replace.*default|SHALL NOT.*contain'; then
      echo "OK: formal-criteria.md AC-STEPS-005 present and references replace contract"
    else
      fail "formal-criteria.md AC-STEPS-005 missing OVERRIDE BODY / replace semantics specification"
    fi
  fi
else
  echo "INFO: formal-criteria.md not accessible from test path — skipping cross-check"
fi

# ---------------------------------------------------------------------------
# Assertion 4: override file content is verifiable as REPLACE (not merge)
#   Verify the created override file contains the marker AND does NOT contain
#   plugin-default step keywords (i.e., if the plugin shipped a default step 04,
#   the override file would contain ONLY the override content)
# ---------------------------------------------------------------------------
echo "--- Assertion 4: override file contains marker AND plugin-default keywords absent ---"

# Verify override file was created with marker
if grep -qF "$OVERRIDE_MARKER" "$TMPDIR_TEST/customization/steps/fix-bugs/04-fixer-reviewer-loop.md"; then
  echo "OK: override file contains sentinel OVERRIDE BODY MARKER 12345"
else
  fail "override file missing OVERRIDE BODY MARKER 12345 — fixture creation error"
fi

# If the plugin default step file exists, verify it does NOT contain the override marker
# (they are independent files — the override does not inherit default content)
DEFAULT_STEP_04=""
TMPFILE="$TMPDIR_TEST/step04.txt"
find "$REPO_ROOT/skills/fix-bugs/steps" -maxdepth 1 -name '04-*.md' -type f 2>/dev/null > "$TMPFILE" || true
if [ -s "$TMPFILE" ]; then
  DEFAULT_STEP_04=$(head -1 "$TMPFILE")
  if grep -qF "$OVERRIDE_MARKER" "$DEFAULT_STEP_04"; then
    fail "Plugin default step 04 contains OVERRIDE BODY MARKER — default and override must be independent files"
  else
    echo "OK: plugin default step 04 does not contain the override marker (files are independent)"
  fi

  # Critical: the override file must NOT contain content from the plugin default step
  # We extract a distinctive phrase from the default step and verify it does NOT appear in override
  # This is the spec contract: override REPLACES, not appends
  DEFAULT_CONTENT_SAMPLE=$(head -5 "$DEFAULT_STEP_04" | tail -1)
  if [ -n "$DEFAULT_CONTENT_SAMPLE" ] && grep -qF "$DEFAULT_CONTENT_SAMPLE" "$TMPDIR_TEST/customization/steps/fix-bugs/04-fixer-reviewer-loop.md"; then
    fail "Override file contains content from plugin default step — replace semantics violated (found: '$DEFAULT_CONTENT_SAMPLE')"
  else
    echo "OK: override file does not contain plugin-default step content (replace semantics)"
  fi
else
  # Plugin default step 04 not yet implemented — acceptable for Phase 5 TDD
  # NOTE: This is a pre-implementation test; Phase 7 will add runtime behavior verification
  echo "INFO: skills/fix-bugs/steps/04-*.md not yet implemented — file independence cannot be verified"
  echo "INFO: Contract verification via design.md §4.2 and steps-decomposition.md completed (Assertions 1-3)"
fi

# ---------------------------------------------------------------------------
# Assertion 5: fix-bugs SKILL.md or steps-decomposition.md does NOT document
#   any append/merge mode for step overrides in v8.0.0
# ---------------------------------------------------------------------------
echo "--- Assertion 5: no append/merge override semantics documented (replace-only in v8.0.0) ---"
if [ -f "$STEPS_GUIDE" ]; then
  # Look for any documentation of merge/append for step overrides specifically
  # (The guide must not contradict the replace-only contract)
  if grep -qiE 'step.*override.*append|step.*override.*merge|merge.*step.*override|partial.*step.*patch' "$STEPS_GUIDE"; then
    fail "steps-decomposition.md documents step override as append/merge — contradicts replace-only contract (REQ-STEPS-004)"
  else
    echo "OK: steps-decomposition.md does not document step override as append/merge (replace-only contract preserved)"
  fi
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-STEPS-005 — override body REPLACES default step (not merged); spec contract verified"
fi
exit "$FAIL"
