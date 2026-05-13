# Phase 3 Brainstorm — Agent 3 (Skeptical Critic)

Date: 2026-04-13
Role: Adversarial risk analysis — challenge assumptions, find what could go wrong

---

## Assumption Challenge

### Assumption 1: "Additive changes can't break the bug-fix pipeline"

**Verdict: SHAKY — holds structurally, fails semantically.**

The structural argument is correct: adding an inline conditional to Step 1 of fixer.md does not change the section headers, does not violate test harness constraints (section-order.sh checks `^## Process` ordering, not step content), and the default/fallback path preserves existing bug-fix behavior.

But there is a **semantic risk the research glossed over**: LLM agents do not execute markdown as code. They *interpret* it. Adding a three-way branch to Step 1 of the fixer creates an ambiguity surface:

```
1. Read the context:
   - **Bug-fix mode** (context includes triage analysis + impact report): ...
   - **Feature mode** (context includes subtask scope + AC from spec-analyst): ...
   - **Scaffold mode** (context includes subtask scope + AC from spec-writer): ...
```

The distinguisher between feature and scaffold is **which agent produced the AC** — spec-analyst vs spec-writer. But the fixer never sees the AC provenance directly. It sees a context string with "acceptance criteria" in it. If the skill does not inject `Mode: scaffold` or `Mode: feature` explicitly, the fixer must *infer* its mode from artifact shape — and the artifact shapes for feature and scaffold are nearly identical (both have subtask scope, both have AC, both have architecture design).

**Mitigation that Phase 2 already recommends but does not enforce as a hard requirement:** The `Mode:` prefix MUST be injected by the dispatching skill, not inferred by the agent. Phase 2 says "preferred approach: inject Mode: {bug-fix|feature|scaffold} into the context string at the skill dispatch level." But the word "preferred" is doing too much work. If any one of the three dispatching skills (fix-ticket, implement-feature, scaffold) forgets to inject the Mode prefix, the agent falls back to inference — and inference between feature and scaffold will fail silently.

**Risk level: MEDIUM.** The fix is to make mode injection a MUST in the spec/plan, not a "preferred approach." Add a validation step: if the fixer receives no `Mode:` prefix, it should Block (not guess).

---

### Assumption 2: "Scaffold mode and feature mode need separate branches in agents"

**Verdict: CORRECT, but the separation point is wrong.**

Phase 2 research (RQ-1, Agent 1) convincingly demonstrates five axes of difference between scaffold and feature contexts: no issue tracker, different input source, hooks suppressed, different build command source, different commit strategy.

But here is the key insight the research MISSED: **all five differences are skill-level concerns, not agent-level concerns.** Let me trace each one:

1. **No issue tracker** — handled by scaffold SKILL.md passing "No issue tracker context" to rollback-agent. The fixer itself never touches the issue tracker. No agent-level branch needed.
2. **Input source differs** — both feature and scaffold pass "subtask scope + AC + architecture design." The labels are identical. The fixer reads them the same way.
3. **Hooks suppressed** — skill-level decision. The fixer is dispatched after the hook step; it never knows whether a hook ran.
4. **Build command source differs** — the dispatching skill resolves the build command and passes it as context. The fixer runs whatever build command it receives.
5. **Commit strategy** — handled by the skill's Step 7d / 6i. The fixer never commits.

**The fixer, reviewer, and test-engineer do NOT need a three-way branch. They need a two-way branch: bug-fix vs non-bug.** The differences between feature and scaffold are entirely handled at the skill dispatch layer.

The only agent that genuinely needs a three-way branch is the **rollback-agent** — because scaffold blocks go to stdout (no tracker) while feature blocks go to the issue tracker. But rollback-agent already has this handled via the context string ("No issue tracker context").

**Risk of implementing unnecessary three-way branching in agents:** Added complexity in 4 agent files with no behavioral benefit. The feature and scaffold branches in fixer/reviewer/test-engineer would be IDENTICAL. This is a maintainability hazard — when you update the feature branch, you must remember to update the scaffold branch too, even though they do the same thing.

**Counter-argument from Phase 2:** "Cannot collapse scaffold into feature mode" — but this is true at the SKILL level, not the AGENT level. The Phase 2 analysis confused the dispatch context (which differs) with the agent behavior (which does not differ).

**Recommendation: Two-way branch in agents (bug-fix / non-bug), three-way mode signal from skills.** Skills inject `Mode: bug-fix`, `Mode: feature`, or `Mode: scaffold`. Agents branch on `Mode: bug-fix` vs "everything else" for their process steps. The skill handles the remaining differentiation (tracker, hooks, commit strategy, build command source).

**Risk level: LOW if we do two-way. MEDIUM if we over-engineer with three-way** (unnecessary duplication).

---

### Assumption 3: "NEEDS_DECOMPOSITION handler is straightforward to add"

**Verdict: THE HARDEST PROBLEM in this entire refactoring. Phase 2 understates the complexity.**

Phase 2 Agent 2 provides a solid recommended handler but acknowledges the semantic tension without fully resolving it. Let me trace the problem completely:

**Scenario A — Single-pass mode, fixer says NEEDS_DECOMPOSITION:**
The implement-feature pipeline went through the architect at Step 5. The architect analyzed the feature and decided `SINGLE_PASS`. Now the fixer disagrees — it hits the 100-line/4-file limit. This is a **contradiction between two opus-model agents** (architect and fixer). Who is right?

Phase 2 suggests: "Always Block in implement-feature when fixer emits NEEDS_DECOMPOSITION." But this is a POOR user experience. The user ran implement-feature expecting automation. If the architect said SINGLE_PASS but the fixer disagrees, the right answer is to re-run the architect with FORCE decomposition. Phase 2 Agent 2 sketches this (step 2c in their handler), but it creates a second problem: the architect already ran and produced output that was used to build context. Re-running it means invalidating that context and starting the loop over. Where does the pipeline resume? Step 5? Step 6? The implement-feature SKILL.md has no "restart from Step 5" logic.

**Scenario B — Decomposition mode (subtask loop), fixer says NEEDS_DECOMPOSITION:**
The architect already decomposed the feature into N subtasks. The fixer is working on subtask K and says it needs further decomposition. Phase 2 correctly says: Block immediately, do not allow nested decomposition.

But what happens to subtasks 1 through K-1 that already completed and committed? The per-subtask commit strategy means we have `feat(subtask-1): ...`, `feat(subtask-2): ...` etc. already in git history. Blocking subtask K leaves those commits in place. If the user re-runs after adjusting the architect output:
- Does the pipeline detect the existing commits?
- Does `/resume-ticket` handle this state?
- Does the architect see the already-implemented subtasks?

None of this is addressed in the handler design. The `decomposition/{ISSUE-ID}.yaml` file tracks subtask status, but the resume logic (`skills/resume-ticket/SKILL.md`) reads from state.json, not from the yaml file directly. There is a potential state inconsistency.

**The deeper problem:** NEEDS_DECOMPOSITION was designed for the bug-fix pipeline where there is ONE attempt at ONE fix. The decomposition signal means "start over with an architect." In the feature pipeline, decomposition already happened before the fixer runs. The signal's semantics are undefined in this context, and the handler must essentially invent new semantics rather than adapting existing ones.

**Risk level: HIGH.** This is the one item that could cause the spec to be wrong at the architectural level, not just at the implementation level. The handler needs careful design with explicit decisions about:
1. What state artifacts are preserved vs invalidated on NEEDS_DECOMPOSITION in single-pass mode
2. Whether re-decomposition is allowed (Phase 2 says Block; I say this might be wrong for single-pass)
3. How resume handles partial completion in decomposition mode after a subtask Block

---

### Assumption 4: "Smoke-check needs rollback"

**Verdict: CORRECT, but the Phase 1 → Phase 2 flip deserves scrutiny.**

Phase 1 research said: "smoke-check exclusion is INTENTIONAL — rolling back after an approved fixer-reviewer loop would discard approved code." Phase 2 reversed this: "exclusion is an omission, not intentional design."

Phase 2 is right. The evidence is clear:
- block-handler's rationale for exclusion is "no git changes to revert" (applies to read-only agents, NOT to smoke-check)
- rollback-agent's allowlist simply never included smoke-check — it is an omission from the original design
- smoke-check runs after fixer commits exist — there ARE git changes to revert
- The audit (CRQ-4) explicitly calls this P0 BLOCKING

But let me challenge the **risk of the fix itself:** when smoke-check blocks and rollback-agent reverts, what exactly is reverted?

In decomposition mode: the fixer for subtask K made changes, the reviewer approved, but then build/tests failed in smoke-check. Rollback reverts the fixer's uncommitted changes. But wait — look at `implement-feature` Step 6i: the commit happens AFTER acceptance-gate (Step 6h), which is AFTER test-engineer (Step 6e), which is AFTER smoke-check (Step 6d-smoke). So at smoke-check time, the fixer's changes are NOT committed yet. They are staged/unstaged changes. `git reset --hard` + `git clean -fd` will revert them. Previous subtask commits are safe.

In single-pass mode: same logic — fixer changes are uncommitted at smoke-check time. Rollback is safe.

**But there is an edge case:** what if the fixer already committed (e.g., ran `git add . && git commit -m "wip"` as part of its process)? The fixer agent's process does NOT instruct it to commit — but it is an opus-model agent with write access. Nothing prevents it from committing. If it does, `git reset --hard {base_branch}` (rollback-agent Step 4) would revert to the base branch, potentially losing ALL subtask commits, not just the current one.

Rollback-agent Step 4 says: "Run: `git reset --hard {base_branch}`". This resets to the BASE branch, not to HEAD~1. In decomposition mode with prior subtask commits, this would destroy subtasks 1 through K-1.

**This is a pre-existing bug in rollback-agent that the smoke-check fix would expose more frequently.** The rollback-agent should reset to the last known good commit (the restore_point from decomposition tracking), not to the base branch. But fixing this is out of scope for the current refactoring.

**Risk level: LOW for the smoke-check addition itself. MEDIUM for the pre-existing rollback scope bug that it exposes.** Recommend documenting the rollback scope issue as a follow-up P2 item.

---

## The #1 Risk That Could Derail This Refactoring

**NEEDS_DECOMPOSITION handler design (Assumption 3).**

The other three assumptions have clear paths forward with known risks. NEEDS_DECOMPOSITION is the one where the spec could be architecturally wrong. The signal was not designed for the feature pipeline. Bolting it on requires inventing new semantics that interact with existing state management, resume logic, and decomposition tracking — all of which were designed for the bug-fix pipeline.

If the handler is designed wrong, it will not just fail to work — it will corrupt pipeline state (partial commits, inconsistent decomposition yaml, state.json/yaml desync) in ways that prevent `/resume-ticket` from recovering.

**Mitigation:** Design the handler as the SIMPLEST possible version: **always Block on NEEDS_DECOMPOSITION in implement-feature, in both single-pass and decomposition modes.** Do not attempt re-decomposition. The Block message should say: "Feature subtask exceeds fixer limits. Re-run with adjusted architect parameters or split the feature into smaller issues." This is the Phase 2 Agent 2 recommendation for decomposition mode, extended to single-pass mode too.

Why this is safer: it avoids all state management questions (no re-running architect, no partial invalidation, no resume edge cases). The user gets a clear message and can re-run manually. The cost is a slightly worse UX for single-pass features that hit the limit — but this is a rare edge case (the architect should have caught it).

---

## Minimum-Risk Implementation Order

**Ship in this order, each independently testable and deployable:**

### Phase A: Smoke-check rollback (CRQ-4) — SHIP FIRST
- 2 files: `core/block-handler.md`, `agents/rollback-agent.md`
- 2 targeted edits (add `smoke-check` to two lists)
- Zero risk of breaking bug-fix pipeline
- Fixes a genuine P0 BLOCKING issue
- Can be verified by reading the two files — no runtime test needed
- **Completely independent of all other changes**

### Phase B: Mode signal injection + agent branching (CRQ-1, CRQ-2, CRQ-5, CRQ-6, CRQ-7)
- 5 files: `agents/fixer.md`, `agents/reviewer.md`, `agents/test-engineer.md`, `agents/e2e-test-engineer.md`, `skills/implement-feature/SKILL.md`
- ~15-20 targeted edits
- **Use two-way branch (bug-fix / non-bug)**, not three-way
- Add `Mode: feature` injection in `implement-feature/SKILL.md` Steps 6b, 6d, 6e
- Verify `scaffold/SKILL.md` already works without explicit Mode injection (scaffold's context is structurally different enough that a "non-bug" default path works)
- Run test harness to verify no structural tests broken
- **Must be done as one atomic change** — partial application (e.g., mode signal without agent branch) creates a worse state than no change

### Phase C: NEEDS_DECOMPOSITION handler (CRQ-3)
- 1 file: `skills/implement-feature/SKILL.md`
- ~5 targeted edits (add handler after fixer-reviewer loop return)
- **Always Block strategy** — simplest possible implementation
- Can be verified by reading the skill file
- **Depends on Phase B** (the handler should reference Mode for its Block message)

### Phase D: Documentation/contract updates (CRQ-10, CRQ-11, CRQ-12)
- 3 files: `core/fixer-reviewer-loop.md`, `core/decomposition-heuristics.md`, `state/schema.md`
- Plus 4 write-site updates for `ac_source` in skill files
- Pure documentation — zero runtime behavior change
- **Independent of Phases A-C** but logically follows them

### Phase E: Quality improvements (CRQ-8, CRQ-9)
- Single-pass acceptance-gate compensation, scope containment
- These are enhancements, not fixes
- **Defer to a follow-up PR** — they add new behavior, not fix broken behavior

---

## Simplest Version That Solves BLOCKING Issues

If time is extremely constrained, here is the absolute minimum that makes implement-feature safe to run:

1. **Add `Mode: feature-implementation` to implement-feature SKILL.md Steps 6b/6d/6e context strings** (3 line edits in 1 file). This is a skill-level fix that does not require any agent changes. The agents will receive the mode signal and can use it to inform their LLM interpretation, even without explicit branching logic. An opus-model agent (fixer, reviewer) receiving "Mode: feature-implementation" in its context will adapt its behavior even if its process steps still say "triage analysis" — because the context explicitly contradicts the step, and opus is smart enough to resolve the contradiction.

2. **Add a simple NEEDS_DECOMPOSITION Block in implement-feature SKILL.md Step 6b** (5-line addition in 1 file). Just Block with a clear message. No re-decomposition logic.

3. **Add `smoke-check` to rollback trigger lists** (2 line edits in 2 files).

**Total: 3 files, ~10 edits. No agent definition changes at all.**

This is the "just make it not crash" version. The agents will produce lower-quality output (fixer will still say "root cause" instead of "spec requirement," reviewer will still check for "impact report completeness" that does not exist), but they will not Block, they will not leave git dirty, and they will not enter undefined states.

The full agent-level branching (Phase B) improves quality but is not strictly required to unblock bulk use. It should still be done, but it can be a follow-up if the P0 fix needs to ship immediately.

---

## Summary Verdicts

| Assumption | Verdict | Risk |
|---|---|---|
| Additive changes can't break bug-fix | HOLDS structurally, SHAKY semantically — Mode prefix must be REQUIRED, not preferred | MEDIUM |
| Scaffold and feature need separate agent branches | WRONG at agent level — two-way (bug/non-bug) is sufficient; three-way is over-engineering | LOW-MEDIUM |
| NEEDS_DECOMPOSITION handler is straightforward | WRONG — hardest problem in the refactoring; simplify to always-Block | HIGH |
| Smoke-check needs rollback | CORRECT — but exposes pre-existing rollback scope bug in decomposition mode | LOW |

**#1 risk:** NEEDS_DECOMPOSITION handler design — simplify ruthlessly.
**Ship first:** Smoke-check rollback (independent, 2-file fix).
**Simplest viable fix:** 3 files, ~10 edits, skill-level only, no agent changes.
