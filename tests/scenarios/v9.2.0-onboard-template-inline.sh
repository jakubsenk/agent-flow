#!/usr/bin/env bash
# v9.2.0 — /onboard Step 1 inlines template logic; /template skill deleted
# Fulfils: AC-V902-CAT-05, AC-V902-DOC-08
#
# RED now because:
#   1. skills/onboard/SKILL.md still delegates to /ceos-agents:template list (line 57)
#   2. skills/template/ directory still exists
#   3. examples/configs/README.md does not exist yet
#
# GREEN after Phase 7:
#   - Replaces /onboard Step 1 with the inline glob+extract block (design.md §"/onboard Step 1 inline")
#   - Deletes skills/template/
#   - Creates examples/configs/README.md
#
# NOTE: SCRIPT_DIR/../.. from .forge/phase-5-tdd/scenarios/ resolves two levels up to repo root.
# After Phase 7 copies this file to tests/scenarios/, SCRIPT_DIR/../.. also resolves to repo root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# Fallback for running from forge staging (.forge/phase-5-tdd/scenarios/ is 3 levels below repo root)
[ -f "$REPO_ROOT/tests/lib/fixtures.sh" ] || REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

SCRATCH="$(setup_scratch)"
trap "rm -rf '$SCRATCH'" EXIT

ONBOARD_SKILL="$REPO_ROOT/skills/onboard/SKILL.md"

# ---------------------------------------------------------------------------
# Guard: onboard SKILL.md must exist (not a v9.2.0 change — should always pass)
# ---------------------------------------------------------------------------
if [ ! -f "$ONBOARD_SKILL" ]; then
  echo "FAIL: skills/onboard/SKILL.md does not exist" >&2
  exit 1
fi

FAIL=0
fail() { printf '[FAIL] %s\n' "$1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# AC-V902-CAT-05 Assertion 1: onboard SKILL.md must NOT contain /ceos-agents:template as callable
# The spec says: does NOT contain the literal `/ceos-agents:template list`
# ---------------------------------------------------------------------------
echo "--- Assertion 1: /onboard does NOT delegate to /ceos-agents:template list ---"
if grep -qF '/ceos-agents:template list' "$ONBOARD_SKILL"; then
  fail "AC-V902-CAT-05 — skills/onboard/SKILL.md still contains '/ceos-agents:template list' (Phase 7 inline not applied)"
else
  echo "PASS: '/ceos-agents:template list' absent from onboard SKILL.md"
fi

# Also check for the generic slash invocation (without 'list' suffix)
if grep -qF '/ceos-agents:template' "$ONBOARD_SKILL"; then
  fail "AC-V902-CAT-05 — skills/onboard/SKILL.md still contains '/ceos-agents:template' invocation"
else
  echo "PASS: '/ceos-agents:template' (any form) absent from onboard SKILL.md"
fi

# ---------------------------------------------------------------------------
# AC-V902-CAT-05 Assertion 2: onboard SKILL.md MUST contain the glob pattern
# Exact string from spec: "examples/configs/*.md"
# ---------------------------------------------------------------------------
echo "--- Assertion 2: /onboard DOES contain examples/configs/*.md glob pattern ---"
if grep -qF 'examples/configs/*.md' "$ONBOARD_SKILL"; then
  echo "PASS: 'examples/configs/*.md' found in onboard SKILL.md"
else
  fail "AC-V902-CAT-05 — skills/onboard/SKILL.md does NOT contain 'examples/configs/*.md' (Phase 7 inline not applied)"
fi

# Also verify the Glob keyword is present (the inline calls Glob tool)
# Note: use -F without -i to avoid grep crash on multibyte UTF-8 chars
if grep -qF 'Glob' "$ONBOARD_SKILL"; then
  echo "PASS: 'Glob' keyword present in onboard SKILL.md"
else
  fail "AC-V902-CAT-05 — skills/onboard/SKILL.md missing 'Glob' keyword in Step 1"
fi

# ---------------------------------------------------------------------------
# AC-V902-CAT-05 / AC-V902-CAT-02: skills/template/ must NOT exist
# ---------------------------------------------------------------------------
echo "--- Assertion 3: skills/template/ directory does NOT exist ---"
if [ -d "$REPO_ROOT/skills/template" ]; then
  fail "AC-V902-CAT-02 — skills/template/ directory still exists (Phase 7 deletion not applied)"
else
  echo "PASS: skills/template/ correctly absent"
fi

# ---------------------------------------------------------------------------
# AC-V902-DOC-08 Assertion 1: examples/configs/README.md must exist
# ---------------------------------------------------------------------------
echo "--- Assertion 4: examples/configs/README.md exists ---"
CONFIGS_README="$REPO_ROOT/examples/configs/README.md"
if [ ! -f "$CONFIGS_README" ]; then
  fail "AC-V902-DOC-08 — examples/configs/README.md does not exist (Phase 7 must create it)"
else
  echo "PASS: examples/configs/README.md exists"

  # ---------------------------------------------------------------------------
  # AC-V902-DOC-08 Assertion 2: each *.md in examples/configs/ (excluding README) starts with "# "
  # ---------------------------------------------------------------------------
  echo "--- Assertion 5: each examples/configs/*.md starts with # heading ---"
  while IFS= read -r -d '' config_file; do
    # Skip README.md itself
    [ "$(basename "$config_file")" = "README.md" ] && continue

    first_line="$(head -1 "$config_file")"
    if [[ "$first_line" != "# "* ]]; then
      fail "AC-V902-DOC-08 — $config_file does not start with '# ' (heading-extraction contract violation)"
    else
      echo "PASS: $(basename "$config_file") starts with '# ' heading"
    fi
  done < <(find "$REPO_ROOT/examples/configs" -maxdepth 1 -name "*.md" -print0 2>/dev/null)
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.2.0-onboard-template-inline — /onboard Step 1 inline verified"
fi
exit "$FAIL"
