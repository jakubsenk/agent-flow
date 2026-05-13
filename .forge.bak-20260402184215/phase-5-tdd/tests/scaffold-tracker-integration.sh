#!/bin/bash
# Test: scaffold tracker integration — Bug 1 (Step 4e story sub-issues) + Bug 2 (Step 8b Done transition)
# Validates: G-01 through G-18, G-19/G-20 ordering, G-21 through G-25 trackers.md,
#            G-26 through G-32 example configs, regression guards
# Expected: ALL assertions FAIL before implementation, PASS after.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCAFFOLD_SKILL="$REPO_ROOT/skills/scaffold/SKILL.md"
TRACKERS_DOC="$REPO_ROOT/docs/reference/trackers.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# =============================================================================
# BUG 1: Step 4e — Story Sub-Issue Creation
# =============================================================================

# G-01: Story heading pattern documented
if ! grep -q 'Story N\.M:' "$SCAFFOLD_SKILL"; then
  fail "G-01: Step 4e missing story heading pattern 'Story N.M:'"
fi

# G-02: Story back-reference format (STORY-ISSUE-ID)
if ! grep -q 'STORY-ISSUE-ID' "$SCAFFOLD_SKILL"; then
  fail "G-02: Step 4e missing story back-reference format 'STORY-ISSUE-ID'"
fi

# G-03: Idempotency guard present for stories
if ! grep -q 'Idempotency guard\|idempotency guard' "$SCAFFOLD_SKILL"; then
  fail "G-03: Step 4e missing idempotency guard instruction"
fi

# G-04: Tracker-specific branching (native sub-issues vs fallback)
if ! grep -q 'supports native sub-issues' "$SCAFFOLD_SKILL"; then
  fail "G-04: Step 4e missing tracker branching logic ('supports native sub-issues')"
fi

# G-05: Reference to trackers.md Sub-Issue Capabilities table
if ! grep -q 'Sub-Issue Capabilities' "$SCAFFOLD_SKILL"; then
  fail "G-05: Step 4e missing reference to trackers.md 'Sub-Issue Capabilities'"
fi

# G-06: GitHub/Gitea fallback title format [{epic_title}]
if ! grep -q '\[{epic_title}\]' "$SCAFFOLD_SKILL"; then
  fail "G-06: Step 4e missing GitHub/Gitea fallback title format '[{epic_title}] {story_title}'"
fi

# G-07: Updated display message with story counts
if ! grep -q 'story failures' "$SCAFFOLD_SKILL"; then
  fail "G-07: Step 4e missing updated display message with 'story failures' count"
fi

# G-08: Parsing instruction (delimiter-based — split on ---)
if ! grep -q 'Split content on\|split.*content.*on\|Split.*on.*---\|delimiter' "$SCAFFOLD_SKILL"; then
  fail "G-08: Step 4e missing parsing instruction (delimiter-based split)"
fi

# G-09: Zero stories edge case handled
if ! grep -q 'zero stories\|Zero stories\|no.*story.*headings\|no.*### Story' "$SCAFFOLD_SKILL"; then
  fail "G-09: Step 4e missing zero-stories edge case handling"
fi

# G-10: Fallback cross-reference to epic issue in story description
if ! grep -q 'cross-reference to epic issue\|cross-reference.*epic\|epic.*cross-reference' "$SCAFFOLD_SKILL"; then
  fail "G-10: Step 4e missing fallback cross-reference to epic issue"
fi

# Per-story failure handling: WARN + continue
if ! grep -q 'WARN.*story\|story.*WARN\|continue.*next story\|next story' "$SCAFFOLD_SKILL"; then
  fail "Step 4e missing per-story failure handling (WARN + continue to next story)"
fi

# Story back-reference writeback comment format (<!-- {TrackerType}: {STORY-ISSUE-ID} -->)
if ! grep -q '<!-- {TrackerType}.*STORY\|TrackerType.*STORY-ISSUE-ID\|back-reference.*story' "$SCAFFOLD_SKILL"; then
  fail "Step 4e missing story back-reference writeback format (<!-- {TrackerType}: {STORY-ISSUE-ID} -->)"
fi

# =============================================================================
# BUG 2: Step 8b — Done Transition
# =============================================================================

# G-11: Step 8b section heading exists
if ! grep -q 'Step 8b: Close Tracker Issues\|Step 8b.*Close.*Tracker\|Step 8b.*Tracker.*Close' "$SCAFFOLD_SKILL"; then
  fail "G-11: 'Step 8b: Close Tracker Issues' section heading missing"
fi

# G-12: WARN message for missing Done mapping
if ! grep -q "does not include a 'Done' mapping" "$SCAFFOLD_SKILL"; then
  fail "G-12: Step 8b missing WARN message for missing Done mapping"
fi

# G-13: Per-epic completion check against blocked features list
if ! grep -q 'blocked features list\|blocked.*features' "$SCAFFOLD_SKILL"; then
  fail "G-13: Step 8b missing 'blocked features list' check for per-epic granularity"
fi

# G-14: Display message format "Transitioned ... tracker issues to Done"
if ! grep -qE 'Transitioned.*tracker issues to Done' "$SCAFFOLD_SKILL"; then
  fail "G-14: Step 8b missing display message 'Transitioned {N}/{M} tracker issues to Done'"
fi

# G-15: Skipped epics reported (blocked subtasks)
if ! grep -q 'skipped (blocked subtasks)' "$SCAFFOLD_SKILL"; then
  fail "G-15: Step 8b missing 'skipped (blocked subtasks)' in display message"
fi

# G-16: Per-issue failure WARN message
if ! grep -q 'Could not transition' "$SCAFFOLD_SKILL"; then
  fail "G-16: Step 8b missing per-issue failure WARN 'Could not transition'"
fi

# G-17: Cascade-aware — do NOT close sub-issues for native trackers
if ! grep -q 'Do NOT explicitly close story sub-issues\|do not.*explicitly close.*sub-issues\|cascade' "$SCAFFOLD_SKILL"; then
  fail "G-17: Step 8b missing cascade-aware behavior ('Do NOT explicitly close story sub-issues')"
fi

# Guard clause: tracker_effective_status must be checked
if ! grep -q 'tracker_effective_status\|tracker_write_available\|no.*back-reference' "$SCAFFOLD_SKILL"; then
  fail "Step 8b missing guard clause referencing tracker_effective_status"
fi

# Step 8b reads back-references from spec/epics/*.md
if ! grep -qE 'spec/epics/\*\.md.*back-reference|back-reference.*spec/epics|parsing.*spec.*epics.*back-ref|spec.epics.*md.*issue.*ID' "$SCAFFOLD_SKILL"; then
  if ! grep -q 'back-reference comments.*spec\|spec.*back-reference comments' "$SCAFFOLD_SKILL"; then
    fail "Step 8b missing instruction to read back-references from spec/epics/*.md"
  fi
fi

# =============================================================================
# G-18: Step 9 Final Report — closed issues count
# =============================================================================

if ! grep -q 'issues closed' "$SCAFFOLD_SKILL"; then
  fail "G-18: Step 9 Final Report missing 'issues closed' count"
fi

# =============================================================================
# G-19/G-20: Ordering — Step 8b between Step 8 and Step 9
# =============================================================================

STEP8_LINE=$(grep -n "Step 8: E2E Tests\|### Step 8:" "$SCAFFOLD_SKILL" | grep -v "Step 8b" | head -1 | cut -d: -f1)
STEP8B_LINE=$(grep -n "Step 8b: Close Tracker Issues\|### Step 8b" "$SCAFFOLD_SKILL" | head -1 | cut -d: -f1)
STEP9_LINE=$(grep -n "Step 9: Final Report\|### Step 9:" "$SCAFFOLD_SKILL" | head -1 | cut -d: -f1)

if [ -z "$STEP8B_LINE" ]; then
  fail "G-19/G-20: Step 8b section not found — cannot check ordering"
else
  # G-19: Step 8b after Step 8
  if [ -n "$STEP8_LINE" ] && [ "$STEP8B_LINE" -le "$STEP8_LINE" ]; then
    fail "G-19: Step 8b (line $STEP8B_LINE) must appear AFTER Step 8 (line $STEP8_LINE)"
  fi

  # G-20: Step 8b before Step 9
  if [ -n "$STEP9_LINE" ] && [ "$STEP8B_LINE" -ge "$STEP9_LINE" ]; then
    fail "G-20: Step 8b (line $STEP8B_LINE) must appear BEFORE Step 9 (line $STEP9_LINE)"
  fi
fi

# =============================================================================
# DOCUMENTATION: trackers.md — Sub-Issue Capabilities
# =============================================================================

# G-21: Sub-Issue Capabilities section heading
if ! grep -q 'Sub-Issue Capabilities' "$TRACKERS_DOC"; then
  fail "G-21: trackers.md missing '## Sub-Issue Capabilities' section"
fi

# G-22: Column header "Native sub-issues"
if ! grep -q 'Native sub-issues' "$TRACKERS_DOC"; then
  fail "G-22: trackers.md Sub-Issue Capabilities table missing 'Native sub-issues' column"
fi

# G-23: Redmine parent_issue_id parameter documented
if ! grep -q 'parent_issue_id' "$TRACKERS_DOC"; then
  fail "G-23: trackers.md missing Redmine 'parent_issue_id' parameter"
fi

# G-24: Linear parentId parameter documented
if ! grep -q 'parentId' "$TRACKERS_DOC"; then
  fail "G-24: trackers.md missing Linear 'parentId' parameter"
fi

# G-25: Fallback strategy documented (Standalone issue)
if ! grep -q 'Standalone issue' "$TRACKERS_DOC"; then
  fail "G-25: trackers.md missing 'Standalone issue' fallback strategy"
fi

# =============================================================================
# EXAMPLE CONFIGS: Done Mapping
# =============================================================================

# G-26: github-dotnet.md — Done: close
if ! grep -qE 'Done:.*close' "$REPO_ROOT/examples/configs/github-dotnet.md"; then
  fail "G-26: examples/configs/github-dotnet.md missing 'Done: close' mapping"
fi

# G-27: github-python-fastapi.md — Done: close
if ! grep -qE 'Done:.*close' "$REPO_ROOT/examples/configs/github-python-fastapi.md"; then
  fail "G-27: examples/configs/github-python-fastapi.md missing 'Done: close' mapping"
fi

# G-28: github-nextjs.md — Done: close
if ! grep -qE 'Done:.*close' "$REPO_ROOT/examples/configs/github-nextjs.md"; then
  fail "G-28: examples/configs/github-nextjs.md missing 'Done: close' mapping"
fi

# G-29: gitea-spring-boot.md — Done: close
if ! grep -qE 'Done:.*close' "$REPO_ROOT/examples/configs/gitea-spring-boot.md"; then
  fail "G-29: examples/configs/gitea-spring-boot.md missing 'Done: close' mapping"
fi

# G-30: jira-react.md — Done: transition:Done
if ! grep -qE 'Done:.*transition:Done' "$REPO_ROOT/examples/configs/jira-react.md"; then
  fail "G-30: examples/configs/jira-react.md missing 'Done: transition:Done' mapping"
fi

# G-31: youtrack-python.md — Done: State: Done
if ! grep -qE 'Done:.*State: Done' "$REPO_ROOT/examples/configs/youtrack-python.md"; then
  fail "G-31: examples/configs/youtrack-python.md missing 'Done: State: Done' mapping"
fi

# G-32: redmine-rails.md — Done: status:Closed (pre-existing, must not be removed)
if ! grep -qE 'Done:.*status:Closed' "$REPO_ROOT/examples/configs/redmine-rails.md"; then
  fail "G-32: examples/configs/redmine-rails.md 'Done: status:Closed' missing or accidentally removed"
fi

# =============================================================================
# REGRESSION: Step 4e existing behavior preserved
# =============================================================================

# Epic-level issues still created
if ! grep -q 'Create Tracker Issues\|epic-level issue\|Create an epic' "$SCAFFOLD_SKILL"; then
  fail "REGRESSION: Step 4e missing epic-level issue creation (existing behavior removed)"
fi

# Accumulator pattern for epic failures still present
if ! grep -q 'accumulator pattern\|Partial failure handling\|WARN: Could not create tracker issue' "$SCAFFOLD_SKILL"; then
  fail "REGRESSION: Step 4e missing accumulator pattern / partial failure handling for epics"
fi

# Commit message for tracker links unchanged
if ! grep -q 'chore: link spec epics to tracker issues' "$SCAFFOLD_SKILL"; then
  fail "REGRESSION: Step 4e commit message 'chore: link spec epics to tracker issues' missing or changed"
fi

# Do NOT apply On start set
if ! grep -q "Do NOT apply the \`On start set\`\|Do NOT apply.*On start set" "$SCAFFOLD_SKILL"; then
  fail "REGRESSION: Step 4e missing 'Do NOT apply On start set' instruction (backward compat)"
fi

# =============================================================================
# SUMMARY
# =============================================================================

[ "$FAIL" -eq 0 ] && echo "PASS: scaffold tracker integration — all Step 4e (story sub-issues) + Step 8b (Done transition) + docs assertions verified"
exit "$FAIL"
