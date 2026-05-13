#!/usr/bin/env bash
# v9.5.0 — AC-52: skills/migrate-config/ must not exist (deleted in v9.5.0 Wave 3).
# The /migrate-config skill (323 lines) was removed; its functionality was superseded
# by the Automation Config format which has been stable since v6.x.
# Created 2026-05-09 as part of v9.5.0 post-cleanup test polish.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if test ! -d "$REPO_ROOT/skills/migrate-config"; then
  echo "PASS: skills/migrate-config directory correctly absent (deleted in v9.5.0)"
  exit 0
else
  echo "FAIL: v9.5.0-deleted-skill-migrate-config — skills/migrate-config/ still exists (must be deleted per v9.5.0 Wave 3)"
  exit 1
fi
