#!/usr/bin/env bash
# v9.1.0-workflow-router-removed.sh — REQ-V910-001, REQ-V910-002, REQ-V910-003,
# REQ-V910-003b, REQ-V910-004, REQ-V910-005 (dir count), REQ-V910-014,
# REQ-V910-014b, REQ-V910-015, REQ-V910-016, REQ-V910-017:
# Asserts all router deletion artifacts are absent and skills/ count is 18.
# v9.5.0 reduced skills 22→18; this test updated 2026-05-09 to reflect post-cleanup baseline.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# REQ-V910-001: skills/workflow-router/ directory must not exist.
# ---------------------------------------------------------------------------
echo "--- REQ-V910-001: skills/workflow-router/ absent ---"
if [ -d "$REPO_ROOT/skills/workflow-router" ]; then
  fail "skills/workflow-router/ directory still exists — router deletion required"
else
  echo "OK: skills/workflow-router/ does not exist"
fi

# ---------------------------------------------------------------------------
# REQ-V910-005 (dir count): skills/ directory must have exactly 18 entries.
# (Updated for v9.5.0: estimate, migrate-config, pipeline-status, scaffold-validate removed.)
# ---------------------------------------------------------------------------
echo "--- REQ-V910-005: skills/ contains exactly 18 directories ---"
actual_count=$(find "$REPO_ROOT/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
if [ "$actual_count" -eq 18 ]; then
  echo "OK: skills/ contains exactly 18 directories"
else
  fail "skills/ directory count: expected 18, found $actual_count"
fi

# ---------------------------------------------------------------------------
# REQ-V910-002: sprint-workflow-router.sh must not exist.
# ---------------------------------------------------------------------------
echo "--- REQ-V910-002: sprint-workflow-router.sh absent ---"
if [ -f "$REPO_ROOT/tests/scenarios/sprint-workflow-router.sh" ]; then
  fail "tests/scenarios/sprint-workflow-router.sh still exists — must be deleted"
else
  echo "OK: tests/scenarios/sprint-workflow-router.sh does not exist"
fi

# ---------------------------------------------------------------------------
# REQ-V910-003: v7.0.0-workflow-router-intent-table.sh must not exist.
# ---------------------------------------------------------------------------
echo "--- REQ-V910-003: v7.0.0-workflow-router-intent-table.sh absent ---"
if [ -f "$REPO_ROOT/tests/scenarios/v7.0.0-workflow-router-intent-table.sh" ]; then
  fail "tests/scenarios/v7.0.0-workflow-router-intent-table.sh still exists — must be deleted"
else
  echo "OK: tests/scenarios/v7.0.0-workflow-router-intent-table.sh does not exist"
fi

# ---------------------------------------------------------------------------
# REQ-V910-003b: v7.0.0-skill-rename-status.sh must not exist.
# (DA-001/DA-010: full-delete, not surgical — test has 5 positive assertions
# on skills/workflow-router/SKILL.md content and a hard-exit guard at L20.)
# ---------------------------------------------------------------------------
echo "--- REQ-V910-003b: v7.0.0-skill-rename-status.sh absent ---"
if [ -f "$REPO_ROOT/tests/scenarios/v7.0.0-skill-rename-status.sh" ]; then
  fail "tests/scenarios/v7.0.0-skill-rename-status.sh still exists — must be deleted (DA-001/DA-010: 5 positive router assertions, surgical edit insufficient)"
else
  echo "OK: tests/scenarios/v7.0.0-skill-rename-status.sh does not exist"
fi

# ---------------------------------------------------------------------------
# REQ-V910-014: v9-overlay-dispatch-wiring.sh must not exist.
# REQ-V910-015: v9-overlay-legacy-md-policy.sh must not exist.
# REQ-V910-016: v9-overlay-provenance-log-emission.sh must not exist.
# REQ-V910-017: v9-overlay-toml-render-layout.sh must not exist.
# (forge-staging-orphan tests: depend on transient .forge/ spec content)
# ---------------------------------------------------------------------------
echo "--- REQ-V910-014..017: v9-overlay forge-orphan tests absent ---"
for orphan_file in \
  "tests/scenarios/v9-overlay-dispatch-wiring.sh" \
  "tests/scenarios/v9-overlay-legacy-md-policy.sh" \
  "tests/scenarios/v9-overlay-provenance-log-emission.sh" \
  "tests/scenarios/v9-overlay-toml-render-layout.sh"
do
  if [ -f "$REPO_ROOT/$orphan_file" ]; then
    fail "$orphan_file still exists — forge-staging-orphan, must be deleted"
  else
    echo "OK: $orphan_file does not exist"
  fi
done

# ---------------------------------------------------------------------------
# REQ-V910-014b: v8-steps-override-replace.sh must not exist.
# (Round-2 BLOCKER 1: forge-staging-orphan by class — checks .forge/ transient
# spec content; currently passing by coincidence; deletion is mandatory.)
# ---------------------------------------------------------------------------
echo "--- REQ-V910-014b: v8-steps-override-replace.sh absent ---"
if [ -f "$REPO_ROOT/tests/scenarios/v8-steps-override-replace.sh" ]; then
  fail "tests/scenarios/v8-steps-override-replace.sh still exists — forge-staging-orphan-by-class, must be deleted (Round-2 BLOCKER 1)"
else
  echo "OK: tests/scenarios/v8-steps-override-replace.sh does not exist"
fi

# ---------------------------------------------------------------------------
# REQ-V910-004: skills-directory-structure.sh must NOT contain workflow-router.
# ---------------------------------------------------------------------------
echo "--- REQ-V910-004: skills-directory-structure.sh has no workflow-router ---"
DSS="$REPO_ROOT/tests/scenarios/skills-directory-structure.sh"
if [ ! -f "$DSS" ]; then
  fail "tests/scenarios/skills-directory-structure.sh not found — cannot verify"
else
  wf_count=$(grep -c 'workflow-router' "$DSS" 2>/dev/null | tr -d '[:space:]' || echo 0)
  if [ "$wf_count" -eq 0 ]; then
    echo "OK: skills-directory-structure.sh contains no workflow-router references"
  else
    fail "skills-directory-structure.sh still contains $wf_count workflow-router reference(s)"
  fi

  # Also verify the EXPECTED_SKILLS array has exactly 18 entries.
  # Extract lines between EXPECTED_SKILLS=( and the closing ) and count
  # non-blank, non-comment entries (simple skill name lines).
  array_count=$(awk '/EXPECTED_SKILLS=\(/{flag=1;next} /^\)/{flag=0} flag && /^[[:space:]]*[a-z]/{count++} END{print count+0}' "$DSS")
  if [ "$array_count" -eq 18 ]; then
    echo "OK: EXPECTED_SKILLS array in skills-directory-structure.sh has 18 entries"
  else
    fail "EXPECTED_SKILLS array in skills-directory-structure.sh has $array_count entries (expected 18)"
  fi
fi

# ---------------------------------------------------------------------------
# Final verdict.
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.1.0-workflow-router-removed — all deletion assertions satisfied; 18 skills"
fi
exit "$FAIL"
