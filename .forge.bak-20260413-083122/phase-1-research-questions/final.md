# Phase 1 Research Questions — Final Synthesis

**Produced by:** Synthesis Agent
**Date:** 2026-04-13
**Source agents:** agent-1 (bug-fix language audit), agent-2 (context flow & AC mechanism), agent-3 (core contracts, decomposition, guardrails)
**Feeds:** Phase 2 investigation agents (this file is the sole input — do NOT read individual agent outputs)

---

## 1. Executive Summary

The ceos-agents feature pipeline (`implement-feature`) reuses fixer, reviewer, test-engineer, and e2e-test-engineer agents that were designed exclusively for the bug-fix pipeline. All four agents carry bug-fix identity at the role, goal, and process-step levels, with no explicit feature-mode handling. The most acute risk is the fixer's hard Block guard in Step 1, which will fire if "triage analysis" or "impact report" are absent — and these artifacts are never produced by the feature pipeline. Three additional HIGH-risk gaps exist: (1) no handler in `implement-feature` when the fixer emits `NEEDS_DECOMPOSITION` from within a subtask, (2) the smoke-check Block leaves git state dirty because `smoke-check` is not in the rollback-agent trigger list, and (3) the reviewer and test-engineer receive feature context but their process steps reference bug-only artifacts, causing silent context loss and lower-quality quality gates. The core contracts (`fixer-reviewer-loop.md`) are partially dual-purpose but have documentation gaps; the architect and acceptance-gate are correctly dual-source aware and require no changes.

---

## 2. Consolidated Research Questions

### Priority P0 — BLOCKING (must resolve before feature pipeline is production-ready)

**CRQ-1: Fixer hard Block on missing triage/impact artifacts**
- **Question:** Does `implement-feature` Step 6b provide enough context to prevent fixer Step 1's hard Block ("If triage analysis or impact report is missing, Block")? Specifically: does the LLM interpret "architectural design + subtask scope + AC" as satisfying the fixer's Step 1 guard, or does the guard fire regardless?
- **Severity:** BLOCKING
- **Found by:** agent-1 (RQ-1, RQ-5, highest-risk item), agent-2 (Finding 1, Gap G1), agent-3 (Finding 6.1)
- **Files to read:** `agents/fixer.md` (Step 1), `skills/implement-feature/SKILL.md` (Step 6b), `core/fixer-reviewer-loop.md` (input contract)

**CRQ-2: No pipeline mode signal to shared agents**
- **Question:** Does `implement-feature` pass any explicit "mode: feature-implementation" signal when dispatching fixer, reviewer, and test-engineer? Without it, all three agents must infer context from artifact absence — an LLM-unreliable heuristic. Is there any explicit mode injection, or is this entirely implicit?
- **Severity:** BLOCKING
- **Found by:** agent-1 (RQ-5, highest-risk item #3), agent-2 (Finding 6, Gap G6), agent-3 (Finding 6.1)
- **Files to read:** `skills/implement-feature/SKILL.md` (Step 6b, 6d, 6e), `agents/fixer.md`, `agents/reviewer.md`, `agents/test-engineer.md`

**CRQ-3: NEEDS_DECOMPOSITION emitted from within a feature subtask — no handler**
- **Question:** When the fixer emits `NEEDS_DECOMPOSITION` during a feature subtask (Step 6b of `implement-feature`), what happens? The `core/fixer-reviewer-loop.md` Failure Handling section references only `skills/fix-ticket/SKILL.md` Step 5 as the handler. There is no documented handler in `implement-feature`. Does the signal propagate to a Block, silently fail, or trigger undefined behavior? And does "once per ticket" in the loop contract mean once across all subtask invocations or once per invocation?
- **Severity:** BLOCKING (HIGH risk — partial git commits, no rollback path)
- **Found by:** agent-3 (Finding 5.1, RQ-5a, RQ-5b, RQ-7c, RQ-7.4)
- **Files to read:** `skills/implement-feature/SKILL.md` (Step 6b), `core/fixer-reviewer-loop.md` (Step 3, Failure Handling), `agents/fixer.md` (Step 5 ESCAPE HATCH)

**CRQ-4: Smoke-check Block leaves git dirty — no rollback in feature pipeline**
- **Question:** When the smoke check fails (Step 6d-smoke in `implement-feature`) and calls the Block handler with `agent = smoke-check`, does rollback-agent actually trigger? The rollback-agent trigger list includes `fixer`, `test-engineer`, `e2e-test-engineer`, `reviewer` — but NOT `smoke-check`. Result: fixer's committed changes remain in git with the issue transitioned to Blocked and no revert. Is this intentional, and does `implement-feature` have any compensating mechanism?
- **Severity:** BLOCKING (HIGH risk — dirty repo on resume)
- **Found by:** agent-3 (Finding 7.6, RQ-7e)
- **Files to read:** `core/block-handler.md` (Step 1), `agents/rollback-agent.md` (Step 1, trigger list), `skills/implement-feature/SKILL.md` (Step 6d-smoke, Step X)

---

### Priority P1 — HIGH (significant quality degradation, fix before GA)

**CRQ-5: Fixer role identity and TDD step mismatch for feature work**
- **Question:** The fixer's role ("Senior Developer specializing in surgical bug fixes"), Goal ("minimal correct fix that solves the root cause"), and TDD Step 5 ("Write a test that reproduces the bug. Run it — confirm it FAILS") are all bug-fix-oriented. For feature subtasks, the fixer is implementing net-new code — not fixing a defect. Do these identity and process anchors cause the fixer to under-scope feature work, apply incorrect TDD framing, or discard valid new tests (because "if the test passes on first write, your test does not capture the actual bug")?
- **Severity:** HIGH
- **Found by:** agent-1 (RQ-1, RQ-6, items #1 and #2 of Top 5), agent-3 (Finding 6.1, RQ-6a)
- **Files to read:** `agents/fixer.md` (frontmatter, Goal, Expertise, Step 1, Step 3, Step 5, Constraints)

**CRQ-6: Reviewer reads bug-specific artifacts in feature context — silent quality degradation**
- **Question:** Reviewer Step 1 reads "bug report, triage analysis, impact report" — none of which exist in the feature pipeline. Unlike fixer Step 1, there is no hard Block here, so the reviewer proceeds silently without these inputs. The review checklist then asks "Does the fix address the actual root cause?" — a question without a meaningful answer for feature code. Does the reviewer produce meaningful feature reviews despite this, or does the absence of bug artifacts cause the AC Fulfillment section to be superficial?
- **Severity:** HIGH
- **Found by:** agent-1 (RQ-2, items #4 of Top 5), agent-2 (Finding 1, Gap G2, RQ-4.5), agent-3 (Finding 7.3, RQ-7b)
- **Files to read:** `agents/reviewer.md` (Step 1, Step 2 checklist, Constraints), `core/fixer-reviewer-loop.md` (Step 6-7)

**CRQ-7: Test-engineer reads "bug report" and requires "regression test" in feature context**
- **Question:** Test-engineer Step 1 reads "bug report, fixer output (changed files, root cause), and impact report" — none present in feature pipeline. Step 3 requires "One test verifying the specific behavior that was fixed (regression test)." In a feature context there is no bug and no regression. Does the agent gracefully adapt, or does it fail to find required inputs? Does the "1-3 focused tests" scope and regression-test framing under-test feature implementations that may require integration or workflow tests?
- **Severity:** HIGH
- **Found by:** agent-1 (RQ-3, item #5 of Top 5), agent-2 (Gap G6 — Medium), agent-3 (Finding 6.6, RQ-6h, RQ-6i)
- **Files to read:** `agents/test-engineer.md` (Step 1, Step 2, Step 3, Goal, frontmatter)

**CRQ-8: Acceptance gate skipped in single-pass feature mode**
- **Question:** `implement-feature` Step 6h states "In single-pass mode (no decomposition), this step is skipped." This means the most common feature path (simple features, no decomposition) has NO dedicated acceptance-gate run — only the reviewer's AC Fulfillment section. Decomposition mode always runs the full gate. Is this asymmetry intentional? Is the reviewer's AC Fulfillment section a sufficient quality gate for single-pass features?
- **Severity:** HIGH
- **Found by:** agent-2 (Finding 4, Gap G4)
- **Files to read:** `skills/implement-feature/SKILL.md` (Step 6h), `agents/acceptance-gate.md` (Step 1, Constraints), `agents/reviewer.md` (AC Fulfillment section)

---

### Priority P2 — MEDIUM (quality gaps, technical debt, fix in follow-up)

**CRQ-9: Fixer scope containment — no check against architect's per-subtask file list**
- **Question:** If the fixer modifies files outside the subtask's `files` list (as defined in the architect's task tree), is there any automated check? The reviewer is given "diff from fixer + acceptance criteria" but NOT the architect's subtask file scope. A fixer implementing subtask 2 could touch subtask 3's files, committing out-of-scope changes that break later subtask execution. Is there a scope containment mechanism anywhere in the feature pipeline?
- **Severity:** MEDIUM
- **Found by:** agent-3 (Finding 6.2, RQ-6d)
- **Files to read:** `skills/implement-feature/SKILL.md` (Step 6b, 6d, 6i), `agents/reviewer.md` (Step 2 checklist), `agents/architect.md` (task tree YAML schema)

**CRQ-10: fixer-reviewer-loop.md context contract lists "code-analyst output" for feature pipeline, but architect output is used instead**
- **Question:** `core/fixer-reviewer-loop.md` Input Contract says `context: "Bug report or spec + AC + code-analyst output"`. In the feature pipeline, code-analyst does NOT run — the architect provides the design. Should the contract explicitly separate bug and feature context shapes to avoid maintainer confusion? Additionally: does the context serialization format for "acceptance criteria" (raw markdown vs structured list) differ between pipelines, and does this affect how fixer/reviewer interpret the AC?
- **Severity:** MEDIUM
- **Found by:** agent-2 (Finding 5, Gap G5), agent-3 (Finding 7.1, RQ-7a)
- **Files to read:** `core/fixer-reviewer-loop.md` (Input Contract, Step 3, Step 6), `skills/implement-feature/SKILL.md` (Step 6b, 6d, 6e)

**CRQ-11: Decomposition-heuristics.md requires code-analyst fields not available in feature pipeline**
- **Question:** `core/decomposition-heuristics.md` Input Contract requires `code_analyst_output` fields (`risk`, `affected_files`, `estimated_diff_lines`, `independent_changes`). In `implement-feature`, code-analyst never runs. The skill uses this contract only for structural validation (cycle detection, max_subtasks). Does the feature pipeline pass incomplete input to the contract, triggering a silent fallback to SINGLE_PASS? Should the contract be split into decision logic (bug-only) and structural validation (dual-purpose)?
- **Severity:** MEDIUM
- **Found by:** agent-3 (Finding 5.2, RQ-5d, Finding 7.8, RQ-7g)
- **Files to read:** `core/decomposition-heuristics.md` (Input Contract, AUTO decision logic, validation checks), `skills/implement-feature/SKILL.md` (Step 5)

**CRQ-12: State.json field reuse and AC source ambiguity**
- **Question:** Both pipelines write AC to `triage.acceptance_criteria` in state.json. For bugs, the source is triage-analyst; for features, it is spec-analyst (documented inline as "field reused"). There is no `source` tag distinguishing the two. Could `/status`, `/resume-ticket`, or acceptance-gate accidentally misinterpret feature AC as bug AC (or vice versa) when reading state? Additionally: spec-analyst posts AC as a separate tracker comment (`[ceos-agents] Acceptance Criteria:`), while triage-analyst does not — is this asymmetry intentional and does it affect any downstream consumer?
- **Severity:** MEDIUM
- **Found by:** agent-2 (Finding 3, Gap G3, RQ-4.1, RQ-4.2)
- **Files to read:** `state/` schema docs, `skills/implement-feature/SKILL.md` (Step 3), `skills/fix-ticket/SKILL.md` (triage state write step), `agents/spec-analyst.md` (Step 5), `agents/triage-analyst.md` (Step 9)

---

## 3. Key Findings from Phase 1 (No Further Research Needed)

These are confirmed facts from reading the source files — Phase 2 agents do not need to re-investigate them.

| # | Finding | Status |
|---|---------|--------|
| F1 | **Architect is correctly dual-source aware.** Its Step 1 explicitly names both input paths: "(from spec-analyst for features, or impact report from code-analyst for bugs)." No change needed. | Confirmed correct |
| F2 | **Acceptance-gate is context-source-agnostic.** It reads whatever is injected; both pipelines name the source explicitly in the context string (Step 6h and fix-ticket Step 8c). No mismatch at the gate. | Confirmed correct |
| F3 | **fixer-reviewer-loop.md build step is pipeline-neutral.** References only "Build command" from Automation Config. No bug-fix-specific assumption. | Confirmed correct |
| F4 | **E2E test engineer is the lowest-risk shared agent** (0 BLOCKING, 2 WARNING). Its goal and user-flow framing degrade gracefully in feature context. | Confirmed low-risk |
| F5 | **AC format is identical between pipelines** (numbered markdown list). The quality gate tokens differ (`UNCLEAR` for triage vs `incomplete` for spec-analyst) but neither is consumed downstream in a machine-parsed way that causes cross-pipeline confusion. | Confirmed acceptable |
| F6 | **fixer-reviewer-loop.md AC list field is neutral** — passes whatever the caller injects. The core contract does not hard-code a bug-specific AC source. | Confirmed correct |
| F7 | **fix-verification.md says "Fix verified" even in feature pipeline** — cosmetic issue only. No functional impact. | Confirmed cosmetic |
| F8 | **Single-pass feature mode (no decomposition) always skips the acceptance-gate** — this is an existing architectural decision in `implement-feature` Step 6h, not a defect introduced by dual-pipeline reuse. | Confirmed by design (but quality gap — see CRQ-8) |
| F9 | **Block-handler state transitions share a single "Blocked" config key** — gracefully degrades (log warning, continue) on tracker type-specific state machines. Not a critical gap. | Confirmed low risk |
| F10 | **AC coverage check asymmetry is intentional:** bug pipeline coverage is conditional (soft), feature pipeline coverage in decomposition mode is unconditional (hard block in YOLO mode). | Confirmed intentional asymmetry |

---

## 4. Files to Read in Phase 2

Phase 2 agents should read these files to answer the CRQs above. Files are grouped by CRQ relevance.

### Core Agent Definitions (for CRQ-1, 2, 5, 6, 7)
- `/agents/fixer.md` — frontmatter, Goal, Step 1, Step 3, Step 4, Step 5, Constraints
- `/agents/reviewer.md` — frontmatter, Goal, Step 1, Step 2 checklist, Constraints
- `/agents/test-engineer.md` — frontmatter, Goal, Step 1, Step 2, Step 3
- `/agents/e2e-test-engineer.md` — Goal, Step 1, Step 6 (low risk, verify only)
- `/agents/acceptance-gate.md` — Step 1, Constraints (verify dual-source handling)
- `/agents/rollback-agent.md` — Step 1 trigger list (for CRQ-4)

### Skills (for CRQ-1, 2, 3, 4, 8, 9)
- `/skills/implement-feature/SKILL.md` — Steps 3, 4, 5, 6b, 6d, 6d-smoke, 6e, 6h, 6i, Step X (Block handler invocation)
- `/skills/fix-ticket/SKILL.md` — Steps 4b, 5, 8c (for AC coverage and acceptance-gate comparison)

### Core Contracts (for CRQ-3, 4, 10, 11)
- `/core/fixer-reviewer-loop.md` — Input Contract, Step 3 (NEEDS_DECOMPOSITION), Step 6-7, Failure Handling
- `/core/block-handler.md` — Step 1 (rollback trigger list), Step 2
- `/core/decomposition-heuristics.md` — Input Contract, AUTO decision logic, validation checks
- `/core/fix-verification.md` — failure comment wording (cosmetic, CRQ-7d reference only)

### State & Schema (for CRQ-12)
- `/state/` — all schema documentation files
- Any state.json examples or schema definitions

### Agent Context Sources (for CRQ-12)
- `/agents/spec-analyst.md` — Step 5 (AC comment writeback to tracker)
- `/agents/triage-analyst.md` — Step 9 (checkpoint comment format, no separate AC comment)

---

## 5. Risk Matrix — Agent × Issue Category

Cells: **CRITICAL** / **HIGH** / **MEDIUM** / **LOW** / `—` (no issue)

| Agent / Contract | Bug-Fix Language | Missing Artifact Guard | NEEDS_DECOMP Handling | AC Mechanism | Scope Containment | Rollback Safety |
|---|---|---|---|---|---|---|
| **fixer** | CRITICAL | CRITICAL (hard Block) | HIGH (threshold miscalibration) | MEDIUM | — | — |
| **reviewer** | HIGH | HIGH (silent degradation) | — | MEDIUM | — | — |
| **test-engineer** | HIGH | HIGH (silent degradation) | — | MEDIUM | — | — |
| **e2e-test-engineer** | LOW | LOW | — | — | — | — |
| **acceptance-gate** | — | — | — | MEDIUM (single-pass skip) | — | — |
| **rollback-agent** | — | — | — | — | — | CRITICAL (smoke-check gap) |
| **implement-feature (skill)** | — | CRITICAL (no mode signal) | CRITICAL (no handler) | MEDIUM | MEDIUM | HIGH (smoke-check block) |
| **fixer-reviewer-loop (core)** | — | — | HIGH (doc gap, no feature handler ref) | — | — | — |
| **block-handler (core)** | — | — | — | — | — | HIGH (smoke-check not in trigger list) |
| **decomposition-heuristics (core)** | — | MEDIUM (missing code-analyst input) | — | — | — | — |
| **state.json schema** | — | — | — | MEDIUM (field reuse, no source tag) | — | — |
| **architect** | — | — | — | — | — | — |
| **spec-analyst** | — | — | — | LOW (token asymmetry) | — | — |

### Legend
- **CRITICAL:** Pipeline-halting or undefined-state risk; must fix before feature pipeline goes live
- **HIGH:** Significant quality degradation or silent failure; fix before GA
- **MEDIUM:** Quality gap or maintainability issue; fix in follow-up release
- **LOW:** Cosmetic, documentation, or theoretical risk; address in backlog
- `—`: No issue identified in this category
