#!/usr/bin/env bash
# v9.5.0 — AC-55: skills/scaffold-validate/ must not exist (deleted in v9.5.0 Wave 3).
# The /scaffold-validate skill (88 lines) was removed; validation functionality
# was incorporated into the Docker dry-build block within /check-setup (Block 4b).
# Created 2026-05-09 as part of v9.5.0 post-cleanup test polish.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if test ! -d "$REPO_ROOT/skills/scaffold-validate"; then
  echo "PASS: skills/scaffold-validate directory correctly absent (deleted in v9.5.0)"
  exit 0
else
  echo "FAIL: v9.5.0-deleted-skill-scaffold-validate — skills/scaffold-validate/ still exists (must be deleted per v9.5.0 Wave 3)"
  exit 1
fi
