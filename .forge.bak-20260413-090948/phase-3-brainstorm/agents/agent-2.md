# Phase 3 Brainstorm — Agent 2 (Innovative)

Date: 2026-04-13
Role: Innovative brainstormer — looking for the design that best serves the three-pipeline reality while keeping the door open for future evolution.

---

## 1. Evaluation of Options A, B, and C

### Option A: Three Explicit Modes (`bug-fix | feature-implementation | scaffold`)

**How it works:** Every shared agent gets a three-way conditional at each mode-sensitive step.

```markdown
1. Read the context:
   - **Bug-fix mode** (context contains `Mode: bug-fix` or no Mode prefix): read triage analysis, impact report, and bug report.
   - **Feature mode** (context contains `Mode: feature`): read spec-analyst output, decomposition plan, subtask scope, and acceptance criteria. Issue tracker is active.
   - **Scaffold mode** (context contains `Mode: scaffold`): read subtask scope, acceptance criteria, and architecture design from spec/ folder. No issue tracker context. Hooks are suppressed. Build command comes from generated CLAUDE.md.
```

**Strengths:**
- Every pipeline has an exact, unambiguous branch. No collapsing, no "close enough."
- When reading the agent definition, you know precisely what happens in each pipeline. No guessing whether "non-bug" means feature or scaffold.
- Scaffold's unique constraints (no tracker, suppressed hooks, generated CLAUDE.md as build source) are visible at the agent level, not hidden in dispatch context.

**Weaknesses:**
- 3 branches in 4 agents x ~2.5 affected steps = ~10 three-way conditionals. That's real visual weight.
- Feature and scaffold share significant overlap in the fixer (both read subtask scope + AC + architecture, both use red-green-refactor for new behavior rather than bug reproduction). Having both spell out nearly identical text creates duplication.
- Every future mode adds another branch to every conditional. At mode 4 or 5, this becomes a wall of if/else in each step.

### Option B: Two Umbrella Modes (`bug-fix | guided-implementation`)

**How it works:** Collapse feature and scaffold into a single "guided-implementation" umbrella. Any dispatch that is NOT a bug-fix — whether it comes from implement-feature or scaffold — follows the same agent-level path. Scaffold-specific differences (no tracker, suppressed hooks, generated CLAUDE.md) are handled entirely at the skill dispatch layer, not inside the agent.

```markdown
1. Read the context:
   - **Bug-fix mode** (context contains `Mode: bug-fix` or no Mode prefix): read triage analysis, impact report, and bug report.
   - **Guided-implementation mode** (context contains `Mode: guided-implementation`): read subtask scope, acceptance criteria, and architecture design. Apply red-green-refactor for new behavior (not bug reproduction).
```

**Key insight:** The agent does NOT need to know whether hooks are suppressed or whether the tracker is active. Those are skill-layer concerns. The agent needs to know: "Am I fixing a bug or implementing a feature?" That binary question determines:
- Input vocabulary (triage analysis vs subtask scope)
- Step 5 framing (reproduce bug vs implement new behavior)
- Output labels (Root cause vs Feature implemented)

Everything scaffold-specific that differs from feature is a SKILL concern, not an AGENT concern:
- No tracker context → skill simply doesn't pass tracker info. Agent never touches the tracker directly.
- Hooks suppressed → skill doesn't run hooks. Agent never invokes hooks.
- Build from generated CLAUDE.md → skill passes the build command. Agent runs whatever command it receives.
- Per-subtask commits → skill handles commit after agent returns. Agent doesn't commit.

**Strengths:**
- Minimal agent changes: 2 branches per affected step, not 3.
- Correct separation of concerns: agents know about their coding task, skills know about pipeline orchestration.
- Future modes that involve "implement something new" (deployment, migration, onboarding) naturally fall into the guided-implementation umbrella. No agent changes needed.
- Feature and scaffold get identical agent behavior — which is correct, because the agent's job (implement a subtask from a spec) is identical in both cases.

**Weaknesses:**
- Hides the scaffold-vs-feature distinction at the agent level. If an agent ever DOES need to behave differently for scaffold vs feature (a future requirement), we'd need to split the umbrella.
- The name "guided-implementation" is new vocabulary — requires agreement and documentation.

### Option C: Hybrid (Two modes for most, three where scaffold truly differs)

**How it works:** Default to two branches (bug vs non-bug). Add a third scaffold branch only in steps where scaffold behavior is genuinely different from feature behavior at the agent level.

After careful analysis of every step in all 4 agents:

| Agent | Step | Bug vs Feature difference? | Feature vs Scaffold difference (at agent level)? |
|-------|------|---------------------------|--------------------------------------------------|
| fixer | 1 (input) | YES: triage vs subtask scope | NO: both receive subtask scope + AC |
| fixer | 5 (TDD) | YES: reproduce bug vs new behavior | NO: both do new behavior TDD |
| fixer | 8 (output) | YES: "Root cause" vs "Feature" | NO: same output labels |
| reviewer | 1 (input) | YES: bug report vs spec | NO: both receive spec + AC |
| reviewer | 4 (checklist) | YES: "Root cause" item reworded | NO: same checklist applies |
| test-engineer | 1 (input) | YES: bug report vs subtask | NO: both receive subtask + AC |
| test-engineer | 3 (scope) | YES: regression test vs AC test | NO: same AC-based scoping |
| e2e-test-engineer | 1 (input) | YES: bug report vs spec | NO: both receive spec |

**Result: Zero steps where scaffold differs from feature at the agent level.**

This means Option C collapses into Option B. There is no step where a third branch is needed.

---

## 2. Proposed Pattern — Fixer Step 1 (Exact Markdown)

Using Option B terminology (`Mode: bug-fix | guided-implementation`):

```markdown
1. Read the context provided by the orchestrating skill:
   - If context contains `Mode: bug-fix` (or no Mode prefix — backward compatibility default):
     Read the triage analysis and impact report thoroughly. If triage analysis or impact report is missing, Block with reason 'Missing input from previous pipeline stage'.
   - If context contains `Mode: guided-implementation`:
     Read the subtask scope, acceptance criteria, and architecture design. These replace the triage analysis and impact report. If subtask scope or acceptance criteria are missing, Block with reason 'Missing input from previous pipeline stage'.
```

And Fixer Step 5 (the biggest change):

```markdown
5. Implement the fix using red-green-refactor:
   - If `Mode: bug-fix`:
     - **RED:** Write a test that reproduces the bug. Run it — confirm it FAILS. If the test passes, your test does not capture the actual bug; rewrite it.
     - **GREEN:** Implement the minimal fix to make the failing test pass. Target root cause, not symptoms. Smallest possible change. Follow existing code conventions exactly. No unrelated cleanup or refactoring.
   - If `Mode: guided-implementation`:
     - **RED:** Write a test that captures the acceptance criteria for this subtask. Run it — confirm it FAILS. If the test passes, the feature already exists; verify against AC and skip to output.
     - **GREEN:** Implement the minimal code to make the failing test pass. Follow the architecture design. Smallest possible change. Follow existing code conventions exactly. No unrelated cleanup or refactoring.
   - **REFACTOR:** (both modes) If the change introduced duplication or unclear code, clean up — but only within the changed scope.
   - If the project has no test infrastructure (no test framework, no test directory), skip the RED phase and implement directly. Note "No test infrastructure — TDD skipped" in your output.
   - **ESCAPE HATCH:** (both modes, unchanged)
```

And Fixer Step 8 (output):

```markdown
8. Output:

   If `Mode: bug-fix`:
   ```markdown
   ## Fix Report
   - **Root cause:** {what was wrong and why}
   - **Approach:** {what was done and why this approach over alternatives}
   - **Files changed:** {list with brief description of each change}
   - **Build:** PASS
   - **Tests:** PASS / {note about pre-existing failures}
   ```

   If `Mode: guided-implementation`:
   ```markdown
   ## Implementation Report
   - **Subtask:** {subtask ID and title}
   - **Approach:** {what was done and why this approach over alternatives}
   - **AC coverage:** {which acceptance criteria this implementation addresses}
   - **Files changed:** {list with brief description of each change}
   - **Build:** PASS
   - **Tests:** PASS / {note about pre-existing failures}
   ```
```

---

## 3. Future Modes Analysis

Potential future dispatch contexts:

| Future caller | What fixer does | Bug-fix or guided-implementation? |
|---------------|----------------|-----------------------------------|
| deployment-verifier fix | Fixes a deployment config issue found by verifier | Bug-fix (fixing a broken thing) |
| reproducer-driven fix | Fixes a bug reproduced by browser | Bug-fix (fixing a broken thing) |
| scaffold --extend | Adds features to existing scaffold | Guided-implementation (subtask from spec) |
| batch feature | Multiple features in sequence | Guided-implementation (subtask from spec) |
| migration pipeline | Migrates code from old to new patterns | Could go either way, but closer to guided-implementation |
| onboard wizard fix | Fixes config issues found during onboarding | Bug-fix (fixing a broken thing) |

**Key observation:** Every plausible future caller is either "fix something broken" (bug-fix) or "implement something new from a spec" (guided-implementation). There is no third fundamental modality lurking on the roadmap.

The only hypothetical third mode would be something like "exploratory" — where the agent generates code without a spec or a bug. But that contradicts the entire ceos-agents architecture (every pipeline starts with analysis/spec). It would require a fundamentally different agent, not a mode branch.

**Verdict:** Two modes are future-proof. Three modes is solving a problem that does not exist at the agent level.

---

## 4. Scoring

| Criterion | Option A (3 explicit) | Option B (2 umbrella) | Option C (hybrid) |
|-----------|----------------------|----------------------|-------------------|
| **Maintainability** | 3 — Every new pipeline or mode adds a branch to every conditional in 4 agents. Maintenance burden grows linearly with modes. | 5 — New pipelines that implement features need zero agent changes. Bug-fix pipelines need zero agent changes. Only a truly novel modality requires a new branch. | 4 — Same as B for most steps, but the "where does the third branch go?" question requires ongoing judgment calls. |
| **Correctness** | 5 — Every pipeline has an exact path. No ambiguity. No risk of scaffold accidentally following a feature path that subtly differs. | 4 — Correct IF the assertion holds that scaffold and feature are identical at the agent level. The analysis in Section 1 confirms this, but it requires the skill layer to handle all scaffold-specific concerns (which it already does). | 4 — Same correctness as B since no third-branch steps were found. |
| **Simplicity** | 2 — Three-way conditionals in markdown are harder to read, harder to review, and create the impression of more complexity than exists. A reader must diff all 3 branches to understand what actually varies. | 5 — Two-way branch is the simplest possible conditional. Each step has an "old way" and a "new way." Reviewers can quickly see what changed. | 3 — Inconsistent: some steps have 2 branches, some have 3. Reader must understand why. "Why does this step have 3 branches but the one above only has 2?" is a question that costs cognitive overhead. |
| **Future-proofing** | 3 — Handles known modes well but adds friction for new ones. | 5 — Two stable categories (fix broken / implement new) that naturally accommodate all foreseeable callers. | 3 — Hybrid means every new mode requires auditing every step to decide: 2 or 3 branches? |
| **TOTAL** | **13/20** | **19/20** | **14/20** |

---

## 5. Recommendation

**Option B: Two umbrella modes (`bug-fix | guided-implementation`).**

### Rationale

The Phase 2 research correctly identified that scaffold dispatches agents with structurally different context — but the structural differences are all at the **skill dispatch level**, not the **agent behavior level**. The agent doesn't know or care whether hooks are suppressed. The agent doesn't commit per-subtask. The agent doesn't interact with the issue tracker. All of those are skill responsibilities.

What the agent DOES care about:
1. **What am I reading?** Triage analysis OR subtask scope + AC.
2. **What am I doing?** Fixing a bug OR implementing new behavior.
3. **What do I output?** Root cause report OR implementation report.

That's a binary. Bug-fix or guided-implementation. Two modes.

### Implementation detail: Mode injection

The skill dispatch layer injects the Mode prefix. Update each skill:

- `fix-ticket/SKILL.md`: no change (default = bug-fix, backward compatible)
- `fix-bugs/SKILL.md`: no change (default = bug-fix)
- `implement-feature/SKILL.md`: add `Mode: guided-implementation` to fixer/reviewer/test-engineer/e2e context strings
- `scaffold/SKILL.md`: add `Mode: guided-implementation` to fixer/reviewer/test-engineer/e2e context strings

Both implement-feature and scaffold inject the SAME mode. That's the point — the agent treats them identically.

### Why not "feature" and "scaffold" as separate mode names?

Because it creates a false distinction at the agent level. If we name them `Mode: feature` and `Mode: scaffold`, a future maintainer will ask: "What does the fixer do differently for scaffold vs feature?" The answer is: nothing. The names would imply a distinction that the code does not contain. That's a design lie.

`guided-implementation` accurately describes the shared behavior: "You have a spec, subtask scope, and acceptance criteria. Implement the subtask." Whether the spec came from spec-analyst (feature) or spec-writer (scaffold) is irrelevant to the agent.

### Naming alternatives considered

| Name | Pro | Con |
|------|-----|-----|
| `non-bug` | Simple | Defined by negation, not intention. "What AM I doing?" unanswered. |
| `feature` | Familiar | Excludes scaffold conceptually. Scaffold is not a "feature." |
| `implementation` | Accurate | Too generic. Bug-fix is also implementation. |
| `guided-implementation` | Describes the input contract (spec-guided) | Longer. New vocabulary. |
| `spec-driven` | Describes the AC/spec input | Could apply to bug-fix if triage AC are considered a "spec." |

`guided-implementation` wins on precision. The agent receives explicit guidance (subtask scope, AC, architecture design) and implements from it. This is distinct from bug-fix where the agent receives a problem description and must figure out the solution.

### Risk mitigation

The one risk of Option B: a future scenario where scaffold agents genuinely need different behavior than feature agents. Mitigation: if that happens, add a **sub-mode** (`Mode: guided-implementation/scaffold`) rather than promoting scaffold to a top-level mode. The agent can check the sub-mode only in the specific step that needs it, without polluting all other steps. But based on the current architecture and roadmap, this scenario is unlikely.
