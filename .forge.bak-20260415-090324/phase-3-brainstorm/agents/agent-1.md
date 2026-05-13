# Agent 1 — Conservative API Integration Proposal

**Perspective:** Backward-compatible, minimum-change, fallback-first approach. 10+ years Redmine/Gitea API maintenance experience. Every change must leave existing configs working without modification.

---

## Bug 1: Redmine Status Transitions

### 1. How config-reader.md should parse both formats

**Decision: Option A (trackers.md format change) with dual-format acceptance.**

Do NOT touch `core/config-reader.md` parsing logic at all. The config-reader's job is to produce a verbatim key-value map -- that is correct and should remain unchanged. The problem is not parsing; the problem is that the documented format (`status:{name}`) does not match what the Redmine MCP tool actually accepts (`status_id`).

**Rationale for no config-reader changes:**
- config-reader is tracker-agnostic. Adding Redmine-specific normalization violates the single-responsibility boundary.
- config-reader has no MCP access (not in its contract). Runtime name-to-ID resolution would require an architectural change -- not a PATCH.
- Every other tracker's format (`State: {name}`, `transition:{name}`, `state:{name}`, `add label:{name}`) is a string that the LLM passes directly to the MCP tool. Redmine should follow the same pattern: the config value should be directly usable by the MCP tool without LLM translation.

**The fix is upstream:** change the canonical Redmine format in `docs/reference/trackers.md` so that config values are directly usable. The config-reader passes them through unchanged -- exactly as designed.

### 2. Changes to trackers.md

**File: `docs/reference/trackers.md`**

Three tables need Redmine row updates. The new canonical format is `status_id:{id}` (numeric), with `status:{name}` documented as a legacy alias that requires LLM translation (unreliable).

**Change 1 — State Transition Syntax table (line 28):**

Current:
```
| redmine | `status:{name}` | `status:In Progress` | `status:Closed` |
```

New:
```
| redmine | `status_id:{id}` | `status_id:2` | `status_id:5` |
```

**Change 2 — The Redmine note below that table (line 29):**

Current:
```
> **Redmine note:** The `status:{name}` format is an LLM convention. The LLM translates this to the appropriate Redmine API call (e.g., `status_id=2` for "In Progress"). Status name-to-ID mapping depends on the Redmine instance configuration.
```

New:
```
> **Redmine note:** Use `status_id:{id}` format with the numeric status ID from your Redmine instance. To find your status IDs, run: `GET /issue_statuses.json` against your Redmine API. Common defaults: 1=New, 2=In Progress, 3=Resolved, 4=Feedback, 5=Closed — but these vary per instance. The legacy `status:{name}` format (e.g., `status:In Progress`) is still accepted but unreliable — it depends on the LLM correctly resolving names to IDs via the Redmine API at runtime, which may fail silently.
```

**Change 3 — On Start Set Defaults table (line 51):**

Current:
```
| redmine | `status:In Progress` |
```

New:
```
| redmine | `status_id:2` |
```

Add a note below the table (after line 52, before the next section):
```
> **Redmine note:** The default `status_id:2` assumes the standard Redmine status mapping. Verify with `GET /issue_statuses.json` and adjust if your instance uses a different ID for "In Progress".
```

**Change 4 — Validation Rules table (line 73):**

Current:
```
| redmine | Must contain `project_id=` | `status:{name}` | Any URL |
```

New:
```
| redmine | Must contain `project_id=` | `status_id:{id}` or `status:{name}` (legacy) | Any URL |
```

This is the backward-compatibility gate: check-setup accepts BOTH formats. If it finds `status:{name}`, it emits a `[WARN]` rather than a `[FAIL]`:

> `[WARN] Redmine config uses legacy status:{name} format. Recommended: switch to status_id:{id} for reliability. Run GET /issue_statuses.json to find your status IDs, then update State transitions and On start set.`

### 3. Changes to onboard wizard

**File: `skills/onboard/SKILL.md`**

The onboard wizard is a pure reader of `trackers.md`. Since we changed the tables in trackers.md, the wizard will automatically pick up the new `status_id:{id}` format for:
- State transitions (Step 2, item 6 -- reads State Transition Syntax table)
- On start set (Step 2, item 7 -- reads On Start Set Defaults table)

However, the wizard cannot look up numeric IDs via MCP (its `allowed-tools` list is `Read, Glob, Write, Edit` -- no `mcp__*`). The user must supply the numeric IDs manually.

**Add to Step 2, after item 6 (State transitions), inside the existing step flow:**

Insert a Redmine-specific sub-step after reading the State Transition Syntax table defaults:

```markdown
   If Type is `redmine`:
   - Display: "Redmine uses numeric status IDs. The defaults assume standard IDs (2=In Progress, 5=Closed, etc.)."
   - Display: "To find your instance's status IDs, run in a separate terminal: `curl -s https://<your-instance>/issue_statuses.json?key=<api-key> | jq '.issue_statuses[] | {id, name}'`"
   - Display: "Press Enter to use defaults, or type your IDs (e.g., In Progress=3, Blocked=7, For Review=4, Done=5):"
   - If user provides custom IDs → substitute into the `status_id:{id}` format
   - If user presses Enter → use defaults from trackers.md (status_id:2, etc.)
```

**Do NOT change `allowed-tools` in the frontmatter.** The wizard does not need MCP access. The user does the lookup in a separate terminal. This keeps the wizard's scope minimal and avoids introducing MCP dependency into an interactive configuration tool.

### 4. Post-update verification

**Decision: Do NOT add post-set verification at this time.**

Rationale:
- This is a PATCH version -- adding a verification protocol is a new pattern with no precedent in the codebase.
- There are 6 status-setting call sites. Adding read-back verification to each is MINOR-level scope, not PATCH.
- The root cause is a format problem, not a missing verification. Fix the format, and the MCP call succeeds reliably.
- Post-set verification could be a v6.6.0 feature (new optional `core/state-verify.md` contract).

**However**, add a single defensive instruction to the publisher agent (the most visible call site) as a low-cost safety net:

**File: `agents/publisher.md`**, Step 7 (Update Issue Tracker), add after "Set issue state":

```markdown
   - After setting the state, if the MCP tool returns an error or the response indicates failure, log a warning: "[WARN] Issue state update may have failed: {error}". Do NOT block the pipeline — the PR was already created successfully.
```

This is not post-set verification (no read-back). It is error-response handling for the MCP call itself -- a minimal safety net that does not introduce a new pattern.

### 5. fix-bugs (independent pipeline)

**File: `skills/fix-bugs/SKILL.md`**

fix-bugs has two status-setting locations:
1. **Step X, item 2 (Block handler, line 642):** Sets `State transitions -> Blocked`. This uses the config value verbatim -- same passthrough pattern as everywhere else. No code change needed because the format fix is in the config value itself (via trackers.md + onboard + migrate-config). If the user's config says `status_id:7` for Blocked, fix-bugs passes `status_id:7` to the MCP tool. Correct.

2. **Publisher delegation (line 562):** Dispatches the publisher agent, which executes its own Step 7. Covered by publisher.md changes.

**No "On start set" step exists in fix-bugs.** This is a pre-existing functional gap (documented in Phase 2 research). Adding it would be a new feature (MINOR), not a bug fix (PATCH). **Defer to v6.6.0.** Note this in the changelog as a known limitation.

**One change needed:** The inline block comment in fix-bugs Step X (item 4, lines 649-657) is a multi-line string posted via MCP. This is a Bug 2 call site -- addressed in the Bug 2 section below.

### 6. Backward compatibility strategy

**Three-layer safety net:**

**Layer 1 — Validation accepts both formats (trackers.md Validation Rules):**
The `status_id:{id}` format is canonical. The `status:{name}` format is accepted with a `[WARN]`. check-setup will tell the user their config works but is suboptimal.

**Layer 2 — migrate-config offers upgrade (see section 7):**
Users running `/ceos-agents:migrate-config` will be offered the format upgrade interactively.

**Layer 3 — Existing configs continue to work:**
The `status:{name}` format still works for Redmine MCP servers that support name-based lookup (the LLM translates at runtime, as documented in the legacy note). The `status_id:{id}` format is strictly better (no LLM translation, no runtime API lookup, no silent failures), but the old format is not rejected.

**No breaking change.** No MAJOR version bump needed. This is a PATCH: fixing a reliability bug by changing the recommended format while keeping the old format accepted.

### 7. migrate-config changes

**File: `skills/migrate-config/SKILL.md`**

**Add to Step 3 (Check for deprecated patterns), after the existing two rules (bullet-point format, missing Type key):**

```markdown
- Redmine `status:{name}` format in State transitions or On start set (pre-v6.5.2) → offer conversion to `status_id:{id}` format:
  - Detection: If Type is `redmine` AND (State transitions contains `status:` without `status_id:` OR On start set contains `status:` without `status_id:`)
  - Display: "Redmine config uses `status:{name}` format. This relies on LLM runtime translation which can fail silently. Recommended: switch to `status_id:{id}` format."
  - Display: "To find your status IDs, run: `curl -s https://{Instance}/issue_statuses.json?key=<api-key> | jq '.issue_statuses[] | {id, name}'`"
  - Ask: "Enter your status IDs (press Enter to skip for now):"
    - "In Progress ID:" → if provided, replace `status:In Progress` with `status_id:{id}` in State transitions and On start set
    - "Blocked ID:" → if provided, replace `status:Blocked` with `status_id:{id}` in State transitions
    - "For Review ID:" → if provided, replace `status:For Review` with `status_id:{id}` in State transitions
    - "Done/Closed ID:" → if provided, replace `status:Closed` (or `status:Done`) with `status_id:{id}` in State transitions
  - If user skips (presses Enter without IDs): add to report as `[AVAILABLE]` enhancement, do not modify the config. Display: "You can update later with `/ceos-agents:onboard --update` or edit CLAUDE.md manually."
  - If user provides IDs: perform the substitution and add to the migration diff
```

**Important:** This is an interactive sub-step because status IDs are instance-specific. migrate-config has `allowed-tools: Read, Edit, Glob` -- no MCP access. The user must provide the IDs manually, same as in the onboard wizard.

### 8. Config template updates

**File: `examples/configs/redmine-oracle-plsql.md`**

Change State transitions (line 14):
```
| State transitions | In Progress: `status_id:2`, Blocked: `status_id:4`, For Review: `status_id:3`, Done: `status_id:5` |
```

Change On start set (line 15):
```
| On start set | `status_id:2` |
```

Update TODO comment (line 17):
```
<!-- TODO: Verify status IDs match your Redmine workflow (GET /issue_statuses.json). Defaults: 1=New, 2=In Progress, 3=Resolved, 4=Feedback, 5=Closed -->
```

Same changes for the commented-out Feature Workflow section (line 119):
```
| On start set | `status_id:2` |
```

**File: `examples/configs/redmine-rails.md`**

Same State transitions and On start set changes as above (lines 14-15).

Add the TODO comment that the oracle-plsql template already has (this template was missing it):
```
<!-- TODO: Verify status IDs match your Redmine workflow (GET /issue_statuses.json). Defaults: 1=New, 2=In Progress, 3=Resolved, 4=Feedback, 5=Closed -->
```

### 9. check-setup changes

**File: `skills/check-setup/SKILL.md`**

In Step 3a (Per-tracker validation), after applying the state transition format check:

The Validation Rules table in trackers.md already accepts both formats (see Change 4 above). check-setup reads that table. No change to check-setup is needed -- it follows trackers.md as its source of truth.

However, add a WARN emission rule specific to the legacy format:

After the existing state transition format check (which now passes for both `status_id:{id}` and `status:{name}`), add:

```markdown
   - If Type is `redmine` and State transitions contains `status:` (without `status_id:`):
     [WARN] "Redmine config uses legacy `status:{name}` format. Recommend `status_id:{id}` for reliability. See: `GET /issue_statuses.json`."
```

---

## Bug 2: Publisher Literal `\n`

### 1. Where exactly should the newline fix go?

**Decision: Per-site guidance in the affected agents/skills, NOT a new core/ contract.**

Rationale:
- A new `core/mcp-encoding.md` contract would be MINOR-level scope (new file, new cross-references). Overkill for a PATCH.
- The fix is a single-sentence Constraint addition to two agents and two skills. Simple, direct, unambiguous.
- Publisher is haiku model -- needs the instruction right there in its Constraints, not a cross-reference to a separate file.

**Fix locations (5 vulnerable call sites across 4 files):**

#### Fix 1 — `agents/publisher.md`

**Call site #1 (PR description, Step 6) and #2 (Block comment, Constraints).**

Add to the **Constraints** section (after the existing "PR description always in English" constraint, line 93):

```markdown
- NEVER use literal backslash-n (`\n`) or other escape sequences in MCP tool string parameters — always use actual line breaks when constructing multi-line strings for PR descriptions, issue comments, and other MCP tool fields. Build the string with real line breaks between sections, not escape sequences.
```

This covers both call sites in publisher.md (PR description in Step 6 and block comment in Constraints) with a single constraint. Haiku needs this stated once, clearly, in the Constraints section where it always looks.

Additionally, reinforce in **Step 6** (Create Pull Request), in the Description sub-point (line 64), add after "Fill in ALL template sections:":

```markdown
   - Construct the description as a multi-line string with actual line breaks between sections (do NOT use `\n` escape sequences)
```

#### Fix 2 — `core/block-handler.md`

**Call site #3 (Block comment, Step 4).**

Add to Step 4 (Post block comment), after the template block (after line 36):

```markdown
   When posting the block comment to the issue tracker via MCP, construct the comment text as a multi-line string with actual line breaks. Do NOT use escape sequences (`\n`, `\t`). Pass the comment as-is — MCP tool string parameters accept real line breaks.
```

#### Fix 3 — `skills/fix-ticket/SKILL.md`

**Call site #4 (Subtask description, Step 4b-tracker).**

Add after the Issue Description Template block and its bullet points (after line 383):

```markdown
When passing the description to the MCP tool, construct it as a multi-line string with actual line breaks between sections. Do NOT use escape sequences (`\n`). The MCP tool accepts real line breaks in the description parameter.
```

#### Fix 4 — `skills/implement-feature/SKILL.md`

**Call site #5 (Subtask description, Step 5a).**

Identical instruction as Fix 3, added after line 429:

```markdown
When passing the description to the MCP tool, construct it as a multi-line string with actual line breaks between sections. Do NOT use escape sequences (`\n`). The MCP tool accepts real line breaks in the description parameter.
```

### 2. Should it cover block-handler too?

**Yes.** `core/block-handler.md` Step 4 is call site #3 -- a 6-line multi-line block comment posted via MCP. It is vulnerable to the same `\n` literal rendering problem. Fix 2 above covers it.

Additionally, `skills/fix-bugs/SKILL.md` Step X item 4 (lines 649-657) has an inline block comment template that duplicates the block-handler pattern. Add the same instruction after line 657:

```markdown
   When posting the block comment via MCP, construct it as a multi-line string with actual line breaks. Do NOT use escape sequences (`\n`).
```

### 3. How to prevent regression?

**Three measures:**

**Measure 1 — Test assertion.**

Add a test to the existing test suite that verifies the encoding instruction exists in all vulnerable files.

**File: `tests/scenarios/` — new test file `publisher-newline-handling.sh`:**

```bash
# Test: All MCP body call sites have newline encoding guidance
# Verifies that the multi-line string instruction is present in all vulnerable files

assert_contains "agents/publisher.md" "actual line breaks"
assert_contains "core/block-handler.md" "actual line breaks"
assert_contains "skills/fix-ticket/SKILL.md" "actual line breaks"
assert_contains "skills/implement-feature/SKILL.md" "actual line breaks"
assert_contains "skills/fix-bugs/SKILL.md" "actual line breaks"
```

(Use the test harness's existing `assert_contains` pattern -- verify the exact function name by reading the harness before implementation.)

**Measure 2 — The Constraint in publisher.md is permanent.**

Adding it to the Constraints section means any future edit to publisher.md will see the constraint and maintain it. This is the standard pattern for agent-level behavioral rules.

**Measure 3 — Comment in block-handler.md and skill templates.**

The inline instruction in block-handler.md and the skill templates serves as a code-level reminder for anyone adding new MCP call sites.

---

## Summary of Files Changed

| File | Bug | Change |
|------|-----|--------|
| `docs/reference/trackers.md` | 1 | 4 table row updates + 2 notes |
| `skills/onboard/SKILL.md` | 1 | Redmine-specific ID prompt in Step 2 |
| `skills/migrate-config/SKILL.md` | 1 | New deprecated-pattern rule in Step 3 |
| `skills/check-setup/SKILL.md` | 1 | WARN for legacy `status:{name}` |
| `examples/configs/redmine-oracle-plsql.md` | 1 | `status_id:{id}` format + TODO update |
| `examples/configs/redmine-rails.md` | 1 | `status_id:{id}` format + TODO added |
| `agents/publisher.md` | 1+2 | MCP error handling in Step 7 + newline constraint |
| `core/block-handler.md` | 2 | Newline instruction in Step 4 |
| `skills/fix-ticket/SKILL.md` | 2 | Newline instruction after Step 4b-tracker template |
| `skills/implement-feature/SKILL.md` | 2 | Newline instruction after Step 5a template |
| `skills/fix-bugs/SKILL.md` | 2 | Newline instruction in Step X |
| `tests/scenarios/publisher-newline-handling.sh` | 2 | Regression test |

**Total: 12 files, 0 new core contracts, 0 config-reader changes, 0 allowed-tools changes.**

## What This Proposal Does NOT Do (and Why)

| Deferred item | Reason | Target version |
|---------------|--------|----------------|
| Post-set verification (read-back) | New pattern, no precedent, MINOR scope | v6.6.0 |
| `core/mcp-encoding.md` shared contract | MINOR scope, overkill for PATCH | v6.6.0 |
| fix-bugs "On start set" step | New feature, not a bug fix | v6.6.0 |
| config-reader Redmine normalization | Architectural change, needs MCP access | Not planned |
| Onboard wizard MCP access | allowed-tools expansion, design decision | Not planned |
