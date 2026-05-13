# Phase 4: Specification

## Persona
You are a **Plugin Contract Architect** specializing in declarative pipeline systems. You write formal specifications with machine-checkable acceptance criteria for markdown-based plugin changes.

## Task Instructions
Write a formal specification for v6.6.0 (v6.5.2 Follow-ups) covering 3 items:

### Item 1: Status Verification — Remaining Call Sites
**Requirement:** Wire `core/status-verification.md` advisory verification into 4 call sites:

A. `skills/implement-feature/SKILL.md` Step 1 — After the status-set call, add verification reference. Pattern: match fix-ticket Step 1.

B. `core/fix-verification.md` Step 5/6 — After the re-open status-set call (on verify failure), add verification reference. Note: this is inside a conditional (verify fails -> re-open). The verification applies to the re-open transition, not the verify command itself.

C. `skills/fix-bugs/SKILL.md` Block handler Step 2 — After "Set issue state to Blocked", add verification reference. Pattern: match core/block-handler.md Step 2.

D. `skills/scaffold/SKILL.md` Step 8b — After each epic/story Done transition in the loop, add verification reference. Note: this step transitions MULTIPLE issues in a loop. Verification should apply per-transition.

### Item 2: MCP Body Formatting Contract
**Requirement:** Create `core/mcp-body-formatting.md` and replace inline instructions.

A. New core contract with standard sections (Purpose, Process, Constraints at minimum). Must contain the marker text `NEVER use the literal characters` for test compatibility.

B. Replace inline instructions in 5 files with references to the contract:
   - `agents/publisher.md` — TWO sites: Step 6 (PR description) and Constraints section
   - `core/block-handler.md` — Step 4 (block comment)
   - `skills/fix-ticket/SKILL.md` — Issue Description Template section
   - `skills/implement-feature/SKILL.md` — Issue Description Template section
   - `skills/fix-bugs/SKILL.md` — TWO sites: Issue Description Template + Block handler Step 4

C. Update `CLAUDE.md` core count: `core/` line in Repository Structure from "12 shared" to "13 shared"

D. Update test `tests/scenarios/mcp-newline-handling.sh`:
   - Add `core/mcp-body-formatting.md` to VULNERABLE_FILES array
   - Update count in PASS message from "5" to "6"
   - Keep checking ALL existing 5 files (they must still contain the marker via contract reference or inline)

### Item 3: fix-bugs "On start set" Step
**Requirement:** Add per-issue "On start set" step in the fix-bugs per-issue loop.

- Insert as Step 1a (between Step 1 "Fetch bugs" and Step 2 "Triage") — or as a sub-step within the per-issue processing before triage
- Set issue state per `Issue Tracker -> On start set` from Automation Config
- Include status verification reference
- Include state.json update
- In dry-run mode: skip this step (no issue tracker changes)
- Pattern: match fix-ticket Step 1

### Formal Acceptance Criteria (machine-checkable)

For each criterion, provide:
- Criterion ID (AC-1, AC-2, ...)
- Description
- Verification command (grep, file existence check, or structural test)

## Success Criteria
- All 4 status verification sites have explicit insertion point descriptions
- MCP body formatting contract structure is fully specified
- All 5+2 replacement sites (5 files, publisher has 2 sites) are specified
- fix-bugs step placement is unambiguous
- Every AC has a machine-checkable verification command
- Test scenario update is fully specified (new file in array, new count)

## Anti-Patterns
- Do NOT leave any insertion point ambiguous ("somewhere in Step 1" — specify EXACTLY where)
- Do NOT forget publisher.md has TWO separate inline NEVER instructions
- Do NOT forget fix-bugs/SKILL.md has TWO separate inline NEVER instructions (template + block handler)
- Do NOT create an AC that requires manual reading to verify (all must be grep-able or script-checkable)
- Do NOT change the marker text — the test depends on `NEVER use the literal characters`

## Codebase Context
- Core contract section convention: Purpose, Input Contract, Process, Output Contract, Constraints, Failure Handling
- Status verification reference: "After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded."
- MCP formatting inline (short): "use real line breaks between sections — NEVER use the literal characters `\n` as line separators."
- MCP formatting inline (full, publisher Constraints): "NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always construct multi-line strings with actual line breaks (real newlines). The MCP tool receives the parameter value as-is — escaped sequences like `\n` are rendered literally, not as newlines."
- fix-ticket Step 1 (template for fix-bugs): "Set the state per Automation Config (Issue Tracker -> On start set). Read Type for the correct MCP server.\n\nAfter the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.\n\n*In dry-run: skip this step.*"
- Current core/*.md files: 12 (agent-override-injector, block-handler, config-reader, decomposition-heuristics, fix-verification, fixer-reviewer-loop, mcp-detection, mcp-preflight, post-publish-hook, profile-parser, state-manager, status-verification)
