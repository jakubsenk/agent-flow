# Phase 9 Prompt: Completion Report

## Persona

You are a senior release manager writing the final go/no-go report for v7.0.0. 15 years of release-management experience. Trait: you write reports that the user can act on without asking questions.

## Task Instructions

Produce a completion report at `.forge/phase-9-completion/report.md` with the following sections:

### 1. Summary

- Run ID, target version (v7.0.0), pipeline mode (adaptive), final status (PASS / WARN / FAIL).
- Top-line metrics: total tasks (20), tasks complete, tests added (16+), tests RETIRED (1), test harness final tally (PASS/FAIL/SKIP).
- Aggregate verification score and per-dimension scores.

### 2. Changes Shipped

Per release-action group:

- **Action 1 (Extra labels deletion)**: file list, line counts changed.
- **Action 2 (Pause Limits doc)**: file:line, before/after.
- **Action 3 (status -> pipeline-status rename)**: directory rename, frontmatter update, reference rewrite count.
- **Action 4 (init -> setup-mcp rename)**: same shape.
- **Action 5 (/publish auto-detect rewrite)**: skill prose summary; the 4 outcomes the rewrite handles; publisher agent change.
- **Action 6 (/create-pr deletion)**: directory removed; reference rewrite count.
- **Action 7 (collision warnings)**: README and installation.md additions.

### 3. Counts post-v7.0.0

- Skills: 29 -> 28 (`/create-pr` removed).
- Optional config sections: 19 -> 18 (`Extra labels` removed).
- Agents: 21 -> 21 (no change).
- Doc anchor files updated: 5/5.

### 4. Cross-File Invariants Verification

| Invariant | Status | Evidence |
|---|---|---|
| License SPDX MIT consistent | PASS / FAIL | command output |
| Maintainer email consistent | PASS / FAIL | command output |
| Template parity .gitea<->.github | PASS / FAIL | `diff -q` output per template |

### 5. Out-of-Scope Verification

- plugin.json version unchanged: PASS / FAIL.
- marketplace.json version unchanged: PASS / FAIL.
- No git tag `v7.0.0` created: PASS / FAIL.

### 6. NEXT STEPS FOR USER (CRITICAL)

The user runs the version bump manually after this pipeline. The exact next steps:

1. Review the diff: `git diff main`.
2. Run `./tests/harness/run-tests.sh` again locally to confirm baseline.
3. Run `/ceos-agents:version-bump 7.0.0` (this skill updates plugin.json, marketplace.json, creates the version-bump commit, and creates the `v7.0.0` git tag).
4. Push: `git push --follow-tags origin main` (or merge via PR per release convention).

**This pipeline DID NOT bump the version.** That is intentional and per the user's instruction.

### 7. Doc-Audit (per-anchor enumeration)

For each of the 5 anchor files (CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md), confirm:

- "28 skills" appears at least once.
- "29 skills" appears zero times.
- "18 optional config sections" appears at least once.
- "19 optional config sections" appears zero times.
- "21 agents" appears unchanged.

Report any drift; do not auto-fix at Phase 9 (replanning would be Phase 8 territory).

### 8. Test Harness Result Summary

Total visible scenarios: ~ (203 + 16) - 1 RETIRED = ~218.
Functional vs SKIP: report exact PASS / FAIL / SKIP counts.
New v7.0.0 scenarios: 16 (list).
RETIRED scenarios: 1 (`v6.9.0-bc-no-renamed-section.sh`).

### 9. Known Follow-ups (for roadmap)

If any of the v6.10.1 deferred items remain (autopilot dispatch audit parity, anti-pattern regex widening, README enumeration drift), note them. Otherwise: "No new roadmap items introduced in v7.0.0 - the cleanup release closed sub-projekt C; sub-projekty A+B unblock v8.0.0 brainstorm."

### 10. Pipeline Telemetry

- Tokens used (estimated + measured per Phase 0 onwards).
- Wallclock duration.
- Approval gates triggered (3, 4, 6).
- Replanning cycles (expected: 0, given high spec confidence).
- Any phase that needed retry.

## Success Criteria

- [ ] Report has all 10 sections.
- [ ] Counts in section 3 match doc-audit in section 7.
- [ ] Section 6 explicitly tells user to run `/ceos-agents:version-bump 7.0.0`.
- [ ] Section 6 explicitly states the pipeline did NOT bump the version.
- [ ] Section 4 cites command output as evidence (not "checked manually").
- [ ] Section 5 reports zero version diff (out-of-scope tripwire).
- [ ] Test harness section reports PASS for all 16 new v7.0.0 scenarios.

## Anti-Patterns

- DO NOT auto-bump the version in Phase 9.
- DO NOT auto-create the `v7.0.0` git tag.
- DO NOT auto-push.
- DO NOT cite tests that were skipped as PASS.
- DO NOT omit the cross-file invariant verification (these MUST hold per CLAUDE.md).
- DO NOT skip the doc-audit step - the v6.9.0 release shipped with 34 doc gaps because Phase 9 doc-audit checked count strings rather than enumeration completeness. v7.0.0 audit MUST enumerate.

## Codebase Context

Same compressed CODEBASE_CONTEXT. Use Phase 8 commander verdict + Phase 7 per-task artifacts as the evidence base.
