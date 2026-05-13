# Phase 4 Specification — Architecture & Design

## v6.6.0: Status Verification Wiring + MCP Body Formatting Contract + fix-bugs On-Start-Set

Version: 1.0
Date: 2026-04-15

---

## File Change Inventory

| # | File | Change Type | Item |
|---|------|-------------|------|
| 1 | `core/mcp-body-formatting.md` | CREATE NEW | MCP contract |
| 2 | `agents/publisher.md` | EDIT (2x) | MCP Replacements 1 + 2 |
| 3 | `core/block-handler.md` | EDIT | MCP Replacement 3 |
| 4 | `skills/fix-ticket/SKILL.md` | EDIT | MCP Replacement 4 |
| 5 | `skills/implement-feature/SKILL.md` | EDIT (2x) | MCP Replacement 5 + SV Insertion 1 |
| 6 | `skills/fix-bugs/SKILL.md` | EDIT (4x) | MCP Replacements 6+7 + SV Insertion 3 + Step 1a + Worktree range |
| 7 | `core/fix-verification.md` | EDIT | SV Insertion 2 |
| 8 | `skills/scaffold/SKILL.md` | EDIT | SV Insertion 4 |
| 9 | `CLAUDE.md` | EDIT | Core count 12 -> 13 |
| 10 | `tests/scenarios/mcp-newline-handling.sh` | EDIT | Test update (Check A + Check B) |
| 11 | `docs/plans/roadmap.md` | EDIT | v6.6.0 PLANNED -> DONE |

**Total: 1 new file + 10 edits across 10 existing files.**

---

## Part A: New File — `core/mcp-body-formatting.md`

### Content (5 sections, per brainstorm Decision 1)

```markdown
# MCP Body Formatting

## Purpose

Prevent literal `\n` escape sequences from appearing in MCP tool parameters that accept
multi-line text. MCP tools receive parameter values as-is from the calling model --
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

## Constraints

- NEVER use `\n` as a line separator in any MCP parameter value
- NEVER concatenate field values with the string `"\n"` -- use actual newlines
- NEVER interpolate `\n` inside template strings passed to MCP tools

## Failure Mode

There is no runtime failure -- the MCP tool accepts the parameter and creates the
issue/comment/PR. The failure is visual: multi-line content appears as a single line
with literal `\n` characters visible to end users in the issue tracker or source control UI.
```

### Design Rationale

- **5 sections** (not 4, not 6+): Minimalist core (Purpose, Applies To, Process, Constraints) plus Failure Mode kept as a separate section because the failure is non-obvious (visual, not runtime) and is the primary motivation for the contract. Output Contract omitted because the contract has no return value -- absence communicates this more clearly than "N/A". No Detection section -- operational guidance belongs in contributor docs, not pipeline contracts.
- **Double-dash** (`--`) used instead of em-dash in the contract file content per the brainstorm final revision. The research Phase 2 used em-dashes; the brainstorm explicitly revised to double-dashes.

---

## Part B: MCP Replacements (7 edits across 5 files)

### Replacement 1 -- `agents/publisher.md` Step 6 sub-bullet

**old_string:**
```
  - Build the PR body as a multi-line string with real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

**new_string:**
```
  - Build the PR body as a multi-line string with real line breaks between sections — follow `core/mcp-body-formatting.md`.
```

### Replacement 2 -- `agents/publisher.md` Constraints section (DX hybrid)

Per brainstorm Decision 1: the publisher.md Constraints replacement uses a condensed NEVER + contract reference, preserving the NEVER-scanning convention.

**old_string:**
```
- NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is — escaped sequences like `\n` are rendered literally, not as newlines.
```

**new_string:**
```
- NEVER use `\n` as a line separator in MCP tool parameters -- use actual newlines. See `core/mcp-body-formatting.md` for the full formatting rule.
```

### Replacement 3 -- `core/block-handler.md` Step 4 post-template note

**old_string:**
```
   When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators.
```

**new_string:**
```
   Follow `core/mcp-body-formatting.md` when constructing the comment string.
```

### Replacement 4 -- `skills/fix-ticket/SKILL.md` Step 4b-tracker

**old_string:**
```
    - When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

**new_string:**
```
    - Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters.
```

### Replacement 5 -- `skills/implement-feature/SKILL.md` Step 5a

**old_string:**
```
When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

**new_string:**
```
Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters.
```

### Replacement 6 -- `skills/fix-bugs/SKILL.md` Step 3b-tracker

**old_string:**
```
When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators.
```

**new_string:**
```
Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters.
```

### Replacement 7 -- `skills/fix-bugs/SKILL.md` Block handler Step 4 post-template

**old_string:**
```
When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators.
```

**new_string:**
```
Follow `core/mcp-body-formatting.md` when constructing the comment string.
```

---

## Part C: Status Verification Wiring (4 insertions)

All 4 insertions use the canonical phrase: "After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded."

### SV Insertion 1 -- `skills/implement-feature/SKILL.md` Step 1

**old_string:**
```
Read the issue from the issue tracker. Set the state per Feature Workflow → On start set
(fallback: Issue Tracker → On start set).

### 2. Create branch
```

**new_string:**
```
Read the issue from the issue tracker. Set the state per Feature Workflow → On start set
(fallback: Issue Tracker → On start set).

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

### 2. Create branch
```

### SV Insertion 2 -- `core/fix-verification.md` Step 6

**old_string:**
```
   If State transitions contains a re-open key → set the issue state back. Display: "Fix verification failed. Issue re-opened." Return `FAILED`.
```

**new_string:**
```
   If State transitions contains a re-open key → set the issue state back. After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded. Display: "Fix verification failed. Issue re-opened." Return `FAILED`.
```

### SV Insertion 3 -- `skills/fix-bugs/SKILL.md` Block handler Step 2

**old_string:**
```
2. **Set issue state to Blocked** (State transitions → Blocked)

3. **On block action** (per Error Handling → On block):
```

**new_string:**
```
2. **Set issue state to Blocked** (State transitions → Blocked)
   After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

3. **On block action** (per Error Handling → On block):
```

### SV Insertion 4 -- `skills/scaffold/SKILL.md` Step 8b items 3a and 3b

**old_string:**
```
3. For each fully-completed epic:
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config.
   b. Close each story sub-issue individually for ALL tracker types. Read story IDs from back-reference comments (`<!-- {TrackerType}: {STORY-ID} -->`) within the epic file. Transition each story issue to Done using the same `State transitions -> Done` syntax.
   c. If a story issue is already in the target Done state, treat it as success — do not emit a warning or error.
   d. On failure (epic or story transition): WARN (`Could not transition {issue_id} to Done: {error}`), continue to next.
```

**new_string:**
```
3. For each fully-completed epic:
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config. After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
   b. Close each story sub-issue individually for ALL tracker types. Read story IDs from back-reference comments (`<!-- {TrackerType}: {STORY-ID} -->`) within the epic file. Transition each story issue to Done using the same `State transitions -> Done` syntax. After each status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
   c. If a story issue is already in the target Done state, treat it as success — do not emit a warning or error.
   d. On failure (epic or story transition): WARN (`Could not transition {issue_id} to Done: {error}`), continue to next.
```

---

## Part D: fix-bugs Step 1a (insertion + worktree range)

### Step 1a Insertion

**old_string:**
```
### 1. Fetch bugs
Use Bug query from Automation Config via the MCP server matching Type. Limit = count from $ARGUMENTS.

### 2. Triage (parallel — triage is read-only, parallelism does not depend on worktree configuration)
```

**new_string:**
```
### 1. Fetch bugs
Use Bug query from Automation Config via the MCP server matching Type. Limit = count from $ARGUMENTS.

### 1a. Set issue tracker

Set the state per Automation Config (Issue Tracker → On start set). Read Type for the correct MCP server.

After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

*In dry-run: skip this step.*

### 2. Triage (parallel — triage is read-only, parallelism does not depend on worktree configuration)
```

### Design Notes

- **Label "1a"**: Preserves all existing step numbers (triage=2, code-analyst=3, etc.). No renumbering cascade.
- **No guard clause**: Matches fix-ticket Step 1 behavior. If "On start set" is not configured, there is nothing to set. Implicit skip.
- **No failure note**: Redundant with `core/status-verification.md` referenced in the same step.
- **Dry-run annotation**: Matches fix-ticket pattern. Step 1a makes an issue tracker state change, so it is skipped in dry-run mode.

### Worktree Range Update

**old_string:**
```
3. Run the pipeline (steps 2–8) for EVERY bug in the batch IN PARALLEL:
```

**new_string:**
```
3. Run the pipeline (steps 1a–8) for EVERY bug in the batch IN PARALLEL:
```

Step 1a is a per-bug step that executes within each parallel Task, not a global step. It must be included in the worktree dispatch range.

---

## Part E: CLAUDE.md Core Count Update

**old_string:**
```
- `core/` — 12 shared pipeline pattern contracts
```

**new_string:**
```
- `core/` — 13 shared pipeline pattern contracts
```

---

## Part F: Test Scenario Update -- `tests/scenarios/mcp-newline-handling.sh`

The existing test checks for "NEVER use the literal characters" in 5 files. After v6.6.0, this marker no longer appears in those files. The test must be rewritten with two checks.

### New Test Logic

**Check A** -- Contract file contains the NEVER rule:
```bash
CONTRACT="core/mcp-body-formatting.md"
if ! grep -q "NEVER use" "$CONTRACT"; then
  echo "FAIL: $CONTRACT missing NEVER rule"
  FAIL=1
fi
```

**Check B** -- All 5 files reference the contract:
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

**PASS message:** `"PASS: All 5 files reference core/mcp-body-formatting.md and contract contains NEVER rule (T-013)"`

The T-013 tag is preserved on both PASS and FAIL messages.

No dynamic scan (Check C) is added -- rejected per brainstorm Decision 2. The hardcoded file list is sufficient for the 5 known files.

---

## Part G: Roadmap Update

After all changes are implemented and tests pass, update `docs/plans/roadmap.md`:
- Change `## PLANNED — v6.6.0` to `## DONE — v6.6.0` (or equivalent marker per roadmap conventions).

---

## Edit Application Order

Edits to `skills/fix-bugs/SKILL.md` have 4 independent changes. To avoid overlapping old_string contexts, apply in document order (by line number):

1. Step 1a insertion (after Step 1, before Step 2) -- approx line 340
2. MCP Replacement 6 (Step 3b-tracker) -- approx line 373
3. MCP Replacement 7 (block handler Step 4) -- approx line 661
4. SV Insertion 3 (block handler Step 2) -- approx line 648
5. Worktree range update -- approx line 697

Edits to `skills/implement-feature/SKILL.md` have 2 independent changes:

1. SV Insertion 1 (Step 1) -- early in file
2. MCP Replacement 5 (Step 5a) -- approx line 431

All other files have single edits and can be applied in any order.

---

## What Is NOT Changing

- No new test files (no `xref-status-verification.sh`).
- No changes to `docs/reference/skills.md` (no step-number enumeration for fix-bugs).
- No changes to `skills/resume-ticket/SKILL.md` (references fix-ticket steps, not fix-bugs).
- No changes to `checklists/` (no step-number references).
- No changes to `tests/scenarios/xref-core-registry.sh` (dynamic discovery auto-detects new core file; CLAUDE.md count update satisfies its check).
- No guard clause or failure note in Step 1a.
- No backport of guard clause to fix-ticket Step 1.
