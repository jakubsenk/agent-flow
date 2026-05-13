# Agent 3 Research Questions — Onboard Wizard, Config Templates, Backward Compatibility, Cross-Cutting

## Scope
Onboard wizard behavior for Redmine state transitions, config template current formats, backward compatibility of format changes, post-update verification pattern, and fix-bugs delegation model.

---

## Q3-1: Onboard Wizard — Redmine State Transition Generation

**File:** `skills/onboard/SKILL.md` (Step 2, item 6), `docs/reference/trackers.md` (State Transition Syntax table)

In `skills/onboard/SKILL.md` Step 2 item 6, the wizard reads `{trackers_md_path}` State Transition Syntax table and composes the full State transitions value using comma separator. The `docs/reference/trackers.md` State Transition Syntax table currently shows Redmine format as `status:{name}` (e.g., `status:In Progress`).

**Question:** If the v6.5.2 fix adopts `status_id:XX` as the new preferred format for Redmine state transitions (replacing the name-based `status:{name}`), what exactly needs to change in `docs/reference/trackers.md` to make the onboard wizard generate the correct format for new Redmine projects? Would the trackers.md State Transition Syntax table format cell need to change from `status:{name}` to `status_id:{id}`, and if so, how does the wizard handle the fact that the ID is instance-specific (not a static default)?

**Files to read:** `docs/reference/trackers.md` (State Transition Syntax table, rows 25-29), `skills/onboard/SKILL.md` (Step 2, items 5-7, lines 85-87)

---

## Q3-2: Config Templates — Current Redmine State Transition Format and TODO Pattern

**Files:** `examples/configs/redmine-oracle-plsql.md`, `examples/configs/redmine-rails.md`

Both Redmine config templates currently use `status:{name}` format in the State transitions and On start set fields (e.g., `status:In Progress`, `status:Blocked`, `status:Closed`). The oracle-plsql template includes a TODO comment `<!-- TODO: Verify status names match your Redmine workflow (GET /issue_statuses.json) -->`, while the rails template has no such comment.

**Question:** Given that the TODO pattern already exists in redmine-oracle-plsql.md but not in redmine-rails.md, and both templates use name-based format, what is the minimal set of changes to both templates to reflect the v6.5.2 fix? Specifically: should the templates switch to `status_id:XX` with placeholder numeric IDs (e.g., `status_id:2`), or keep `status:{name}` as a human-readable default with an updated TODO, and should the rails template receive the same TODO comment as the oracle-plsql template for consistency?

**Files to read:** `examples/configs/redmine-oracle-plsql.md` (lines 14-17), `examples/configs/redmine-rails.md` (lines 14-15)

---

## Q3-3: Backward Compatibility — Migration Path for Existing status:{name} Configs

**Files:** `skills/migrate-config/SKILL.md`, `docs/reference/trackers.md`

The `skills/migrate-config/SKILL.md` skill detects config versions heuristically based on presence of sections (Pipeline Profiles, Metrics, etc.) and offers to add missing optional sections. Its "deprecated patterns" detection (Step 3) currently only covers bullet-point format and missing `Type` key — it does NOT check for Redmine-specific state transition format changes.

**Question:** If v6.5.2 changes the recommended Redmine State transitions format from `status:{name}` to `status_id:{id}`, does `skills/migrate-config/SKILL.md` need a new deprecated-pattern rule to detect and offer migration for existing Redmine projects using the old format? Or is this a WARN-only advisory (since the old `status:{name}` format still works for some Redmine MCP implementations), meaning migrate-config should not be changed and only docs should note the deprecation?

**Files to read:** `skills/migrate-config/SKILL.md` (Step 3, lines 46-50), `docs/reference/trackers.md` (Validation Rules table, redmine row, lines 72-73)

---

## Q3-4: Post-Update Verification Pattern — Is redmine_get_issue Verification Used Elsewhere?

**Files:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `agents/publisher.md`

The v6.5.2 spec mentions verifying the Redmine status update via `redmine_get_issue` after setting it. In `skills/fix-ticket/SKILL.md` Step 1 ("Set issue tracker"), the skill simply calls the MCP to set state with no explicit verification step — it trusts the MCP call succeeded if no error is thrown.

**Question:** Is there any existing pattern in `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, or any agent definition where a tracker state-set is followed by a read-back verification call? What is the established WARN vs BLOCK policy for such verification failures — does a failed verification (e.g., `redmine_get_issue` returns unexpected status after update) warrant blocking the pipeline or only a WARN comment, and where in the pipeline skill should the verification step be inserted (before branch creation, or after the "On start set" call in Step 1)?

**Files to read:** `skills/fix-ticket/SKILL.md` (Step 1, lines 113-117), `skills/fix-bugs/SKILL.md` (steps 1-3, approximately lines 98-140), `agents/publisher.md`

---

## Q3-5: fix-bugs Delegation — Does fix-bugs Have Its Own Status-Setting or Delegate to fix-ticket?

**File:** `skills/fix-bugs/SKILL.md`

`skills/fix-bugs/SKILL.md` is a standalone orchestration skill with its own pipeline steps — it does NOT delegate to `fix-ticket`. It has its own Step 1 (Fetch bugs) and Step 2 (Triage) etc., with its own status-setting logic. The "On start set" is applied per-issue in fix-bugs via the same config key as fix-ticket, but the code path is duplicated in the fix-bugs skill body.

**Question:** When implementing the v6.5.2 Redmine status-setting fix (e.g., translating `status:{name}` to `status_id:{id}` via an MCP lookup, or adding post-set verification), must the fix be applied independently in BOTH `skills/fix-ticket/SKILL.md` AND `skills/fix-bugs/SKILL.md`, or does fix-bugs delegate its per-issue status setting to fix-ticket in a way that a single fix would cover both? Specifically, does fix-bugs call fix-ticket as a Task, or does it contain its own duplicate "Set issue tracker" step?

**Files to read:** `skills/fix-bugs/SKILL.md` (Step 1 fetch + per-issue status set, lines 98-130 and lines 1-100), `skills/fix-ticket/SKILL.md` (Step 1, lines 113-117)

---

## Q3-6: Onboard Wizard — MCP Call During Wizard for Dynamic status_id Resolution

**Files:** `skills/onboard/SKILL.md`, `docs/reference/trackers.md`

The onboard wizard already performs MCP-based lookups in other skills (e.g., `check-setup` calls MCP to validate connectivity). However, `skills/onboard/SKILL.md` Step 2 item 6 currently only reads static defaults from `trackers.md` — it does not call any MCP tool during the wizard session.

**Question:** Is it architecturally consistent with the onboard wizard's design (`skills/onboard/SKILL.md` Rules section, line 295-301: "Do not validate answers — validation belongs in /check-setup") to have the wizard call `GET /issue_statuses.json` via the Redmine MCP during Step 2 to dynamically resolve status names to IDs? Or does the "do not validate" rule prohibit this, meaning the wizard should only emit placeholder IDs (e.g., `status_id:2`) with a TODO comment, leaving actual ID discovery to a separate step like `/check-setup` or manual lookup?

**Files to read:** `skills/onboard/SKILL.md` (Rules section, lines 295-301; Step 2 items 5-7, lines 81-87), `docs/reference/trackers.md` (Redmine row across all tables)
