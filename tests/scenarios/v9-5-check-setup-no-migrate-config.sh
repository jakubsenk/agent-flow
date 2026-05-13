#!/bin/bash
# Covers: AC-20 (skills/check-setup/SKILL.md does not reference /migrate-config)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/skills/check-setup/SKILL.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-check-setup-no-migrate-config — skills/check-setup/SKILL.md not found"
  exit 1
fi

if grep -qE 'run /ceos-agents:migrate-config|run /migrate-config' "$FILE"; then
  echo "FAIL: v9-5-check-setup-no-migrate-config — skills/check-setup/SKILL.md still references /migrate-config"
  exit 1
else
  echo "PASS: v9-5-check-setup-no-migrate-config — /migrate-config reference absent from check-setup SKILL.md"
  exit 0
fi
