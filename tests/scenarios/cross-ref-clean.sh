#!/bin/bash
# Covers: AC-8 (no production references to deleted skills outside CHANGELOG/migration docs)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

COUNT=$(grep -rnE '(/|:)(migrate-config|estimate|pipeline-status|scaffold-validate)([^a-zA-Z0-9_-]|$)' \
  --include='*.md' --include='*.sh' \
  "$REPO_ROOT/agents/" "$REPO_ROOT/skills/" "$REPO_ROOT/core/" \
  "$REPO_ROOT/state/" "$REPO_ROOT/checklists/" \
  "$REPO_ROOT/docs/guides/" "$REPO_ROOT/docs/reference/" \
  "$REPO_ROOT/examples/" \
  "$REPO_ROOT/tests/scenarios/" \
  2>/dev/null \
  | grep -v 'CHANGELOG.md' \
  | grep -v 'tombstone\|removed in earlier versions\|estimate' \
  | grep -v '\\\\: ' \
  | wc -l | tr -d ' ')

if [ "$COUNT" -eq 0 ]; then
  echo "PASS: v9-5-cross-ref-clean — no production references to deleted skills found"
  exit 0
else
  echo "FAIL: v9-5-cross-ref-clean — found $COUNT reference(s) to deleted skills in production files"
  grep -rnE '(/|:)(migrate-config|estimate|pipeline-status|scaffold-validate)([^a-zA-Z0-9_-]|$)' \
    --include='*.md' --include='*.sh' \
    "$REPO_ROOT/agents/" "$REPO_ROOT/skills/" "$REPO_ROOT/core/" \
    "$REPO_ROOT/state/" "$REPO_ROOT/checklists/" \
    "$REPO_ROOT/docs/guides/" "$REPO_ROOT/docs/reference/" \
    "$REPO_ROOT/examples/" \
    "$REPO_ROOT/tests/scenarios/" \
    2>/dev/null \
    | grep -v 'CHANGELOG.md' \
    | grep -v 'tombstone\|removed in earlier versions\|estimate' \
    | grep -v '\\\\: ' \
    || true
  exit 1
fi
