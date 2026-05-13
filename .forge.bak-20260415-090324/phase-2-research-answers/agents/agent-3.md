# Agent-3 Research Answers: Categories D, E, F + fix-bugs Deep Dive

**Researcher:** Agent-3 (Senior DevOps Integration Engineer)
**Files read:** skills/onboard/SKILL.md, docs/reference/trackers.md, skills/fix-ticket/SKILL.md, skills/fix-bugs/SKILL.md, agents/publisher.md, skills/migrate-config/SKILL.md

---

## D1: Onboard Wizard — trackers.md authority, MCP prohibition, format generation

### (a) Is trackers.md the ONLY source the wizard reads for state transitions?

**Answer: YES — trackers.md is the single authoritative source for state transition defaults in the wizard.**

`skills/onboard/SKILL.md` lines 85–86:

> 5. **Feature query** — "Do you also want to configure a feature query for `/implement-feature`?"
>    ...
> 6. State transitions — read defaults from `{trackers_md_path}` State Transition Syntax table. Compose the full value using comma separator: `In Progress: {format}, Blocked: {format}, For Review: {format}, Done: {format}`
> 7. On start set — read defaults from `{trackers_md_path}` On Start Set Defaults table

The wizard resolves `{trackers_md_path}` using a 3-step Glob fallback (lines 71–76):
1. `.claude/plugins/**/docs/reference/trackers.md` (prefer path containing `.claude/plugins/` or `ceos-agents/`)
2. `**/docs/reference/trackers.md`
3. `docs/reference/trackers.md` as last resort

If not found at all: "use built-in defaults from knowledge" — so in that degenerate case, the LLM's baked-in knowledge is the fallback, not any other file. No other file is consulted for state transition defaults during the wizard.

**Conclusion:** Changing `trackers.md` alone IS sufficient to change the wizard's emitted defaults for state transitions and On Start Set, provided the wizard is run after the change. All lookups for steps 6 and 7 point exclusively to `trackers.md`.

### (b) Does the Rules section's "Do not validate answers" prohibit live MCP calls during the wizard?

**Answer: The rule prohibits VALIDATION, not all MCP calls — but the wizard's allowed-tools list effectively prevents any MCP calls.**

`skills/onboard/SKILL.md` line 295:
> - Do not validate answers — validation belongs in `/check-setup`

The frontmatter (line 4) declares:
```
allowed-tools: Read, Glob, Write, Edit
```

MCP tools (`mcp__*`) are NOT in the allowed-tools list. This is a hard constraint enforced by the Claude Code harness — the wizard cannot call MCP tools regardless of what the Rules section says. The "do not validate" rule is conceptually aligned with this, but the allowed-tools restriction is the operative technical constraint.

**Conclusion:** The wizard cannot and does not make live MCP calls. The "do not validate" rule is a design principle that matches the capability restriction. Adding live MCP calls to the wizard would require both a Rules change AND an allowed-tools amendment in the frontmatter.

### (c) What would need to change to generate `status_id:XX` format?

Currently, `docs/reference/trackers.md` State Transition Syntax table (lines 26–29) shows for Redmine:

> | redmine | `status:{name}` | `status:In Progress` | `status:Closed` |
>
> **Redmine note:** The `status:{name}` format is an LLM convention. The LLM translates this to the appropriate Redmine API call (e.g., `status_id=2` for "In Progress"). Status name-to-ID mapping depends on the Redmine instance configuration.

And the On Start Set Defaults table (line 51):
> | redmine | `status:In Progress` |

The Validation Rules table (lines 65–73) for Redmine validates:
> | redmine | Must contain `project_id=` | `status:{name}` | Any URL |

**Three changes would be required to generate `status_id:XX` format:**

1. **`docs/reference/trackers.md` State Transition Syntax table** (line 27): Change `status:{name}` to `status_id:{id}` — the wizard reads this for step 6 defaults.

2. **`docs/reference/trackers.md` On Start Set Defaults table** (line 51): Change `status:In Progress` to `status_id:{id}` — the wizard reads this for step 7 defaults.

3. **`docs/reference/trackers.md` Validation Rules table** (line 72): Update the "State transition format" column for redmine from `status:{name}` to `status_id:{id}` — otherwise `check-setup` would reject the new format.

Without changing the trackers.md Validation Rules row, `check-setup` would flag any `status_id:XX` value as invalid even if the wizard correctly emitted it.

The wizard itself (SKILL.md) requires no changes — it is a pure reader of trackers.md for these values.

---

## E1: Existing post-set verification pattern

### Does any skill read back after a status-set call?

**Answer: NO — there is no existing post-set verification pattern anywhere in the pipeline.**

**fix-ticket Step 1** (`skills/fix-ticket/SKILL.md` lines 113–116):

```
### 1. Set issue tracker

Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server.

*In dry-run: skip this step.*
```

This is a fire-and-forget instruction: set the state, then proceed. There is no subsequent MCP read-back, no verification of what state the issue actually landed in, no conditional retry.

**fix-bugs** has no Step 1 "Set issue tracker" step at all (see Section F of this document). State is only set in the Block Handler (line 642) and by the publisher.

**publisher.md Step 7** (lines 73–77):

```
7. **Update Issue Tracker**

   - Set issue state: "For Review" (or equivalent from Automation Config → State transitions)
- Add comment to issue with PR link
```

Again, fire-and-forget. The publisher output (Step 8, lines 80–86) reports `**Issue updated:** {issue ID} → {new state}` — but this is a text summary that the publisher writes from its own knowledge of what it tried to do, NOT from a read-back of the actual tracker state.

**Grep across all skills for read-back patterns:** No file contains language like "confirm state", "verify state", "read back", "get_issue after set", or equivalent post-set verification call.

**Conclusion:** The v6.5.2 verification protocol (if it introduces a post-set read-back to confirm the state actually changed) would be a **completely new pattern** with no precedent in the existing codebase. Every status-set in the pipeline today is fire-and-forget.

---

## F1: migrate-config Step 3 — Redmine format detection

### Current deprecated-pattern detection

`skills/migrate-config/SKILL.md` Step 3 (lines 45–49):

```markdown
### 3. Check for deprecated patterns

- Bullet-point format instead of table format → offer conversion
- Missing `Type` in Issue Tracker (pre-v1.6) → offer to add (default: youtrack)
```

**That is the complete list.** Step 3 has exactly two deprecated pattern rules:
1. Bullet-point format → convert to table format
2. Missing `Type` key in Issue Tracker section → add with default `youtrack`

There is NO detection for:
- `status:{name}` → `status_id:{id}` conversion (Redmine format)
- Any tracker-specific state transition format upgrades
- Any other format variants

### Is a new rule for `status:{name}` → `status_id:{id}` needed?

**YES — if `status_id:{id}` becomes the canonical Redmine format, a migration rule is required.**

Existing Redmine users who ran `onboard` before the format change will have `status:In Progress` in their Automation Config. After the format change:
- `check-setup` Validation Rules would reject their existing `status:{name}` values (if the Validation Rules table is updated)
- `fix-ticket` and `fix-bugs` would use `status:{name}` format for MCP calls, which would fail or produce wrong results

A new Step 3 rule is needed:
```
- Redmine state transitions in `status:{name}` format (pre-vX.Y) → offer conversion to `status_id:{id}` format
```

The Step 5 "Apply changes" logic (lines 75–80) already handles deprecated pattern conversion via the Edit tool, so the structural mechanism exists — only the detection rule and the conversion logic (requiring an ID-lookup conversation with the user) would be new.

**Migration complexity note:** Unlike the bullet-point conversion (purely syntactic), converting `status:{name}` → `status_id:{id}` requires the user to supply the numeric IDs for their specific Redmine instance, since these are instance-specific. The migration wizard would need an interactive sub-step to collect IDs for each status name found in the config.

---

## Additional: fix-bugs Status-Setting Deep Dive

### Does fix-bugs have a "Set issue tracker" step per-issue?

**Answer: NO — fix-bugs does NOT have a per-issue "Set issue tracker" step equivalent to fix-ticket Step 1.**

Comparing the pipelines:

**fix-ticket** (`skills/fix-ticket/SKILL.md` lines 113–116):
```
### 1. Set issue tracker

Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server.
```
This explicitly sets the issue state to "On start set" value at the beginning of processing.

**fix-bugs** (`skills/fix-bugs/SKILL.md` lines 98–100):
```
### 1. Fetch bugs

Use Bug query from Automation Config via the MCP server matching Type. Limit = count from $ARGUMENTS.
```
Step 1 of fix-bugs is ONLY a fetch — no state change. The pipeline proceeds directly from fetch → triage → code-analyst → fixer → ... → publisher, with no "On start set" call for each bug.

### Where does fix-bugs change tracker state?

fix-bugs changes issue tracker state in exactly TWO places:

**1. Block Handler** (lines 641–642):
```
2. **Set issue state to Blocked** (State transitions → Blocked)
```
This is in the Block Handler (Step X), triggered on fixer/reviewer/test-engineer failure.

**2. Publisher** (via `ceos-agents:publisher`): Step 8 (line 562) runs the publisher, which sets state to "For Review" (publisher.md Step 7).

### Does fix-bugs delegate to fix-ticket?

**Answer: NO — fix-bugs does NOT call fix-ticket. It has its own complete pipeline implementation.**

fix-bugs implements its own versions of every pipeline stage with the same agent calls:
- Step 2: Triage (runs `ceos-agents:triage-analyst`)
- Step 3: Code-analyst (runs `ceos-agents:code-analyst`)
- Step 4: Fixer (runs `ceos-agents:fixer`)
- Step 5: Build
- Step 6: Reviewer (runs `ceos-agents:reviewer`)
- Step 7: Test-engineer (runs `ceos-agents:test-engineer`)
- Step 8: Publisher (runs `ceos-agents:publisher`)

The parallel structure is nearly identical to fix-ticket but the step numbers differ (fix-bugs steps: 1–9, fix-ticket steps: 0–9d with different numbering).

### Critical implication for the v6.5.2 change scope

**Changes to fix-ticket do NOT automatically cover fix-bugs.** Any status-setting behavior change (e.g., adding post-set verification, or changing Redmine format from `status:{name}` to `status_id:{id}`) must be implemented independently in BOTH files:

1. `skills/fix-ticket/SKILL.md` — Step 1 (Set issue tracker) and wherever the fix is applied
2. `skills/fix-bugs/SKILL.md` — Block Handler Step X (line 642, "Set issue state to Blocked") and publisher delegation

Note that fix-bugs has no "On start set" call at all, so if the v6.5.2 change is about the initial "In Progress" state-set, fix-bugs users would not benefit from a fix-ticket-only change — because fix-bugs simply does not make that call.

---

## Summary Table

| Question | Answer |
|----------|--------|
| D1(a) trackers.md only source for wizard | YES — trackers.md is sole source for steps 6 and 7 |
| D1(b) "do not validate" prohibits MCP calls | Technically YES (allowed-tools has no mcp__*); the rule is a design principle reinforcing the capability constraint |
| D1(c) what changes for status_id:XX | 3 rows in trackers.md (State Transition Syntax, On Start Set Defaults, Validation Rules) |
| E1 post-set verification is new | YES — no read-back pattern exists anywhere; all status-sets are fire-and-forget |
| F1 migrate-config has Redmine detection | NO — Step 3 only detects bullet-point format and missing Type; new rule needed for status:{name} → status_id:{id} |
| fix-bugs delegates to fix-ticket | NO — independent implementation; changes must be duplicated |
| fix-bugs has "On start set" call | NO — fix-bugs never calls "On start set"; state changes only in Block Handler and publisher |
