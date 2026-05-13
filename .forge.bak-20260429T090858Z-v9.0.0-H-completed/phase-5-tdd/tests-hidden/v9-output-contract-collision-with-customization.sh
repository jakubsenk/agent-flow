#!/bin/bash
# PURPOSE: (HIDDEN) Verify the heading collision detection logic described in the migration guide
#          (REQ-H-023, REQ-H-074). The examples/customization/*.md files must NOT contain
#          ## Project-Specific Instructions (hard error), and the migration guide's detection
#          command must be copy-pasteable (syntactically valid bash).
# AC-H-N covered: AC-H-004, AC-H-073 (adversarial variant)
# INVOKED BY: tests/harness/run-tests.sh (hidden)
# EXPECTED ON v8.0.0: PASS (no override files use reserved headings; migration guide absent — SKIP subtask)
# EXPECTED ON v9.0.0: PASS (same + migration guide detection command is syntactically valid)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Check 1: No example customization .md file uses ## Project-Specific Instructions (hard-blocked heading)
for dir in "$REPO_ROOT/examples/customization" "$REPO_ROOT/examples/agent-overrides"; do
  if [ ! -d "$dir" ]; then
    continue
  fi
  find "$dir" -name "*.md" | while read -r override_file; do
    if grep -qE '^## Project-Specific Instructions$' "$override_file"; then
      fail "$(basename "$override_file"): contains reserved heading '## Project-Specific Instructions' — REQ-H-022 violation; injector must reject or this causes duplicate-heading confusion"
    fi
  done
done

# Check 2: Migration guide detection command is valid bash (if guide exists)
MIGRATION_FILE="$REPO_ROOT/docs/guides/migration-v8-to-v9.md"
if [ ! -f "$MIGRATION_FILE" ]; then
  echo "SKIP: migration-v8-to-v9.md not yet created (v8.0.0 baseline)" >&2
  # Only skip this sub-check, don't exit 77 globally — the reserved-heading check above still runs
else
  # Extract the detection command from the Compatibility Check section
  # Look for grep -lE '...' customization pattern
  detect_cmd=$(grep -oE "grep -lE[^']*'[^']*Output Contract[^']*'[^|&;]*" "$MIGRATION_FILE" | head -1)
  if [ -n "$detect_cmd" ]; then
    # Validate it's syntactically parseable bash (bash -n syntax check)
    if ! echo "$detect_cmd customization/*.md 2>/dev/null" | bash -n 2>/dev/null; then
      fail "Migration guide compatibility check command has invalid bash syntax: $detect_cmd"
      # Mutation catch: a syntactically broken detection command fails here
    fi
  else
    fail "Migration guide Compatibility Check section has no grep -lE detection command for heading collisions"
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-H-004, AC-H-073 (adversarial) — no reserved heading collisions in examples; migration guide detection command is syntactically valid"
fi
exit "$FAIL"
