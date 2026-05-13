# Research Questions — Work Item 3: Block Handler Inline Removal

Agent: agent-2
Focus: Comparing inline block handler in `skills/implement-feature/SKILL.md` against `core/block-handler.md` and peer skills.

---

## Q1 — Does the inline block handler in implement-feature (lines 643–666) differ in substance from `core/block-handler.md`?

**File references:**
- `skills/implement-feature/SKILL.md` lines 643–666 (Step X — Block handler section)
- `core/block-handler.md` lines 1–57 (full file)

**What to verify:** The inline copy in implement-feature spells out all 6 steps verbatim (rollback, set issue state, on-block action, block comment, webhook, state.json update), including the full block comment template and the curl webhook command. Compare against `core/block-handler.md` to identify any divergence in:
- The rollback condition (implement-feature step 1 names `fixer`, `reviewer`, `test-engineer`, `e2e-test-engineer`, `smoke-check` as rollback triggers — core names the same set but does not mention `smoke-check` explicitly).
- Webhook payload shape: implement-feature uses `"issue":"{issue_id}"` and `"agent":"{agent}"` (step 5); core uses `"issue_id":"{issue_id}"` and `"agent_name":"{agent_name}"` — **this is a semantic discrepancy**.
- Curl flags: implement-feature omits `--max-time 5 --retry 0` that are present in core step 5.

**Answer needed:** Confirm whether these three discrepancies are real diffs or transcription artifacts, and whether they constitute behavioral differences or only cosmetic ones.

---

## Q2 — What skill-specific logic in implement-feature's Step X must remain after the inline body is replaced with a delegation reference?

**File references:**
- `skills/implement-feature/SKILL.md` lines 643–666 (Step X body)
- `skills/implement-feature/SKILL.md` line 666 (state.json update at end of Step X)

**What to verify:** Implement-feature's Step X contains a 6th numbered item that updates `state.json` (set `status: "blocked"`, write `block` object). Core's step 6 (`core/block-handler.md` line 46) defines the same state.json write. Determine whether this is fully covered by the core contract or whether implement-feature needs an explicit state.json reminder after delegation (as fix-ticket does at line 609: `Update state.json: set top-level status to "blocked"...`).

**Answer needed:** Which part of Step X, if any, is implement-feature-specific and cannot be moved into the core delegation call?

---

## Q3 — How do `fix-ticket` and `fix-bugs` structure their Step X, and do they inline or purely delegate?

**File references:**
- `skills/fix-ticket/SKILL.md` lines 605–609 (Step X — Block handler)
- `skills/fix-bugs/SKILL.md` lines 667–710 (Step X — Block handler)

**What to verify:**
- `fix-ticket` Step X (lines 605–609): Uses a two-line delegation — `Follow core/block-handler.md for the block protocol` — followed by a single state.json update sentence. This is the "delegate + skill-specific state update" pattern.
- `fix-bugs` Step X (lines 667–710): Inlines the full 8-step procedure including rollback, state transitions, on-block action, block comment template, webhook curl command, state.json update, block counter check, and "continue with next bug" — making it significantly longer than both core and fix-ticket's versions.

**Answer needed:** Confirm the three-way divergence: fix-ticket delegates cleanly (2 lines + state.json), implement-feature inlines 6 steps (~24 lines), fix-bugs inlines 8 steps (~44 lines with fix-bugs-specific additions like block counter and "continue with next bug"). Identify which additions in fix-bugs are legitimately skill-specific.

---

## Q4 — Where exactly is the inline block handler in implement-feature, and what is the precise line range?

**File references:**
- `skills/implement-feature/SKILL.md` lines 642–667

**What to verify:** The inline block handler starts at line 642 (`### X. Block handler`) and ends at line 667 (end of step 6, state.json update). The header line (`### X. Block handler`) at line 642 is followed by `Follow core/block-handler.md:` at line 644, but then continues to spell out all 6 steps verbatim rather than stopping at the delegation reference. The full inline body spans approximately lines 644–666 (23 lines of procedure text after the heading and delegation prefix).

**Answer needed:** Confirm that after a clean refactor, lines 644–666 can be collapsed to a single delegation sentence (`Follow core/block-handler.md.`) plus a single implement-feature-specific state.json reminder (if Q2 determines one is needed).

---

## Q5 — Does implement-feature's inline block handler reference any variables or pipeline state that are specific to implement-feature and not part of core/block-handler.md's input contract?

**File references:**
- `skills/implement-feature/SKILL.md` lines 643–666 (Step X body)
- `core/block-handler.md` lines 7–17 (Input Contract table)

**What to verify:** The core input contract (`core/block-handler.md` lines 7–17) defines six input fields: `agent_name`, `step_name`, `reason`, `detail`, `recommendation`, `issue_id`, `config`. Cross-check whether implement-feature's inline Step X references any pipeline-local variables beyond these — for example, the `mode` field (`"code-feature"`) or `pipeline` field (`"implement-feature"`) that appear in state.json but are not part of core's input contract. The inline state.json update at line 666 writes `{agent, step, reason, detail, recommendation}` — this matches core's `block` object schema exactly (no extra fields).

**Answer needed:** Confirm no implement-feature-specific variables are embedded in the block comment template or webhook payload within the inline copy, meaning the delegation can be done with zero field remapping.

---

## Q6 — What is the established "delegate to core + add skill-specific state update" pattern, and where is the canonical example?

**File references:**
- `skills/fix-ticket/SKILL.md` lines 605–609 (Step X — the canonical minimal delegation pattern)
- `core/block-handler.md` lines 19–46 (Process steps — what the core covers)

**What to verify:** Fix-ticket's Step X reads:
```
### X. Block handler
Follow `core/block-handler.md` for the block protocol.
Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```
This is the minimal pattern: one delegation sentence (covering all 6 core steps) + one state.json sentence (because state.json is also covered by core step 6, but fix-ticket repeats it explicitly for LLM-directed compliance — per the contributor note in fix-bugs line 89).

**Answer needed:** Confirm whether the state.json reminder sentence in fix-ticket Step X is redundant (core covers it) or intentional per the "LLM-directed repetition" philosophy documented in fix-bugs line 89 (`<!-- Contributor note: ... -->`). If intentional, implement-feature's refactored Step X should retain the state.json line even after removing the 6-step inline body.
