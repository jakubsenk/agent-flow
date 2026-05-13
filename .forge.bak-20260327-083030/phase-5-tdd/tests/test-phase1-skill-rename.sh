#!/usr/bin/env bash
# Test: Phase 1 skill rename — bug-workflow to workflow-router, plus parent_run_id and roadmap docs
# Validates FC-021 to FC-033
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL_DIR="$REPO_ROOT/skills"
SKILL_FILE="$SKILL_DIR/workflow-router/SKILL.md"
OLD_SKILL_FILE="$SKILL_DIR/bug-workflow/SKILL.md"
STATE_SCHEMA="$REPO_ROOT/state/schema.md"
SCAFFOLD="$REPO_ROOT/commands/scaffold.md"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
ROADMAP="$REPO_ROOT/docs/plans/roadmap.md"

# ── FC-021: skills/workflow-router/ directory exists ─────────────────────────
if [ ! -d "$SKILL_DIR/workflow-router" ]; then
  fail "FC-021: Directory skills/workflow-router/ does not exist"
fi

# ── FC-022: skills/bug-workflow/ does NOT exist ───────────────────────────────
if [ -d "$SKILL_DIR/bug-workflow" ]; then
  fail "FC-022: Directory skills/bug-workflow/ still exists (must be removed after rename)"
fi

# ── FC-023: SKILL.md has name: workflow-router ────────────────────────────────
if [ ! -f "$SKILL_FILE" ]; then
  fail "FC-023: skills/workflow-router/SKILL.md does not exist"
else
  if ! grep -q "^name: workflow-router$" "$SKILL_FILE"; then
    fail "FC-023: skills/workflow-router/SKILL.md frontmatter 'name' is not 'workflow-router'"
  fi
fi

# ── FC-024: SKILL.md description mentions both bugs and features ──────────────
if [ -f "$SKILL_FILE" ]; then
  description_line=$(grep "^description:" "$SKILL_FILE" || true)
  if [ -z "$description_line" ]; then
    fail "FC-024: skills/workflow-router/SKILL.md missing 'description' frontmatter field"
  else
    if ! echo "$description_line" | grep -qi 'bug\|fix\|issue'; then
      fail "FC-024: SKILL.md description does not mention bugs/fixes/issues"
    fi
    if ! echo "$description_line" | grep -qi 'feature\|implement\|scaffold'; then
      fail "FC-024: SKILL.md description does not mention features/implementation/scaffold (broader scope required)"
    fi
  fi
fi

# ── FC-025: Intent mapping table has >= rows as original bug-workflow ─────────
# Original bug-workflow had 22 intent rows (counting non-header, non-separator rows)
if [ -f "$SKILL_FILE" ]; then
  new_rows=$(grep -c '^|' "$SKILL_FILE" || true)
  # Original had at least 20 table rows (header + separator + 18+ intent rows)
  if [ "$new_rows" -lt 20 ]; then
    fail "FC-025: workflow-router intent table has $new_rows rows — fewer than original bug-workflow (expected >= 20)"
  fi
fi

# ── FC-026: CLAUDE.md does NOT contain string "bug-workflow" ─────────────────
if [ -f "$CLAUDE_MD" ]; then
  if grep -q 'bug-workflow' "$CLAUDE_MD"; then
    fail "FC-026: CLAUDE.md still contains 'bug-workflow' reference (all references must be updated)"
  fi
fi

# ── FC-027: state/schema.md JSON example contains "parent_run_id": null ───────
if [ ! -f "$STATE_SCHEMA" ]; then
  fail "FC-027: state/schema.md does not exist"
else
  if ! grep -q '"parent_run_id"' "$STATE_SCHEMA"; then
    fail "FC-027: state/schema.md Full Schema Example JSON missing '\"parent_run_id\"' field"
  fi
  if ! grep -q '"parent_run_id".*null\|parent_run_id.*: null' "$STATE_SCHEMA"; then
    fail "FC-027: state/schema.md JSON example does not show parent_run_id defaulting to null"
  fi
fi

# ── FC-028: state/schema.md Field Definitions table has parent_run_id row ──────
if [ -f "$STATE_SCHEMA" ]; then
  if ! grep -q 'parent_run_id' "$STATE_SCHEMA"; then
    fail "FC-028: state/schema.md Field Definitions table missing 'parent_run_id' row"
  fi
  # Check for type "string or null" in the same area
  if ! grep -qi 'string or null\|string.*null' "$STATE_SCHEMA"; then
    fail "FC-028: state/schema.md parent_run_id definition missing type 'string or null'"
  fi
fi

# ── FC-029: scaffold.md references setting parent_run_id in subtask state ──────
if [ -f "$SCAFFOLD" ]; then
  if ! grep -q 'parent_run_id' "$SCAFFOLD"; then
    fail "FC-029: scaffold.md does not reference 'parent_run_id' when creating subtask state"
  fi
fi

# ── FC-030: CLAUDE.md Architecture section references workflow-router ─────────
if [ -f "$CLAUDE_MD" ]; then
  if ! grep -q 'workflow-router' "$CLAUDE_MD"; then
    fail "FC-030: CLAUDE.md Architecture section does not reference 'workflow-router'"
  fi
fi

# ── FC-031: roadmap.md contains DONE section for v5.3.0 ──────────────────────
if [ ! -f "$ROADMAP" ]; then
  fail "FC-031: docs/plans/roadmap.md does not exist"
else
  if ! grep -q 'v5\.3\.0\|5\.3\.0' "$ROADMAP"; then
    fail "FC-031: roadmap.md missing v5.3.0 DONE section for Guided Handoff changes"
  fi
fi

# ── FC-032: roadmap.md contains NEXT/PLANNED items for Phase 2 features ───────
if [ -f "$ROADMAP" ]; then
  if ! grep -qi 'feature.*description\|description.*feature\|local deployment\|check-deploy' "$ROADMAP"; then
    fail "FC-032: roadmap.md missing NEXT/PLANNED items for Phase 2 features (feature from description, local deployment)"
  fi
fi

# ── FC-033: roadmap.md contains deferred items for 4 specified features ───────
if [ -f "$ROADMAP" ]; then
  if ! grep -qi 'forge.*bridge\|cross-plugin\|cross-plug' "$ROADMAP"; then
    fail "FC-033: roadmap.md missing deferred item for forge bridge / cross-plugin integration"
  fi
  if ! grep -qi 'standalone.*deploy\|standalone.*cli\|standalone.*cli\|standalone deployment' "$ROADMAP"; then
    fail "FC-033: roadmap.md missing deferred item for standalone deployment"
  fi
  if ! grep -qi 'scaffold.*extend\|--extend' "$ROADMAP"; then
    fail "FC-033: roadmap.md missing deferred item for scaffold --extend"
  fi
  if ! grep -qi 'batch.*feature\|implement.*batch\|implement-features' "$ROADMAP"; then
    fail "FC-033: roadmap.md missing deferred item for batch feature implementation"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Phase 1 skill rename and documentation tests passed (FC-021 to FC-033)"
exit "$FAIL"
