# Phase 3 Brainstorm: Conservative Agent (Areas 1-3)

**Date:** 2026-04-13
**Perspective:** Conservative — backward compatibility, minimal risk, proven patterns
**Inputs:** Phase 2 audit (27 findings), all 5 shared agent definitions, 4 core contracts, acceptance-gate + scaffolder as reference patterns

---

## Area 1: Mode Awareness in Shared Agents

### Approach Evaluation

#### Approach A: Mode-Specific Sections
Add `### Bug-fix mode`, `### Feature mode`, `### Scaffold mode` subsections within Process steps.

**Pros:**
- Maximum clarity — LLM sees exactly what to do per mode
- Easy to audit — each mode's behavior is explicitly spelled out
- No inference required by the model

**Cons:**
- Triples the line count in already-long agents (fixer is 93 lines; with 3 mode sections per step, easily 150+)
- Maintenance burden: every process change must be replicated across mode subsections
- Violates the existing agent definition convention ("Process steps must be numbered and actionable" — subsections within steps break the flat structure)
- Creates a new pattern that no existing agent uses — 14 out of 19 agents work fine without this
- **Risk of mode sections going stale independently** — exactly the duplication problem Phase 2 found in skills (P2-D1: 540 lines of verbatim tracker-subtask duplication)

**Verdict: REJECT.** This approach trades one maintenance problem (implicit mode handling) for a worse one (explicit tripled maintenance surface).

#### Approach B: Inline Conditionals
Add "If context contains Mode: feature..." within existing steps (scaffolder pattern).

**Pros:**
- Proven pattern — scaffolder.md line 22-24 already does this: "If a `spec/README.md` file is provided... If no spec is provided..."
- Acceptance-gate line 21 does this: "from triage-analyst for bugs, spec-analyst for features"
- Keeps the flat numbered-step structure intact
- Changes are surgical — only the specific lines that need mode awareness get conditionals
- Backward compatible — bug-fix behavior is unchanged; feature/scaffold is additive
- Easy to review: diff shows exactly what was added per agent

**Cons:**
- For agents with many mode-sensitive steps (fixer has 4: Steps 1, 3, 4, 5), inline conditionals can make individual steps harder to read
- The pattern requires consistent mode signal format across all dispatch points

**Verdict: RECOMMENDED for all 5 agents.** This is the lowest-risk approach with proven precedent in 2 existing agents.

#### Approach C: Context-Driven (No Agent Changes)
Keep agents generic, let skills handle all mode differences.

**Pros:**
- Zero changes to agent definitions
- Skills already control what context is passed

**Cons:**
- **Does not fix CRQ-1 (CRITICAL):** Fixer Step 1 will still Block on missing "triage analysis" regardless of what context the skill passes. The agent explicitly checks for a named artifact and blocks if absent.
- **Does not fix CRQ-5 (HIGH):** Fixer Step 5 TDD will still say "reproduce the bug" regardless of skill context. The LLM reads its own instructions.
- **Does not fix CRQ-6 (HIGH):** Reviewer Step 4 "Root cause" checklist item remains bug-specific.
- Skills already pass different context per mode (implement-feature passes "architectural design + subtask scope" while fix-ticket passes "triage analysis + code-analyst output"). The agents still fail because their internal instructions reference bug-specific artifacts.

**Verdict: REJECT.** This approach was implicitly the status quo, and Phase 2 proved it produces CRITICAL failures in feature mode. The problem is in the agent text itself, not in what context skills provide.

---

### Per-Agent Recommendations

#### Fixer (BROKEN, score 3/5 — highest priority)

**Recommended approach: B (Inline Conditionals)**

Specific changes required (4 edits, all within existing steps):

1. **Step 1, line 20 (CRITICAL):** The current guard "Read the triage analysis and impact report thoroughly. If triage analysis or impact report is missing, Block..." hard-blocks in feature mode because those artifacts do not exist.

   Replace with inline conditional following the acceptance-gate pattern:
   ```
   Read the upstream analysis thoroughly (triage analysis + impact report for bugs;
   specification + architecture design for features; spec + architecture for scaffold).
   If no upstream analysis exists, Block with reason 'Missing input from previous
   pipeline stage'.
   ```

   **Conservative rationale:** This preserves the Block guard (safety net) while making the artifact name mode-aware. The parenthetical pattern "(X for bugs; Y for features)" is identical to acceptance-gate line 21.

2. **Step 5, line 29 (HIGH):** TDD RED phase says "Write a test that reproduces the bug. Run it -- confirm it FAILS. If the test passes, your test does not capture the actual bug; rewrite it."

   Replace with:
   ```
   RED: Write a test that verifies the target behavior. For bugs: the test should
   reproduce the bug — confirm it FAILS before your fix. If the test passes, it does
   not capture the actual bug; rewrite it. For features: the test should specify the
   expected new behavior — confirm it FAILS because the feature is not yet implemented.
   If the test passes trivially (empty assertion, always-true), rewrite it.
   ```

   **Conservative rationale:** Bug-fix TDD is preserved verbatim as a sub-path. Feature TDD is additive. The "If the test passes trivially" guard prevents the LLM from writing vacuous tests.

3. **Step 3, line 23 (MEDIUM):** "reason through the root cause" -> "reason through the problem"

   **Conservative rationale:** Single-word replacement. "Problem" is mode-neutral and preserves the analytical intent. No structural change.

4. **Step 4, line 27 (MEDIUM):** "from impact report" -> "from the upstream analysis (impact report for bugs, subtask scope for features)"

   **Conservative rationale:** Parenthetical addition, same pattern as Step 1.

5. **Frontmatter line 3 (LOW):** "Implements minimal, correct bug fixes" -> "Implements minimal, correct code changes"

   **Conservative rationale:** Two-word replacement. Does not change model selection, style, or behavior.

**NOT recommended for fixer:**
- Adding a `Mode:` field to frontmatter (breaks the 4-field convention: name, description, model, style)
- Adding mode-specific `## Process` sections (Approach A — maintenance burden)
- Splitting fixer into fixer-bug and fixer-feature (doubles agent count, violates architecture)

#### Reviewer (NEEDS_UPDATE, score 4/5)

**Recommended approach: B (Inline Conditionals)**

Specific changes required (3 edits):

1. **Step 1, line 20 (MEDIUM):** "Read the original bug report, triage analysis, impact report, and the fixer's output" references 3 artifacts that do not exist in feature mode.

   Replace with:
   ```
   Read the upstream analysis (bug report + triage analysis + impact report for bugs;
   specification + architecture design for features), and the fixer's output
   (changed files, approach, reasoning)
   ```

   **Conservative rationale:** Additive parenthetical. Bug-fix path is word-for-word preserved within the parenthetical.

2. **Step 4, line 30 (MEDIUM):** "Root cause: Does the fix address the actual root cause, not just symptoms?" is meaningless for features.

   Replace with:
   ```
   Correctness: Does the change address the actual problem (root cause for bugs,
   specification requirements for features)?
   ```

   **Conservative rationale:** The checklist item name changes from "Root cause" to "Correctness" — a generalization. The parenthetical preserves the original intent for bugs.

3. **Frontmatter line 3 (LOW):** "Ensures root cause fix, convention compliance, no regressions" -> "Ensures correct implementation, convention compliance, no regressions"

**Assessment: LOW RISK.** Reviewer is read-only, so even if the updated instructions are imperfect, no code damage results. The AC Fulfillment section (Step 4, line 37-41) already works correctly for both modes — it references "triage/spec analysis" generically.

#### Test-Engineer (NEEDS_UPDATE, score 4/5)

**Recommended approach: B (Inline Conditionals)**

Specific changes required (2 edits):

1. **Step 1, line 20 (MEDIUM):** "Read the bug report, fixer output (changed files, root cause), and impact report (test coverage section)"

   Replace with:
   ```
   Read the upstream analysis (bug report + impact report for bugs; specification +
   changed files for features), and fixer output (changed files, approach)
   ```

2. **Step 3, line 25 (LOW):** "One test verifying the specific behavior that was fixed (regression test)"

   Replace with:
   ```
   One test verifying the specific behavior that was changed or added
   (regression test for bugs, behavior verification for features)
   ```

**Assessment: VERY LOW RISK.** Test-engineer's actual test-writing behavior (Steps 4-5) is entirely mode-agnostic — it reads changed files, follows conventions, writes AAA tests. The mode issue is purely in the framing of Steps 1 and 3.

#### E2E-Test-Engineer (NEEDS_UPDATE, score 4/5)

**Recommended approach: B (Inline Conditionals)**

Specific changes required (1 edit):

1. **Step 1, line 20 (MEDIUM):** "Read the bug report and fix diff"

   Replace with:
   ```
   Read the upstream context (bug report for bugs; specification + test strategy
   for features) and fix diff — understand which user flow was affected
   ```

**Assessment: MINIMAL RISK.** Only Step 1 needs updating. Steps 2-9 (deployment pre-flight, test infrastructure, selector strategy, auth handling) are fully mode-agnostic already.

#### Publisher (NEEDS_UPDATE, score 4/5)

**Recommended approach: B (Inline Conditionals)**

Specific changes required (2 edits):

1. **Step 6, line 57 (MEDIUM):** PR title hardcodes "Fix:" prefix: `[PROJ-123] Fix: {concise description}`

   Replace with:
   ```
   Title: Use issue summary. Format: `[PROJ-123] {prefix}: {concise description}`
   where prefix is derived from the branch naming pattern (fix/ -> Fix, feat/ -> Feat,
   chore/ -> Chore) or defaults to the issue type.
   ```

   **Conservative rationale:** Branch naming pattern already exists in Automation Config. Deriving the prefix from it requires no new config key and is deterministic. The publisher already reads Source Control config in Step 1.

2. **Step 6, line 59 (MEDIUM):** "Summary, Root Cause, Changes, Testing, Issue link" lists bug-specific sections.

   Replace with:
   ```
   Fill in ALL sections from the project's PR Description Template (from Automation
   Config). The template is the single source of truth for PR description structure.
   ```

   **Conservative rationale:** This is strictly more correct than the current instruction — the PR Description Template in Automation Config is already the canonical source. The current instruction at line 59 was an informal summary that introduced a bug-specific assumption. Removing it and deferring to the template is less prescriptive, not more.

**NOT recommended for publisher:**
- Adding mode-specific PR description templates (breaks the single-template config contract)
- Adding a `PR Title Prefix` config key (unnecessary — derivable from branch naming)

---

### Mode Signal Mechanism

**Recommended:** Skills inject `Mode: bug-fix | feature | scaffold` as a prefix in the context string passed to agents via Task tool. Agents detect this signal in Step 1 and branch behavior.

**Why this is conservative:**
- No new config key required
- No agent frontmatter changes
- No new core contract needed
- Skills already control the context string — this is a 1-line addition per agent dispatch
- Follows the same pattern as existing "Max build retries = {N}" context injection

**What changes in skills:**
- `fix-ticket/SKILL.md`: Add `Mode: bug-fix.` to fixer/reviewer/test-engineer/e2e-test-engineer/publisher dispatch context
- `fix-bugs/SKILL.md`: Same
- `implement-feature/SKILL.md`: Add `Mode: feature.` to same dispatches
- `scaffold/SKILL.md`: Add `Mode: scaffold.` to same dispatches

**What does NOT need to change:**
- The fixer-reviewer-loop core contract does not need a `mode` field in its Input Contract for Batch 1. The mode signal travels in the `context` string, which is already documented as free-form. Formalizing it can happen in Batch 3 (CRQ-10).

**Risk assessment:** LOW. If a skill forgets to inject the mode signal, agents fall back to their current bug-fix behavior — which is the existing status quo. No regression possible.

---

## Area 2: Agent Content Quality — Highest-Impact Improvements

### Priority Order (by impact on pipeline correctness)

#### 1. Fixer Step 1 Guard (CRQ-1, CRITICAL)

**Current:** `If triage analysis or impact report is missing, Block with reason 'Missing input from previous pipeline stage'.`

**Problem:** Hard-blocks every feature/scaffold invocation because "triage analysis" and "impact report" are bug-pipeline-only artifacts.

**Recommended fix:** Replace artifact names with generic term + mode-specific parenthetical (detailed in Area 1 above).

**Impact:** Unblocks the entire feature pipeline through fixer. Without this fix, CRQ-3, CRQ-5, CRQ-6, CRQ-7, CRQ-8 are all moot because the pipeline never gets past fixer Step 1.

**Risk:** VERY LOW. The guard's intent (reject invocations with no upstream analysis) is preserved. Only the artifact names change.

#### 2. Fixer Step 5 TDD (CRQ-5, HIGH)

**Current:** `Write a test that reproduces the bug. Run it — confirm it FAILS. If the test passes, your test does not capture the actual bug; rewrite it.`

**Problem:** For features, there is no bug to reproduce. The test should verify new behavior. The "If the test passes, your test does not capture the actual bug" logic is inverted for features — a passing test on a new feature means the skeleton already satisfies the requirement, which is valid (not an error).

**Recommended fix:** Dual-path inline conditional (detailed in Area 1 above). The bug path is preserved verbatim. The feature path adds explicit guidance for behavior-verifying tests.

**Impact:** HIGH. Without this fix, fixer may discard valid feature tests, or waste iterations trying to write a test that "fails for the right reason" when the reason is "the feature does not exist yet" (which trivially fails for any assertion).

**Risk:** LOW. Bug-fix TDD behavior is unchanged. Feature TDD is additive.

**Alternative considered and rejected:** "Remove TDD entirely for features." This would reduce test quality. TDD is valuable for features — the RED phase should verify that the expected behavior does not yet exist, which is useful for preventing duplicate implementations.

#### 3. Reviewer Step 2 "Root Cause" (CRQ-6, HIGH)

**Current:** `Root cause: Does the fix address the actual root cause, not just symptoms?`

**Problem:** For features, there is no root cause. The reviewer may flag "root cause not addressed" on perfectly valid feature code, creating false REQUEST_CHANGES cycles.

**Recommended fix:** Rename to "Correctness" with mode-specific parenthetical (detailed in Area 1).

**Impact:** MEDIUM-HIGH. False negatives in the reviewer waste fixer iterations (expensive — opus model, up to 5 cycles). But the reviewer also has the AC Fulfillment section which already works correctly for features, providing a compensating check.

**Risk:** VERY LOW. The checklist item intent is preserved. Only the framing changes.

#### 4. Publisher "Fix:" PR Title and "Root Cause" Section (CRQ-related, MEDIUM)

**Current:** `Format: [PROJ-123] Fix: {concise description}` and `Summary, Root Cause, Changes, Testing, Issue link`

**Problem:** Feature PRs get "Fix:" prefix and include a "Root Cause" section that does not apply.

**Recommended fix:** Dynamic prefix from branch naming + defer to PR Description Template (detailed in Area 1).

**Impact:** MEDIUM. Affects human readability of PRs, not pipeline correctness. But "Fix:" on a feature PR is confusing for human reviewers and may trigger incorrect CI labeling rules.

**Risk:** LOW. The publisher already reads branch naming config. Deriving a prefix is deterministic.

#### 5. Test-Engineer Step 1 "Bug Report" and Step 3 "Regression Test" (CRQ-7, LOW-MEDIUM)

**Current:** Step 1 references "bug report" and "impact report". Step 3 says "regression test".

**Problem:** In feature mode, the test-engineer looks for artifacts that do not exist and frames all tests as regression tests.

**Recommended fix:** Generic upstream analysis reference + "behavior verification for features" parenthetical.

**Impact:** LOW-MEDIUM. Test-engineer's actual test-writing behavior is correct regardless of framing — it reads changed files and writes tests for them. The issue is more about LLM confidence and test naming than test quality.

**Risk:** VERY LOW.

### Content Improvements NOT Recommended for This Pass

- **Fixer output format change** (renaming "Root cause" to "Problem" in the Fix Report template): LOW priority, cosmetic, can confuse downstream consumers (reviewer, state.json) that may parse this field name. Defer to Batch 4.
- **Reviewer issue count gate relaxation**: The "MUST identify at least 3 specific issues per review" rule (Step 6) is aggressive but works. Changing it risks reducing review quality. Leave as-is.
- **Test-engineer max test count increase**: Currently 1-3 focused tests. Sufficient for both bugs and features. No change needed.

---

## Area 3: Core Contract Gaps

### 1. fixer-reviewer-loop.md — Generalize or Narrow?

**Current state:** Input Contract says `context: "Bug report or spec + AC + code-analyst output"`. The "or spec" acknowledgment exists but is undocumented. `acceptance_criteria` source is "AC list from triage-analyst output" only.

**Recommendation: GENERALIZE (minimal, additive).**

Specific changes:

1. **Input Contract `context` field (line 11):** Change Notes from `"Bug report or spec + AC + code-analyst output"` to `"Upstream analysis: triage + code-analyst output (bugs), spec-analyst + architect output (features), spec + architect output (scaffold)"`.

2. **Input Contract `acceptance_criteria` field (line 13):** Change Notes from `"AC list from triage-analyst output"` to `"AC list from triage-analyst (bugs) or spec-analyst (features/scaffold)"`.

3. **Failure Handling line 44:** Change `"see core/decomposition-heuristics.md and skills/fix-ticket/SKILL.md step 5"` to `"see core/decomposition-heuristics.md and the NEEDS_DECOMPOSITION handler in the calling skill (fix-ticket step 5, fix-bugs step 4, implement-feature step TBD)"`.

**Why generalize, not narrow:**
- This contract IS used by all 3 pipeline skills + scaffold. Narrowing it to bug-only would require creating a second loop contract for features, which is unnecessary duplication.
- The Process steps (1-10) are already mode-agnostic — they dispatch fixer, check output, dispatch reviewer, iterate. No mode-specific behavior exists in the contract itself.
- Only the Input Contract documentation is wrong, not the actual behavior.

**Risk:** VERY LOW. These are documentation-only changes to the Input Contract table. No behavioral change.

### 2. block-handler.md — Generalize (add smoke-check)

**Current state:** Rollback trigger list (line 21) specifies `fixer`, `reviewer`, or `test-engineer`. Smoke-check is not listed. When smoke-check blocks, rollback is skipped and git remains dirty.

**Recommendation: GENERALIZE (add smoke-check to the allowlist).**

Specific change:

1. **Process Step 1, line 21:** Change `"If the blocking agent is fixer, reviewer, or test-engineer"` to `"If the blocking agent is fixer, reviewer, test-engineer, or smoke-check"`.

**Why not switch to a denylist approach (Phase 2 suggestion):**
- The denylist approach ("rollback all agents EXCEPT triage-analyst, code-analyst, spec-analyst, architect, stack-selector, publisher, scaffolder") is more future-proof but also more dangerous — any new agent would default to triggering rollback, which may not be correct.
- The allowlist approach is safer: only agents that are explicitly known to modify git state trigger rollback. New agents must be consciously added.
- Conservative principle: **opt-in is safer than opt-out for destructive operations.**

**Additional consideration:** Should `e2e-test-engineer` trigger rollback? Currently it is not in the list. E2E tests do not modify code, so no rollback is needed. However, if e2e-test-engineer fails, the implementation code is still correct — only the E2E test file might be wrong. Leave e2e-test-engineer off the rollback list.

**Risk:** LOW. Adding one entry to an allowlist. No existing behavior changes.

### 3. decomposition-heuristics.md — Narrow (document as bug-only)

**Current state:** Designed exclusively for code-analyst output (risk, affected_files, estimated_diff_lines, independent_changes). Feature pipeline has no code-analyst phase. implement-feature line 200 says "Follow `core/decomposition-heuristics.md`" but the inline steps bear no resemblance to the contract.

**Recommendation: NARROW — document as bug-pipeline-only and remove the false reference from implement-feature.**

Specific changes:

1. **decomposition-heuristics.md:** Add a Scope section at the top:
   ```
   ## Scope
   Bug-fix pipeline only (fix-ticket, fix-bugs). Feature pipeline (implement-feature)
   uses architect-driven task tree decomposition, not threshold-based heuristics.
   ```

2. **implement-feature/SKILL.md line 200:** Replace `"Follow core/decomposition-heuristics.md:"` with `"Validate the architect's task tree:"` (the inline steps that follow are already task-tree validation, not threshold heuristics).

3. **fix-bugs/SKILL.md lines 158-164:** Remove the inlined threshold values and replace with `"Follow core/decomposition-heuristics.md to determine DECOMPOSE vs SINGLE_PASS."` (reference-only, no inline duplication).

**Why narrow instead of generalize:**
- Generalizing would require adding an `architect_output` input shape to the contract, with completely different heuristics (cycle check, topological sort, max_subtasks validation). These two approaches share nothing except the word "decomposition".
- The feature pipeline's "decomposition" is structurally different: it is architect-driven (top-down design) while the bug pipeline's is threshold-driven (bottom-up risk assessment). Forcing them into one contract would create a confusing dual-mode contract with no shared logic.
- YAGNI: if a future pipeline needs a hybrid, it can be added then. Today, the two are cleanly separable.

**Risk:** LOW. The narrowing makes the existing implicit scope explicit. The implement-feature false reference is simply corrected, and fix-bugs duplication is removed (reducing divergence risk).

### 4. config-reader.md — Add Missing Key

**Current state:** `decomposition.create_tracker_subtasks` (default: `enabled`) is used by all three pipeline skills but not listed in config-reader's Decomposition section parsing (line 33).

**Recommendation: GENERALIZE — add the missing key.**

Specific change:

1. **config-reader.md line 33:** Change:
   ```
   `### Decomposition` → `decomposition.max_subtasks` (default: 7), `decomposition.fail_strategy` (default: `fail-fast`), `decomposition.commit_strategy` (default: `squash`)
   ```
   to:
   ```
   `### Decomposition` → `decomposition.max_subtasks` (default: 7), `decomposition.fail_strategy` (default: `fail-fast`), `decomposition.commit_strategy` (default: `squash`), `decomposition.create_tracker_subtasks` (default: `enabled`)
   ```

**Risk:** NONE. This is a documentation fix. The key already exists in the Automation Config contract (CLAUDE.md) and is already parsed by all three skills. The config-reader contract simply failed to document it.

---

## Summary: Conservative Batch Sizing

### Batch 1 (CRITICAL — blocks production use, 5 files, ~15 surgical edits)
1. Fixer Step 1 guard: mode-aware artifact names (CRQ-1)
2. Fixer Step 5 TDD: dual-path for bugs vs features (CRQ-5)
3. Mode signal injection in skill dispatches (CRQ-2) — 4 skill files
4. block-handler: add smoke-check to rollback triggers (CRQ-4)
5. implement-feature webhook format alignment (P2-W1)

### Batch 2 (HIGH — before GA, 6 files, ~12 edits)
6. Reviewer Steps 1 + 4: mode-aware language (CRQ-6)
7. Test-engineer Steps 1 + 3: mode-aware language (CRQ-7)
8. E2E-test-engineer Step 1: mode-aware language
9. Publisher Step 6: dynamic prefix + defer to template
10. implement-feature: NEEDS_DECOMPOSITION handler (CRQ-3)
11. fix-bugs: Config Validity Gate (P2-G1)

### Batch 3 (MEDIUM — tech debt, 5 files, ~10 edits)
12. fixer-reviewer-loop.md: generalize Input Contract docs (CRQ-10)
13. decomposition-heuristics.md: narrow scope + fix mislabel (CRQ-11, P2-C1)
14. config-reader.md: add create_tracker_subtasks (P2-K1)
15. fix-bugs: remove inlined thresholds, use contract reference (P2-D2)
16. Fixer/reviewer frontmatter description updates (LOW)

### Deferred (not in this pass)
- State schema changes (CRQ-12, P2-K2, P2-S1, P2-L4, P2-L6) — separate schema-focused pass
- Tracker subtask extraction to core contract (P2-D1) — large refactor, needs its own plan
- Cosmetic/documentation fixes (P2-L1 through P2-L7)

---

## Key Conservative Principles Applied

1. **Inline conditionals over structural changes.** The "(X for bugs; Y for features)" parenthetical pattern is proven in acceptance-gate and scaffolder. Reuse it everywhere.

2. **Allowlist over denylist for destructive operations.** Block-handler's rollback trigger list should grow explicitly, not default to rollback-everything.

3. **Narrow contracts that serve one purpose; generalize contracts that serve all modes.** decomposition-heuristics is bug-only (narrow it). fixer-reviewer-loop serves all modes (generalize its docs).

4. **Documentation fixes before behavioral changes.** Many "issues" are documentation gaps (config-reader missing key, loop contract missing feature-mode notes). Fix docs first; behavioral changes only where the pipeline demonstrably breaks.

5. **Preserve bug-fix behavior verbatim.** Every recommended change keeps the bug-fix code path word-for-word intact within a conditional. No existing bug-fix user will see any behavioral difference.

6. **Mode signal as context prefix, not structural change.** The `Mode: X` injection travels in the existing `context` string field. No new Input Contract fields, no frontmatter changes, no new core contracts needed for Batch 1.
