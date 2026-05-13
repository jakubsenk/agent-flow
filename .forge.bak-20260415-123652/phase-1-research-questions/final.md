# Phase 1 Research Questions — Synthesized Final
## v6.6.0: Status Verification Wiring + MCP Body Formatting Contract + fix-bugs On-Start-Set

Synthesized from agents 1, 2, and 3. Duplicates removed, questions organized by topic, status marked RESOLVED or OPEN.

---

## 1. Status Verification Wiring

### Background

Three call sites were already wired in v6.5.2. Four new sites need wiring in v6.6.0.

**Already wired (v6.5.2):**

| File | Step | Transition |
|------|------|------------|
| `agents/publisher.md` | Step 7 | "For Review" |
| `core/block-handler.md` | Step 2 | Blocked |
| `skills/fix-ticket/SKILL.md` | Step 1 | On start set |

**Needs wiring (v6.6.0):**

| File | Step | Transition |
|------|------|------------|
| `skills/implement-feature/SKILL.md` | Step 1 | On start set |
| `core/fix-verification.md` | Step 6 | Re-open (conditional) |
| `skills/fix-bugs/SKILL.md` | Block handler Step 2 | Blocked (inline expansion) |
| `skills/scaffold/SKILL.md` | Step 8b items 3a, 3b | Done (epic + stories) |

---

### SV-1: implement-feature/SKILL.md — Step 1 insertion point

**RESOLVED.**

Current Step 1 text is a two-sentence prose paragraph with no sub-bullets. The verification sentence belongs as a standalone paragraph after the closing parenthesis of "(fallback: Issue Tracker → On start set)." and before `### 2. Create branch`.

**Exact old_string:**
```
### 1. Set issue state

Read the issue from the issue tracker. Set the state per Feature Workflow → On start set
(fallback: Issue Tracker → On start set).

### 2. Create branch
```

**Exact new_string:**
```
### 1. Set issue state

Read the issue from the issue tracker. Set the state per Feature Workflow → On start set
(fallback: Issue Tracker → On start set).

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

### 2. Create branch
```

---

### SV-2: core/fix-verification.md — Step 6 insertion point

**RESOLVED.**

Step 5 (success path) only posts a comment — no status-set call. Step 6 (failure path) conditionally sets state back (re-open). The verification sentence belongs inline within the conditional re-open clause in Step 6, immediately after "set the issue state back."

**Exact old_string:**
```
6. If command fails → post failure comment to the issue:
   ```
   [ceos-agents] ❌ Fix verification failed.
   Command: `{command}`
   Output: {first 500 chars}
   ```
   If State transitions contains a re-open key → set the issue state back. Display: "Fix verification failed. Issue re-opened." Return `FAILED`.
```

**Exact new_string:**
```
6. If command fails → post failure comment to the issue:
   ```
   [ceos-agents] ❌ Fix verification failed.
   Command: `{command}`
   Output: {first 500 chars}
   ```
   If State transitions contains a re-open key → set the issue state back. After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded. Display: "Fix verification failed. Issue re-opened." Return `FAILED`.
```

---

### SV-3: skills/fix-bugs/SKILL.md — Block handler Step 2 insertion point

**RESOLVED.**

`core/block-handler.md` already has the verification hook. However, fix-bugs re-expands the block protocol inline in numbered steps 1–8 without delegating verification. The inline expansion's Step 2 needs the verification line for consistent human readability. TDD test markers also check for `core/status-verification.md` in fix-bugs/SKILL.md directly.

**Exact old_string:**
```
2. **Set issue state to Blocked** (State transitions → Blocked)
```

**Exact new_string:**
```
2. **Set issue state to Blocked** (State transitions → Blocked)
   After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
```

---

### SV-4: skills/scaffold/SKILL.md — Step 8b items 3a and 3b

**RESOLVED.**

Step 8b performs status-set MCP calls in items 3a (epic transition to Done) and 3b (story transitions to Done). Step 8b uses WARN on failure (item 3d) and has no block handler dispatch — only items 3a and 3b need verification. The verification sentence is added inline after each transition call as a continuation clause.

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

## 2. MCP Body Formatting Contract

### Background

Five files contain inline `NEVER use the literal characters \n` instructions. The goal is to centralize this into a new `core/mcp-body-formatting.md` contract and replace inline text with a reference phrase.

**Confirmed occurrence counts per file:**

| File | Occurrences | Location(s) |
|------|-------------|-------------|
| `agents/publisher.md` | 2 | Step 6 description bullet + Constraints section |
| `core/block-handler.md` | 1 | Step 4 post-comment note |
| `skills/fix-ticket/SKILL.md` | 1 | Step 4b-tracker (subtask creation, after code block) |
| `skills/implement-feature/SKILL.md` | 1 | Step 5a (decomposition subtask creation, after code block) |
| `skills/fix-bugs/SKILL.md` | 2 | Step 3b (subtask creation) + Block handler Step 4 |

**Total: at minimum 7 replacements across 5 files.**

---

### MCP-1: Exact NEVER text in each file

**RESOLVED for all 5 files.**

**`agents/publisher.md` Step 6:**
> "Build the PR body as a multi-line string with real line breaks between sections — NEVER use the literal characters `\n` as line separators."

**`agents/publisher.md` Constraints section:**
> "NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is — escaped sequences like `\n` are rendered literally, not as newlines."

**`core/block-handler.md` Step 4:**
> "When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators."

**`skills/fix-ticket/SKILL.md` Step 4b-tracker:**
> "When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators."

**`skills/implement-feature/SKILL.md` Step 5a:**
> "When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators."
*(Identical wording to fix-ticket Step 4b-tracker.)*

**`skills/fix-bugs/SKILL.md` Step 3b (line 373):**
> "When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators."

**`skills/fix-bugs/SKILL.md` Block handler Step 4 (line 661):**
> "When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators."

---

### MCP-2: Contract structure for `core/mcp-body-formatting.md`

**RESOLVED.**

Canonical section order (from `core/status-verification.md`): `## Purpose` → `## Input Contract` → `## Process` → `## Output Contract` → `## Constraints` → `## Failure Handling`.

Since MCP body formatting is a behavioral constraint (not a data-flow contract), `## Input Contract` should be replaced or repurposed as `## Applies To` (listing caller contexts). `## Output Contract` should state "No return value. Callers apply the rule inline before constructing MCP tool parameters." The core NEVER rule belongs in both `## Process` (how to apply it) and `## Constraints` (the prohibition).

**Full proposed contract:**

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

### MCP-3: Reference phrase to use in the 5 files

**RESOLVED.**

The replacement phrase follows the same convention as status-verification references. The canonical form varies slightly by context:

- For sub-issue/PR body construction (replacing "When passing... NEVER use..."): `"Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters."`
- For block comment posting (replacing "When posting this comment... NEVER use..."): `"Follow \`core/mcp-body-formatting.md\` when constructing the comment string."`

OPEN question: whether `agents/publisher.md` Constraints section (the more detailed occurrence) should keep a condensed inline note alongside the reference, or whether a pure reference is sufficient. The DRY principle favors full replacement (Option A from Agent 1 analysis), consistent with how status-verification references were implemented.

---

### MCP-4: How to handle publisher.md's two occurrences (Step 6 inline vs Constraints section)

**OPEN.**

Both occurrences in `agents/publisher.md` must be replaced. The Step 6 version is a short inline note; the Constraints version is the longest and most explanatory occurrence in any file. Choices:
- Replace both with the reference phrase (full DRY approach)
- Replace Step 6 with reference phrase, keep a one-line summary in Constraints alongside the reference

The full DRY replacement is preferred for consistency. The implementer should replace both and verify that `core/mcp-body-formatting.md` contains the full explanatory text that was previously in the Constraints entry.

---

## 3. fix-bugs "On Start Set" Step

### Background

fix-bugs is the only pipeline skill that does not set issue state on start. It delegates to publisher for the "For Review" transition but never sets "In Progress." The new step mirrors fix-ticket Step 1 pattern.

**fix-ticket Step 1 exact pattern (3 lines):**
```
### 1. Set issue tracker

Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server.

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

*In dry-run: skip this step.*
```

---

### FBX-1: Insertion point — between step 1 (Fetch bugs) and step 2 (Triage)

**RESOLVED.**

The new step belongs between the existing Step 1 (Fetch bugs) and Step 2 (Triage), labeled as **Step 1a**. This preserves all existing step numbers (triage stays step 2, code-analyst stays step 3, etc.), requiring zero changes to the stage mapping table.

---

### FBX-2: Exact step numbering — stage mapping table impact

**RESOLVED.**

Stage mapping table (lines 65–71) maps: triage=step 2, code-analyst=step 3, test-engineer=step 7, e2e-test-engineer=step 7b, reproducer=step 3e, browser-verifier=step 7b-browser. Inserting step 1a does not shift any of these references. No update to the stage mapping table is needed.

---

### FBX-3: Step heading and wording

**RESOLVED.**

Use "Set issue tracker" as the step heading (matching fix-ticket Step 1 exactly). fix-bugs uses `Issue Tracker → On start set` only (no Feature Workflow fallback — fix-bugs processes bugs, not features). The step must include:
1. State-set instruction referencing `Issue Tracker → On start set`
2. Status-verification reference (`core/status-verification.md`)
3. Dry-run skip annotation (`*In dry-run: skip this step.*`)

Step 1a should apply per-bug within the processing loop (each bug's state is set before triage begins for that bug, or immediately after fetch before the parallel triage dispatch).

---

### FBX-4: Timing — before or after parallel triage dispatch?

**OPEN.**

fix-bugs runs triage in parallel for ALL bugs. Setting all N issues to "In Progress" before triage begins is optimistic — some may be triaged as DUPLICATE or UNCLEAR and never reach fix. Two options:
- **Option A (before triage — optimistic, matches fix-ticket):** Step 1a fires per-bug before the parallel triage batch, consistent with fix-ticket's "On start set" that runs before any work.
- **Option B (after triage passes — conservative):** State is set only for bugs that proceed past triage to code-analyst/fixer.

The fix-ticket pattern is optimistic (state is set at start, before triage). Consistency with fix-ticket suggests Option A. The implementer should confirm which option the roadmap/spec intends.

---

### FBX-5: Worktree parallel range annotation

**OPEN.**

The worktree variant states "Run the pipeline (steps 2–8) for EVERY bug in the batch IN PARALLEL." If step 1a is per-bug (not global), the worktree range should be updated to "steps 1a–8" or annotated to include 1a. If step 1a is global (fires once before triage dispatch, setting all N bugs at once), no update to the worktree range is needed. The implementer must decide on the per-bug vs global semantics before updating the worktree annotation.

---

### FBX-6: Dry-run section annotation

**RESOLVED.**

Step 1a carries a dry-run skip annotation (`*In dry-run: skip this step.*`), matching fix-ticket Step 1. The existing dry-run prose ("steps 1–3") in fix-bugs should be amended to clarify that step 1a has issue tracker side effects and is skipped in dry-run mode. The per-step annotation is sufficient for runtime guidance; the prose clarification is a documentation courtesy.

---

### FBX-7: Risk of conflict with publisher's existing state transition

**RESOLVED.**

Publisher already handles the "For Review" transition (step 8). Adding "In Progress" at step 1a does not conflict — they target different states at different pipeline stages. No conflict risk.

---

### FBX-8: CLAUDE.md update requirement for this item

**RESOLVED.**

The fix-bugs "On start set" step addition changes only `skills/fix-bugs/SKILL.md`. It does not create a new core file and does not change agent or skill counts. CLAUDE.md does not need updating for this item alone. (CLAUDE.md core count 12→13 is required only for the MCP body formatting contract addition — see Cross-Reference section.)

---

## 4. Test Infrastructure

### TI-1: mcp-newline-handling.sh — current check logic

**RESOLVED.**

The test (`tests/scenarios/mcp-newline-handling.sh`) checks:
- `MARKER='NEVER use the literal characters'` (exact string, case-sensitive)
- `VULNERABLE_FILES` array: 5 files (publisher.md, block-handler.md, fix-ticket/SKILL.md, implement-feature/SKILL.md, fix-bugs/SKILL.md)
- Logic: loops over files, `grep -q MARKER`. PASS message: `"PASS: All 5 vulnerable files contain MCP newline-safe output instruction (T-013)"`

---

### TI-2: mcp-newline-handling.sh — required updates after contract extraction

**RESOLVED.**

After the inline NEVER text is replaced by contract references:
- The marker `'NEVER use the literal characters'` will no longer appear in the 5 skill/agent files
- The marker WILL appear in `core/mcp-body-formatting.md`
- The existing test will FAIL unless updated

**Required test update:**
1. Add `core/mcp-body-formatting.md` to VULNERABLE_FILES (or handle separately) and check for the NEVER marker there
2. Change the per-file check for the 5 skill/agent files to look for the reference phrase `core/mcp-body-formatting.md` instead of the old NEVER marker
3. Update PASS message from `"All 5 vulnerable files"` to reflect the new check (e.g., `"All 5 files reference core/mcp-body-formatting.md and contract contains NEVER rule (T-013)"`)
4. Preserve the T-013 tag

---

### TI-3: xref-core-registry.sh — impact of adding core/mcp-body-formatting.md

**RESOLVED.**

`tests/scenarios/xref-core-registry.sh` dynamically counts `core/*.md` files on disk (no hardcoded count). It:
1. Checks that CLAUDE.md count matches the filesystem count — **CLAUDE.md must be updated from 12 to 13**
2. Checks that each core file is referenced by at least one SKILL.md — the 3 skills (fix-ticket, implement-feature, fix-bugs) will reference `core/mcp-body-formatting.md`, so this check passes automatically

No changes to `xref-core-registry.sh` itself are needed. The only required action is the CLAUDE.md count update.

---

### TI-4: Other tests affected

**RESOLVED.**

- `xref-command-count.sh` — checks skill/agent counts, not core counts. Not affected.
- Tests referencing fix-bugs step numbers — step 1a insertion does not renumber existing steps, so no test breakage expected from step numbering changes.
- No other test files are known to hardcode the core count of 12.

---

### TI-5: Deleted TDD test files — replacement needed

**OPEN.**

Git status shows 5 TDD test files were deleted from `.forge/phase-5-tdd/tests/`:
- `ac1-scaffolder-step-numbering.sh`
- `ac2-fixbugs-contributor-note.sh`
- `ac3-triage-token-constraints.sh`
- `ac4-codeanalyst-token-constraints.sh`
- `ac5-fixer-reviewer-token-constraints.sh`

And 1 from `.forge/phase-5-tdd/tests-hidden/`:
- `regression-no-content-loss.sh`

These deletions appear to be from the forge pipeline run itself (TDD phase). Whether replacement test files need to be written for v6.6.0 AC coverage is unclear. The implementer should check `.forge/phase-5-tdd/final.md` to determine if new test scenarios targeting v6.6.0 ACs exist.

---

## 5. Cross-Reference Integrity

### XR-1: CLAUDE.md core count

**RESOLVED.**

Current CLAUDE.md line: `` `core/` — 12 shared pipeline pattern contracts ``

Must be updated to **13** when `core/mcp-body-formatting.md` is created. This is the only CLAUDE.md change required for v6.6.0.

---

### XR-2: CLAUDE.md bug-fix pipeline description

**RESOLVED.**

The `## Bug-Fix Pipeline` section in CLAUDE.md uses a flow diagram, not step numbers. Adding the "On start set" step to fix-bugs does not require updating the flow diagram — the step is a behavioral detail, not a pipeline stage. No CLAUDE.md update needed for this item.

---

### XR-3: docs/reference/skills.md — fix-bugs step listing

**OPEN.**

If `docs/reference/skills.md` describes fix-bugs pipeline steps in detail (by number), inserting step 1a may require a documentation update. This file was not read during research. The implementer should check whether it enumerates fix-bugs steps numerically.

---

### XR-4: skills/resume-ticket — step number references

**OPEN.**

`/ceos-agents:resume-ticket` may reference step numbers or step names for fix-bugs pipeline position tracking. Adding step 1a could affect resume logic if it uses numeric step references. This file was not read during research. The implementer should verify that resume-ticket uses step labels (names) rather than numbers, or that step 1a does not break any position detection.

---

### XR-5: checklists/ — fix-bugs step references

**OPEN.**

Checklist files in `checklists/` may enumerate fix-bugs steps. Since step 1a does not renumber existing steps, any existing checklist references to steps 2–9 remain valid. Verify no checklist uses "step 1" to mean something that would be displaced.

---

### XR-6: roadmap.md — v6.6.0 tracking

**RESOLVED.**

The roadmap entry for v6.6.0 covers both implementation items. No roadmap update is needed during implementation — the roadmap was the source of the feature definition.

---

## Summary Table

| ID | Question | Status |
|----|----------|--------|
| SV-1 | implement-feature Step 1 insertion point and exact edit strings | RESOLVED |
| SV-2 | core/fix-verification.md Step 6 insertion point and exact edit strings | RESOLVED |
| SV-3 | fix-bugs block handler Step 2 insertion point and exact edit strings | RESOLVED |
| SV-4 | scaffold Step 8b items 3a/3b insertion point and exact edit strings | RESOLVED |
| MCP-1 | Exact NEVER text in all 5 files (all occurrences) | RESOLVED |
| MCP-2 | core/mcp-body-formatting.md contract structure and full text | RESOLVED |
| MCP-3 | Replacement reference phrase for the 5 files | RESOLVED |
| MCP-4 | How to handle publisher.md's two occurrences (Step 6 + Constraints) | OPEN |
| FBX-1 | fix-bugs new step insertion point (step 1a, between step 1 and step 2) | RESOLVED |
| FBX-2 | Stage mapping table update needed? No | RESOLVED |
| FBX-3 | Step heading and required sub-elements | RESOLVED |
| FBX-4 | Timing — before triage (optimistic) vs after triage (conservative) | OPEN |
| FBX-5 | Worktree parallel range annotation update | OPEN |
| FBX-6 | Dry-run annotation on new step | RESOLVED |
| FBX-7 | Risk of conflict with publisher's existing state transition | RESOLVED |
| FBX-8 | CLAUDE.md update needed for fix-bugs item? No | RESOLVED |
| TI-1 | mcp-newline-handling.sh current check logic | RESOLVED |
| TI-2 | mcp-newline-handling.sh required updates after extraction | RESOLVED |
| TI-3 | xref-core-registry.sh impact | RESOLVED |
| TI-4 | Other tests affected | RESOLVED |
| TI-5 | Deleted TDD test files — replacement coverage | OPEN |
| XR-1 | CLAUDE.md core count update (12 → 13) | RESOLVED |
| XR-2 | CLAUDE.md bug-fix pipeline description update needed? No | RESOLVED |
| XR-3 | docs/reference/skills.md fix-bugs step listing | OPEN |
| XR-4 | resume-ticket skill step number references | OPEN |
| XR-5 | checklists/ fix-bugs step references | OPEN |
| XR-6 | roadmap.md update during implementation | RESOLVED |
