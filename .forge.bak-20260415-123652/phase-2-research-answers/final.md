# Phase 2 Research Answers — Final Synthesis
## v6.6.0: Status Verification Wiring + MCP Body Formatting Contract + fix-bugs On-Start-Set

Synthesized from agents 1, 2, and 3. All OPEN questions from Phase 1 are now RESOLVED.

---

## Resolution of Previously OPEN Questions

| ID | Phase 1 Status | Resolution Source | Final Status |
|----|---------------|-------------------|--------------|
| MCP-4 | OPEN | Agent 1 DRY analysis | RESOLVED — replace both with reference phrase |
| FBX-4 | OPEN | Agent 2 structural analysis | RESOLVED — before triage (optimistic, matches fix-ticket) |
| FBX-5 | OPEN | Agent 2 worktree finding | RESOLVED — update range to `steps 1a–8` |
| TI-5 | OPEN | Out of scope for this phase | RESOLVED — check `.forge/phase-5-tdd/final.md` at execution time |
| XR-3 | OPEN | Agent 2 direct read | RESOLVED — no step enumeration in docs/reference/skills.md, no update needed |
| XR-4 | OPEN | Agent 2 direct read | RESOLVED — resume-ticket references fix-ticket steps, not fix-bugs steps; no update needed |
| XR-5 | OPEN | Agent 2 direct read | RESOLVED — checklists contain no step number references; no update needed |

---

## Item 1: Status Verification Wiring

### Context

`core/status-verification.md` was created in v6.5.2. Three call sites were already wired:

| File | Step | Transition | Already wired |
|------|------|------------|---------------|
| `agents/publisher.md` | Step 7 | "For Review" | YES (v6.5.2) |
| `core/block-handler.md` | Step 2 | Blocked | YES (v6.5.2) |
| `skills/fix-ticket/SKILL.md` | Step 1 | On start set | YES (v6.5.2) |

Four new call sites need wiring in v6.6.0:

| File | Step | Transition |
|------|------|------------|
| `skills/implement-feature/SKILL.md` | Step 1 | On start set |
| `core/fix-verification.md` | Step 6 | Re-open (conditional) |
| `skills/fix-bugs/SKILL.md` | Block handler Step 2 | Blocked (inline expansion) |
| `skills/scaffold/SKILL.md` | Step 8b items 3a, 3b | Done (epic + stories) |

---

### Insertion Point 1 — `skills/implement-feature/SKILL.md` Step 1

**RESOLVED.**

Step 1 is a two-sentence prose paragraph. The verification sentence is a new standalone paragraph after the closing parenthesis of "(fallback: Issue Tracker → On start set)." and before `### 2. Create branch`.

**Exact old_string:**
```
Read the issue from the issue tracker. Set the state per Feature Workflow → On start set
(fallback: Issue Tracker → On start set).

### 2. Create branch
```

**Exact new_string:**
```
Read the issue from the issue tracker. Set the state per Feature Workflow → On start set
(fallback: Issue Tracker → On start set).

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

### 2. Create branch
```

---

### Insertion Point 2 — `core/fix-verification.md` Step 6

**RESOLVED.**

Step 5 (success path) has no status-set call. Step 6 (failure path) conditionally re-opens the issue. The verification sentence is inserted inline within the conditional re-open clause, immediately after "set the issue state back."

**Exact old_string:**
```
   If State transitions contains a re-open key → set the issue state back. Display: "Fix verification failed. Issue re-opened." Return `FAILED`.
```

**Exact new_string:**
```
   If State transitions contains a re-open key → set the issue state back. After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded. Display: "Fix verification failed. Issue re-opened." Return `FAILED`.
```

---

### Insertion Point 3 — `skills/fix-bugs/SKILL.md` Block Handler Step 2

**RESOLVED.**

`core/block-handler.md` already has the verification hook. fix-bugs re-expands the block protocol inline (numbered steps 1–8) without delegating verification. The inline expansion's Step 2 needs the verification line for consistent human readability. The line is added as an indented continuation directly after Step 2.

**Exact old_string:**
```
2. **Set issue state to Blocked** (State transitions → Blocked)

3. **On block action** (per Error Handling → On block):
```

**Exact new_string:**
```
2. **Set issue state to Blocked** (State transitions → Blocked)
   After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

3. **On block action** (per Error Handling → On block):
```

---

### Insertion Point 4 — `skills/scaffold/SKILL.md` Step 8b Items 3a and 3b

**RESOLVED.**

Step 8b performs status-set MCP calls in items 3a (epic transition to Done) and 3b (story transitions to Done). Step 8b uses WARN on failure (item 3d) — there is no block handler dispatch — so only items 3a and 3b need verification. The verification sentence is added inline after each transition call as a continuation clause.

**Exact old_string:**
```
3. For each fully-completed epic:
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config.
   b. Close each story sub-issue individually for ALL tracker types. Read story IDs from back-reference comments (`<!-- {TrackerType}: {STORY-ID} -->`) within the epic file. Transition each story issue to Done using the same `State transitions -> Done` syntax.
   c. If a story issue is already in the target Done state, treat it as success — do not emit a warning or error.
   d. On failure (epic or story transition): WARN (`Could not transition {issue_id} to Done: {error}`), continue to next.
```

**Exact new_string:**
```
3. For each fully-completed epic:
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config. After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
   b. Close each story sub-issue individually for ALL tracker types. Read story IDs from back-reference comments (`<!-- {TrackerType}: {STORY-ID} -->`) within the epic file. Transition each story issue to Done using the same `State transitions -> Done` syntax. After each status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
   c. If a story issue is already in the target Done state, treat it as success — do not emit a warning or error.
   d. On failure (epic or story transition): WARN (`Could not transition {issue_id} to Done: {error}`), continue to next.
```

---

## Item 2: MCP Body Formatting Contract

### Context

Seven inline `NEVER use the literal characters \n` instructions are scattered across 5 files. The goal is to centralize the rule into a new `core/mcp-body-formatting.md` contract and replace every inline occurrence with a short reference phrase.

### Contract File — `core/mcp-body-formatting.md` (NEW)

**RESOLVED.** Full content to create:

```markdown
# MCP Body Formatting

## Purpose

Prevent literal `\n` escape sequences from appearing in MCP tool parameters that accept
multi-line text. MCP tools receive parameter values as-is from the calling model —
escaped sequences like `\n` are rendered as the literal two-character sequence backslash-n,
not as actual newlines. This contract defines the required construction pattern.

## Applies To

All MCP tool calls where the parameter value contains multi-line content:
- PR description body (source control MCP: create_pull_request, create_pr)
- Issue comment body (tracker MCP: create_comment, add_comment)
- Issue/card description body (tracker MCP: create_issue, update_issue)
- Block comment fields (pipeline block protocol)
- Sub-issue description body (decomposition subtask creation)

## Process

1. Construct all multi-line strings with actual line breaks (real newlines in the source text).
2. Never interpolate or concatenate the string literal `\n` as a line separator.
3. Verify the constructed string contains Unicode U+000A newline characters between lines, not escape sequences.

## Output Contract

No return value. Callers apply the rule inline before constructing MCP tool parameters.

## Constraints

- NEVER use `\n` as a line separator in any MCP parameter value
- NEVER concatenate field values with the string `"\n"` — use actual newlines
- NEVER interpolate `\n` inside template strings passed to MCP tools

## Failure Mode

There is no runtime failure — the MCP tool accepts the parameter and creates the
issue/comment/PR. The failure is visual: multi-line content appears as a single line
with literal `\n` characters visible to end users in the issue tracker or source control UI.
```

---

### Reference Phrase by Context

Two canonical forms, by context:

| Context | Replacement phrase |
|---------|-------------------|
| Sub-issue / PR body construction | `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.` |
| Block comment posting | `Follow \`core/mcp-body-formatting.md\` when constructing the comment string.` |
| publisher.md Step 6 sub-bullet (inline) | `follow \`core/mcp-body-formatting.md\`` (continuation of the existing sentence) |
| publisher.md Constraints section (full bullet) | `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters (PR description, issue comments).` |

---

### All 7 Replacements — Exact Edit Strings

#### Replacement 1 — `agents/publisher.md` Step 6 sub-bullet

**RESOLVED.** (Previously OPEN MCP-4 — full DRY approach confirmed.)

**Exact old_string:**
```
  - Build the PR body as a multi-line string with real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

**Exact new_string:**
```
  - Build the PR body as a multi-line string with real line breaks between sections — follow `core/mcp-body-formatting.md`.
```

---

#### Replacement 2 — `agents/publisher.md` Constraints section

**RESOLVED.** (Previously OPEN MCP-4 — full DRY replacement; full explanation moves to the contract file.)

**Exact old_string:**
```
- NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is — escaped sequences like `\n` are rendered literally, not as newlines.
```

**Exact new_string:**
```
- Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters (PR description, issue comments).
```

---

#### Replacement 3 — `core/block-handler.md` Step 4 post-template note

**Exact old_string:**
```
   When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators.
```

**Exact new_string:**
```
   Follow `core/mcp-body-formatting.md` when constructing the comment string.
```

---

#### Replacement 4 — `skills/fix-ticket/SKILL.md` Step 4b-tracker

**Exact old_string:**
```
    - When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

**Exact new_string:**
```
    - Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters.
```

---

#### Replacement 5 — `skills/implement-feature/SKILL.md` Step 5a

**Exact old_string:**
```
When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

**Exact new_string:**
```
Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters.
```

---

#### Replacement 6 — `skills/fix-bugs/SKILL.md` Step 3b-tracker

**Exact old_string:**
```
When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

**Exact new_string:**
```
Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters.
```

---

#### Replacement 7 — `skills/fix-bugs/SKILL.md` Block handler Step 4 post-template note

**Exact old_string:**
```
When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators.
```

**Exact new_string:**
```
Follow `core/mcp-body-formatting.md` when constructing the comment string.
```

---

### Summary Table — 7 Replacements Across 5 Files

| # | File | Location | Old text (abbreviated) | New text |
|---|------|----------|------------------------|----------|
| 1 | `agents/publisher.md` | Step 6 sub-bullet | `...NEVER use the literal characters \`\n\` as line separators.` | `follow \`core/mcp-body-formatting.md\`` |
| 2 | `agents/publisher.md` | Constraints 5th bullet | `NEVER use the literal characters \`\n\` in any MCP tool parameter...` | `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters (PR description, issue comments).` |
| 3 | `core/block-handler.md` | Step 4 post-template | `When posting this comment via MCP...NEVER use...` | `Follow \`core/mcp-body-formatting.md\` when constructing the comment string.` |
| 4 | `skills/fix-ticket/SKILL.md` | Step 4b-tracker bullet | `When passing the issue description...NEVER use...` | `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.` |
| 5 | `skills/implement-feature/SKILL.md` | Step 5a standalone line | `When passing the issue description...NEVER use...` | `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.` |
| 6 | `skills/fix-bugs/SKILL.md` | Step 3b-tracker standalone | `When passing the issue description...NEVER use...` | `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.` |
| 7 | `skills/fix-bugs/SKILL.md` | Block handler Step 4 post-template | `When posting this comment via MCP...NEVER use...` | `Follow \`core/mcp-body-formatting.md\` when constructing the comment string.` |

---

## Item 3: fix-bugs "On Start Set" Step

### All Sub-Questions Resolved

#### Insertion Point (FBX-1) — RESOLVED

The new step is labeled **Step 1a** and inserted between Step 1 (Fetch bugs) and Step 2 (Triage). Using "1a" preserves all existing step numbers — triage remains step 2, code-analyst step 3, etc.

#### Stage Mapping Table (FBX-2) — RESOLVED

The stage mapping table (`triage=step 2, code-analyst=step 3, ...`) does not need updating. Step 1a falls before triage and is not a named stage in the mapping.

#### Step Heading and Wording (FBX-3) — RESOLVED

Use `### 1a. Set issue tracker` (matching fix-ticket Step 1 heading style). fix-bugs processes bugs only — no Feature Workflow fallback.

#### Timing (FBX-4) — RESOLVED

**Option A — before triage (optimistic)**, matching fix-ticket's pattern. The step fires per-bug within the processing loop, before triage is dispatched. Rationale: fix-ticket sets state before any work begins; fix-bugs should match this behavior for consistency. Some bugs may be triaged as DUPLICATE or UNCLEAR and never reach fix, but this is acceptable — the same risk exists in fix-ticket and is not addressed there.

#### Worktree Parallel Range (FBX-5) — RESOLVED

Agent 2 confirmed the current worktree range is explicitly `steps 2–8` in the text:
> "Run the pipeline (steps 2–8) for EVERY bug in the batch IN PARALLEL"

Step 1a is a per-bug step that must execute within each Task. The range must be updated to `steps 1a–8`.

**Exact old_string:**
```
3. Run the pipeline (steps 2–8) for EVERY bug in the batch IN PARALLEL:
```

**Exact new_string:**
```
3. Run the pipeline (steps 1a–8) for EVERY bug in the batch IN PARALLEL:
```

#### Dry-Run Annotation (FBX-6) — RESOLVED

Step 1a carries `*In dry-run: skip this step.*` matching fix-ticket Step 1. The dry-run prose in fix-bugs ("steps 1–3, no side effects: no issue tracker state changes") covers this implicitly (step 1a makes an issue tracker state change and is therefore skipped in dry-run). No change to the prose range "steps 1–3" is required since 1a is numerically within that range and the prose explicitly excludes state changes.

#### Full New Step Text

```
### 1a. Set issue tracker

Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server.

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

*In dry-run: skip this step.*
```

#### Insertion Location

**Exact old_string** (surrounding context for the Edit tool):
```
### 1. Fetch bugs
Use Bug query from Automation Config via the MCP server matching Type. Limit = count from $ARGUMENTS.

### 2. Triage (parallel — triage is read-only, parallelism does not depend on worktree configuration)
```

**Exact new_string:**
```
### 1. Fetch bugs
Use Bug query from Automation Config via the MCP server matching Type. Limit = count from $ARGUMENTS.

### 1a. Set issue tracker

Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server.

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

*In dry-run: skip this step.*

### 2. Triage (parallel — triage is read-only, parallelism does not depend on worktree configuration)
```

---

## Cross-References

### CLAUDE.md Updates Required

| Change | Reason | Current | New |
|--------|---------|---------|-----|
| `core/` count | Adding `core/mcp-body-formatting.md` | `12 shared pipeline pattern contracts` | `13 shared pipeline pattern contracts` |

The Bug-Fix Pipeline flow diagram does NOT need updating — the "On start set" step in fix-bugs is a behavioral detail, not a named pipeline stage.

### docs/reference/skills.md — RESOLVED, No Update Needed

Agent 2 confirmed: the `/fix-bugs` section uses high-level prose with no step-number enumeration. Inserting step 1a does not require updating this file.

### skills/resume-ticket/SKILL.md — RESOLVED, No Update Needed

Agent 2 confirmed: resume-ticket references step numbers for fix-ticket (e.g., "code-analyst (step 4)", "fixer (step 5)"), not fix-bugs steps. Resume-ticket dispatches fix-ticket for BUG pipeline resumption. Step 1a in fix-bugs is not mapped in resume-ticket. No update required.

### checklists/ — RESOLVED, No Update Needed

Agent 2 confirmed: all three checklist files (`publish-checklist.md`, `review-checklist.md`, `test-checklist.md`) contain only generic quality gates with no step number references to fix-bugs. No update required.

### docs/plans/roadmap.md — No Update During Implementation

The v6.6.0 roadmap entry is the source of the feature definition. It should be moved from PLANNED to DONE after implementation is complete and the version is bumped.

---

## Test Infrastructure

### `tests/scenarios/mcp-newline-handling.sh` — Required Changes

**Current state:**
- `MARKER='NEVER use the literal characters'`
- `VULNERABLE_FILES` = 5 files: `agents/publisher.md`, `core/block-handler.md`, `skills/fix-ticket/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/fix-bugs/SKILL.md`
- Logic: `grep -q "$MARKER" "$f"` — checks for MARKER presence in each file
- PASS message: `"PASS: All 5 vulnerable files contain MCP newline-safe output instruction (T-013)"`

**After v6.6.0 the MARKER will no longer appear in those 5 files.** The test must be updated.

**Required changes:**

1. **Replace the single-marker loop with TWO checks:**

   Check A — Contract file contains the rule:
   ```bash
   # Check that the contract file itself contains the NEVER rule
   CONTRACT="core/mcp-body-formatting.md"
   if ! grep -q "NEVER use" "$CONTRACT"; then
     echo "FAIL: $CONTRACT missing NEVER rule"
     FAIL=1
   fi
   ```

   Check B — All 5 skill/agent files reference the contract:
   ```bash
   REFERENCE_MARKER="core/mcp-body-formatting.md"
   REFERENCE_FILES=(
     "agents/publisher.md"
     "core/block-handler.md"
     "skills/fix-ticket/SKILL.md"
     "skills/implement-feature/SKILL.md"
     "skills/fix-bugs/SKILL.md"
   )
   for f in "${REFERENCE_FILES[@]}"; do
     if ! grep -q "$REFERENCE_MARKER" "$f"; then
       echo "FAIL: $f missing reference to $REFERENCE_MARKER"
       FAIL=1
     fi
   done
   ```

2. **Update PASS message:**
   ```
   "PASS: All 5 files reference core/mcp-body-formatting.md and contract contains NEVER rule (T-013)"
   ```

3. **Preserve the T-013 tag** on both PASS and FAIL messages.

---

### `tests/scenarios/xref-core-registry.sh` — No Code Changes Needed

**RESOLVED.** The test uses dynamic discovery (`ls core/*.md | basename`), so it automatically picks up the new `core/mcp-body-formatting.md` file. However:

1. **CLAUDE.md must be updated** (12 → 13) — the test compares filesystem count against the number extracted from the CLAUDE.md line:
   `` `core/` — N shared pipeline pattern contracts ``
   If CLAUDE.md still says 12, the test FAILS.

2. **The new core file must be referenced** — the test verifies every `core/*.md` is referenced in at least one `skills/*/SKILL.md`. After replacements 4–7 above, `core/mcp-body-formatting.md` will be referenced in `fix-ticket/SKILL.md`, `implement-feature/SKILL.md`, and `fix-bugs/SKILL.md`. This check passes automatically.

No changes to `xref-core-registry.sh` itself are needed.

---

### Other Tests — No Changes Needed

- `xref-command-count.sh` — checks skill/agent counts, not core counts. Unaffected.
- Tests referencing fix-bugs step numbers — step 1a does not renumber steps 2–9. No breakage.
- No other test file hardcodes the core count of 12.

---

### TI-5: Deleted TDD Test Files

Six TDD test files were deleted from `.forge/phase-5-tdd/` (5 AC tests + 1 regression test). These were generated by the forge TDD phase for a previous feature iteration. The authoritative list of AC tests for v6.6.0 is in `.forge/phase-5-tdd/final.md`. The executor should read that file before implementing and use it as the acceptance gate. New scenario tests in `tests/scenarios/` (specifically `mcp-newline-handling.sh`) serve as the persistent regression guard.

---

## Complete File Change Inventory

| File | Change Type | Description |
|------|-------------|-------------|
| `core/mcp-body-formatting.md` | CREATE NEW | Full contract text (see Item 2 above) |
| `skills/implement-feature/SKILL.md` | EDIT | SV-1: add verification sentence after Step 1 |
| `core/fix-verification.md` | EDIT | SV-2: add verification sentence within Step 6 conditional |
| `skills/fix-bugs/SKILL.md` | EDIT (3×) | SV-3: block handler Step 2 verification line; MCP Rep 6+7; step 1a insertion; worktree range update |
| `skills/scaffold/SKILL.md` | EDIT | SV-4: add verification sentences to Step 8b items 3a and 3b |
| `agents/publisher.md` | EDIT (2×) | MCP Rep 1+2: replace both NEVER occurrences |
| `core/block-handler.md` | EDIT | MCP Rep 3: replace NEVER occurrence in Step 4 |
| `skills/fix-ticket/SKILL.md` | EDIT | MCP Rep 4: replace NEVER occurrence in Step 4b-tracker |
| `skills/implement-feature/SKILL.md` | EDIT | MCP Rep 5: replace NEVER occurrence in Step 5a |
| `CLAUDE.md` | EDIT | Update core count 12 → 13 |
| `tests/scenarios/mcp-newline-handling.sh` | EDIT | Update check logic (see Test Infrastructure above) |

**Total: 1 new file + 10 edits across 9 existing files.**

Note: `skills/fix-bugs/SKILL.md` has 3 independent edits (block handler SV-3, MCP reps 6+7, step 1a + worktree range). These can be batched but must be applied in document order to avoid overlapping old_string contexts.
