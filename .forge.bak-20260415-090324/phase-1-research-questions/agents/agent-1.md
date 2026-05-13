# Agent 1 Research Questions — Redmine Status Transitions & Call-Site Enumeration

**Scope:** Bug 1 (Redmine Status Transitions) + first-half call-site enumeration
**Date:** 2026-04-15

---

## Q1: What exact call-site pattern does `block-handler.md` use to set issue state, and does it pass a raw config value or resolve it first?

**Files to read:** `core/block-handler.md` (step 2)

**What to answer:** Step 2 of block-handler says "Transition the issue to the Blocked state (from config → State transitions → Blocked) via the issue tracker MCP server." It does NOT show any resolution logic — it consumes the raw config string directly. For Redmine, `state_transitions.Blocked` would contain a value like `status:Blocked`. The question is: does block-handler do any name-to-ID translation, or does it pass the raw `status:{name}` string directly to the MCP tool? If it passes it raw, the MCP server must interpret the name — which is the bug.

---

## Q2: What does `fix-ticket/SKILL.md` Step 1 actually do when setting issue state, and is there any tracker-type branching?

**Files to read:** `skills/fix-ticket/SKILL.md` (Step 1: "Set issue tracker")

**What to answer:** Step 1 says "Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server." There is no per-tracker branching shown — it passes the raw `on_start_set` value string directly to the MCP tool. For Redmine, `on_start_set` is documented as `status:In Progress` (see `docs/reference/trackers.md` On Start Set Defaults table). The question is whether the skill has any intermediate translation step between reading the config string and calling the MCP tool, or whether the raw string is used verbatim as a tool parameter.

---

## Q3: How does `config-reader.md` parse `state_transitions` — is it a key→value map, and what key names does it produce?

**Files to read:** `core/config-reader.md` (step 2, `### Issue Tracker` row)

**What to answer:** Config-reader documents `issue_tracker.state_transitions` as a "key→value map". The keys are the transition names (e.g., `In Progress`, `Blocked`, `Done`) and the values are the tracker-specific format strings (e.g., `status:In Progress` for Redmine). There is no tracker-type-specific parsing — the config object stores these verbatim. This confirms that whatever the user wrote in their CLAUDE.md `State transitions` table row is passed through unchanged to the call sites. For Redmine this means `status:{name}` strings reach the MCP tool unmodified.

---

## Q4: What does `docs/reference/trackers.md` document as the Redmine state transition format, and what does it say about LLM translation?

**Files to read:** `docs/reference/trackers.md` (State Transition Syntax table + Redmine note, Validation Rules table)

**What to answer:** The State Transition Syntax table documents Redmine format as `status:{name}` with example `status:In Progress`. The Redmine note immediately below says: "The `status:{name}` format is an LLM convention. The LLM translates this to the appropriate Redmine API call (e.g., `status_id=2` for 'In Progress'). Status name-to-ID mapping depends on the Redmine instance configuration." The Validation Rules table confirms the format must match `status:{name}`. This is the root of the bug: the format relies on LLM translation, which is not guaranteed — the MCP tool `redmine_update_issue` expects a numeric `status_id`, not a name string.

---

## Q5: What call sites in `fix-ticket/SKILL.md` and `implement-feature/SKILL.md` set issue state, and do any of them perform tracker-type branching?

**Files to read:** `skills/fix-ticket/SKILL.md` (Step 1 and Step 9), `skills/implement-feature/SKILL.md` (Step 1 and Step 10)

**What to answer:**

- `fix-ticket` Step 1: sets state via `Issue Tracker → On start set` — no branching, raw value passed.
- `fix-ticket` Step 9: dispatches `publisher` agent with `Type` context — publisher handles final state changes (PR creation), not a direct status-set call.
- `implement-feature` Step 1: sets state via `Feature Workflow → On start set` (fallback: `Issue Tracker → On start set`) — no branching, raw value passed.
- `implement-feature` Step 10: dispatches `publisher` agent — same as fix-ticket Step 9.

Neither skill has tracker-type branching at status-set call sites. All status transitions use the verbatim config string. This means a fix must be applied at a shared layer (config-reader normalization or a new resolution helper called by all skills), not at each individual call site.

---

## Q6: Does `fix-verification.md` set issue state when re-opening, and does it do any Redmine-specific handling?

**Files to read:** `core/fix-verification.md` (step 6)

**What to answer:** Step 6 says: "If State transitions contains a re-open key → set the issue state back." It reads the raw `State transitions` config key (whatever key name the user chose for re-open — there is no standardized key name enforced here) and passes it directly to the MCP server. No Redmine-specific handling exists. This is a fifth call site (after fix-ticket Step 1, block-handler Step 2, implement-feature Step 1, and publisher) that has the same raw-string-passthrough problem for Redmine. The fix must cover this site too.
