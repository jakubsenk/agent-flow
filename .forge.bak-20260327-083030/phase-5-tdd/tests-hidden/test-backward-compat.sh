#!/usr/bin/env bash
# Test: Backward compatibility — existing commands, agents, and config contract unchanged by Phase 1/2
# Hidden: catches regressions introduced during Phase 1/2 implementation
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

# ── COMPAT-001: All 18 original agents still exist ────────────────────────────
ORIGINAL_AGENTS=(
  triage-analyst code-analyst fixer reviewer acceptance-gate
  test-engineer e2e-test-engineer publisher rollback-agent spec-analyst
  architect stack-selector scaffolder priority-engine spec-writer
  spec-reviewer reproducer browser-verifier
)
for agent in "${ORIGINAL_AGENTS[@]}"; do
  if [ ! -f "$REPO_ROOT/agents/$agent.md" ]; then
    fail "COMPAT-001: Original agent file missing after Phase 1/2: agents/$agent.md"
  fi
done

# ── COMPAT-002: All 24 original commands still exist ────────────────────────────
ORIGINAL_COMMANDS=(
  analyze-bug fix-ticket fix-bugs create-pr publish version-bump
  check-setup resume-ticket status onboard init changelog version-check
  implement-feature scaffold scaffold-add scaffold-validate dashboard
  metrics estimate prioritize migrate-config template discuss
)
for cmd in "${ORIGINAL_COMMANDS[@]}"; do
  if [ ! -f "$REPO_ROOT/commands/$cmd.md" ]; then
    fail "COMPAT-002: Original command file missing after Phase 1/2: commands/$cmd.md"
  fi
done

# ── COMPAT-003: Required Automation Config sections unchanged ─────────────────
# Required sections per CLAUDE.md: Issue Tracker, Source Control, PR Rules,
# PR Description Template, Build & Test. These must NOT be changed.
if [ -f "$CLAUDE_MD" ]; then
  for section in 'Issue Tracker' 'Source Control' 'PR Rules' 'PR Description Template' 'Build & Test'; do
    if ! grep -q "$section" "$CLAUDE_MD"; then
      fail "COMPAT-003: CLAUDE.md required Automation Config section removed or renamed: '$section'"
    fi
  done
fi

# ── COMPAT-004: Required config section keys unchanged ────────────────────────
# Spot-check key names from required sections per CLAUDE.md table
if [ -f "$CLAUDE_MD" ]; then
  for key in 'Type' 'Instance' 'Project' 'Bug query' 'Remote' 'Base branch' 'Branch naming' 'Build command' 'Test command'; do
    if ! grep -q "$key" "$CLAUDE_MD"; then
      fail "COMPAT-004: CLAUDE.md required config key removed or renamed: '$key'"
    fi
  done
fi

# ── COMPAT-005: Existing optional sections still in config table ──────────────
if [ -f "$CLAUDE_MD" ]; then
  for section in 'Retry Limits' 'Hooks' 'Custom Agents' 'Notifications' 'Worktrees' 'E2E Test' 'Browser Verification' 'Error Handling' 'Feature Workflow' 'Decomposition' 'Pipeline Profiles' 'Metrics' 'Agent Overrides'; do
    if ! grep -q "$section" "$CLAUDE_MD"; then
      fail "COMPAT-005: CLAUDE.md optional config section removed or renamed: '$section'"
    fi
  done
fi

# ── COMPAT-006: Core pattern files still intact (10 files) ────────────────────
CORE_FILES=(
  config-reader mcp-preflight fixer-reviewer-loop block-handler
  agent-override-injector decomposition-heuristics profile-parser
  post-publish-hook fix-verification state-manager
)
for name in "${CORE_FILES[@]}"; do
  if [ ! -f "$REPO_ROOT/core/$name.md" ]; then
    fail "COMPAT-006: Core pattern file removed: core/$name.md"
  fi
done

# ── COMPAT-007: State schema still has schema_version field ──────────────────
if [ -f "$REPO_ROOT/state/schema.md" ]; then
  if ! grep -q 'schema_version' "$REPO_ROOT/state/schema.md"; then
    fail "COMPAT-007: state/schema.md 'schema_version' field was removed (backward compatibility broken)"
  fi
else
  fail "COMPAT-007: state/schema.md does not exist"
fi

# ── COMPAT-008: Existing agents retain correct model assignments ──────────────
OPUS_AGENTS=(fixer reviewer architect priority-engine spec-writer spec-reviewer)
for agent in "${OPUS_AGENTS[@]}"; do
  f="$REPO_ROOT/agents/$agent.md"
  if [ -f "$f" ]; then
    if ! grep -q "^model: opus$" "$f"; then
      fail "COMPAT-008: $agent.md model changed from opus — backward compatibility broken"
    fi
  fi
done

HAIKU_AGENTS=(publisher rollback-agent)
for agent in "${HAIKU_AGENTS[@]}"; do
  f="$REPO_ROOT/agents/$agent.md"
  if [ -f "$f" ]; then
    if ! grep -q "^model: haiku$" "$f"; then
      fail "COMPAT-008: $agent.md model changed from haiku — backward compatibility broken"
    fi
  fi
done

# ── COMPAT-009: fix-ticket.md still has MCP pre-flight (Step 0) ───────────────
FIX_TICKET="$REPO_ROOT/commands/fix-ticket.md"
if [ -f "$FIX_TICKET" ]; then
  if ! grep -qi 'mcp.*pre.?flight\|pre.?flight.*mcp\|MCP pre-flight\|mcp-preflight\|0\. MCP' "$FIX_TICKET"; then
    fail "COMPAT-009: fix-ticket.md missing MCP pre-flight step (Step 0) — regression from Phase 1 changes"
  fi
fi

# ── COMPAT-010: implement-feature.md still processes Issue ID path ────────────
IMPLEMENT="$REPO_ROOT/commands/implement-feature.md"
if [ -f "$IMPLEMENT" ]; then
  if ! grep -qi 'Issue ID\|ISSUE-ID\|issue_id\|ticket.*ID' "$IMPLEMENT"; then
    fail "COMPAT-010: implement-feature.md no longer references Issue ID path — existing behavior broken"
  fi
fi

# ── COMPAT-011: scaffold.md Steps 1-10 still present after Step 4b/4c insertion
SCAFFOLD="$REPO_ROOT/commands/scaffold.md"
if [ -f "$SCAFFOLD" ]; then
  # Verify key steps still exist — match '### Step N:' format used in scaffold.md
  for step_pattern in 'Step 1:' 'Step 4:' 'Step 5:' 'Step 10:'; do
    if ! grep -q "$step_pattern" "$SCAFFOLD"; then
      fail "COMPAT-011: scaffold.md missing step matching '$step_pattern' — regression from Step 4b/4c insertion"
    fi
  done
fi

# ── COMPAT-012: fixer.md and reviewer.md Process sections unchanged ────────────
# Spot-check for core loop content that must not be accidentally removed
FIXER="$REPO_ROOT/agents/fixer.md"
REVIEWER="$REPO_ROOT/agents/reviewer.md"
if [ -f "$FIXER" ]; then
  if ! grep -qi 'TDD\|red.*green\|test.*first\|failing.*test' "$FIXER"; then
    fail "COMPAT-012: fixer.md lost TDD red-green-refactor content — regression"
  fi
fi
if [ -f "$REVIEWER" ]; then
  if ! grep -qi 'AC Fulfillment\|FULFILLED\|PARTIALLY\|NOT ADDRESSED' "$REVIEWER"; then
    fail "COMPAT-012: reviewer.md lost AC Fulfillment section — regression"
  fi
fi

# ── COMPAT-013: Block comment format documented in CLAUDE.md unchanged ────────
# The [ceos-agents] 🔴 Pipeline Block format is defined in CLAUDE.md and referenced by commands
if [ -f "$CLAUDE_MD" ]; then
  if ! grep -q '\[ceos-agents\].*Pipeline Block\|\[ceos-agents\] 🔴' "$CLAUDE_MD"; then
    fail "COMPAT-013: CLAUDE.md lost [ceos-agents] Pipeline Block format definition — regression"
  fi
fi

# ── COMPAT-014: Plugin metadata files intact ──────────────────────────────────
if [ ! -f "$REPO_ROOT/.claude-plugin/plugin.json" ]; then
  fail "COMPAT-014: .claude-plugin/plugin.json missing — plugin metadata removed"
fi
if [ ! -f "$REPO_ROOT/.claude-plugin/marketplace.json" ]; then
  fail "COMPAT-014: .claude-plugin/marketplace.json missing — plugin metadata removed"
fi

# ── COMPAT-015: No new required keys added to Automation Config ───────────────
# Verify fix-ticket and implement-feature (pipeline commands) do not require
# Local Deployment section for basic operation (it must remain optional)
if [ -f "$FIX_TICKET" ]; then
  if grep -qi 'Local Deployment.*required\|required.*Local Deployment\|must.*Local Deployment' "$FIX_TICKET"; then
    fail "COMPAT-015: fix-ticket.md treats Local Deployment as REQUIRED — must remain optional"
  fi
fi
if [ -f "$IMPLEMENT" ]; then
  if grep -qi 'Local Deployment.*required\|required.*Local Deployment\|must.*Local Deployment' "$IMPLEMENT"; then
    fail "COMPAT-015: implement-feature.md treats Local Deployment as REQUIRED — must remain optional"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Backward compatibility tests passed — no regressions from Phase 1/2 changes"
exit "$FAIL"
