# Phase 1 Research Questions — Synthesized & Deduplicated

**Produced by:** Synthesis agent  
**Source agents:** agent-1.md (Redmine status call sites), agent-2.md (Publisher newline bug), agent-3.md (Onboard, templates, backward compat)  
**Date:** 2026-04-15  
**Total questions:** 15

---

## Key Findings from Phase 1

### Bug 1 — Redmine Status Transitions (`status:{name}` raw-string passthrough)

- **Root cause is in the config contract, not in individual skills.** `core/config-reader.md` stores `state_transitions` as a verbatim key→value map; no tracker-type-specific parsing or name-to-ID translation occurs at read time.
- **Five distinct call sites** pass raw config strings directly to MCP tools with no Redmine-specific branching: (1) `fix-ticket` Step 1 (on_start_set), (2) `implement-feature` Step 1 (on_start_set), (3) `core/block-handler.md` Step 2 (Blocked transition), (4) `core/fix-verification.md` Step 6 (re-open transition), (5) `fix-bugs` per-issue status set (independent code path, not delegating to fix-ticket).
- **`docs/reference/trackers.md` explicitly documents the bug pattern** — the "LLM convention" note says the LLM translates `status:{name}` to `status_id=N`, but the MCP tool `redmine_update_issue` expects a numeric `status_id`. This is the specification of the broken behavior.
- **Neither `fix-ticket` nor `fix-bugs` has any tracker-type branching at status-set call sites.** A fix must be applied at a shared layer (config-reader or a new resolution helper), or duplicated at all five call sites.
- **No existing post-set verification pattern** exists in any skill or agent — all status-set calls trust the MCP call silently.

### Bug 2 — Publisher Literal `\n` in PR Body

- **The bug is structural:** `agents/publisher.md` Step 6 instructs the LLM to fill the PR Description Template but gives no encoding contract for how to pass the multi-line `body` parameter to the MCP `create_pull_request` tool.
- **Three MCP call sites are vulnerable** to the same `\n` literal rendering problem: (1) `publisher.md` Step 6 (PR body), (2) `publisher.md` Step 7 (PR link comment + block comment when publisher blocks), (3) subtask `body` construction in `fix-ticket` Step 4b-tracker and `implement-feature` Step 5a.
- **`core/post-publish-hook.md` already uses a heredoc pattern** for the webhook curl call, explicitly to avoid encoding problems — but this pattern is NOT applied to MCP tool calls anywhere in the plugin.
- **The MCP tool layer's behavior with embedded newlines is undocumented** within the repo; it is unknown whether the fix belongs in the agent prompt (instruct LLM to use real newlines) or at a pre-processing step.

### Cross-cutting

- **Onboard wizard** (`skills/onboard/SKILL.md` Step 2 item 6) reads `docs/reference/trackers.md` State Transition Syntax table to compose Redmine state transitions — if the format changes, the wizard auto-generates the updated format for new projects with no code change needed beyond the table.
- **Both Redmine config templates** use `status:{name}` format; `redmine-oracle-plsql.md` already has a TODO comment for status verification, `redmine-rails.md` does not.
- **`skills/migrate-config/SKILL.md`** has deprecated-pattern detection but currently covers only bullet-point format and missing `Type` key — no Redmine status format detection.

---

## Category A: Redmine Status Call Sites

### A1: What exact MCP call does `core/block-handler.md` make to set the Blocked state, and does it pass the raw config string or perform any resolution?

**Files to read:** `core/block-handler.md` (Step 2)

**What to confirm:** Whether Step 2 passes `state_transitions.Blocked` verbatim to the MCP tool with no name-to-ID translation — establishing block-handler as a call site requiring the fix.

---

### A2: Do `fix-ticket/SKILL.md` Step 1 and `implement-feature/SKILL.md` Step 1 contain any tracker-type branching when setting on_start_set state, or do both pass the raw config string?

**Files to read:** `skills/fix-ticket/SKILL.md` (Step 1), `skills/implement-feature/SKILL.md` (Step 1)

**What to confirm:** Whether either skill branches on `Issue Tracker → Type` before the MCP call, or whether both pass the raw `on_start_set` value directly — establishing whether a shared-layer fix covers both, or each needs individual changes.

---

### A3: Does `core/fix-verification.md` Step 6 set issue state when re-opening, and does it do any Redmine-specific handling?

**Files to read:** `core/fix-verification.md` (Step 6)

**What to confirm:** Whether the re-open state-set call is a fifth distinct call site requiring the fix, and what key name it reads from `State transitions`.

---

### A4: Does `skills/fix-bugs/SKILL.md` contain its own per-issue status-setting step, or does it delegate to `fix-ticket` via a Task call?

**Files to read:** `skills/fix-bugs/SKILL.md` (Steps 1–3, per-issue status-set logic), `skills/fix-ticket/SKILL.md` (Step 1)

**What to confirm:** Whether fix-bugs has a duplicated "Set issue tracker" step (requiring an independent fix) or delegates to fix-ticket (meaning a single fix covers both entry points).

---

### A5: What does `docs/reference/trackers.md` specify as the Redmine state transition format, the LLM-translation contract, and the Validation Rules for the `status:` prefix?

**Files to read:** `docs/reference/trackers.md` (State Transition Syntax table, Redmine note, Validation Rules table)

**What to confirm:** The exact documented format (`status:{name}`), the "LLM convention" note text, and whether any alternative ID-based format (`status_id:{id}`) is already mentioned — establishing the baseline that must change in the fix.

---

## Category B: Config Parsing & Format

### B1: How does `core/config-reader.md` parse `state_transitions` — does it produce a verbatim key→value map, and is there any tracker-type-specific normalization step?

**Files to read:** `core/config-reader.md` (Step 2, Issue Tracker section)

**What to confirm:** Whether config-reader is a viable injection point for a centralized name-to-ID translation fix (i.e., could it normalize Redmine values at parse time), or whether the verbatim passthrough makes all call sites individually responsible.

---

### B2: Do both Redmine config templates use `status:{name}` format, and does `redmine-oracle-plsql.md` already have a TODO comment that `redmine-rails.md` lacks?

**Files to read:** `examples/configs/redmine-oracle-plsql.md` (lines 14–17), `examples/configs/redmine-rails.md` (lines 14–15)

**What to confirm:** Exact current text of State transitions and On start set fields in both templates, and whether the TODO comment for status verification is present in one but missing from the other — to define the minimal diff for template updates.

---

## Category C: Publisher & Newline Handling

### C1: Does `agents/publisher.md` Step 6 give any explicit encoding instruction for passing the multi-line PR Description Template `body` to the MCP `create_pull_request` tool?

**Files to read:** `agents/publisher.md` (Step 6, Constraints section)

**What to confirm:** Whether the agent prompt specifies how to pass multi-line text to the MCP tool (e.g., real newlines, heredoc, file-based), or leaves encoding up to the LLM — establishing whether the fix is a prompt addition or requires a structural change.

---

### C2: Does `agents/publisher.md` Step 7 post a single-line PR link comment or a multi-line markdown block, and does the Constraints section give encoding guidance for the Block Comment Template it must post when blocking?

**Files to read:** `agents/publisher.md` (Step 7, Constraints section lines 95–103)

**What to confirm:** Whether Step 7's comment is short enough to be safe from the `\n` bug, and whether the Block Comment Template in the Constraints section has encoding guidance — establishing both as potential fix targets.

---

### C3: Do the subtask issue description templates in `fix-ticket/SKILL.md` Step 4b-tracker and `implement-feature/SKILL.md` Step 5a provide encoding guidance for the multi-line `body` passed to `create_issue`?

**Files to read:** `skills/fix-ticket/SKILL.md` (Step 4b-tracker, Issue Description Template), `skills/implement-feature/SKILL.md` (Step 5a, Issue Description Template)

**What to confirm:** Whether these two call sites use the same unguarded inline-string pattern as the publisher PR body — establishing them as additional fix targets for the newline bug.

---

### C4: Does `core/block-handler.md` Steps 3–4 give any newline encoding guidance for the block comment posted via MCP `add_comment`, and does `core/post-publish-hook.md` use a heredoc pattern that could serve as a model?

**Files to read:** `core/block-handler.md` (Steps 3–5), `core/post-publish-hook.md`

**What to confirm:** Whether block-handler is a third MCP comment call site vulnerable to `\n` literal rendering, and whether the post-publish-hook heredoc pattern already established in the repo provides a reusable fix template.

---

## Category D: Onboard & Templates

### D1: Does `skills/onboard/SKILL.md` Step 2 item 6 read `docs/reference/trackers.md` State Transition Syntax table to generate Redmine state transitions — and does the wizard's "do not validate" rule (Rules section) prohibit calling the Redmine MCP during the wizard to dynamically resolve status IDs?

**Files to read:** `skills/onboard/SKILL.md` (Step 2 items 5–7; Rules section), `docs/reference/trackers.md` (State Transition Syntax table, Redmine row)

**What to confirm:** (a) Whether changing the trackers.md table alone is sufficient to make the wizard emit the new format for new projects, and (b) whether the wizard's design rules allow or prohibit a live `GET /issue_statuses.json` MCP call during onboarding — determining whether the fix is a doc-only change or requires a wizard code change.

---

## Category E: Verification Protocol

### E1: Is there any existing pattern in `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, or any agent where a tracker state-set is followed by a read-back verification call — and what is the established WARN vs. BLOCK policy for failed verification?

**Files to read:** `skills/fix-ticket/SKILL.md` (Step 1), `skills/fix-bugs/SKILL.md` (Steps 1–3), `agents/publisher.md`

**What to confirm:** Whether any precedent for post-set verification exists (to follow the same pattern), or whether the v6.5.2 fix would establish a new pattern — and whether a failed `redmine_get_issue` read-back should block the pipeline or only emit a WARN comment.

---

## Category F: Backward Compatibility

### F1: Does `skills/migrate-config/SKILL.md` Step 3 have a deprecated-pattern rule for Redmine `status:{name}` format, and is a new detection rule needed or only a doc-level advisory?

**Files to read:** `skills/migrate-config/SKILL.md` (Step 3, deprecated patterns section)

**What to confirm:** The current scope of migrate-config's deprecated-pattern detection, and whether adding a Redmine-specific rule is warranted (active migration offer) or whether the fix should only update `docs/reference/trackers.md` with a deprecation note — establishing the backward-compatibility scope of v6.5.2.

---

*End of synthesized research questions. Total: 15 questions across 6 categories, covering all call sites from all 3 agents with no duplicates.*
