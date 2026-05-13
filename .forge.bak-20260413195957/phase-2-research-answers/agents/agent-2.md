# Phase 2 — Agent 2: Core Contracts, State Schema, Consistency, Prioritized Summary

**Date:** 2026-04-13
**Scope:** Output 4 (Core Contract Assessment), Output 5 (State Schema Assessment), Output 6 (Consistency Findings), Output 7 (Prioritized Findings Summary)

---

## Output 4: Core Contract Assessment

### Contract: config-reader
**File:** `core/config-reader.md`
**Referenced by:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/check-deploy/SKILL.md`
**Mode assumptions:** None — generic config parser
**Input contract completeness:** OK
**Output contract completeness:** ISSUE — `decomposition.create_tracker_subtasks` key is used by all three pipeline skills (fix-ticket, fix-bugs, implement-feature) but is not listed in the config-reader Decomposition section parsing. The section at line 33 lists only `max_subtasks`, `fail_strategy`, `commit_strategy`. The `Create tracker subtasks` key (default: `enabled`) is missing from the config-reader contract.
**Verdict:** NEEDS_UPDATE
**Recommendations:**
1. Add `decomposition.create_tracker_subtasks` (default: `enabled`) to the Decomposition optional section parsing at line 33.
2. Phase 1 finding CONFIRMED.

---

### Contract: block-handler
**File:** `core/block-handler.md`
**Referenced by:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`
**Mode assumptions:** None — generic block protocol
**Input contract completeness:** OK
**Output contract completeness:** OK
**Verdict:** NEEDS_UPDATE
**Recommendations:**
1. Phase 1 CRQ-4 CONFIRMED: Rollback trigger list (line 21) specifies `fixer`, `reviewer`, or `test-engineer` but omits `smoke-check`. When smoke-check blocks in implement-feature Step 6d-smoke or fix-ticket Step 7a, rollback is skipped and git remains dirty.
2. Add `smoke-check` to the rollback trigger list, or (better) switch to a denylist approach: specify agents that should NOT trigger rollback (triage-analyst, code-analyst, spec-analyst, architect, stack-selector, publisher, scaffolder); all others default to rollback.
3. implement-feature references `core/block-handler.md` at Step X (line 604) but then inlines the full block procedure (lines 606-626). This inlined copy has webhook format inconsistencies (see Output 6). The reference + inline duplication is fragile. Recommendation: Either reference-only or inline-only, not both.

---

### Contract: decomposition-heuristics
**File:** `core/decomposition-heuristics.md`
**Referenced by:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`
**Mode assumptions:** YES — designed exclusively for code-analyst output (Input Contract requires `code_analyst_output` with fields `risk`, `affected_files`, `estimated_diff_lines`, `independent_changes`). Feature pipeline has no code-analyst phase.
**Input contract completeness:** ISSUE — only accepts code-analyst fields; no architect-mode input.
**Output contract completeness:** OK
**Verdict:** NEEDS_UPDATE
**Recommendations:**
1. Phase 1 CRQ-11 CONFIRMED: Feature pipeline bypasses this contract entirely. `implement-feature/SKILL.md` line 200 says "Follow `core/decomposition-heuristics.md`" but the inline steps (cycle check, topological sort, max_subtasks validation, AC coverage check) bear no resemblance to the contract's threshold-based heuristics. This is a **mislabel** — the reference is misleading.
2. Either: (a) Add explicit note that this contract is bug-pipeline-only and remove the false reference from implement-feature, OR (b) generalize with a `source` discriminated union field.
3. fix-bugs inlines the same threshold rules (lines 156-164) rather than simply referencing the contract, creating subtle divergence risk.

---

### Contract: agent-override-injector
**File:** `core/agent-override-injector.md`
**Referenced by:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`
**Mode assumptions:** None — generic injector
**Input contract completeness:** OK
**Output contract completeness:** OK
**Verdict:** GOOD
**Recommendations:** None. Clean, well-defined contract.

---

### Contract: fix-verification
**File:** `core/fix-verification.md`
**Referenced by:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`
**Mode assumptions:** Minor — uses "Fix" language ("Fix verified", "Fix verification failed") even when used in feature pipeline. Cosmetic issue.
**Input contract completeness:** OK
**Output contract completeness:** OK
**Verdict:** GOOD
**Recommendations:**
1. LOW: Consider mode-neutral language ("Verification passed" / "Verification failed") since this is now used by implement-feature too.

---

### Contract: fixer-reviewer-loop
**File:** `core/fixer-reviewer-loop.md`
**Referenced by:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`
**Mode assumptions:** YES — Input Contract line 13 documents `context` field as "Bug report or spec + AC + code-analyst output". The "or spec" acknowledgment exists but `acceptance_criteria` source is documented only as "AC list from triage-analyst output" (line 14). Feature pipeline provides AC from spec-analyst.
**Input contract completeness:** ISSUE — no dual-mode context shape documented. `code-analyst output` is not available in feature pipeline.
**Output contract completeness:** OK
**Verdict:** NEEDS_UPDATE
**Recommendations:**
1. Phase 1 CRQ-10 CONFIRMED: Add discriminated union for context shapes: `context_type: "bug" | "feature"`. Update acceptance_criteria source note to include spec-analyst.
2. The NEEDS_DECOMPOSITION handling (line 44) references only `skills/fix-ticket/SKILL.md` — should also reference implement-feature, which currently has NO handler for this signal (CRQ-3).

---

### Contract: mcp-detection
**File:** `core/mcp-detection.md`
**Referenced by:** `skills/scaffold/SKILL.md`, `skills/init/SKILL.md`
**Mode assumptions:** None — generic MCP detection
**Input contract completeness:** OK
**Output contract completeness:** OK — includes structured `error_type` classification
**Verdict:** GOOD
**Recommendations:** None. Well-documented with Classification Reference table.

---

### Contract: mcp-preflight
**File:** `core/mcp-preflight.md`
**Referenced by:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`
**Mode assumptions:** None
**Input contract completeness:** OK
**Output contract completeness:** OK
**Verdict:** GOOD
**Recommendations:** None.

---

### Contract: post-publish-hook
**File:** `core/post-publish-hook.md`
**Referenced by:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`
**Mode assumptions:** None
**Input contract completeness:** OK
**Output contract completeness:** OK
**Verdict:** GOOD
**Recommendations:**
1. LOW: The webhook curl in this contract uses heredoc format (`--data-binary @- <<EOF`) while skills use `-d '...'`. These are functionally equivalent but aesthetically inconsistent. Consider aligning.

---

### Contract: profile-parser
**File:** `core/profile-parser.md`
**Referenced by:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`
**Mode assumptions:** None — generic profile parser
**Input contract completeness:** OK
**Output contract completeness:** OK
**Verdict:** GOOD
**Recommendations:** None.

---

### Contract: state-manager
**File:** `core/state-manager.md`
**Referenced by:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/check-deploy/SKILL.md`
**Mode assumptions:** None — generic state persistence
**Input contract completeness:** OK
**Output contract completeness:** OK
**Verdict:** GOOD
**Recommendations:**
1. LOW: The resume process (lines 37-42) mentions "see resume-ticket.md existing logic" for heuristic fallback — this is a forward reference to a skill, not a core contract. Consider documenting the heuristic inline or making it a separate core contract.

---

### Core Contract Summary

| Contract | Verdict | Issues |
|----------|---------|--------|
| config-reader | NEEDS_UPDATE | Missing `create_tracker_subtasks` key |
| block-handler | NEEDS_UPDATE | Missing `smoke-check` in rollback triggers; implement-feature inlines + references (fragile duplication) |
| decomposition-heuristics | NEEDS_UPDATE | Bug-only design; implement-feature mislabels it as its reference |
| agent-override-injector | GOOD | — |
| fix-verification | GOOD | Minor: bug-only language |
| fixer-reviewer-loop | NEEDS_UPDATE | No dual-mode context shape; NEEDS_DECOMPOSITION refs only fix-ticket |
| mcp-detection | GOOD | — |
| mcp-preflight | GOOD | — |
| post-publish-hook | GOOD | Minor: curl format inconsistency |
| profile-parser | GOOD | — |
| state-manager | GOOD | Minor: forward reference to skill |

**Score: 7/11 GOOD, 4/11 NEEDS_UPDATE, 0/11 BROKEN**

---

## Output 5: State Schema Assessment

### Field Overloading

**1. `triage.*` reused for spec-analyst in feature mode**
- CONFIRMED. `skills/implement-feature/SKILL.md` line 182: `set triage.status to "completed" (field reused for spec-analyst AC), write spec-analyst AC list to triage.acceptance_criteria`
- `skills/scaffold/SKILL.md` line 434: `set triage.status to "completed" (field reused for spec-writer phase), write total AC count to triage.acceptance_criteria`
- Both explicitly acknowledge the reuse in inline comments, but `state/schema.md` does not document this dual provenance. The schema describes `triage.acceptance_criteria` generically as "Full AC text items" without noting that in `code-feature` mode it comes from spec-analyst, and in `code-project` mode from spec-writer.
- `triage.severity`, `triage.area`, `triage.complexity`, `triage.reproduction_steps` — these fields are never written in feature or scaffold mode, remaining null. This is harmless but semantically confusing (why does a feature run have a `triage` section?).

**2. `code_analysis.*` reused for architect in feature mode**
- CONFIRMED. `skills/implement-feature/SKILL.md` line 192: `set code_analysis.status to "completed" (field reused for architect output)`
- `skills/scaffold/SKILL.md` line 483: `set code_analysis.status to "completed" (field reused for scaffolder phase)`
- The `code_analysis.risk`, `code_analysis.affected_files`, `code_analysis.estimated_diff_lines` fields are never written in feature/scaffold mode — only `status` is set. This means the schema section is mostly empty in non-bug pipelines.

**3. `decomposition.*` — consistent across pipelines**
- No overloading detected. All three pipeline skills (fix-ticket, fix-bugs, implement-feature) write `decomposition.decision`, `decomposition.subtasks`, `decomposition.strategy` with consistent semantics.

**4. `fixer_reviewer.ac_fulfillment` — written correctly but undocumented source**
- In bug mode: AC comes from triage-analyst. In feature mode: AC comes from spec-analyst. The schema does not note this distinction. Impact: minimal at runtime but confusing for tooling/reporting.

### Missing Fields

**1. Scaffold-specific sections: NOT needed (confirmed)**
- Scaffold pipeline reuses `triage.*` (for spec-writer), `code_analysis.*` (for scaffolder), `fixer_reviewer.*`, `test.*`, and `decomposition.*`. The `infrastructure` object is scaffold-only and already exists in the schema. No additional scaffold-specific section is required.

**2. `triage.ac_source` field: MISSING**
- Phase 1 CRQ-12 CONFIRMED. Currently no way to programmatically determine whether `triage.acceptance_criteria` was populated by triage-analyst, spec-analyst, or spec-writer.
- Proposed: `triage.ac_source: string | null` with values `"triage-analyst"` | `"spec-analyst"` | `"spec-writer"`.

**3. `mode` field: EXISTS and could disambiguate**
- The top-level `mode` field (`code-bugfix`, `code-feature`, `code-project`) exists and can theoretically disambiguate the source. However, no consumer documentation instructs readers to use `mode` for this purpose.

**4. `config.retry_limits.spec_iterations` and `config.retry_limits.root_cause_iterations`: MISSING from schema**
- `state/schema.md` line 150-153 defines `config.retry_limits` with only `fixer_iterations`, `test_attempts`, `build_retries`. The config-reader (line 23) parses 5 retry limits including `spec_iterations` (default 5) and `root_cause_iterations` (default 3). These are not represented in the state schema. Impact: resume cannot restore these limits from state.json.

**5. `deployment.health_check` vs `deployment.health_url`: REDUNDANT**
- Schema lines 237-238 define both `deployment.health_check` and `deployment.health_url` described as "Alias for health_check (backward compatibility)". This creates ambiguity for consumers — which field to read? Should be consolidated with a single canonical name and deprecation note.

**6. `e2e_test` section: SPARSE**
- Schema line 98-99: `e2e_test` has only `status`. No test result, error message, or execution time. Compare with `test` section (status, attempts, max_attempts, last_result) and `browser_verification` (status, result_path, verdict). This is an under-documented section.

### Recommendations

1. **HIGH:** Add `triage.ac_source` field (`"triage-analyst"` | `"spec-analyst"` | `"spec-writer"` | `null`). Update all three pipeline skills to write this field.
2. **MEDIUM:** Add `config.retry_limits.spec_iterations` and `config.retry_limits.root_cause_iterations` to the schema.
3. **MEDIUM:** Add documentation notes on `triage.*` and `code_analysis.*` explaining dual provenance (bug vs. feature vs. scaffold). Reference the `mode` field as the disambiguator.
4. **LOW:** Consolidate `deployment.health_check` and `deployment.health_url` — deprecate one.
5. **LOW:** Expand `e2e_test` section to include `verdict`, `result_path`, and `attempts` fields for parity with other phase objects.

---

## Output 6: Consistency Findings

### 6.1: fix-ticket vs. fix-bugs — Duplicated Logic

**Create Tracker Subtasks** — MASSIVE DUPLICATION:
- `fix-ticket/SKILL.md` lines 203-397 (step 4b-tracker): ~195 lines
- `fix-bugs/SKILL.md` lines 190-371 (step 3b-tracker): ~182 lines
- `implement-feature/SKILL.md` lines 246-427 (step 5a): ~182 lines
- These are **verbatim copies** of the same pseudocode: triple gate, idempotency check, per-tracker MCP creation, GitHub/Gitea checklist, commit YAML, result display. Identical down to the variable names and comments.
- **Risk:** Any fix to the tracker creation logic must be applied in 3 places simultaneously. A future discrepancy is virtually guaranteed.
- **Recommendation:** Extract to a core contract `core/tracker-subtask-creator.md` referenced by all three skills.

**Subtask Execution Logic** — SIGNIFICANT DUPLICATION:
- `fix-ticket/SKILL.md` step 4c (lines 386-418): subtask execution, rollback, squash
- `fix-bugs/SKILL.md` step 3c (lines 372-405): identical logic
- `implement-feature/SKILL.md` step 6 (lines 428-541): similar but expanded (adds smoke-check, acceptance-gate, deployment guard)
- Fix-ticket and fix-bugs are near-identical. Implement-feature adds unique steps.
- **Recommendation:** Extract shared subtask execution loop to core contract; implement-feature extends with its additional steps.

**Block Handler** — PARTIALLY DUPLICATED:
- `fix-ticket/SKILL.md` Step X (lines 600-604): References `core/block-handler.md` with minimal inline.
- `fix-bugs/SKILL.md` Step X (lines 631-671): References `core/block-handler.md` then adds block counter logic (lines 667-669). This is a legitimate extension.
- `implement-feature/SKILL.md` Step X (lines 602-626): References `core/block-handler.md` BUT THEN inlines the full 6-step block procedure. This creates drift risk.

**Config Parsing** — PARTIALLY DUPLICATED:
- All three skills list their config requirements inline. fix-ticket and fix-bugs are nearly identical (fix-bugs adds Worktrees and Max blocked per run). implement-feature adds Feature Workflow and Decomposition keys but omits Browser Verification.
- This is acceptable — each skill documents its own config surface.

### 6.2: NEEDS_DECOMPOSITION Handler Comparison

| Skill | NEEDS_DECOMPOSITION handled? | Handler behavior |
|-------|------------------------------|------------------|
| `fix-ticket` | YES (Step 5) | Authoritative revert, check --no-decompose, check 1-per-ticket limit, run architect, continue subtask execution |
| `fix-bugs` | YES (Step 4) | Identical to fix-ticket |
| `implement-feature` | **NO** | No handler. Signal falls through. CRQ-3 BLOCKING confirmed. |
| `scaffold` | N/A | Scaffold does not invoke fixer directly in a mode where NEEDS_DECOMPOSITION would occur at the top level; uses fixer-reviewer loop for feature plan execution but the subtask context makes NEEDS_DECOMPOSITION less likely (scope already constrained by architect). However, it IS theoretically possible and unhandled. |

**Additional finding:** `core/fixer-reviewer-loop.md` line 44 references only `skills/fix-ticket/SKILL.md step 5` for NEEDS_DECOMPOSITION handling. Missing references to fix-bugs and (absent) implement-feature handlers.

### 6.3: Block Comment Template Consistency

**Core contract template** (`core/block-handler.md` lines 29-36):
```
[ceos-agents] Pipeline Block
Agent: {agent_name}
Step: {step_name}
Reason: {reason}
Detail: {detail}
Recommendation: {recommendation}
```

**Skill inline templates** — all three skills reproduce this template identically in their Step X sections. No format drift detected.

**Config Validity Gate template** (`fix-ticket` line 93-101, `implement-feature` line 103-113):
- Uses `Agent: config-validator` (not a real agent name — it is an inline validation step).
- Uses the same 6-field format. Consistent.

**MCP pre-flight template** (`implement-feature` lines 74-82):
- Uses `Agent: implement-feature` (the skill itself, not an agent).
- Consistent format otherwise.

### 6.4: Webhook Format Inconsistencies

**CRITICAL INCONSISTENCY found in implement-feature:**

`implement-feature/SKILL.md` (lines 582, 623):
```bash
curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"pr-created","issue":"{issue_id}","pr":"{pr_url}"}'
curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"issue-blocked","issue":"{issue_id}","agent":"{agent}","reason":"{reason}"}'
```

`fix-bugs/SKILL.md` (lines 578-579, 660-661) and `core/block-handler.md` and `core/post-publish-hook.md`:
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"pr-created","issue_id":"{issue}","pr_url":"{url}","timestamp":"{ISO8601}"}' \
```

**Differences:**
1. implement-feature MISSING `--max-time 5 --retry 0` — webhook calls can hang indefinitely.
2. implement-feature uses JSON key `"issue"` — fix-bugs and core contracts use `"issue_id"`.
3. implement-feature uses JSON key `"pr"` — fix-bugs and core contracts use `"pr_url"`.
4. implement-feature MISSING `"timestamp"` field in webhook payloads.

These are breaking differences for any webhook consumer expecting a consistent payload schema across pipelines.

### 6.5: Config Validity Gate (Step 0b) Missing from fix-bugs

- `fix-ticket/SKILL.md` — has Step 0b Config Validity Gate (lines 87-105)
- `implement-feature/SKILL.md` — has Step 0b Config Validity Gate (lines 95-116)
- `fix-bugs/SKILL.md` — **MISSING**. No Config Validity Gate. fix-bugs proceeds directly from MCP pre-flight to fetching bugs.

**Impact:** Projects with incomplete Automation Config (containing `<!-- TODO: -->` placeholders) will be caught by fix-ticket and implement-feature but will slip through fix-bugs, potentially causing mid-pipeline failures when incomplete config values are used.

### 6.6: Decomposition-heuristics Mislabel in implement-feature

`implement-feature/SKILL.md` line 200: "Follow `core/decomposition-heuristics.md`:"
But the inline steps that follow (lines 201-206: cycle check, topological sort, max_subtasks, field validation) are **completely different** from decomposition-heuristics.md content (threshold-based decision using code-analyst risk/affected_files/estimated_diff_lines/independent_changes). The reference is wrong — implement-feature does NOT follow decomposition-heuristics.md at all. It performs its own task-tree validation logic.

`fix-ticket/SKILL.md` line 174: "Follow `core/decomposition-heuristics.md` to determine DECOMPOSE vs SINGLE_PASS." — This reference IS correct. fix-ticket uses the threshold-based heuristic.

`fix-bugs/SKILL.md` line 148: "Follow `core/decomposition-heuristics.md` to determine DECOMPOSE vs SINGLE_PASS." — Then ALSO inlines the thresholds at lines 158-164. Duplication with the contract, creating divergence risk.

---

## Output 7: Prioritized Findings Summary

Consolidation of Phase 1 CRQ-1 through CRQ-12 plus all Phase 2 findings.

### CRITICAL: Pipeline Failures

| ID | Finding | File(s) | Impact |
|----|---------|---------|--------|
| CRQ-1 | Fixer hard-blocks on missing "triage analysis" — feature pipeline never produces this artifact | `agents/fixer.md` Step 1 | Every implement-feature fixer invocation risks hard Block |
| CRQ-2 | No pipeline mode signal passed to shared agents (fixer, reviewer, test-engineer) | `skills/implement-feature/SKILL.md` Steps 6b/6d/6e | All three quality agents infer context from absent artifacts — unreliable |
| CRQ-3 | NEEDS_DECOMPOSITION from fixer has no handler in implement-feature | `skills/implement-feature/SKILL.md` Step 6b, `core/fixer-reviewer-loop.md` | Signal falls through; pipeline reaches undefined state |
| CRQ-4 | smoke-check not in rollback trigger list — git remains dirty after block | `core/block-handler.md` line 21, `agents/rollback-agent.md` | Dirty git state on resume after smoke-check failure |
| P2-W1 | Webhook format inconsistency in implement-feature: missing `--max-time`, wrong JSON keys (`issue` vs `issue_id`, `pr` vs `pr_url`), missing `timestamp` | `skills/implement-feature/SKILL.md` lines 582, 623 | Webhook consumers receive inconsistent payloads; implement-feature webhooks can hang indefinitely |

### HIGH: Incorrect Behavior, Wrong Instructions

| ID | Finding | File(s) | Impact |
|----|---------|---------|--------|
| CRQ-5 | Fixer identity anchored to bug-fix; TDD RED phase instructs "reproduce the bug" | `agents/fixer.md` frontmatter, Step 5 | Feature tests discarded if they pass immediately ("test does not capture the actual bug") |
| CRQ-6 | Reviewer reads bug-specific artifacts silently; AC Fulfillment does activate via fallback | `agents/reviewer.md` Steps 1/2 | Partial quality degradation — root cause check meaningless for features |
| CRQ-7 | Test-engineer reads "bug report" and requires "regression test" label | `agents/test-engineer.md` Steps 1/3 | Under-testing of features; wrong test framing |
| CRQ-8 | Single-pass features skip acceptance-gate entirely | `skills/implement-feature/SKILL.md` Step 6h | Asymmetric quality: decomposed features get evidence-backed AC check; single-pass do not |
| P2-G1 | fix-bugs missing Config Validity Gate (Step 0b) | `skills/fix-bugs/SKILL.md` | Incomplete config slips through fix-bugs but is caught by fix-ticket/implement-feature |
| P2-C1 | decomposition-heuristics mislabeled in implement-feature — "Follow core/decomposition-heuristics.md" but inline steps are completely different logic | `skills/implement-feature/SKILL.md` line 200 | Misleading reference; maintainers may change the wrong file |

### MEDIUM: Quality Gaps, Missing Best Practices

| ID | Finding | File(s) | Impact |
|----|---------|---------|--------|
| CRQ-9 | No scope containment check — fixer can modify future-subtask files; `git add -A` commits all | `skills/implement-feature/SKILL.md` Step 6b/6i | Cross-subtask interference in decomposition mode |
| CRQ-10 | fixer-reviewer-loop.md context contract undocumented for feature mode | `core/fixer-reviewer-loop.md` | Maintainability risk — implicit coupling |
| CRQ-11 | decomposition-heuristics.md designed for code-analyst inputs only; undocumented as bug-only | `core/decomposition-heuristics.md` | Misleading contract scope |
| CRQ-12 | state.json `triage.acceptance_criteria` written by 3 different agents; no `ac_source` tag | `state/schema.md` | Cannot programmatically determine AC provenance |
| P2-K1 | config-reader.md missing `decomposition.create_tracker_subtasks` key | `core/config-reader.md` line 33 | Config contract incomplete — key used by 3 skills but not documented in parser |
| P2-K2 | state schema missing `config.retry_limits.spec_iterations` and `root_cause_iterations` | `state/schema.md` lines 150-153 | Resume cannot restore these limits from state |
| P2-D1 | Create Tracker Subtasks logic duplicated verbatim across 3 skills (~180 lines each = ~540 lines total) | `fix-ticket`, `fix-bugs`, `implement-feature` | Any fix must be applied 3 times; divergence guaranteed |
| P2-D2 | fix-bugs inlines decomposition thresholds (lines 158-164) instead of referencing core contract only | `skills/fix-bugs/SKILL.md` | Divergence risk with `core/decomposition-heuristics.md` |
| P2-S1 | `deployment.health_check` vs `deployment.health_url` redundant fields in schema | `state/schema.md` lines 237-238 | Consumer ambiguity — which field to read? |

### LOW: Cosmetic, Documentation

| ID | Finding | File(s) | Impact |
|----|---------|---------|--------|
| P2-L1 | fix-verification.md uses "Fix" language even for feature pipeline | `core/fix-verification.md` | Cosmetic |
| P2-L2 | post-publish-hook.md uses heredoc format; skills use inline `-d`; implement-feature uses neither `--max-time` nor `--retry 0` | `core/post-publish-hook.md` vs skills | Format inconsistency (functional ones are captured in P2-W1 above) |
| P2-L3 | state-manager.md resume process references "resume-ticket.md existing logic" — forward reference to a skill | `core/state-manager.md` line 42 | Documentation clarity |
| P2-L4 | `e2e_test` schema section has only `status` field — no verdict, result_path, or attempts | `state/schema.md` line 98-99 | Under-documented compared to peer sections |
| P2-L5 | implement-feature Step X block handler both references core contract AND inlines 6 steps | `skills/implement-feature/SKILL.md` lines 602-626 | Fragile duplication |
| P2-L6 | `triage.*` and `code_analysis.*` field reuse acknowledged in inline comments but not in schema docs | `state/schema.md` | Documentation gap |
| P2-L7 | fixer-reviewer-loop.md NEEDS_DECOMPOSITION handling references only fix-ticket, not fix-bugs or implement-feature | `core/fixer-reviewer-loop.md` line 44 | Incomplete cross-reference |

---

### Priority Action Plan

**Batch 1 — CRITICAL (must fix before production use):**
1. CRQ-1 + CRQ-2: Add mode signal to shared agent dispatches in implement-feature; update fixer/reviewer/test-engineer guards
2. CRQ-3: Add NEEDS_DECOMPOSITION handler in implement-feature Step 6b
3. CRQ-4: Add smoke-check to block-handler and rollback-agent trigger lists
4. P2-W1: Fix implement-feature webhook format (add --max-time, use correct JSON keys, add timestamp)

**Batch 2 — HIGH (before GA):**
5. CRQ-5: Add feature-mode TDD override in implement-feature fixer dispatch
6. CRQ-6 + CRQ-7: Add mode-branch to reviewer and test-engineer Step 1
7. CRQ-8: Add compensating requirement for single-pass feature AC verification
8. P2-G1: Add Config Validity Gate (Step 0b) to fix-bugs
9. P2-C1: Fix decomposition-heuristics mislabel in implement-feature line 200

**Batch 3 — MEDIUM (tech debt):**
10. CRQ-9 through CRQ-12: Scope containment, loop contract, heuristics scope, ac_source
11. P2-K1: Add create_tracker_subtasks to config-reader
12. P2-K2: Add spec_iterations and root_cause_iterations to state schema
13. P2-D1: Extract tracker subtask creation to core contract (biggest dedup win: ~540 lines -> ~180)
14. P2-D2: Remove inlined thresholds from fix-bugs, use core contract reference only

**Batch 4 — LOW (polish):**
15. P2-L1 through P2-L7: Language, format, documentation alignment

**Estimated scope:**
- Batch 1: ~5 files, ~25 targeted edits
- Batch 2: ~8 files, ~35 targeted edits
- Batch 3: ~8 files, ~40 targeted edits + 1 new core contract
- Batch 4: ~7 files, ~15 cosmetic edits
