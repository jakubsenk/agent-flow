#!/bin/bash
# PURPOSE: Assert docs/guides/migration-v8-to-v9.md exists and contains the 4 required H2
#          section headings in order: Overview, Breaking Changes, Migration Steps, Compatibility
#          Check. Also verifies Breaking Changes enumerates the 4 required changes (REQ-H-070..H-074).
# AC-H-N covered: AC-H-070, AC-H-071, AC-H-072, AC-H-073
# INVOKED BY: tests/harness/run-tests.sh
# EXPECTED ON v8.0.0: FAIL (migration guide for v9 does not exist yet)
# EXPECTED ON v9.0.0: PASS (migration guide exists with all required sections and content)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

MIGRATION_FILE="$REPO_ROOT/docs/guides/migration-v8-to-v9.md"

# AC-H-070: file must exist and be non-empty
if [ ! -f "$MIGRATION_FILE" ]; then
  fail "docs/guides/migration-v8-to-v9.md does not exist — required per REQ-H-070"
  exit 1
fi
if [ ! -s "$MIGRATION_FILE" ]; then
  fail "docs/guides/migration-v8-to-v9.md exists but is empty"
  exit 1
fi

# AC-H-071: assert all 4 required H2 headings exist in correct order
# Extract H2 headings in order
h2_headings=$(grep -nE '^## (Overview|Breaking Changes|Migration Steps|Compatibility Check)$' "$MIGRATION_FILE")

overview_line=$(echo "$h2_headings" | grep '## Overview$' | head -1 | cut -d: -f1)
breaking_line=$(echo "$h2_headings" | grep '## Breaking Changes$' | head -1 | cut -d: -f1)
migration_line=$(echo "$h2_headings" | grep '## Migration Steps$' | head -1 | cut -d: -f1)
compat_line=$(echo "$h2_headings" | grep '## Compatibility Check$' | head -1 | cut -d: -f1)

if [ -z "$overview_line" ]; then
  fail "migration-v8-to-v9.md missing '## Overview' section"
fi
if [ -z "$breaking_line" ]; then
  fail "migration-v8-to-v9.md missing '## Breaking Changes' section"
fi
if [ -z "$migration_line" ]; then
  fail "migration-v8-to-v9.md missing '## Migration Steps' section"
fi
if [ -z "$compat_line" ]; then
  fail "migration-v8-to-v9.md missing '## Compatibility Check' section"
fi

# Assert ordering: Overview < Breaking Changes < Migration Steps < Compatibility Check
if [ -n "$overview_line" ] && [ -n "$breaking_line" ] && [ "$overview_line" -ge "$breaking_line" ]; then
  fail "migration-v8-to-v9.md: ## Overview must precede ## Breaking Changes"
fi
if [ -n "$breaking_line" ] && [ -n "$migration_line" ] && [ "$breaking_line" -ge "$migration_line" ]; then
  fail "migration-v8-to-v9.md: ## Breaking Changes must precede ## Migration Steps"
fi
if [ -n "$migration_line" ] && [ -n "$compat_line" ] && [ "$migration_line" -ge "$compat_line" ]; then
  fail "migration-v8-to-v9.md: ## Migration Steps must precede ## Compatibility Check"
  # Mutation catch: wrong section order fails here
fi

# AC-H-072: Breaking Changes section must enumerate the 4 required changes
if ! grep -qF 'Output Contract' "$MIGRATION_FILE"; then
  fail "migration-v8-to-v9.md ## Breaking Changes missing '## Output Contract' mention"
fi
if ! grep -qF 'triage-analyst' "$MIGRATION_FILE"; then
  fail "migration-v8-to-v9.md ## Breaking Changes missing 'triage-analyst' deprecated name"
fi
if ! grep -qF 'stack-selector' "$MIGRATION_FILE"; then
  fail "migration-v8-to-v9.md ## Breaking Changes missing 'stack-selector' deletion mention"
fi
# .md overlay removal — check for at least one of the key phrases
if ! grep -qE '\.md.*(overlay|agent overlay)' "$MIGRATION_FILE"; then
  fail "migration-v8-to-v9.md ## Breaking Changes missing .md overlay hard removal mention"
fi

# AC-H-073: Compatibility Check section must contain the heading collision detection bash command
if ! grep -qE 'grep.*-l.*Output Contract.*customization|grep.*-lE.*Output Contract.*customization' "$MIGRATION_FILE"; then
  fail "migration-v8-to-v9.md ## Compatibility Check missing heading collision detection bash command"
  # Mutation catch: removing the detection command from the guide fails here
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-H-070..H-073 — migration-v8-to-v9.md exists with 4 required sections in order and correct content"
fi
exit "$FAIL"
