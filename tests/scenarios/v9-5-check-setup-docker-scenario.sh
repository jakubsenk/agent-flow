#!/bin/bash
# Covers: AC-58 — check-setup-docker-dry-build.sh deletion check
# v9.5.0 cleanup deleted this scenario. Docker dry-build logic was moved
# into /check-setup Block 4b (with a 4-branch decision tree), so the
# standalone scenario was removed as it tested relocated functionality.
# This meta-test now asserts the file is ABSENT (deletion was intentional).
# Updated 2026-05-09: inverted check per v9.5.0 cleanup audit.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/tests/scenarios/check-setup-docker-dry-build.sh"

if [ -f "$FILE" ]; then
  echo "FAIL: v9-5-check-setup-docker-scenario — tests/scenarios/check-setup-docker-dry-build.sh unexpectedly exists (should have been deleted in v9.5.0 cleanup)"
  exit 1
fi

echo "PASS: v9-5-check-setup-docker-scenario — check-setup-docker-dry-build.sh correctly absent (deleted in v9.5.0 cleanup; Docker logic lives in check-setup Block 4b)"
exit 0
