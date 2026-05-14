#!/usr/bin/env bash
# Test: FC-9 (CLAUDE.md), FC-10 (automation-config.md) — CHANGELOG entry and roadmap status
# Also validates that docs/reference/pipelines.md or skills.md mentions the new step
# TDD red phase: expects FAIL on pre-implementation codebase
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

CHANGELOG="$REPO_ROOT/CHANGELOG.md"
ROADMAP="$REPO_ROOT/docs/roadmap.md"
PIPELINES_REF="$REPO_ROOT/docs/reference/pipelines.md"
SKILLS_REF="$REPO_ROOT/docs/reference/skills.md"
AUTOCONFIG="$REPO_ROOT/docs/reference/automation-config.md"

# -----------------------------------------------------------------------
# CHANGELOG must contain a v6.4.0 entry
# -----------------------------------------------------------------------
if [ ! -f "$CHANGELOG" ]; then
  fail "CHANGELOG.md not found"
else
  if ! grep -qE '6\.4\.0|v6\.4\.0' "$CHANGELOG" 2>/dev/null; then
    fail "CHANGELOG.md missing v6.4.0 entry"
  fi

  # The v6.4.0 entry must mention tracker subtask creation
  v640_context=$(grep -A20 '6\.4\.0' "$CHANGELOG" 2>/dev/null | head -20 || true)
  if ! echo "$v640_context" | grep -qiE 'tracker subtask|subtask.*tracker|tracker.*sub-issue|sub-issue.*tracker'; then
    fail "CHANGELOG.md v6.4.0 entry does not mention tracker subtask creation"
  fi
fi

# -----------------------------------------------------------------------
# Roadmap: v6.4.0 item must be moved from PLANNED to IMPLEMENTED
# REQ-5.4: this is a MINOR version (6.4.0) feature
# -----------------------------------------------------------------------
if [ ! -f "$ROADMAP" ]; then
  fail "docs/roadmap.md not found"
else
  # The item should be under a DONE heading (roadmap uses "## DONE — vX.Y.Z" not "## IMPLEMENTED")
  DONE_640_LINE=$(grep -n '## DONE.*6\.4\.0\|## DONE.*v6\.4\.0' "$ROADMAP" | head -1 | cut -d: -f1 || true)
  PLANNED_640_LINE=$(grep -n 'PLANNED.*6\.4\.0\|6\.4\.0.*PLANNED' "$ROADMAP" | head -1 | cut -d: -f1 || true)

  if [ -z "$DONE_640_LINE" ]; then
    fail "docs/roadmap.md does not have a '## DONE — v6.4.0' section (still in PLANNED or missing entirely)"
  fi

  if [ -n "$PLANNED_640_LINE" ]; then
    fail "docs/roadmap.md: v6.4.0 entry still appears in PLANNED section (line $PLANNED_640_LINE) — should be DONE"
  fi
fi

# -----------------------------------------------------------------------
# docs/reference/automation-config.md must document the Decomposition section
# with Create tracker subtasks key
# -----------------------------------------------------------------------
if [ ! -f "$AUTOCONFIG" ]; then
  fail "docs/reference/automation-config.md not found"
else
  if ! grep -q 'Create tracker subtasks' "$AUTOCONFIG" 2>/dev/null; then
    fail "docs/reference/automation-config.md missing 'Create tracker subtasks' key documentation"
  fi
fi

# -----------------------------------------------------------------------
# docs/reference/pipelines.md or skills.md must acknowledge the new step
# At least one reference doc must mention the new tracker subtask creation step
# -----------------------------------------------------------------------
pipeline_docs_updated=0
for ref_doc in "$PIPELINES_REF" "$SKILLS_REF"; do
  if [ -f "$ref_doc" ] && grep -qiE 'tracker subtask|tracker sub-issue|5a.*tracker|4b-tracker|3b-tracker' "$ref_doc" 2>/dev/null; then
    pipeline_docs_updated=1
    break
  fi
done

if [ "$pipeline_docs_updated" -eq 0 ]; then
  fail "Neither docs/reference/pipelines.md nor docs/reference/skills.md references the new tracker subtask creation step"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: CHANGELOG has v6.4.0 entry, roadmap updated to IMPLEMENTED, automation-config.md and at least one reference doc updated (FC-9, FC-10)"
exit "$FAIL"
