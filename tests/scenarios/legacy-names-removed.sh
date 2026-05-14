#!/bin/bash
# Covers: AC-9 (canonical Wave-1 grep returns no production matches outside historical exclusions)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

COUNT=$(grep -rn 'triage-analyst\|code-analyst\|e2e-test-engineer\|reproducer\|browser-verifier' \
  --include='*.md' --include='*.sh' \
  "$REPO_ROOT/agents/" "$REPO_ROOT/skills/" "$REPO_ROOT/core/" \
  "$REPO_ROOT/state/" "$REPO_ROOT/checklists/" \
  "$REPO_ROOT/docs/reference/" "$REPO_ROOT/docs/guides/" \
  "$REPO_ROOT/examples/" \
  2>/dev/null \
  | grep -v '^'"$REPO_ROOT"'/skills/migrate-config/' \
  | grep -v '^'"$REPO_ROOT"'/core/aliases/' \
  | grep -v 'CHANGELOG.md' \
  | grep -v 'reproducer-script' \
  | grep -v 'docs/reference/agents.md' \
  | grep -v 'v7 alias:' \
  | grep -v 'examples/configs/' \
  | grep -v 'examples/agent-overrides/codegraph/README.md' \
  | wc -l | tr -d ' ')

if [ "$COUNT" -eq 0 ]; then
  echo "PASS: v9-5-v7-names-removed — no v7 agent name references in production files"
  exit 0
else
  echo "FAIL: v9-5-v7-names-removed — found $COUNT v7 agent name reference(s) in production files"
  grep -rn 'triage-analyst\|code-analyst\|e2e-test-engineer\|reproducer\|browser-verifier' \
    --include='*.md' --include='*.sh' \
    "$REPO_ROOT/agents/" "$REPO_ROOT/skills/" "$REPO_ROOT/core/" \
    "$REPO_ROOT/state/" "$REPO_ROOT/checklists/" \
    "$REPO_ROOT/docs/reference/" "$REPO_ROOT/docs/guides/" \
    "$REPO_ROOT/examples/" \
    2>/dev/null \
    | grep -v '^'"$REPO_ROOT"'/skills/migrate-config/' \
    | grep -v '^'"$REPO_ROOT"'/core/aliases/' \
    | grep -v 'CHANGELOG.md' \
    | grep -v 'reproducer-script' \
    | grep -v 'docs/reference/agents.md' \
    | grep -v 'examples/configs/' \
    | grep -v 'examples/agent-overrides/codegraph/README.md' \
    || true
  exit 1
fi
