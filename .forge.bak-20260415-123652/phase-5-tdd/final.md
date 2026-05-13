# Phase 5: TDD — Final Summary

## v6.6.0: Status Verification Wiring + MCP Body Formatting Contract + fix-bugs On-Start-Set

Date: 2026-04-15

---

## Test Changes

### Updated: `tests/scenarios/mcp-newline-handling.sh`

**Source:** `.forge/phase-5-tdd/tests/mcp-newline-handling.sh`
**Destination:** `tests/scenarios/mcp-newline-handling.sh` (overwrite during execution)

**Reason for rewrite:** The v6.6.0 MCP body formatting contract (REQ-MCP-1 through REQ-MCP-10) changes the structural enforcement model. Instead of embedding the NEVER rule in each of the 5 vulnerable files, the rule is centralised in `core/mcp-body-formatting.md`. The old test checked for the inline marker in each file — after the change, those markers are gone, so the old test would false-pass on pre-change files and false-fail on post-change files.

**Old behaviour (pre-v6.6.0):**
- Checked 5 files (`agents/publisher.md`, `core/block-handler.md`, `skills/fix-ticket/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/fix-bugs/SKILL.md`) for the literal string `NEVER use the literal characters`.

**New behaviour (post-v6.6.0):**
- **Check A:** Verifies `core/mcp-body-formatting.md` exists AND contains `NEVER use` (AC-1 + AC-2).
- **Check B:** Verifies all 5 previously-vulnerable files contain a reference to `core/mcp-body-formatting.md` (AC-4).

**Preserved:** T-013 tag, `set -euo pipefail`, FAIL counter pattern, same 5-file list.

---

## Tests NOT Created

### `xref-core-registry.sh` — no change needed

`tests/scenarios/xref-core-registry.sh` dynamically counts files in `core/` and compares against the number claimed in CLAUDE.md. When `core/mcp-body-formatting.md` is added and CLAUDE.md is updated from "12" to "13" (AC-6 / REQ-POST-1), this test will automatically catch any mismatch without modification. Creating a new test for AC-6 would duplicate this existing coverage.

### `xref-status-verification.sh` — explicitly rejected

The brainstorm phase considered a dedicated test to scan all 4 status verification call sites for the reference phrase. This was rejected (Brainstorm Decision 2) as scope creep: the 4 sites are content additions to existing files, and their correctness is already enforced by the AC-3/AC-7 verification commands documented in `formal-criteria.md`. A grep-based test scanning for a canonical phrase across specific files adds maintenance burden (fragile to phrase changes) with no coverage gain over the acceptance criteria verification commands.

---

## Test Coverage Map

| AC | Description | Covered by |
|----|-------------|------------|
| AC-1 | Contract file exists | `mcp-newline-handling.sh` Check A |
| AC-2 | Contract contains NEVER rule | `mcp-newline-handling.sh` Check A |
| AC-3 | 4 status verification sites wired | Acceptance criteria verification (not a scenario test) |
| AC-4 | 5 MCP files contain contract reference | `mcp-newline-handling.sh` Check B |
| AC-5 | No remaining old inline NEVER instructions | Acceptance criteria verification (not a scenario test) |
| AC-6 | CLAUDE.md core count = 13 | `xref-core-registry.sh` (existing, no change needed) |
| AC-7 | fix-bugs Step 1a with all 4 elements | Acceptance criteria verification (not a scenario test) |
| AC-8 | fix-bugs worktree range = 1a-8 | Acceptance criteria verification (not a scenario test) |
| AC-9 | Test scenario updated with dual checks | Self-referential — satisfied by this rewrite |
| AC-10 | All tests pass | `tests/harness/run-tests.sh` |
| AC-11 | Roadmap updated to DONE | Post-implementation step |
