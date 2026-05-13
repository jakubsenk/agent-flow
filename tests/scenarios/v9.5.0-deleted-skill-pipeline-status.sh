#!/usr/bin/env bash
# v9.5.0 — AC-54: skills/pipeline-status/ must not exist (deleted in v9.5.0 Wave 3).
# The /pipeline-status skill (152 lines) was removed; it was renamed from /status
# in v7.0.0 and deleted in v9.5.0 as its functionality is superseded by direct
# .ceos-agents/state.json inspection and forge-status.
# Created 2026-05-09 as part of v9.5.0 post-cleanup test polish.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if test ! -d "$REPO_ROOT/skills/pipeline-status"; then
  echo "PASS: skills/pipeline-status directory correctly absent (deleted in v9.5.0)"
  exit 0
else
  echo "FAIL: v9.5.0-deleted-skill-pipeline-status — skills/pipeline-status/ still exists (must be deleted per v9.5.0 Wave 3)"
  exit 1
fi
