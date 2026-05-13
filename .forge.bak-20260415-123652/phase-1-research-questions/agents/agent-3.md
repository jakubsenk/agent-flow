# Research Questions — Agent 3: Core Contract Structure & Test Infrastructure

## Area of Focus
Core contract pattern analysis, test scenario structure, existing inline NEVER instructions, and cross-reference integrity for the v6.6.0 implementation.

---

## 1. Core Contract Structure

### Q3-01: What is the canonical section order for core contracts?
**Finding from `core/status-verification.md` (most recent):**
The exact order is: `## Purpose`, `## Input Contract`, `## Process`, `## Output Contract`, `## Constraints`, `## Failure Handling`. Not all sections are required — `status-verification.md` has all six. `fix-verification.md` uses `## Purpose`, `## Input Contract`, `## Process`, `## Output Contract`, `## Failure Handling` (no `## Constraints` section). The new `core/mcp-body-formatting.md` contract should include all six canonical sections.

### Q3-02: How does Input Contract use tables vs bullet lists?
**Finding:** Two patterns exist in the corpus:
- **Table format** (used in `status-verification.md`, `fixer-reviewer-loop.md`): `| Field | Type | Notes |` with each input as a row.
- **Bullet format** (used in `mcp-preflight.md`, `mcp-detection.md`, `fix-verification.md`): `- **field_name** (type, required/optional): description`

For `core/mcp-body-formatting.md`, which format is preferred? Given that MCP body formatting has no structured input fields (it's a behavioral constraint, not a data-flow contract), should the Input Contract section be omitted or replaced with a `## Applies To` section listing the caller contexts?

### Q3-03: What is the correct Output Contract format for a behavioral-constraint-only contract?
**Finding from `core/status-verification.md`:**
```
## Output Contract
Log-only. No return value. No state.json write. No issue tracker modification.
```
**Question:** For `core/mcp-body-formatting.md`, the output contract is similarly behavioral (callers format their strings correctly — no return value). Should the Output Contract say "No return value. Callers apply the rule inline before constructing MCP tool parameters" or is a simpler statement sufficient?

### Q3-04: Does `core/mcp-body-formatting.md` need a Constraints section?
**Finding from `core/status-verification.md`:** Constraints uses NEVER rules:
```
- NEVER block the pipeline on verification failure — always continue
- NEVER retry the status-set call — verification is advisory only
```
**Question:** For MCP body formatting, the Constraints section would be the core rule itself (NEVER use `\n`). Should the Constraints section contain the primary NEVER rule, with Process explaining how to apply it, or should the NEVER rule appear only in Process?

### Q3-05: What phrase do callers use to reference the new contract?
**Finding:** `block-handler.md` Step 2 references status-verification with:
> "After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded."

The replacement phrase for the inline NEVER instructions should follow this same convention. The proposed replacement is:
> "When constructing multi-line MCP tool parameters, follow `core/mcp-body-formatting.md`."

**Question:** Is this the exact phrase to use, or should it be more specific, e.g., "For PR description and issue comment formatting, follow `core/mcp-body-formatting.md`"?

---

## 2. Test Scenario Structure

### Q3-06: What does `tests/scenarios/mcp-newline-handling.sh` currently check?
**Finding — full scenario analysis:**
- **Grep marker used:** `'NEVER use the literal characters'` (exact string, case-sensitive)
- **VULNERABLE_FILES array (5 files):**
  1. `agents/publisher.md`
  2. `core/block-handler.md`
  3. `skills/fix-ticket/SKILL.md`
  4. `skills/implement-feature/SKILL.md`
  5. `skills/fix-bugs/SKILL.md`
- **PASS message:** `"PASS: All 5 vulnerable files contain MCP newline-safe output instruction (T-013)"`
- **Logic:** Loops over VULNERABLE_FILES, checks each for the marker with `grep -q`. Fails if file not found or marker missing.

### Q3-07: What must change in `mcp-newline-handling.sh` after extracting to a core contract?
**Finding:** After creating `core/mcp-body-formatting.md`:

**Option A — Add core file to VULNERABLE_FILES (file existence + marker check):**
- Add `"core/mcp-body-formatting.md"` to VULNERABLE_FILES
- The core file must contain the `NEVER use the literal characters` marker text
- PASS message changes from `"All 5 vulnerable files"` to `"All 6 vulnerable files"`

**Option B — Separate existence check for the core file:**
- Keep VULNERABLE_FILES at 5 (the inline sites are replaced by references, so marker no longer present there)
- Add a separate existence check for `core/mcp-body-formatting.md`
- Replace the per-file marker check logic with: skill files contain the reference phrase, core file contains the NEVER marker

**Critical question:** After the refactor, do the 5 skill/agent files STILL contain `NEVER use the literal characters`, or does the inline instruction get REPLACED by a reference like "follow `core/mcp-body-formatting.md`"? If replaced, Option A breaks (marker gone from the 5 files). If the test checks only the core file for the marker, the VULNERABLE_FILES array must be updated or the test logic must change.

### Q3-08: Does the xref-core-registry test need updating?
**Finding from `tests/scenarios/xref-core-registry.sh`:**
- Dynamically counts `core/*.md` files on disk (no hardcoded count)
- Checks that each core file is referenced by at least one SKILL.md
- Checks that CLAUDE.md count matches the filesystem count

**Impact:** Adding `core/mcp-body-formatting.md` means:
1. Core file count automatically becomes 13 on disk
2. CLAUDE.md line `core/ — 12 shared pipeline pattern contracts` must be updated to `13`
3. The new core file must be referenced by at least one SKILL.md (the test will fail if it isn't)

**Question:** Which SKILL.md files will reference `core/mcp-body-formatting.md`? The refactor replaces inline instructions in `skills/fix-ticket/SKILL.md`, `skills/implement-feature/SKILL.md`, and `skills/fix-bugs/SKILL.md` — these will contain the reference phrase. But will `agents/publisher.md` and `core/block-handler.md` also use the reference phrase? If so, the xref check searches only `skills/` directory — agent files and other core files are NOT searched. The core file must be referenced by at least one SKILL.md or the test fails.

---

## 3. Enumeration of Core Files (Verification)

### Q3-09: Current core file count confirmed as 12?
**Finding from `ls core/`:**
```
agent-override-injector.md
block-handler.md
config-reader.md
decomposition-heuristics.md
fix-verification.md
fixer-reviewer-loop.md
mcp-detection.md
mcp-preflight.md
post-publish-hook.md
profile-parser.md
state-manager.md
status-verification.md
```
Count: **12 files** — confirmed. Adding `core/mcp-body-formatting.md` brings the count to **13**.

---

## 4. MCP Inline NEVER Instructions — Exact Text Found

### Q3-10: What is the exact NEVER instruction in `agents/publisher.md`?

**Location:** Step 6 (Create Pull Request) and Constraints section.

**Step 6 (line 65):**
> "Build the PR body as a multi-line string with real line breaks between sections — NEVER use the literal characters `\n` as line separators."

**Constraints section (line 96):**
> "NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is — escaped sequences like `\n` are rendered literally, not as newlines."

**Question:** The Constraints version is more detailed than the Step 6 version. When replacing with a reference to `core/mcp-body-formatting.md`, which version gets the reference? Both? Or does Step 6 keep a condensed inline note and only Constraints gets the reference?

### Q3-11: What is the exact NEVER instruction in `core/block-handler.md`?

**Location:** Step 4 (Post block comment), end of code block.

**Exact text (line 38):**
> "When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators."

**Question:** This is a single inline sentence following the code block. The replacement reference should be a single sentence or inline note. Proposed: remove this sentence and replace the step ending with "Follow `core/mcp-body-formatting.md` when constructing the comment string."

### Q3-12: What is the exact NEVER instruction in `skills/fix-ticket/SKILL.md`?

**Location:** Step 4b-tracker (subtask creation), after the issue description code block.

**Exact text (line 386):**
> "When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators."

**Question:** This sentence is a standalone note after a multi-line template block. The replacement reference should follow the same single-sentence pattern.

### Q3-13: What is the exact NEVER instruction in `skills/implement-feature/SKILL.md`?

**Location:** Step 5a (Decomposition — create subtasks), after the issue description code block.

**Exact text (line 431):**
> "When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators."

**Finding:** Identical wording to fix-ticket Step 4b-tracker. Both files use this instruction in the decomposition subtask creation step. The replacement pattern will be identical in both files.

### Q3-14: What are the exact NEVER instructions in `skills/fix-bugs/SKILL.md`?

**Location 1:** Step 3b (decomposition subtask creation), after code block — line 373:
> "When passing the issue description to the MCP create-issue tool, use real line breaks between sections — NEVER use the literal characters `\n` as line separators."

**Location 2:** Block comment Step 4 (inline block handler in fix-bugs), line 661:
> "When posting this comment via MCP, use real line breaks between fields — NEVER use the literal characters `\n` as line separators."

**Finding:** fix-bugs has TWO occurrences of the marker, not one. The test `grep -q` returns true if either is found, so both must be replaced or one kept for the test to remain valid. If both are replaced with references, the test must update to check for the reference phrase instead of the old marker.

---

## 5. Cross-Reference Integrity Questions

### Q3-15: What other tests might be affected by the core count change?
**Finding:** `tests/scenarios/xref-core-registry.sh` dynamically counts `core/*.md` files and validates the CLAUDE.md claim. No hardcoded count in that test. However, `xref-command-count.sh` checks skill/agent counts — not affected by core count.

**The only hardcoded count is in `CLAUDE.md` line:**
> `` `core/` — 12 shared pipeline pattern contracts ``

This must be updated to `13`.

### Q3-16: Does the PASS message in `mcp-newline-handling.sh` need to update?
**Current:** `"PASS: All 5 vulnerable files contain MCP newline-safe output instruction (T-013)"`

If the core file is added to VULNERABLE_FILES, the message must change to `"All 6 vulnerable files"`. If the test logic changes to check reference phrase instead of NEVER marker, the message should describe the new check. The T-013 tag should be preserved.

### Q3-17: Is `core/mcp-body-formatting.md` referenced by a skill (required by xref-core-registry)?
**Critical finding:** `tests/scenarios/xref-core-registry.sh` searches only `skills/` directory for references. Since `skills/fix-ticket/SKILL.md`, `skills/implement-feature/SKILL.md`, and `skills/fix-bugs/SKILL.md` will all reference `core/mcp-body-formatting.md`, the xref test will pass automatically. No additional action needed for this test — but the CLAUDE.md count update (Q3-15) is still required.

---

## Summary of Key Findings

| Question | Finding |
|----------|---------|
| Core section order | Purpose → Input Contract → Process → Output Contract → Constraints → Failure Handling |
| Current core file count | 12 (confirmed by `ls core/`) |
| New count after addition | 13 |
| CLAUDE.md line to update | `` `core/` — 12 shared pipeline pattern contracts `` → 13 |
| Test marker (current) | `'NEVER use the literal characters'` |
| Test VULNERABLE_FILES count | 5 files |
| fix-bugs occurrences of marker | 2 locations (Step 3b + block handler Step 4) |
| publisher.md occurrences | 2 locations (Step 6 inline + Constraints section) |
| block-handler.md occurrences | 1 location (Step 4 post-comment note) |
| fix-ticket/SKILL.md occurrences | 1 location (Step 4b-tracker) |
| implement-feature/SKILL.md occurrences | 1 location (Step 5a) |
| xref-core-registry test impact | Auto-passes if any SKILL.md references new core file; CLAUDE.md count must be updated |
