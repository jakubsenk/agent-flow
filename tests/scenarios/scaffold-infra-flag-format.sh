#!/bin/bash
# Test: scaffold --infra flag uses named tracker:value,sc:value format (UXP-1)
# Validates: old positional format removed, new named format present in scaffold.md
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# 1. Named format "tracker:{value}" documented in Flag Parsing
if ! grep -q 'tracker:{' "$SCAFFOLD_CMD" && ! grep -q 'tracker:ready\|tracker:later\|tracker:\(ready\|later\)' "$SCAFFOLD_CMD"; then
  fail "scaffold.md Flag Parsing missing named format (tracker:{value})"
fi

# 2. Named format "sc:{value}" documented in Flag Parsing
if ! grep -q 'sc:{' "$SCAFFOLD_CMD" && ! grep -q 'sc:ready\|sc:later\|sc:\(ready\|later\)' "$SCAFFOLD_CMD"; then
  fail "scaffold.md Flag Parsing missing named format (sc:{value})"
fi

# 3. Old positional format detection: migration error message present
# The old format was ready,later or later,ready — the new code must detect it and show a migration error
if ! grep -q 'positional\|old.*format\|migration\|--infra ready,later\|--infra later' "$SCAFFOLD_CMD"; then
  fail "scaffold.md Flag Validation missing old-format detection or migration error"
fi

# 4. Flag Parsing description no longer uses the old positional format description
# Old: format: `{tracker},{sc}` where each is `ready` or `later`
if grep -q 'format: `{tracker},{sc}`' "$SCAFFOLD_CMD"; then
  fail "scaffold.md still references old positional --infra format description: format: \`{tracker},{sc}\`"
fi

# 5. Step 0-INFRA preset parsing uses named-pair extraction (tracker= and sc= assignment)
# The new parsing extracts by key name, not by position
if ! grep -q 'tracker=\|tracker_preset\|extract.*tracker\|parse.*tracker' "$SCAFFOLD_CMD"; then
  fail "scaffold.md Step 0-INFRA missing named-key extraction for tracker preset"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: scaffold --infra named format verified (UXP-1)"
exit "$FAIL"
