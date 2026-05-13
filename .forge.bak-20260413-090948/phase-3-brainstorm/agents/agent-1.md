# Phase 3 Brainstorm -- Agent 1 (Conservative)

**Role:** CONSERVATIVE evaluator -- backward compatibility and minimal risk above all else
**Approach under review:** Approach A (Inline Mode-Branch)
**Date:** 2026-04-13

---

## 1. Pattern Validation Verdict

**APPROVE_WITH_CONDITIONS**

---

## 2. Backward Compatibility Analysis

### 2.1 Bug-Fix Pipeline (fix-ticket, fix-bugs) -- Primary Concern

The existing bug-fix pipeline is the MOST TESTED, MOST USED pipeline. Any regression here is unacceptable.

**Finding: DEFAULT-FIRST IS SAFE.** Approach A uses a critical design principle: the bug-fix behavior is the DEFAULT (fallback). The conditional is structured as "If Mode: feature/scaffold, then [new behavior]; Otherwise [existing behavior unchanged]." This means:

- If no `Mode:` prefix is present in context (current behavior from all existing bug-fix dispatches): all agents behave EXACTLY as they do today. Zero change to runtime behavior.
- If `Mode:` prefix is present but unrecognized: falls through to default (bug-fix behavior). Safe.
- The only way to trigger new behavior is explicit `Mode: feature-implementation` or `Mode: scaffold` in the context string.

**Risk level: VERY LOW.** The existing fix-ticket and fix-bugs skills pass NO mode prefix today. Their agent invocations remain untouched. The agents' default paths are the existing code verbatim.

**Verified against test harness:**
- `section-order.sh`: Checks Goal/Expertise/Process/Constraints order. Approach A adds conditional paragraphs WITHIN existing Process steps (not new ## sections). SAFE.
- `read-only-agents.sh`: Checks reviewer Process section for write-tool phrases. Approach A modifies reviewer Step 1 vocabulary mapping only. No write-tool phrases introduced. SAFE.
- `frontmatter-completeness.sh`: Approach A does not change frontmatter. SAFE.
- `pipeline-feature-agents.sh`: Checks agent file existence and dispatch references. No agent files added/removed. SAFE.

### 2.2 Feature Pipeline (implement-feature) -- Secondary Concern

This pipeline is currently BROKEN for the shared agents (confirmed by 4 BLOCKING CRQs). Approach A is the FIX, not a risk. Any change here is an improvement over the status quo.

**Concern: Double-dispatch regression.** Currently implement-feature passes context like "architectural design + subtask scope + acceptance criteria" without a Mode prefix. Adding `Mode: feature-implementation` prefix could theoretically change how an LLM interprets the rest of the context. However, this is ADDITIVE INFORMATION -- it tells the agent what it already has in front of it. The LLM was previously inferring mode from context shape; now it has explicit guidance. This is strictly better.

**Risk level: NONE (net positive).** The current state is already broken.

### 2.3 Scaffold Pipeline -- Tertiary Concern

The scaffold pipeline dispatches fixer, reviewer, test-engineer in Step 7 with scaffold-specific context (no issue tracker, hooks suppressed, per-subtask commits). Phase 2 research confirmed a THREE-WAY branch is needed (scaffold is structurally different from feature).

**Concern: Scaffold has additional constraints.** Rollback-agent gets "No issue tracker context -- skip issue tracker updates" instruction. Block handler should not attempt to post to issue tracker. The inline conditional must handle this third mode correctly.

**Risk level: LOW.** Scaffold currently works with the same bug-fix-flavored agents and compensates at the skill level (suppressing hooks, passing different instructions). Adding `Mode: scaffold` makes this explicit rather than implicit.

---

## 3. Risk Assessment

### Risk 1: Conditional Complexity Creep (MEDIUM, mitigatable)

**Description:** Each agent gets a 3-way conditional block. Future modes (e.g., "migration", "onboarding") would require adding another branch to every shared agent. At 5 agents x N modes, this becomes maintenance overhead.

**Mitigation:** Accept this for now. The audit explicitly ruled out Approach B (generic vocabulary) as a breaking change. The three current modes (bug-fix, feature, scaffold) are well-defined and stable. If a 4th mode emerges, THAT is the time to consider vocabulary generalization (a v7.0.0 MAJOR). Mark this as technical debt.

**Conservative verdict:** Acceptable. Three-way branching in 5 agents is manageable. 15 total conditional blocks is not excessive.

### Risk 2: Fixer TDD RED Phase Semantic Conflict (HIGH, requires condition)

**Description:** The fixer's Step 5 RED phase says: "Write a test that reproduces the bug. Run it -- confirm it FAILS. If the test passes, your test does not capture the actual bug; rewrite it." In feature mode, writing a test that PASSES on first run is the CORRECT behavior (you're writing a specification test for new functionality, not a regression test for a bug). The inline conditional MUST override this instruction in feature/scaffold mode, or the fixer will discard valid tests.

**This is the single highest-risk item.** If the conditional is written as a soft suggestion ("consider reading 'spec requirement' instead of 'root cause'") rather than a hard override ("In feature mode: replace the RED phase entirely"), the LLM may still follow the bug-fix TDD instruction and reject valid passing tests.

**Mitigation:** The conditional for fixer Step 5 must be PRESCRIPTIVE, not suggestive. Write it as:
```
If Mode is `feature-implementation` or `scaffold`:
  - **Step 5 RED phase override:** Write a test that verifies the new behavior described in the 
    acceptance criteria. If this test PASSES immediately (because the implementation already 
    satisfies it), this is CORRECT -- do not rewrite it. Proceed to GREEN.
```
This must be a HARD override, not a "consider" suggestion.

**Conservative verdict:** CONDITION. The fixer Step 5 conditional must explicitly neutralize the bug-specific RED phase guard.

### Risk 3: Reviewer Artifact Mapping Ambiguity (LOW, mitigatable)

**Description:** Reviewer Step 1 says "Read the original bug report, triage analysis, impact report, and the fixer's output." In feature mode, the conditional maps these to "specification, architectural design, subtask scope." The concern is that in feature decomposition mode, the reviewer receives context from MULTIPLE sources (spec-analyst + architect + per-subtask fixer output), and the mapping is not 1:1.

**Mitigation:** The reviewer's conditional should map to ACTUAL artifact names used by implement-feature:
- "bug report" -> "feature specification from spec-analyst"
- "triage analysis" -> "architectural design from architect"
- "impact report" -> "subtask scope from decomposition plan"

Using the same terminology as the skill uses in its `Context:` line eliminates ambiguity.

**Conservative verdict:** Acceptable with precise vocabulary.

### Risk 4: Rollback-Agent Allowlist vs. Denylist (LOW, out of scope)

**Description:** The audit recommends switching rollback-agent from allowlist to denylist. This is a separate design decision from Approach A. However, Approach A adds `smoke-check` to the allowlist, which means any FUTURE agent that triggers blocks will also need to be added.

**Mitigation:** For this iteration: add `smoke-check` to the allowlist (minimal change). File a follow-up task for the allowlist-to-denylist refactoring. This is a PATCH-level change that does not affect the mode-branch pattern.

**Conservative verdict:** Accept allowlist addition. Denylist refactoring is separate scope.

### Risk 5: Test-Engineer "Regression Test" Labeling (LOW, cosmetic but real)

**Description:** test-engineer Step 3 says "Required: One test verifying the specific behavior that was fixed (regression test)." In feature mode, calling a new-functionality test a "regression test" is semantically wrong but functionally harmless -- the agent will still write a test that verifies the behavior. The concern is that the "regression" framing may lead the LLM to write a test that asserts the ABSENCE of the old behavior rather than the PRESENCE of the new behavior.

**Mitigation:** The conditional should relabel: "In feature/scaffold mode: Required: One test verifying the acceptance criterion is satisfied (behavior test)."

**Conservative verdict:** Include in conditional. Low risk but easy to fix.

---

## 4. Conditions for Approval

I would ship this WITH the following 4 conditions:

### Condition 1: Fixer Step 5 RED Phase Hard Override (MANDATORY)

The inline conditional for fixer Step 5 MUST contain an explicit hard override of the TDD RED phase semantics for feature/scaffold mode. The instruction must make clear that a passing test on first run is CORRECT in feature mode, not a signal to rewrite. Without this, the fixer will actively sabotage feature test generation.

### Condition 2: Default-First Guard in Every Conditional (MANDATORY)

Every conditional block must use the pattern:
```
If context contains `Mode: feature-implementation` or `Mode: scaffold`:
  [alternative behavior]
Otherwise (default -- bug-fix mode or no Mode prefix):
  [existing behavior unchanged]
```

The default branch must be listed LAST and must contain the EXACT existing text (no rewording, no "improvements"). This ensures that if the Mode prefix is missing (which is the case for ALL existing bug-fix invocations), behavior is bit-for-bit identical.

### Condition 3: Smoke-Check in Rollback Triggers (MANDATORY)

The `smoke-check` addition to `core/block-handler.md` and `agents/rollback-agent.md` must be part of this change. It is a P0 BLOCKING fix that predates Approach A but is a prerequisite for safe pipeline operation. Without it, feature pipeline smoke-check failures leave dirty git state regardless of mode-branching.

### Condition 4: Implement-Feature NEEDS_DECOMPOSITION Handler (MANDATORY)

The NEEDS_DECOMPOSITION handler must be added to `skills/implement-feature/SKILL.md` Step 6b before or simultaneously with the mode-branch changes. This is a P0 BLOCKING fix. Adding mode signals to the fixer without handling its decomposition signal creates a scenario where the fixer can now correctly identify that feature scope exceeds limits (because it understands the mode) but the pipeline still cannot process the signal.

---

## 5. Items I Would NOT Ship (Out of Scope)

1. **Generic vocabulary refactoring (Approach B):** Breaking change. Requires MAJOR version bump. Not worth the risk for a problem that inline conditionals solve adequately.
2. **Rollback-agent allowlist-to-denylist refactoring:** Good idea, separate scope, file as follow-up.
3. **Separate `implementer` agent:** Massive scope increase. The fixer with mode-branching is adequate.
4. **Core mode-translator contract (Approach C):** Adds architectural complexity for no measurable benefit over inline conditionals.

---

## 6. Per-Agent Risk Summary

| Agent | Changes Needed | Risk to Bug-Fix | Risk to Scaffold | Risk to Feature |
|-------|---------------|-----------------|-------------------|-----------------|
| fixer | Step 1 guard, Step 5 RED phase, output labels | NONE (default path) | LOW (new path) | NET POSITIVE (fixes CRQ-1, CRQ-5) |
| reviewer | Step 1 artifact mapping | NONE (default path) | LOW (new path) | NET POSITIVE (fixes CRQ-6) |
| test-engineer | Step 1 artifact mapping, Step 3 label | NONE (default path) | LOW (new path) | NET POSITIVE (fixes CRQ-7) |
| e2e-test-engineer | Step 1 only | NONE (default path) | LOW (new path) | NET POSITIVE (minimal) |
| rollback-agent | Step 1 allowlist addition | NONE (additive) | NONE (scaffold excluded) | NET POSITIVE (fixes CRQ-4) |

---

## 7. Final Recommendation

**APPROVE_WITH_CONDITIONS.** Approach A (Inline Mode-Branch) is the correct choice for this iteration. It is additive, preserves all existing bug-fix behavior via default-first conditionals, and directly resolves 4 BLOCKING CRQs. The approach has a well-defined scope (~70 targeted edits across ~10 files), does not require new agent files or core contracts, and the test harness will pass without modification.

The four conditions are non-negotiable: (1) fixer RED phase hard override prevents active test sabotage in feature mode, (2) default-first pattern in every conditional is the backward-compatibility guarantee, (3) smoke-check rollback fix is a prerequisite for safe pipeline operation, and (4) NEEDS_DECOMPOSITION handler prevents an undefined state in the feature pipeline.

The three-way branching (bug-fix/feature/scaffold) adds ~4 conditional paragraphs per shared agent. This is manageable maintenance overhead for 5 agents. If a 4th mode emerges in the future, that is the correct trigger to reconsider vocabulary generalization -- but not before.
