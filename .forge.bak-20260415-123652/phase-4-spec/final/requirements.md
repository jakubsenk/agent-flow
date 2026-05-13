# Phase 4 Specification — Requirements (EARS Format)

## v6.6.0: Status Verification Wiring + MCP Body Formatting Contract + fix-bugs On-Start-Set

Version: 1.0
Date: 2026-04-15
Classification: PATCH (no contract-breaking changes)

---

## Item 1: Status Verification Wiring

### REQ-SV-1: implement-feature status verification

**When** the implement-feature skill sets the issue state in Step 1,
**the system shall** include a verification reference sentence ("After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.") as a standalone paragraph after the state-set instruction and before `### 2. Create branch`.

**Verification:** `grep -q "status-verification.md" skills/implement-feature/SKILL.md` returns 0 AND the reference appears between Step 1 prose and the Step 2 heading.

### REQ-SV-2: fix-verification re-open status verification

**When** `core/fix-verification.md` Step 6 conditionally re-opens an issue,
**the system shall** include the verification reference sentence inline within the conditional clause, immediately after "set the issue state back" and before the Display instruction.

**Verification:** `grep -q "status-verification.md" core/fix-verification.md` returns 0.

### REQ-SV-3: fix-bugs block handler status verification

**When** the fix-bugs skill's inline block handler sets the issue state to Blocked in Step 2,
**the system shall** include the verification reference sentence as an indented continuation line after the Step 2 heading and before Step 3.

**Verification:** `grep -q "status-verification.md" skills/fix-bugs/SKILL.md` returns 0, with the match appearing in the block handler section.

### REQ-SV-4: scaffold status verification

**When** the scaffold skill's Step 8b transitions epics (item 3a) and stories (item 3b) to Done,
**the system shall** include the verification reference sentence inline after each transition instruction.

**Verification:** `grep -c "status-verification.md" skills/scaffold/SKILL.md` returns at least 2 (one for 3a, one for 3b).

### REQ-SV-5: Uniform reference phrasing

**For all** status verification references added in REQ-SV-1 through REQ-SV-4,
**the system shall** use the exact phrase "After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded." (or the continuation form "After each status-set MCP call" for 3b).

**Verification:** All 4 new sites use the canonical phrase. Manual review of edit strings.

---

## Item 2: MCP Body Formatting Contract

### REQ-MCP-1: Contract file creation

**The system shall** create a new file `core/mcp-body-formatting.md` containing exactly 5 sections: Purpose, Applies To, Process, Constraints, Failure Mode.

**Verification:** `test -f core/mcp-body-formatting.md` returns 0. Section headings verified by grep.

### REQ-MCP-2: Contract contains NEVER rule

**The system shall** ensure the contract file's Constraints section contains "NEVER use" as a marker phrase for test compatibility.

**Verification:** `grep -q "NEVER use" core/mcp-body-formatting.md` returns 0.

### REQ-MCP-3: Publisher Step 6 replacement (Replacement 1)

**When** the publisher agent constructs a PR body in Step 6,
**the system shall** replace the inline NEVER instruction with a contract reference: `follow \`core/mcp-body-formatting.md\``.

**Verification:** `grep -q "core/mcp-body-formatting.md" agents/publisher.md` returns 0. The old text "NEVER use the literal characters" no longer appears in the Step 6 sub-bullet.

### REQ-MCP-4: Publisher Constraints hybrid replacement (Replacement 2)

**When** the publisher agent's Constraints section references MCP body formatting,
**the system shall** replace the full inline NEVER explanation with a condensed NEVER + contract reference: `NEVER use \`\\n\` as a line separator in MCP tool parameters -- use actual newlines. See \`core/mcp-body-formatting.md\` for the full formatting rule.`

**Verification:** `grep -q "NEVER use" agents/publisher.md` returns 0 (the Constraints hybrid preserves the NEVER keyword). `grep -q "core/mcp-body-formatting.md" agents/publisher.md` returns 0. The old 3-sentence explanation is gone.

### REQ-MCP-5: block-handler replacement (Replacement 3)

**When** `core/block-handler.md` Step 4 instructs comment posting,
**the system shall** replace the inline NEVER instruction with: `Follow \`core/mcp-body-formatting.md\` when constructing the comment string.`

**Verification:** `grep -q "core/mcp-body-formatting.md" core/block-handler.md` returns 0. `grep -qc "NEVER use the literal characters" core/block-handler.md` returns 0 matches.

### REQ-MCP-6: fix-ticket replacement (Replacement 4)

**When** `skills/fix-ticket/SKILL.md` Step 4b-tracker constructs issue descriptions,
**the system shall** replace the inline NEVER instruction with: `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.`

**Verification:** `grep -q "core/mcp-body-formatting.md" skills/fix-ticket/SKILL.md` returns 0. `grep -qc "NEVER use the literal characters" skills/fix-ticket/SKILL.md` returns 0 matches.

### REQ-MCP-7: implement-feature replacement (Replacement 5)

**When** `skills/implement-feature/SKILL.md` Step 5a constructs issue descriptions,
**the system shall** replace the inline NEVER instruction with: `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.`

**Verification:** `grep -q "core/mcp-body-formatting.md" skills/implement-feature/SKILL.md` returns 0. `grep -qc "NEVER use the literal characters" skills/implement-feature/SKILL.md` returns 0 matches.

### REQ-MCP-8: fix-bugs replacements (Replacements 6 + 7)

**When** `skills/fix-bugs/SKILL.md` constructs issue descriptions (Step 3b-tracker) or block comments (block handler Step 4),
**the system shall** replace both inline NEVER instructions with contract references.

**Verification:** `grep -q "core/mcp-body-formatting.md" skills/fix-bugs/SKILL.md` returns 0. `grep -c "NEVER use the literal characters" skills/fix-bugs/SKILL.md` returns 0 matches.

### REQ-MCP-9: No remaining inline NEVER instructions

**After** all 7 replacements are applied,
**the system shall** ensure no file in agents/, core/, or skills/ contains the old marker phrase "NEVER use the literal characters `\n`" -- the rule now lives exclusively in `core/mcp-body-formatting.md`.

**Verification:** `grep -r "NEVER use the literal characters" agents/ core/ skills/` returns no matches.

### REQ-MCP-10: Test scenario update

**The system shall** update `tests/scenarios/mcp-newline-handling.sh` to:
1. Check that `core/mcp-body-formatting.md` contains "NEVER use" (Check A).
2. Check that all 5 previously-vulnerable files reference `core/mcp-body-formatting.md` (Check B).
3. Preserve the T-013 test tag.

**Verification:** Run the test; it passes. The test file contains both "NEVER use" and "core/mcp-body-formatting.md" as checked strings.

---

## Item 3: fix-bugs "On Start Set" Step

### REQ-FB-1: Step 1a insertion

**The system shall** insert a new step labeled `### 1a. Set issue tracker` in `skills/fix-bugs/SKILL.md` between Step 1 (Fetch bugs) and Step 2 (Triage).

**Verification:** `grep -q "### 1a. Set issue tracker" skills/fix-bugs/SKILL.md` returns 0.

### REQ-FB-2: Step 1a content

**The system shall** include in Step 1a:
1. The state-set instruction: "Set the state per Automation Config (Issue Tracker -> On start set)."
2. The MCP server selection: "Read Type for the correct MCP server."
3. The status verification reference: "After the status-set MCP call, follow `core/status-verification.md`..."
4. The dry-run annotation: "*In dry-run: skip this step.*"

**Verification:** All 4 elements present in the step text via grep.

### REQ-FB-3: Step 1a matches fix-ticket pattern

**The system shall** use wording consistent with fix-ticket Step 1, with no explicit guard clause for missing config keys and no separate failure note.

**Verification:** Manual review confirms no "skip silently" or "If the MCP call fails" language in Step 1a.

### REQ-FB-4: Worktree range update

**When** the fix-bugs worktree parallel dispatch describes the step range,
**the system shall** update "steps 2-8" to "steps 1a-8" to include the new step in per-bug parallel execution.

**Verification:** `grep -q "steps 1a" skills/fix-bugs/SKILL.md` returns 0. `grep -q "steps 2–8" skills/fix-bugs/SKILL.md` returns 1 (no match for old range).

---

## Post-Implementation Requirements

### REQ-POST-1: CLAUDE.md core count update

**The system shall** update the `core/` description in CLAUDE.md from "12 shared pipeline pattern contracts" to "13 shared pipeline pattern contracts".

**Verification:** `grep -q "13 shared pipeline pattern contracts" CLAUDE.md` returns 0.

### REQ-POST-2: Roadmap update

**After** implementation is complete and verified,
**the system shall** update `docs/plans/roadmap.md` to mark the v6.6.0 entry as DONE.

**Verification:** `grep -q "DONE" docs/plans/roadmap.md` in the v6.6.0 section returns 0.

### REQ-POST-3: All tests pass

**After** all changes are applied,
**the system shall** pass the full test suite (`tests/harness/run-tests.sh`).

**Verification:** Exit code 0 from `./tests/harness/run-tests.sh`.
