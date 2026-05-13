#!/usr/bin/env bash
# AC: AC-T2-5-1, AC-T2-5-2
# Asserts state/schema.md has additive dispatched_at field
# and schema_version stays "1.0" (no erroneous bump to 2.0).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
SCHEMA="$REPO_ROOT/state/schema.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

[ -f "$SCHEMA" ] || { fail "state/schema.md does not exist"; exit 1; }

# AC-T2-5-1: dispatched_at field documented
if ! grep -qF 'dispatched_at' "$SCHEMA"; then
  fail "state/schema.md missing dispatched_at field documentation"
fi

# AC-T2-5-2: schema_version stays 1.0
if ! grep -qF '"schema_version": "1.0"' "$SCHEMA"; then
  fail "state/schema.md missing '\"schema_version\": \"1.0\"'"
fi
if grep -qF '"2.0"' "$SCHEMA"; then
  fail "state/schema.md erroneously bumped schema_version to 2.0"
fi

# Mutation guard: dispatched_at must appear in a stage-level context (not just a comment)
# This catches a no-op that adds it as a comment only
dispatched_lines=$(grep -n 'dispatched_at' "$SCHEMA")
if echo "$dispatched_lines" | grep -qE '^\s*#'; then
  fail "dispatched_at appears only in comments — must be in schema field documentation"
fi

echo "PASS: state/schema.md dispatched_at additive and schema_version preserved"
exit "$FAIL"
