# v5.6.1 UX Polish — Formal Acceptance Criteria

## FC-1: Test Suite Passes

**Criterion:** `./tests/harness/run-tests.sh` passes with 0 failures.

**Verification method:** Run the test suite from the repository root. All existing tests must pass. No new tests are required for v5.6.1 (changes are to markdown instruction text, not structural).

**Pass condition:** Exit code 0, all scenarios PASS.

---

## FC-2: No MCP Jargon in User-Facing Error Messages

**Criterion:** The phrase "MCP server for {Type} is not available" does not appear in any command file's user-facing error message.

**Verification method:**
```bash
grep -rn "MCP server for.*is not available" commands/ core/mcp-preflight.md
```
Expected output: 0 matches.

**Scope of "user-facing":** Error messages displayed to the user via STOP, Display, or Block comment output. Excludes:
- Agent dispatch context strings (e.g., `Context: "Use the MCP server for {Type}."`) — these are internal instructions
- `/check-setup` diagnostic output — technical tool, MCP terminology appropriate
- `/init` configuration context — technical tool
- Historical plan documents in `docs/plans/`
- Test harness files

**Allowed exceptions (NOT user-facing, keep as-is):**
- `commands/fix-ticket.md` lines 123, 333 — agent dispatch context
- `commands/fix-bugs.md` lines 99, 321 — agent dispatch context
- `commands/publish.md` line 24 — agent dispatch context
- `commands/check-setup.md` all lines — diagnostic tool
- `commands/init.md` all lines — configuration tool
- `agents/triage-analyst.md` line 110 — agent constraint
- `core/mcp-detection.md` — internal contract (no user-facing strings)

**Files that MUST be updated:**
1. `commands/analyze-bug.md`
2. `commands/changelog.md`
3. `commands/create-pr.md`
4. `commands/dashboard.md`
5. `commands/estimate.md`
6. `commands/fix-bugs.md` (line 80 only)
7. `commands/metrics.md`
8. `commands/prioritize.md`
9. `commands/publish.md` (line 15 only)
10. `commands/resume-ticket.md`
11. `commands/scaffold-add.md`
12. `commands/status.md`
13. `commands/scaffold.md` (lines 146, 158-160, 163, 750-751)
14. `commands/implement-feature.md` (lines 72-74, 76, 146)
15. `core/mcp-preflight.md` (lines 34, 36, 43)

---

## FC-3: --infra Flag Format Documented Consistently

**Criterion:** All references to the `--infra` flag use the new `tracker:{value},sc:{value}` format. No references to the old `{tracker},{sc}` positional format remain (except in the migration error message that tells users about the change).

**Verification method:**
```bash
grep -rn "\-\-infra" commands/scaffold.md
```
Review each match:
- Line 22 (Flag Parsing): must reference `tracker:{ready|later},sc:{ready|later}`
- Lines 36-40 area (Flag Validation): must include old format detection with migration error
- Lines 60-62 area (Step 0-INFRA): must reference named pairs parsing
- Line 126 area (On resume): must reference new format in override logic

**Pass condition:** All `--infra` references use named format. The old positional format only appears in the migration error message text (telling users what changed).

Additional consistency check:
```bash
grep -rn "\-\-infra" docs/ CHANGELOG.md CLAUDE.md
```
All matches must use the new format.

---

## FC-4: CHANGELOG.md Updated

**Criterion:** `CHANGELOG.md` contains a `## [5.6.1]` entry documenting all 4 UXP items.

**Verification method:** Read `CHANGELOG.md` and confirm:
1. Entry exists with correct version header: `## [5.6.1] — {date}`
2. Severity label: `**PATCH**` (no contract changes — error message text and flag format are behavioral, not contractual)
3. Sections present:
   - `### Changed` with entries for:
     - `--infra` flag format change (tracker:ready,sc:later)
     - MCP jargon replacement (user-friendly error messages, file count)
     - Canary-write announcement
     - Resume `--infra` override
4. No `### Added` section (no new features — these are UX refinements)
5. No `### Fixed` section (these are not bug fixes)
6. Details line with unchanged counts (19 agents, 25 commands, etc.)

**Pass condition:** Entry is present, well-formatted, and accurately describes all changes.

---

## FC-5: Roadmap Updated

**Criterion:** The `PLANNED — v5.6.1 (UX Polish)` section in `docs/plans/roadmap.md` is moved to the `DONE` section.

**Verification method:** Read `docs/plans/roadmap.md` and confirm:
1. A `## DONE — v5.6.1 (UX Polish)` section exists
2. It contains all 4 items:
   - --infra flag format
   - Canary-write announcement
   - MCP jargon to user-friendly error messages
   - Resume --infra override
3. The `## PLANNED — v5.6.1` section no longer exists
4. Version header at top is updated to `v5.6.1`
5. `Last updated` date is current

**Pass condition:** Section moved, version updated, date current.

---

## Summary Table

| ID | Criterion | Verification |
|----|-----------|-------------|
| FC-1 | Test suite passes | `./tests/harness/run-tests.sh` exit 0 |
| FC-2 | No MCP jargon in user-facing errors | `grep` returns 0 matches in target files |
| FC-3 | --infra format consistent | All `--infra` refs use named format |
| FC-4 | CHANGELOG entry | v5.6.1 entry with all 4 items |
| FC-5 | Roadmap updated | PLANNED → DONE, version bumped |
