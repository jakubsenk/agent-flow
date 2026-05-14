#!/bin/bash
# Covers: AC-58 — check-setup-docker-dry-build.sh deletion check
# Cleanup deleted this scenario. Docker dry-build logic was moved
# into /check-setup Block 4b (with a 4-branch decision tree), so the
# standalone scenario was removed as it tested relocated functionality.
# This meta-test now asserts the file is ABSENT (deletion was intentional).
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/tests/scenarios/check-setup-docker-dry-build.sh"

if [ -f "$FILE" ]; then
  echo "FAIL: v9-5-check-setup-docker-scenario — tests/scenarios/check-setup-docker-dry-build.sh unexpectedly exists (should have been deleted in cleanup)"
  exit 1
fi

echo "PASS: v9-5-check-setup-docker-scenario — check-setup-docker-dry-build.sh correctly absent (deleted in cleanup; Docker logic lives in check-setup Block 4b)"
exit 0
