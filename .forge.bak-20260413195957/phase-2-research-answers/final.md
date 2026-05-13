# Phase 2 — Research Answers: Final Synthesis

## Comprehensive Audit Results

### Total Findings: 5 CRITICAL + 6 HIGH + 9 MEDIUM + 7 LOW = 27 findings

---

## Shared Agent Verdicts

| Agent | Bug-fix | Feature | Scaffold | Verdict | Priority |
|-------|---------|---------|----------|---------|----------|
| fixer | OK | BROKEN (Step 1 blocks, Step 5 TDD wrong) | BROKEN (same issues) | BROKEN | CRITICAL |
| reviewer | OK | NEEDS_UPDATE (Step 1 reads nonexistent artifacts, Step 2 "Root cause") | NEEDS_UPDATE | NEEDS_UPDATE | HIGH |
| test-engineer | OK | NEEDS_UPDATE (Step 1 "bug report", Step 3 "regression test") | NEEDS_UPDATE | NEEDS_UPDATE | HIGH |
| e2e-test-engineer | OK | NEEDS_UPDATE (Step 1 "bug report") | NEEDS_UPDATE | NEEDS_UPDATE | HIGH |
| publisher | OK | NEEDS_UPDATE (PR title "Fix:", "Root Cause" section) | N/A (not used) | NEEDS_UPDATE | HIGH |
| rollback-agent | OK | OK | OK | GOOD | — |
| acceptance-gate | OK | OK | N/A | GOOD (exemplary) | — |

## Quality Scorecard Summary

- **5/5 (14 agents):** triage-analyst, code-analyst, rollback-agent, acceptance-gate, spec-analyst, architect, spec-writer, spec-reviewer, reproducer, browser-verifier, deployment-verifier, stack-selector, scaffolder, priority-engine
- **4/5 (4 agents):** reviewer, test-engineer, e2e-test-engineer, publisher
- **3/5 (1 agent):** fixer

## Core Contract Status

| Contract | Status | Key Issue |
|----------|--------|-----------|
| fixer-reviewer-loop | NEEDS_UPDATE | Undocumented feature-mode context, NEEDS_DECOMPOSITION refs only fix-ticket |
| block-handler | NEEDS_UPDATE | Missing smoke-check in rollback triggers |
| decomposition-heuristics | NEEDS_UPDATE | Bug-only design, mislabeled in implement-feature |
| config-reader | NEEDS_UPDATE | Missing create_tracker_subtasks key |
| state-manager | GOOD | — |
| agent-override-injector | GOOD | — |
| mcp-preflight | GOOD | — |
| mcp-detection | GOOD | — |
| profile-parser | GOOD | Vestigial param (minor) |
| post-publish-hook | GOOD | — |
| fix-verification | GOOD | Language cosmetic |

## Prioritized Action Batches

### Batch 1 — CRITICAL (5 items)
1. **CRQ-1+2:** Mode signal + fixer Step 1 guard update
2. **CRQ-3:** NEEDS_DECOMPOSITION handler in implement-feature
3. **CRQ-4:** smoke-check in rollback trigger lists
4. **P2-W1:** Webhook format fix in implement-feature
5. **CRQ-5:** Fixer TDD RED phase override for feature mode

### Batch 2 — HIGH (5 items)
6. **CRQ-6+7:** Reviewer + test-engineer mode-aware Step 1
7. **CRQ-8:** Single-pass acceptance-gate compensating requirement
8. **P2-G1:** Config Validity Gate in fix-bugs
9. **P2-C1:** decomposition-heuristics mislabel fix
10. **Publisher:** Mode-aware PR title + template

### Batch 3 — MEDIUM (5 items)
11. **CRQ-10:** fixer-reviewer-loop contract update
12. **CRQ-12:** ac_source field in state schema
13. **P2-K1:** config-reader create_tracker_subtasks
14. **P2-K2:** state schema retry limit fields
15. **e2e-test-engineer:** Minor Step 1 fix

### Batch 4 — LOW (7 items)
16-22. Documentation, cosmetic fixes, dedup opportunities (tracked but not implemented in this pass)

## Key Design Decision from Research

**Mode signal approach:** Skills inject `Mode: bug-fix | feature | scaffold` prefix into agent context at dispatch time. Agents detect mode in Step 1 and branch behavior. This follows the existing acceptance-gate pattern (line 21: "from triage-analyst for bugs, spec-analyst for features").

**Three modes, not two:** While the innovative brainstormer in the prior run argued for two modes, the audit reveals publisher needs scaffold-specific behavior (no "Fix:" but also no standard PR creation since scaffold doesn't publish). Feature and scaffold are different enough at the CONTENT QUALITY level to justify explicit mode mentions even where behavior is similar — it helps the LLM understand what context it's operating in.
