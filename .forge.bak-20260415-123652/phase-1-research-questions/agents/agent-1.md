# Agent 1: Pipeline Contract Analyst — Research Questions & Findings

## Scope

v6.6.0 has two implementation items:
1. **Status Verification Wiring** — wire `core/status-verification.md` into 4 remaining call sites
2. **MCP Body Formatting Contract** — create `core/mcp-body-formatting.md` and replace inline NEVER instructions in 5 files

---

## Item 1: Status Verification Wiring

### Background: Existing Pattern (v6.5.2 — 3 already wired)

Three files already contain the wiring. The exact text used at each:

**`agents/publisher.md` Step 7 (Update Issue Tracker):**
```
After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
```
Placement: immediately after "Set issue state: 'For Review'" bullet, before the closing of step 7.

**`core/block-handler.md` Step 2 (Set issue state):**
```
   After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
```
Placement: indented continuation of the step 2 bullet, after "Transition the issue to the Blocked state ... via the issue tracker MCP server."

**`skills/fix-ticket/SKILL.md` Step 1 (Set issue tracker):**
```
After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
```
Placement: immediately after the "Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server." line, before the dry-run note.

---

### Q1.1: implement-feature/SKILL.md — Step 1 insertion point

**Current text of Step 1 (lines 163–166):**
```
### 1. Set issue state

Read the issue from the issue tracker. Set the state per Feature Workflow → On start set
(fallback: Issue Tracker → On start set).

### 2. Create branch
```

**Finding:** Step 1 has no status-verification reference. It is a two-sentence prose paragraph — no sub-bullets. There is no existing "After the status-set MCP call" phrase anywhere in this step.

**Question:** Where exactly does the verification sentence go?
- Option A: Append as a third sentence to the paragraph (after "fallback: Issue Tracker → On start set).")
- Option B: Add as a new line/paragraph after the existing paragraph, before `### 2. Create branch`

**Answer:** The fix-ticket pattern appends the sentence as a standalone line immediately after the status-set instruction, before the next section. Option B is consistent with fix-ticket Step 1 structure. The new line should read:
```
After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
```
It should be placed after the closing parenthesis of "(fallback: Issue Tracker → On start set)." and before `### 2. Create branch`.

**Exact old_string for Edit tool:**
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

### Q1.2: core/fix-verification.md — Step 5 insertion point

**Current text of Steps 5 and 6:**
```
5. If command succeeds → post success comment to the issue:
   ```
   [ceos-agents] ✅ Fix verified. Verify command: `{command}`. Output: {first 500 chars}.
   ```
   Return `PASSED`.
6. If command fails → post failure comment to the issue:
   ```
   [ceos-agents] ❌ Fix verification failed.
   Command: `{command}`
   Output: {first 500 chars}
   ```
   If State transitions contains a re-open key → set the issue state back. Display: "Fix verification failed. Issue re-opened." Return `FAILED`.
```

**Finding:** Step 6 contains a state-set operation: "set the issue state back" when re-opening after failed verification. This is a status-set MCP call that currently has no verification hook.

**Question:** Does Step 5 also have a status-set call?
- Step 5 (success): Posts a comment. Does NOT set issue state — it only posts a comment. No status-set call.
- Step 6 (failure): Posts a comment AND conditionally sets state back (re-open). This IS a status-set call.

**Answer:** The verification sentence belongs in Step 6, immediately after "set the issue state back." The sentence should use conditional framing since the state-set only happens when "State transitions contains a re-open key."

**Exact old_string for Edit tool:**
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

### Q1.3: skills/fix-bugs/SKILL.md — Block handler Step 2 insertion point

**Current text of Block handler Step 2 (around line 644):**
```
2. **Set issue state to Blocked** (State transitions → Blocked)
```

**Finding:** Step 2 is a single-line bullet with no sub-bullets and no verification hook. The block-handler.md contract already has the pattern (as the contract itself was wired in v6.5.2). The fix-bugs Block handler section at step X is a local re-statement of the block protocol (it summarizes the contract inline rather than delegating fully to core/block-handler.md, though the section header says "Follow `core/block-handler.md` for the block protocol").

**Question:** Should the verification be added to the fix-bugs inline block handler Step 2, or is "Follow `core/block-handler.md` for the block protocol" sufficient since block-handler.md already has the wiring?

**Answer:** The `core/block-handler.md` already contains the verification hook at its Step 2. However, the fix-bugs Block handler section re-expands the protocol inline in numbered steps 1–8 without delegating verification. For consistent reading (human readers see fix-bugs SKILL.md without consulting block-handler.md), Step 2 of the inline expansion needs the verification line. Additionally, the TDD test markers check for `core/status-verification.md` in fix-bugs/SKILL.md directly.

**Exact old_string for Edit tool:**
```
2. **Set issue state to Blocked** (State transitions → Blocked)
```

**Exact new_string:**
```
2. **Set issue state to Blocked** (State transitions → Blocked)
   After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
```

---

### Q1.4: skills/scaffold/SKILL.md — Step 8b insertion point

**Current text of Step 8b (Transition logic):**
```
**Transition logic:**

1. Read all `spec/epics/*.md` files. Extract epic issue IDs from back-reference comments (`<!-- {TrackerType}: {ID} -->`).
2. Determine which epics are fully completed: an epic is complete if NONE of its subtasks (from architect decomposition) appear in the blocked features list (computed by Step 7 block handler).
3. For each fully-completed epic:
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config.
   b. Close each story sub-issue individually for ALL tracker types. Read story IDs from back-reference comments (`<!-- {TrackerType}: {STORY-ID} -->`) within the epic file. Transition each story issue to Done using the same `State transitions -> Done` syntax.
   c. If a story issue is already in the target Done state, treat it as success — do not emit a warning or error.
   d. On failure (epic or story transition): WARN (`Could not transition {issue_id} to Done: {error}`), continue to next.
4. For epics with blocked subtasks: skip. These remain open for manual triage.
5. Display: `Transitioned {N}/{M} epic issues and {S} story issues to Done. {skipped} epics skipped (blocked subtasks).`
```

**Finding:** Step 8b performs status-set MCP calls in items 3a and 3b. These are the state transitions to Done. There are potentially multiple calls per execution (one per epic, one per story), but the verification pattern applies to each status-set call.

**Question 1:** Should verification appear once in item 3a (epic transition) and once in item 3b (story transition), or as a single statement at the top of item 3?

**Answer:** The verification should be placed once after item 3b as a shared sub-item 3e (or as a note at item 3 level), since both 3a and 3b are status-set calls on each iteration. However, the simplest and most consistent approach with other wiring sites is to add the verification sentence after item 3b, as a continuation clause. Given the multi-call nature (both epic and story transitions), the verification sentence should reference "each status-set MCP call" to be precise.

**Question 2:** Does Step 8b's block handler also need wiring?
- Step 8b has no block — it uses WARN on failure (item 3d) and continues. No block handler dispatch.
- Step 8b does NOT call rollback-agent.
- Therefore only the state transition calls in items 3a/3b need verification.

**Exact old_string for Edit tool:**
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

### Q1.5: Summary — All 7 expected call sites post v6.6.0

| File | Step | Status (pre v6.6.0) | Notes |
|------|------|----------------------|-------|
| `agents/publisher.md` | Step 7 | Already wired (v6.5.2) | "For Review" transition |
| `core/block-handler.md` | Step 2 | Already wired (v6.5.2) | Blocked transition |
| `skills/fix-ticket/SKILL.md` | Step 1 | Already wired (v6.5.2) | On start set transition |
| `skills/implement-feature/SKILL.md` | Step 1 | **Needs wiring (v6.6.0)** | On start set transition |
| `core/fix-verification.md` | Step 6 | **Needs wiring (v6.6.0)** | Re-open transition (conditional) |
| `skills/fix-bugs/SKILL.md` | Block handler Step 2 | **Needs wiring (v6.6.0)** | Blocked transition (inline expansion) |
| `skills/scaffold/SKILL.md` | Step 8b items 3a, 3b | **Needs wiring (v6.6.0)** | Done transition (epic + stories) |

---

## Item 2: MCP Body Formatting Contract

### Q2.1: What are the 5 files with inline NEVER instructions?

From the test file `tests/scenarios/mcp-newline-handling.sh` (lines 14–20):

```bash
VULNERABLE_FILES=(
  "agents/publisher.md"
  "core/block-handler.md"
  "skills/fix-ticket/SKILL.md"
  "skills/implement-feature/SKILL.md"
  "skills/fix-bugs/SKILL.md"
)
```

The marker being tested is: `NEVER use the literal characters`

### Q2.2: Exact inline NEVER text in each of the 5 files

**`agents/publisher.md`** (Step 6, Description bullet, line 65):
```
Build the PR body as a multi-line string with real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```
And in Constraints (line 96):
```
NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is — escaped sequences like `\n` are rendered literally, not as newlines.
```
**Note:** publisher.md has TWO occurrences of the marker. The Constraints version is longer and more explanatory.

**`core/block-handler.md`** (Step 4, Post block comment, line 38):
```
When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators.
```

**`skills/fix-ticket/SKILL.md`** — Not yet read in full, but the marker is confirmed present by the test. Likely in the Block comment posting step.

**`skills/implement-feature/SKILL.md`** (Step 5a, Issue Description Template section, line 431):
```
When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```
And in Block handler Step 4 (line 635 area) — the inline Block comment section likely also has it.

**`skills/fix-bugs/SKILL.md`** (two occurrences found):
1. Sub-issue description (line 373): `When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.`
2. Block comment (line 661): `When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators.`

### Q2.3: What should the new `core/mcp-body-formatting.md` contract contain?

**Pattern from existing core contracts** (e.g., `core/status-verification.md`, `core/block-handler.md`):
- `## Purpose` — 1-2 sentence statement
- `## Input Contract` — table (or N/A)
- `## Process` — numbered steps
- `## Output Contract` — what the caller gets back
- `## Constraints` — NEVER rules
- `## Failure Handling` — table of failure modes

**For MCP Body Formatting, the contract should contain:**
- `## Purpose` — describe why real newlines matter (MCP passes parameter values as-is; literal `\n` renders as two characters, not a newline)
- `## Applies To` — list of MCP parameter types: PR descriptions, issue comments, issue bodies, block comments, sub-issue descriptions
- `## Rule` — one clear rule: use actual line breaks (real newlines), not escaped `\n` sequences
- `## Explanation` — how MCP tools receive parameters (Claude constructs the string; the tool sees exactly what was constructed; escaped `\n` is two literal characters `\` + `n`)
- `## Constraints` — NEVER rules listing the specific prohibited patterns

### Q2.4: How should the 5 files reference the new contract?

**Option A:** Replace each inline NEVER sentence with a short reference: `Follow `core/mcp-body-formatting.md` when constructing multi-line MCP parameters.`

**Option B:** Keep a brief inline reminder AND add a reference: `Use real line breaks — NEVER `\n` literals. See `core/mcp-body-formatting.md`.`

**Answer:** Option A (full replacement) is preferred for DRY consistency — the same approach used for status-verification (full delegation to the contract). However, the test file currently checks for the `NEVER use the literal characters` marker directly. If we replace the inline text with a contract reference, the existing test will FAIL unless we also update the test.

### Q2.5: Test file impact analysis

The test `tests/scenarios/mcp-newline-handling.sh` checks:
```bash
MARKER='NEVER use the literal characters'
```
in all 5 files. After centralization:
- If inline text is fully replaced → marker disappears from all 5 files → **test fails**
- The contract file itself (`core/mcp-body-formatting.md`) will contain `NEVER use the literal characters` but is NOT in the VULNERABLE_FILES list → **test still fails**

**Required test update:** The test must be updated to:
1. Check that `core/mcp-body-formatting.md` exists and contains the NEVER rule
2. Check that all 5 files contain a reference to `core/mcp-body-formatting.md`

OR alternatively: update the MARKER to `mcp-body-formatting.md` and update VULNERABLE_FILES to include the contract file too.

**Recommended approach:** Update `VULNERABLE_FILES` to check for `core/mcp-body-formatting.md` reference in the 5 files, and separately verify the contract file contains the NEVER rule. The existing T-013 test description should be updated to reflect the centralized contract approach.

### Q2.6: Does fix-ticket/SKILL.md also have inline NEVER text?

The test includes `skills/fix-ticket/SKILL.md` in VULNERABLE_FILES. It must have at least one instance of `NEVER use the literal characters`. This file was not read in detail during this research pass. The implementer must read it to find the exact text for replacement.

### Q2.7: Does `implement-feature/SKILL.md` Block handler Step 4 have inline NEVER text?

The implement-feature Block handler Step 4 (around lines 635–644) posts a block comment. The fix-bugs Block handler Step 4 explicitly has `NEVER use the literal characters`. The implement-feature Block handler is a local re-expansion of the protocol (same as fix-bugs). Likely YES — but this needs verification by reading lines 625–650 of implement-feature/SKILL.md.

**Finding from search:** The implement-feature SKILL.md marker was confirmed present by the test. The occurrence found in the file is at the sub-issue description (Step 5a line 431). There may also be one in the Block handler section (Step X). The implementer must grep for all occurrences.

### Q2.8: Scope of replacements — exact count

| File | Occurrences of NEVER marker | Location |
|------|------------------------------|----------|
| `agents/publisher.md` | 2 | Step 6 description bullet + Constraints section |
| `core/block-handler.md` | 1 | Step 4 comment posting |
| `skills/fix-ticket/SKILL.md` | Unknown (≥1) | Block comment posting (needs read) |
| `skills/implement-feature/SKILL.md` | ≥1 | Step 5a sub-issue description; possibly Block handler Step 4 |
| `skills/fix-bugs/SKILL.md` | 2 | Sub-issue description + Block handler comment |

**Total: at minimum 7 replacements across 5 files.**

---

## Item 2 Additional: Contract Structure Proposal

Based on the pattern from `core/status-verification.md` and `core/block-handler.md`:

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

## Rule

Construct multi-line strings with **actual line breaks** (real newlines in the source text).
NEVER use the literal two-character sequence `\n` as a line separator.

## Explanation

When Claude Code constructs a string and passes it to an MCP tool, the tool receives
the string value exactly as constructed. If the string contains `\n` (backslash + n),
the tool sees two literal characters — not a newline. The result is a single long line
with the characters `\n` embedded, which renders incorrectly in the issue tracker or
source control UI.

The correct approach: ensure the actual string value contains newline characters
(Unicode U+000A) between lines, not escape sequences.

## Constraints

- NEVER use `\n` as a line separator in any MCP parameter value
- NEVER concatenate field values with the string `"\n"` — use actual newlines
- NEVER interpolate `\n` inside template strings passed to MCP tools

## Failure Mode

There is no runtime failure — the MCP tool accepts the parameter and creates the
issue/comment/PR. The failure is visual: multi-line content appears as a single line
with literal `\n` characters visible to end users.
```

---

## Summary of Implementation Questions Answered

1. **implement-feature Step 1**: Add verification sentence as standalone line after the "On start set" paragraph, before `### 2. Create branch`.

2. **fix-verification Step 6**: Add verification sentence inline within the conditional re-open clause, immediately after "set the issue state back."

3. **fix-bugs Block handler Step 2**: Add verification sentence as indented sub-line under the "Set issue state to Blocked" bullet.

4. **scaffold Step 8b items 3a, 3b**: Add inline verification after each transition call (epic in 3a, story in 3b) — two separate insertions on the same sub-items.

5. **mcp-body-formatting.md**: New contract file covering all multi-line MCP parameters; test must be updated to check for contract reference (not inline NEVER text) in the 5 files.

6. **Test update required**: `tests/scenarios/mcp-newline-handling.sh` must be updated — the MARKER and/or check logic must change when inline NEVER text is replaced by contract references.

7. **fix-ticket/SKILL.md inline text**: Needs a targeted read to find exact replacement text — not yet confirmed from this research pass.
