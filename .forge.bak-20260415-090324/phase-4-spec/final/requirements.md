# v6.5.2 Requirements — Redmine + Publisher Fixes

**Version:** v6.5.2 (PATCH)
**Source:** Brainstorm synthesis (`.forge/phase-3-brainstorm/final.md`), Research findings (`.forge/phase-2-research-answers/final.md`)
**Date:** 2026-04-15

---

## Overview

Two confirmed pipeline bugs found during real-world Redmine usage (drmax-readmine-test project, 2026-04-13):

- **Bug 1:** Redmine status transitions fail silently because config uses text names (`status:In Progress`) but Redmine MCP tool requires numeric `status_id`.
- **Bug 2:** Publisher agent passes PR body with escaped `\n` sequences instead of real newlines, rendering them literally in PR descriptions.

Total files: 15 (11 edits + 2 new files + roadmap + CLAUDE.md count update).

---

## REQ-1: trackers.md Format Change

**File:** `docs/reference/trackers.md`
**AC coverage:** AC1, AC2, AC5

### REQ-1.1: State Transition Syntax Table — Redmine Row

**Section:** `## State Transition Syntax` table
**Change type:** MODIFY

Replace the existing Redmine row:

```
| redmine | `status:{name}` | `status:In Progress` | `status:Closed` |
```

With:

```
| redmine | `status_id:{id}` | `status_id:2` | `status_id:5` |
```

### REQ-1.2: State Transition Syntax — Redmine Note

**Section:** Blockquote note after the State Transition Syntax table
**Change type:** REPLACE

Replace the existing note:

```
> **Redmine note:** The `status:{name}` format is an LLM convention. The LLM translates this to the appropriate Redmine API call (e.g., `status_id=2` for "In Progress"). Status name-to-ID mapping depends on the Redmine instance configuration.
```

With:

```
> **Redmine note:** The `status_id:{id}` format uses the numeric ID from your Redmine instance. Common defaults: 1=New, 2=In Progress, 3=Resolved, 4=Feedback, 5=Closed, 6=Rejected. Verify your instance's IDs via `GET /issue_statuses.json`. The legacy `status:{name}` format (e.g., `status:In Progress`) is accepted but unreliable — it depends on LLM translation at runtime, which may fail silently. Use `status_id:{id}` for deterministic behavior.
```

### REQ-1.3: On Start Set Defaults Table — Redmine Row

**Section:** `## On Start Set Defaults` table
**Change type:** MODIFY

Replace:

```
| redmine | `status:In Progress` |
```

With:

```
| redmine | `status_id:2` |
```

### REQ-1.4: Validation Rules Table — Redmine Row

**Section:** `## Validation Rules` table
**Change type:** MODIFY

Replace the Redmine row's "State transition format" column:

```
| redmine | Must contain `project_id=` | `status:{name}` | Any URL |
```

With:

```
| redmine | Must contain `project_id=` | `status_id:{id}` or `status:{name}` (legacy) | Any URL |
```

---

## REQ-2: Onboard Wizard — Redmine ID Collection

**File:** `skills/onboard/SKILL.md`
**AC coverage:** AC5

### REQ-2.1: Redmine-Specific Sub-Step After Step 2 Item 6

**Section:** Fresh Mode → Step 2: Issue Tracker, after item 6 (State transitions) and before item 7 (On start set)
**Change type:** ADD

Insert a new conditional sub-step between items 6 and 7:

```markdown
6a. **Redmine status ID guidance** (only when tracker type is `redmine`):
   Display:
   ```
   Redmine requires numeric status IDs. Common defaults:
   1=New, 2=In Progress, 3=Resolved, 4=Feedback, 5=Closed, 6=Rejected

   To find your instance's IDs, run in a separate terminal:
   curl -s -H "X-Redmine-API-Key: YOUR_KEY" https://YOUR-INSTANCE/issue_statuses.json | python -m json.tool

   Enter your status IDs (or press Enter for defaults):
   - In Progress ID [2]:
   - Blocked ID (or custom status) [leave empty to use default "Feedback" ID 4]:
   - For Review ID (or custom status) [leave empty to use default "Feedback" ID 4]:
   - Done/Closed ID [5]:
   ```
   Use the provided IDs (or defaults) when composing the State transitions value in `status_id:{id}` format.
   If the user skips (presses Enter for all): use the defaults from trackers.md.
```

---

## REQ-3: migrate-config — Deprecated Pattern Rule

**File:** `skills/migrate-config/SKILL.md`
**AC coverage:** AC2

### REQ-3.1: New Deprecated Pattern in Step 3

**Section:** `### 3. Check for deprecated patterns`
**Change type:** ADD (new bullet)

After the existing two deprecated patterns, add:

```markdown
- Redmine state transitions using `status:{name}` format (pre-v6.5.2) → offer interactive conversion to `status_id:{id}` format:
  ```
  Detected Redmine state transition in legacy format: "status:{name}"
  This format is unreliable — Redmine MCP tools require numeric status_id.

  To convert, provide your Redmine status IDs:
  - In Progress ID [2]:
  - Blocked ID [4]:
  - For Review ID [4]:
  - Done/Closed ID [5]:

  Press Enter to skip (keep legacy format with WARN).
  ```
  If user provides IDs → rewrite each `status:{name}` to `status_id:{id}` in both State transitions and On start set.
  If user skips → leave unchanged, log `[WARN] Redmine legacy status format retained — pipeline may fail silently on status transitions`.
```

### REQ-3.2: Migration Report — Deprecated Patterns Table

**Section:** `### 4. Generate migration report` → Deprecated Patterns Found table
**Change type:** ADD (new row example)

Add to the example table:

```
| Redmine `status:{name}` format | Convert to `status_id:{id}` (interactive) |
```

---

## REQ-4: check-setup — Legacy Format WARN

**File:** `skills/check-setup/SKILL.md`
**AC coverage:** AC2

### REQ-4.1: WARN Emission in Per-Tracker Validation

**Section:** `### 3a. Per-tracker validation`, after the existing validation bullets
**Change type:** ADD

Insert a new bullet after "Apply the state transition format check to the State transitions value":

```markdown
- **Redmine legacy format check:** If Type is `redmine` and any State transitions value matches `status:{name}` (without `status_id:`), emit: `[WARN] Redmine state transition uses legacy text format (status:{name}). Recommend converting to status_id:{id} format — run /ceos-agents:migrate-config or edit manually. See trackers.md Redmine note for ID lookup instructions.`
```

---

## REQ-5: Redmine Config Templates

**AC coverage:** AC1, AC5

### REQ-5.1: redmine-oracle-plsql.md

**File:** `examples/configs/redmine-oracle-plsql.md`
**Change type:** MODIFY

Replace in Issue Tracker section:

```
| State transitions | In Progress: `status:In Progress`, Blocked: `status:Blocked`, For Review: `status:For Review`, Done: `status:Closed` |
| On start set | `status:In Progress` |
```

With:

```
| State transitions | In Progress: `status_id:2`, Blocked: `status_id:4`, For Review: `status_id:4`, Done: `status_id:5` |
| On start set | `status_id:2` |
```

Replace the existing TODO comments below the Issue Tracker table:

```
<!-- TODO: Verify status names match your Redmine workflow (GET /issue_statuses.json) -->
```

With:

```
<!-- TODO: Verify status IDs match your Redmine instance (GET /issue_statuses.json). Common defaults: 1=New, 2=In Progress, 3=Resolved, 4=Feedback, 5=Closed, 6=Rejected. Your instance may differ. -->
```

Also update the commented-out Feature Workflow section:

```
| On start set | `status:In Progress` |
```

With:

```
| On start set | `status_id:2` |
```

### REQ-5.2: redmine-rails.md

**File:** `examples/configs/redmine-rails.md`
**Change type:** MODIFY

Replace in Issue Tracker section:

```
| State transitions | In Progress: `status:In Progress`, Blocked: `status:Blocked`, For Review: `status:For Review`, Done: `status:Closed` |
| On start set | `status:In Progress` |
```

With:

```
| State transitions | In Progress: `status_id:2`, Blocked: `status_id:4`, For Review: `status_id:4`, Done: `status_id:5` |
| On start set | `status_id:2` |
```

Add a TODO comment after the Issue Tracker table (currently missing):

```
<!-- TODO: Verify status IDs match your Redmine instance (GET /issue_statuses.json). Common defaults: 1=New, 2=In Progress, 3=Resolved, 4=Feedback, 5=Closed, 6=Rejected. Your instance may differ. -->
<!-- TODO: Verify tracker_id corresponds to "Bug" tracker (GET /projects/<id>/trackers.json) -->
```

---

## REQ-6: New Core Contract — status-verification.md

**File:** `core/status-verification.md` (NEW)
**AC coverage:** AC3, AC4

### REQ-6.1: Create Advisory Verification Contract

**Change type:** CREATE

See `design.md` for full content specification. Summary:
- Advisory post-update verification: after any status-set MCP call, read back the issue and compare status to expected value.
- WARN on mismatch, NEVER block.
- Handles all failure modes (network error, timeout, permission error, caching delay) with WARN.
- Universal — works for all tracker types, not just Redmine.

---

## REQ-7: Publisher — Newline Constraint + Verification Wiring

**File:** `agents/publisher.md`
**AC coverage:** AC3, AC4, AC6

### REQ-7.1: Newline NEVER Constraint

**Section:** `## Constraints`
**Change type:** ADD (new constraint bullet)

Add after the existing "NEVER include 'Generated with Claude Code' footer" constraint:

```markdown
- NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always use actual line breaks (real newlines) in the string. The MCP tool receives the parameter value as-is — escaped sequences are rendered literally, not as newlines.
```

### REQ-7.2: Newline Reinforcement in Step 6

**Section:** `## Process` → Step 6 (Create Pull Request) → Description bullet
**Change type:** ADD (inline note)

After the line:

```
- **Description:** Use PR Description Template from Automation Config (always English). Fill in ALL template sections:
```

Add:

```
  Use real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

### REQ-7.3: Verification Wiring in Step 7

**Section:** `## Process` → Step 7 (Update Issue Tracker)
**Change type:** ADD

After the existing Step 7 content:

```
   - Set issue state: "For Review" (or equivalent from Automation Config → State transitions)
- Add comment to issue with PR link
```

Add:

```
- After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
```

---

## REQ-8: Block Handler — Newline Instruction + Verification Wiring

**File:** `core/block-handler.md`
**AC coverage:** AC3, AC4, AC7

### REQ-8.1: Newline Instruction in Step 4

**Section:** `## Process` → Step 4 (Post block comment)
**Change type:** ADD

After the block comment template in Step 4, add:

```
   When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators.
```

### REQ-8.2: Verification Wiring in Step 2

**Section:** `## Process` → Step 2 (Set issue state)
**Change type:** MODIFY

Replace:

```
2. **Set issue state:** Transition the issue to the Blocked state (from config → State transitions → Blocked) via the issue tracker MCP server.
```

With:

```
2. **Set issue state:** Transition the issue to the Blocked state (from config → State transitions → Blocked) via the issue tracker MCP server. After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
```

---

## REQ-9: fix-ticket — Newline Instruction + Verification Wiring

**File:** `skills/fix-ticket/SKILL.md`
**AC coverage:** AC3, AC4, AC6

### REQ-9.1: Newline Instruction After Subtask Description Template

**Section:** Step 4b-tracker → Issue Description Template (after the template and its bullets)
**Change type:** ADD

After the line `- The "Parent issue:" line is always present.` (line ~383), add:

```markdown
When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

### REQ-9.2: Verification Wiring in Step 1

**Section:** `### 1. Set issue tracker`
**Change type:** MODIFY

Replace:

```
Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server.
```

With:

```
Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server. After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
```

---

## REQ-10: implement-feature — Newline Instruction

**File:** `skills/implement-feature/SKILL.md`
**AC coverage:** AC6

### REQ-10.1: Newline Instruction After Subtask Description Template

**Section:** Step 5a → Issue Description Template (after the template and its bullets)
**Change type:** ADD

After the line `- The "Parent issue:" line is always present.` (line ~429), add:

```markdown
When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

---

## REQ-11: fix-bugs — Newline Instruction

**File:** `skills/fix-bugs/SKILL.md`
**AC coverage:** AC7

### REQ-11.1: Newline Instruction After Inline Block Comment Template

**Section:** Step X (Block handler) → Step 4 (Add Block comment), after the block comment template
**Change type:** ADD

After the block comment template in Step X item 4 (around line 657), add:

```markdown
   When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators.
```

### REQ-11.2: Newline Instruction After Subtask Description Template

**Section:** Step 3b-tracker → Issue Description Template (after the template and its bullets)
**Change type:** ADD

After the line `- The "Parent issue:" line is always present.` (around line 371), add:

```markdown
When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

---

## REQ-12: Test Scenario — MCP Newline Handling

**File:** `tests/scenarios/mcp-newline-handling.sh` (NEW)
**AC coverage:** AC6, AC7

### REQ-12.1: Create Regression Test

**Change type:** CREATE

Shell script that asserts all 5 vulnerable files contain the newline instruction marker text. See `design.md` for exact assertion list.

The test must:
1. Check each of the 5 files for the presence of `NEVER use the literal characters` marker text.
2. Exit with FAIL if any file is missing the instruction.
3. Follow the existing test harness conventions (set -euo pipefail, FAIL counter, PASS/FAIL output).

---

## REQ-13: Roadmap Update

**File:** `docs/plans/roadmap.md`
**AC coverage:** AC8

### REQ-13.1: Move v6.5.2 Section to DONE

**Change type:** MODIFY

Move the `## PLANNED — v6.5.2 (Redmine + Publisher Fixes)` section into the DONE section area (after `## DONE — v6.5.1`), renaming it to `## DONE — v6.5.2 (Redmine + Publisher Fixes)`.

Update the content to reflect what was actually implemented (not what was originally planned). Include:
- Files changed (all 15)
- Reference to the new `core/status-verification.md` contract
- Note about deferred items

### REQ-13.2: Add Deferred Items to v6.6.0

**Change type:** MODIFY

Add the following items to the existing `## PLANNED — v6.6.0 (Pipeline Hardening)` section:

```markdown
### Status Verification — Remaining Call Sites
**Source:** v6.5.2 deferred scope (2026-04-15)
Wire `core/status-verification.md` into the remaining 4 status-set call sites:
- `skills/implement-feature/SKILL.md` Step 1 (On start set)
- `core/fix-verification.md` Step 6 (re-open on verify failure)
- `skills/fix-bugs/SKILL.md` Step X item 2 (block handler inline)
- `skills/scaffold/SKILL.md` Step 8b (if applicable)
**Files:** 4. **Impact:** PATCH.

### MCP Body Formatting Contract
**Source:** v6.5.2 deferred scope (2026-04-15) — Agent 2 brainstorm proposal
Centralize per-site newline instructions into a single `core/mcp-body-formatting.md` contract. Replace the 5 per-site `NEVER use literal \n` instructions with a single core contract reference.
**Files:** new `core/mcp-body-formatting.md`, 5 files updated. **Impact:** PATCH.

### fix-bugs "On start set" Step
**Source:** v6.5.2 deferred scope (2026-04-15)
fix-bugs has no "On start set" step — bugs processed via `/fix-bugs` never get their tracker state set to In Progress. This is a pre-existing functional gap independent of the format bug.
**Files:** `skills/fix-bugs/SKILL.md`. **Impact:** MINOR (new feature).
```

### REQ-13.3: Add NOT PLANNED Items

**Change type:** ADD

Add to the `## NOT PLANNED` section (create if it does not exist):

```markdown
### config-reader Redmine Normalization
**Source:** v6.5.2 research (2026-04-15), brainstorm Agent 2 proposal
Extend `core/config-reader.md` to detect Redmine type and resolve `status:{name}` to `status_id:{id}` at parse time. Rejected: requires MCP access during config-reader execution, which is not in its contract. The format change in trackers.md (v6.5.2) makes this unnecessary — IDs are baked into config at setup time.

### Onboard Wizard MCP Access
**Source:** v6.5.2 research (2026-04-15), brainstorm Agent 2 proposal
Expand `allowed-tools` in onboard wizard to include `mcp__*` for live status lookup during Redmine setup. Rejected: allowed-tools expansion is a deliberate design choice beyond PATCH scope. The interactive ID collection approach (v6.5.2) achieves the same goal without MCP access.
```

---

## REQ-14: CLAUDE.md Core Count Update

**File:** `CLAUDE.md`
**AC coverage:** AC8 (implicit)

### REQ-14.1: Update Core Count

**Section:** Repository Structure bullet list
**Change type:** MODIFY

Replace:

```
- `core/` — 11 shared pipeline pattern contracts
```

With:

```
- `core/` — 12 shared pipeline pattern contracts
```

---

## REQ-15: Roadmap Header Update

**File:** `docs/plans/roadmap.md`
**AC coverage:** AC8

### REQ-15.1: Update Current Version

**Section:** Header block
**Change type:** MODIFY

Replace:

```
> **Current version:** v6.5.1
```

With:

```
> **Current version:** v6.5.2
```

---

## Summary — File Change Matrix

| # | File | Change Type | Bug | ACs |
|---|------|-------------|-----|-----|
| 1 | `docs/reference/trackers.md` | MODIFY (4 locations) | 1 | AC1, AC2, AC5 |
| 2 | `skills/onboard/SKILL.md` | ADD (1 sub-step) | 1 | AC5 |
| 3 | `skills/migrate-config/SKILL.md` | ADD (1 rule + 1 table row) | 1 | AC2 |
| 4 | `skills/check-setup/SKILL.md` | ADD (1 bullet) | 1 | AC2 |
| 5 | `examples/configs/redmine-oracle-plsql.md` | MODIFY (3 locations) | 1 | AC1, AC5 |
| 6 | `examples/configs/redmine-rails.md` | MODIFY (2 locations) + ADD (TODOs) | 1 | AC1, AC5 |
| 7 | `core/status-verification.md` | CREATE | 1 | AC3, AC4 |
| 8 | `agents/publisher.md` | ADD (3 locations) | 1+2 | AC3, AC4, AC6 |
| 9 | `core/block-handler.md` | ADD (1) + MODIFY (1) | 1+2 | AC3, AC4, AC7 |
| 10 | `skills/fix-ticket/SKILL.md` | ADD (1) + MODIFY (1) | 1+2 | AC3, AC4, AC6 |
| 11 | `skills/implement-feature/SKILL.md` | ADD (1) | 2 | AC6 |
| 12 | `skills/fix-bugs/SKILL.md` | ADD (2) | 2 | AC7 |
| 13 | `tests/scenarios/mcp-newline-handling.sh` | CREATE | 2 | AC6, AC7 |
| 14 | `docs/plans/roadmap.md` | MODIFY (3 locations) | — | AC8 |
| 15 | `CLAUDE.md` | MODIFY (1 location) | — | AC8 |
