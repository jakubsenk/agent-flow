# Cross-Plugin Bridge: Pragmatic Alternatives Analysis

**Date:** 2026-03-30
**Reviewer:** Pragmatic Engineer
**Source document:** `docs/plans/cross-plugin-bridge-value-analysis.md`
**Status:** Critical review of bridge proposal

---

## Executive Summary

The bridge proposal claims unique value from combining forge's divergent thinking with ceos-agents' convergent execution. After reading both codebases thoroughly, I find that **80% of the claimed value can be captured with zero cross-plugin code**, and the remaining 20% (hidden test reserve) is genuinely novel but can be achieved with a single convention file. The full bridge is over-engineered for the actual problem.

---

## Alternative 1: Improve forge Phase 7 Instead of Bridging

### What forge Phase 7 currently lacks (vs ceos-agents execution)

| Gap | forge Phase 7 today | ceos-agents equivalent |
|-----|---------------------|----------------------|
| Adversarial review | Self-review checklist (implementer-prompt.md) + post-hoc code-quality-reviewer | Dedicated opus reviewer agent, adversarial stance, min 3 issues, AC fulfillment verdicts |
| Iteration loop | None within Phase 7; Phase 8 can send back max 2x | fixer <-> reviewer loop, 5 iterations per subtask |
| AC tracking | PASS_TO_PASS gate (test regression only) | Per-AC FULFILLED/PARTIALLY/NOT ADDRESSED verdicts |
| Diff limits | 200 LOC per task (soft) | 100 lines hard limit |
| Failure handling | BLOCKED -> human | Block -> rollback-agent -> tracker comment -> next |

### What it would take to close these gaps

**1a. Add adversarial review to Phase 7 (per-task, not just Phase 8):**
- Create `skills/forge-execute/adversarial-reviewer-prompt.md` (~50 lines)
- Modify `SKILL.md` per-task workflow: after self-review, dispatch adversarial reviewer agent
- Add iteration loop (implement -> review -> fix, max 3 rounds)
- Estimated: ~80 lines of prompt, ~40 lines of SKILL.md changes = **~120 lines across 2 files**

**1b. Add AC fulfillment tracking:**
- Add formal-criteria.md mapping to per-task reviewer context
- Add AC verdict section to reviewer prompt (FULFILLED/PARTIALLY/NOT ADDRESSED per REQ-*)
- Estimated: ~30 lines of prompt addition to adversarial-reviewer-prompt.md

**1c. Add per-task iteration limits:**
- Add to SKILL.md: "If adversarial reviewer returns REVISION_NEEDED, re-dispatch implementer with feedback. Max 3 rounds."
- Estimated: ~15 lines of SKILL.md changes

**Total for Alternative 1: ~165 lines across 3 files**

### Assessment

| Metric | Value |
|--------|-------|
| Lines of change | ~165 |
| Files changed | 3 (new reviewer prompt, SKILL.md, implementer-prompt.md output section) |
| Value captured | ~55% of bridge (gets adversarial review + AC tracking + iteration, but within forge's generic prompt system, not ceos-agents' specialized agents) |
| Maintenance burden | LOW -- changes are internal to forge, no cross-plugin coupling |
| Risk | LOW -- additive changes, no architectural shift |

### What this does NOT capture

- ceos-agents' 19 specialized agent definitions with Process/Constraints structure
- Module Docs + Agent Overrides project-specific knowledge
- Issue tracker lifecycle (state transitions, blocking comments, resume)
- Publisher agent (PR creation with template)
- Rollback agent (git revert on failure)

### Verdict

**Good enough for forge users who don't need tracker integration.** If the goal is "better code quality from forge", this is the simplest path. But it doesn't help anyone who wants tracker-driven pipelines -- those users need ceos-agents regardless.

---

## Alternative 2: Improve ceos-agents' Spec Phase Instead of Bridging

### What ceos-agents spec phase currently lacks (vs forge)

| Gap | ceos-agents today | forge equivalent |
|-----|-------------------|-----------------|
| Multi-perspective research | None | 5 parallel research agents (Phase 1-2) |
| Brainstorming | None | 3 heterogeneous personas + judge (Phase 3) |
| Adversarial spec review | spec-writer <-> spec-reviewer loop (2 agents) | 3 parallel reviewers: compliance + quality + devil's advocate |
| TDD from spec | None (test-engineer writes tests after implementation) | forge-tdd: tests from spec before code, 80/20 visible/hidden split |
| EARS format | Free-form AC | Structured EARS: "When [condition], the system shall [behavior]" |

### What it would take to close these gaps

**2a. Add 3 parallel spec reviewers to spec-writer:**
- Create `agents/spec-compliance-reviewer.md` (~40 lines)
- Create `agents/spec-quality-reviewer.md` (~40 lines)
- Create `agents/spec-devils-advocate.md` (~40 lines)
- Modify `commands/scaffold.md` to dispatch 3 parallel reviewers instead of 1
- Modify iteration logic: all 3 must pass, revision on any failure
- Estimated: ~120 lines of new agents + ~40 lines of command changes = **~160 lines across 4 files**

**2b. Add dependency graph to architect:**
- Already exists! The architect agent already produces DAG with `depends_on`, `maps_to`, topological sort validation, cycle detection, max 7 subtasks
- The architect's task tree IS a dependency graph. forge-plan's format is different (blocks/blockedBy vs depends_on) but functionally equivalent
- **0 lines needed**

**2c. Add EARS format to spec-writer:**
- Modify spec-writer.md Process step 5 to prefer EARS format for functional requirements
- Estimated: ~10 lines

**2d. Add pre-implementation TDD phase:**
- Create `agents/tdd-writer.md` (~60 lines) -- writes tests from spec before fixer runs
- Modify `commands/implement-feature.md` to add TDD step between architect and fixer
- No hidden test split (that's forge-specific and requires structural isolation)
- Estimated: ~60 lines agent + ~25 lines command = **~85 lines across 2 files**

**Total for Alternative 2: ~255 lines across 6-7 files**

### Assessment

| Metric | Value |
|--------|-------|
| Lines of change | ~255 |
| Files changed | 6-7 (3 new reviewer agents, 1 new tdd-writer agent, scaffold.md, implement-feature.md, spec-writer.md) |
| Value captured | ~45% of bridge (gets better spec quality + TDD, but no research phase, no brainstorm, no hidden test reserve) |
| Maintenance burden | MEDIUM -- 4 new agents to maintain, new pipeline step |
| Risk | MEDIUM -- changes the scaffold and implement-feature pipelines |

### What this does NOT capture

- 5 parallel research agents (would require a research infrastructure that doesn't exist in ceos-agents)
- 3 brainstorm personas + judge synthesis (ceos-agents has no brainstorming concept)
- Hidden 20% test reserve (requires structural isolation that worktree-based execution provides)
- Phase 8 five-agent adversarial verification panel

### Verdict

**Worthwhile improvements on their own merits, but don't justify skipping the bridge.** The 3 parallel spec reviewers are a good idea regardless. The TDD agent is a good idea regardless. But these don't replicate forge's core strength: the research + brainstorm + hidden test reserve chain. That chain requires forge's architecture (worktree isolation, multi-phase checkpoints).

---

## Alternative 3: Shared Agent Library (Third Plugin)

### Concept

Extract fixer, reviewer, test-engineer, acceptance-gate into a shared plugin (`shared-agents`) that both forge and ceos-agents depend on.

### Feasibility Analysis

**Claude Code plugin system capabilities (from both plugin.json files):**
- Plugins are identified by name in `plugin.json`
- Plugins have skills and commands that are namespaced (`ceos-agents:fix-ticket`, `filip-superpowers:forge`)
- Skills reference each other via the `Skill` tool
- Agents are dispatched via the `Task` tool with inline prompts

**Critical problem:** Claude Code plugins are self-contained markdown repositories. There is no `dependencies` field in `plugin.json`. There is no mechanism for one plugin to import agents from another plugin. The Task tool receives the agent prompt as inline text, not as a reference to a plugin's agent.

**Could we work around this?**
- The `Skill` tool CAN invoke skills across plugins (e.g., `ceos-agents:workflow-router` can be called from filip-superpowers)
- But agents (dispatched via Task tool) are NOT cross-plugin -- they're inline prompts
- Skills are the only cross-plugin boundary

**Theoretical workaround:** Create skills that wrap each agent (e.g., `shared-agents:fixer` skill that internally dispatches the fixer agent via Task). But this adds a Skill -> Task indirection layer for every agent call, and skills can't return structured data to the caller the way Task tool does.

### Assessment

| Metric | Value |
|--------|-------|
| Lines of change | ~500+ (extracting agents, creating wrapper skills, modifying both plugins) |
| Files changed | 15+ across 3 repositories |
| Value captured | ~30% (shared agents, but loses the orchestration context that makes agents effective) |
| Maintenance burden | HIGH -- 3 repos to maintain, cross-plugin versioning |
| Risk | HIGH -- untested plugin architecture, Skill->Task indirection may not work |

### Verdict

**Do not build this.** The Claude Code plugin system is not designed for shared libraries. The agent effectiveness comes from the orchestration context (what the command passes to the agent), not from the agent definition alone. Extracting agents strips them of their orchestration context. This is the wrong abstraction boundary.

---

## Alternative 4: Convention-Based Handoff (Zero Code)

### The Manual Workflow

```
Step 1: User runs /forge "build task management app"
        forge completes Phase 0-6: research -> brainstorm -> spec -> TDD -> plan
        Output: .forge/phase-4-spec/final/, .forge/phase-5-tdd/tests/, .forge/phase-6-plan/final.md

Step 2: User manually translates forge output to ceos-agents input:
        a) Create issue in tracker from forge spec (copy-paste summary + AC)
        b) Run /ceos-agents:implement-feature {ISSUE-ID}
        c) ceos-agents runs its own spec-analyst -> architect -> fixer -> reviewer -> test -> publish
```

### What is ACTUALLY lost in this manual handoff?

**Lost semantic information (specific, not hand-wavy):**

1. **EARS-format requirements (REQ-*) are not transferred.** ceos-agents spec-analyst will re-analyze the issue from scratch. The EARS requirements from forge-spec are lost. spec-analyst produces its own AC list, which may differ from forge's formal-criteria.md. **Impact: AC drift between what forge specified and what ceos-agents implements.**

2. **Forge's architectural design is lost.** forge-spec produces `design.md` with component diagrams, data flow, interface definitions. ceos-agents architect re-designs from the spec-analyst output. **Impact: The architect may choose a different approach than forge-spec intended. This is actually fine -- architect does its own analysis of the codebase anyway.**

3. **TDD test suite is not used.** forge-tdd produces tests from spec. ceos-agents test-engineer writes tests after implementation. **Impact: No test-first discipline. But more importantly, the hidden 20% test reserve is completely lost -- there are no hidden tests to run in Phase 8 verification.**

4. **Dependency-ordered task graph has different granularity.** forge-plan produces tasks with ~200 LOC estimates. ceos-agents architect produces subtasks with <=100 LOC hard limit. **Impact: ceos-agents will decompose differently, which is fine -- it's designed for its own execution constraints.**

5. **Brainstorm synthesis is lost.** The 3-persona brainstorm that informed forge-spec's direction is not captured anywhere in the issue tracker card. **Impact: The "why this approach" reasoning disappears.**

6. **Research findings are lost.** 5 parallel research agents' findings that informed the spec. **Impact: ceos-agents code-analyst reads the codebase independently, but external research (web, API docs, framework patterns) may not be replicated.**

**What is NOT lost (i.e., ceos-agents re-derives independently):**

- Architecture (architect reads codebase and designs fresh)
- Code quality review (reviewer is adversarial regardless of source)
- Test coverage (test-engineer writes tests from changed code)
- Tracker lifecycle (ceos-agents handles this natively)
- PR creation and publishing

### The key question: does ceos-agents NEED forge's upstream output?

**For most features: NO.** ceos-agents' pipeline (spec-analyst -> architect -> fixer -> reviewer) is self-contained. It reads the codebase, designs the architecture, implements, and reviews. It doesn't need forge's research or brainstorm because it operates at a different abstraction level -- it's implementing a specific issue, not exploring a problem space.

**For complex greenfield systems: MAYBE.** When you're building something entirely new where the "what" is unclear, forge's research + brainstorm + adversarial spec is genuinely valuable. But ceos-agents' `scaffold` command also handles greenfield, with its own spec-writer -> scaffolder -> implement pipeline.

**The honest answer:** The two plugins solve different problems. Forge is for "I have a vague idea, help me think it through and build it." Ceos-agents is for "I have a tracked issue, fix/implement it with quality gates and tracker integration." The overlap (execution) is not where the value lives.

### Assessment

| Metric | Value |
|--------|-------|
| Lines of change | 0 |
| Files changed | 0 |
| Value captured | ~60% (user gets both pipelines, loses only automated handoff and hidden test reserve) |
| Maintenance burden | ZERO |
| Risk | ZERO |

### Verdict

**This is the correct baseline.** The manual handoff works today. The user runs forge for thinking, ceos-agents for executing. The only things genuinely lost are: (1) automated format translation, (2) hidden test reserve in verification, (3) convenience. Of these, only #2 is a structural capability that can't be replicated manually.

---

## Alternative 5: Minimal Bridge (Smallest Possible)

### What is the ABSOLUTE MINIMUM that captures 80% of bridge value?

After analyzing all the gaps, the bridge's unique value reduces to exactly two things:

1. **Format translation** (forge spec -> ceos-agents issue): Mechanical, can be a documentation page
2. **Hidden test reserve** (forge-tdd hidden tests used in post-implementation verification): Structural, genuinely novel

Everything else either (a) works fine without a bridge (manual handoff), or (b) should be improved within each plugin independently (adversarial review in forge, TDD in ceos-agents).

### Minimum Viable Bridge: A Convention File + Documentation

**Option A: Single documentation page (0 code lines)**

Create `docs/guides/forge-to-ceos-handoff.md`:
```markdown
# Using forge output with ceos-agents

## After forge Phase 6 (plan approved):

1. Create issue in tracker:
   - Title: first line of .forge/phase-4-spec/final/requirements.md
   - Description: paste .forge/phase-4-spec/final/requirements.md content
   - AC: paste from .forge/phase-4-spec/final/formal-criteria.md

2. Run: /ceos-agents:implement-feature {ISSUE-ID}

## To use forge's hidden test reserve for post-verification:

1. After ceos-agents creates the PR:
   - Run: /filip-superpowers:forge-verify
   - This runs Phase 8 (5-agent panel) against the implementation
   - Hidden tests from .forge/phase-5-tdd/tests-hidden/ are used
```

Value captured: ~70%. User does 2 minutes of copy-paste. Hidden tests are used via manual forge-verify invocation.

**Option B: Single flag on implement-feature (~50 lines)**

Add `--forge-context` flag to `implement-feature.md`:
```
If --forge-context flag:
  1. Read .forge/phase-4-spec/final/requirements.md
  2. Read .forge/phase-4-spec/final/formal-criteria.md
  3. Skip spec-analyst (forge already did this)
  4. Pass forge requirements + formal criteria directly to architect
  5. After publisher creates PR: display reminder
     "Forge hidden tests available. Run /filip-superpowers:forge-verify for Phase 8 verification."
```

Changes:
- `commands/implement-feature.md`: Add flag parsing (~5 lines), add forge-context read step (~20 lines), modify spec-analyst skip logic (~10 lines), add post-publish reminder (~5 lines)
- Total: **~40-50 lines in 1 file**

Value captured: ~80%. Automated format translation. Hidden tests used via reminder.

**Option C: Option B + auto-invoke forge-verify (~80 lines)**

Same as Option B, but after publisher creates PR, automatically dispatch forge-verify via Skill tool:
```
After step 10 (publisher):
  If --forge-context AND .forge/phase-5-tdd/tests-hidden/ exists:
    Invoke /filip-superpowers:forge-verify
    If Commander verdict < 0.7: display warning with findings
```

Changes:
- `commands/implement-feature.md`: Option B changes + ~30 lines for forge-verify dispatch
- Total: **~70-80 lines in 1 file**

Value captured: ~90%. Full automated pipeline including hidden test verification.

### Assessment for Option B (recommended)

| Metric | Value |
|--------|-------|
| Lines of change | ~50 |
| Files changed | 1 (implement-feature.md) |
| Value captured | ~80% of full bridge |
| Maintenance burden | MINIMAL -- single flag, reads files if they exist, skips if they don't |
| Risk | LOW -- additive flag, zero impact when not used |

### Assessment for Option C (stretch)

| Metric | Value |
|--------|-------|
| Lines of change | ~80 |
| Files changed | 1 (implement-feature.md) |
| Value captured | ~90% of full bridge |
| Maintenance burden | LOW -- depends on forge-verify Skill existing, graceful degradation if not |
| Risk | LOW-MEDIUM -- cross-plugin Skill invocation needs testing |

---

## Comparison Matrix

| Alternative | Lines | Files | Value | Maintenance | Risk | Recommendation |
|-------------|-------|-------|-------|-------------|------|----------------|
| 1: Improve forge Phase 7 | ~165 | 3 | 55% | Low | Low | Do independently (good for forge) |
| 2: Improve ceos-agents spec | ~255 | 6-7 | 45% | Medium | Medium | Do independently (good for ceos-agents) |
| 3: Shared agent library | ~500+ | 15+ | 30% | High | High | DO NOT BUILD |
| 4: Manual handoff (zero code) | 0 | 0 | 60% | Zero | Zero | Current baseline, works today |
| 5A: Documentation page | ~30 | 1 | 70% | Zero | Zero | Quick win, do first |
| 5B: --forge-context flag | ~50 | 1 | 80% | Minimal | Low | RECOMMENDED |
| 5C: 5B + auto forge-verify | ~80 | 1 | 90% | Low | Low-Med | Stretch goal after 5B |
| Full bridge (from proposal) | ~300-600 | 3-7 | 100% | Medium-High | Medium | Over-engineered |

---

## The Honest Assessment of the "Double Adversarial Sandwich"

The value analysis document's centerpiece claim is the "double adversarial sandwich" -- forge-spec's 3 reviewers on one end, ceos-agents' fixer-reviewer loop in the middle, forge-verify's 5-agent panel on the other end. This sounds impressive. Let me evaluate it honestly.

**What the sandwich actually means in practice:**

```
forge-spec reviewers check the SPECIFICATION quality
  (Are requirements clear? Complete? Internally consistent?)

ceos reviewer checks the CODE quality against AC
  (Does the code implement what was specified? Are there bugs?)

forge-verify checks the IMPLEMENTATION against hidden tests + adversarial scenarios
  (Does it actually work? Is it secure? Does it handle edge cases?)
```

These are three DIFFERENT concerns being checked at three DIFFERENT stages. This is not a "sandwich" -- it's just a quality pipeline with multiple gates. Any well-designed pipeline has this. The novel element is specifically the hidden test reserve from forge-tdd that forge-verify uses.

**The hidden test reserve is the only genuinely unique structural capability.** Everything else (adversarial spec review, adversarial code review, AC tracking) can be added to either plugin independently.

**And the hidden test reserve works fine with Option 5B/5C** -- the user runs forge Phases 0-6, then `implement-feature --forge-context`, then forge-verify sees the hidden tests. No bridge needed for this. Just a flag that says "forge output exists, use it."

---

## Final Recommendation

1. **Now:** Write the documentation page (Alternative 5A). Zero code, immediate value.
2. **Next version (v5.7.0):** Add `--forge-context` flag (Alternative 5B). 50 lines, 80% of bridge value.
3. **If cross-plugin Skill calls prove reliable:** Add auto forge-verify (Alternative 5C). 30 more lines.
4. **Independently:** Consider adding 3 parallel spec reviewers to ceos-agents (Alternative 2a) and adversarial per-task review to forge (Alternative 1a). These are good improvements regardless of bridge.
5. **Do not build:** The full bridge, the shared agent library, or any other architecture that requires cross-plugin state management, format translators, or new orchestration layers.

The best architecture is the one that doesn't need to exist. A 50-line flag captures 80% of the value of a 600-line bridge.
