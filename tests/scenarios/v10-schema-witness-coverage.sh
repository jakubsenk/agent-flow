#!/usr/bin/env bash
# ===========================================================================
# Test:        v10-schema-witness-coverage.sh
# Falsifies:   REQ-B-4, REQ-B-6, REQ-B-2 (v1.2: agent_name/stage_name addition)
# FC mapped:   FC-3 (schema documents witness + agent_name + stage_name; schema_version stable)
# What it checks:
#   A)  state/schema.md contains '#### `stages.{stage}.dispatch_witness`' sub-section
#   A') state/schema.md contains '#### `stages.{stage}.agent_name`' sub-section
#   A") state/schema.md contains '#### `stages.{stage}.stage_name`' sub-section
#   B)  All 10 v10.0.0 stage names appear in state/schema.md
#   C)  schema_version literal `"1.0"` still present (REQ-B-6 invariant)
# Expected RED phase: FAIL — state/schema.md does not yet document these fields
# Expected GREEN phase (post-impl): PASS
# ===========================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || { echo "FAIL: cannot cd to REPO_ROOT=$REPO_ROOT" >&2; exit 1; }

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

SCHEMA="state/schema.md"
if [ ! -f "$SCHEMA" ]; then
  fail "FC-3.file: $SCHEMA missing"
  exit 1
fi

# A. dispatch_witness sub-section header (REQ-B-4)
if ! grep -qE '^#### `stages\.\{stage\}\.dispatch_witness`$' "$SCHEMA"; then
  fail "FC-3.A: $SCHEMA missing '#### \`stages.{stage}.dispatch_witness\`' sub-section header"
fi

# A'. agent_name sub-section header (REQ-B-2 v1.2 expansion)
if ! grep -qE '^#### `stages\.\{stage\}\.agent_name`$' "$SCHEMA"; then
  fail "FC-3.A-prime-1: $SCHEMA missing '#### \`stages.{stage}.agent_name\`' sub-section header"
fi

# A". stage_name sub-section header (REQ-B-2 v1.2 expansion)
if ! grep -qE '^#### `stages\.\{stage\}\.stage_name`$' "$SCHEMA"; then
  fail "FC-3.A-prime-2: $SCHEMA missing '#### \`stages.{stage}.stage_name\`' sub-section header"
fi

# B. All 10 v10.0.0 stage names appear in schema.md
STAGES=(triage code_analysis reproduce_browser fixer_reviewer smoke_check test e2e_test browser_verification acceptance_gate publisher)
for stage in "${STAGES[@]}"; do
  if ! grep -qw "$stage" "$SCHEMA"; then
    fail "FC-3.B: $SCHEMA missing stage name '${stage}'"
  fi
done

# C. schema_version still "1.0" (REQ-B-6 stability invariant)
# Accept either:
#   `schema_version` ... `"1.0"`
#   OR the legacy form `"schema_version": "1.0"` in JSON example block.
if ! grep -qE '`schema_version`.*`"1\.0"`|"schema_version"[[:space:]]*:[[:space:]]*"1\.0"' "$SCHEMA"; then
  fail "FC-3.C: $SCHEMA schema_version no longer '1.0' (bump is FORBIDDEN per REQ-B-6)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v10-schema-witness-coverage — schema documents witness/agent_name/stage_name across 10 stages; schema_version=1.0 stable"
  exit 0
fi
exit 1
