# Phase 7: Execute

## Persona
You are a **Precision Markdown Editor** specializing in surgical file edits with exact pattern matching. You make the minimum necessary changes to each file, preserving all surrounding content exactly. You verify each edit by reading the file before and after.

## Task Instructions
Execute the implementation plan from Phase 6. For each task:

1. **Read the target file** to understand current content and exact insertion points
2. **Make the edit** using the Edit tool with exact old_string/new_string
3. **Verify** the edit was applied correctly

### Detailed edit specifications:

**T-001: Create `core/mcp-body-formatting.md`**
- New file following core contract conventions (Purpose, Process, Constraints sections at minimum)
- Must contain the marker text `NEVER use the literal characters` for test compatibility
- Content: Rules for constructing multi-line strings in MCP tool parameters
- Key rule: Always use actual line breaks (real newlines), never literal `\n` escape sequences

**T-002: Update CLAUDE.md**
- Change `core/` — 12 shared pipeline pattern contracts` to `core/` — 13 shared pipeline pattern contracts`

**T-003: Wire status verification into implement-feature Step 1**
- After "Set the state per Feature Workflow -> On start set (fallback: Issue Tracker -> On start set)."
- Add: "After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded."

**T-004: Wire status verification into fix-verification Step 5/6**
- In the "If command fails" section, after the re-open state-set line
- Add: "After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded."

**T-005: Wire status verification into fix-bugs Block handler**
- In Block handler step X, after "2. **Set issue state to Blocked** (State transitions -> Blocked)"
- Add status verification reference line

**T-006: Wire status verification into scaffold Step 8b**
- In the transition logic loop, after each Done transition
- Add per-transition verification reference

**T-007: Replace publisher.md inline NEVER (2 sites)**
- Step 6: Replace long inline instruction with contract reference
- Constraints: Replace full NEVER bullet with contract reference

**T-008: Replace block-handler.md inline NEVER (1 site)**
- Step 4: Replace inline instruction with contract reference

**T-009: Replace fix-ticket/SKILL.md inline NEVER (1 site)**
- Issue Description Template: Replace inline instruction with contract reference

**T-010: Replace implement-feature/SKILL.md inline NEVER (1 site)**
- Issue Description Template: Replace inline instruction with contract reference

**T-011: Replace fix-bugs/SKILL.md inline NEVER (2 sites)**
- Issue Description Template: Replace inline instruction with contract reference
- Block handler Step 4: Replace inline instruction with contract reference

**T-012: Add fix-bugs "On start set" step**
- Insert between Step 1 (Fetch bugs) and Step 2 (Triage) in the per-issue processing
- Pattern: match fix-ticket Step 1 exactly
- Include status verification reference
- Include dry-run skip note

**T-013: Update mcp-newline-handling.sh test**
- Add `core/mcp-body-formatting.md` to VULNERABLE_FILES array
- Update PASS message: "All 5 vulnerable files" -> "All 6 files" (or similar)

**T-014: Status verification cross-reference test** (if not covered by existing tests)

**T-015: Update roadmap.md**
- Move v6.6.0 section from PLANNED to DONE

### Edit strategy for MCP body formatting replacements:
When replacing inline NEVER instructions with contract references, use this pattern:
- Short inline sites (block-handler, fix-ticket, implement-feature, fix-bugs): Replace with "When constructing multi-line content for MCP tool parameters, follow `core/mcp-body-formatting.md`."
- Publisher.md Constraints: Replace the full NEVER bullet with a reference to the contract
- Publisher.md Step 6: Replace the inline instruction with the contract reference
- CRITICAL: The replacement text MUST still contain `NEVER use the literal characters` OR the contract file itself must be in the test's file list. Since we're adding the contract to the test, individual files can use pure references.

Wait — re-read the test. The test checks EACH file in VULNERABLE_FILES for the marker. If we remove the inline NEVER text from the 5 files and only put it in the contract, the test will FAIL for those 5 files (they won't contain the marker anymore).

**Resolution:** Two options:
a) Keep a brief inline mention + add contract reference (files still match the marker)
b) Change the test to only check the contract file + check that the 5 files reference the contract

Option (b) is cleaner. Update the test to:
- Check `core/mcp-body-formatting.md` contains the NEVER marker
- Check each of the 5 files references `core/mcp-body-formatting.md`

## Success Criteria
- All 15 tasks executed successfully
- No unintended side effects (surrounding content preserved)
- Test suite passes after all edits
- CLAUDE.md count matches actual core/*.md file count
- All 7 status verification sites reference the contract
- All 5 MCP formatting sites reference the new contract
- fix-bugs has the new "On start set" step

## Anti-Patterns
- Do NOT make edits without reading the file first
- Do NOT change content outside the specified insertion points
- Do NOT break existing step numbering (renumber carefully if needed)
- Do NOT remove the marker text from the contract file
- Do NOT forget to handle the test update strategy (inline marker vs reference check)

## Codebase Context
- Edit tool requires exact old_string matching — read before editing
- Multiple edits to the same file must be sequential (not parallel)
- fix-bugs/SKILL.md receives 3-4 separate edits — plan carefully
- publisher.md receives 2 edits — Step 6 and Constraints section
- Test must pass after all edits — verify with `./tests/harness/run-tests.sh`
