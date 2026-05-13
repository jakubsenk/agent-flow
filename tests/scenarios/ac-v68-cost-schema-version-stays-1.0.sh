#!/usr/bin/env bash
set -euo pipefail

# AC-14: schema_version stays "1.0" in schema doc (no bump)
# Traces: COST-R1
# Description: Verifies state/schema.md still documents schema_version "1.0" (not "1.1")

# Pre-flight: file must exist (exists before Phase 7)

cd "$(dirname "$0")/../.."

FILE="state/schema.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist" >&2
  exit 1
fi

# Must have schema_version "1.0"
if ! grep -qF '"schema_version": "1.0"' "$FILE"; then
  echo "FAIL: $FILE missing '\"schema_version\": \"1.0\"'" >&2
  exit 1
fi

# Must document Always "1.0" text
if ! grep -qF 'Always `"1.0"`' "$FILE"; then
  echo "FAIL: $FILE missing 'Always \`\"1.0\"\`' description" >&2
  exit 1
fi

# Must NOT have "1.1" schema version
if grep -qF '"1.1"' "$FILE"; then
  echo "FAIL: $FILE contains '\"1.1\"' — schema_version must stay at 1.0" >&2
  exit 1
fi

echo "PASS: AC-14 — state/schema.md keeps schema_version = \"1.0\""
exit 0
