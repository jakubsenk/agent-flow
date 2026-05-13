# Phase 8 — Verify

## Context

You are verifying the v5.6.1 (UX Polish) implementation for the ceos-agents plugin. All changes were markdown text edits across 3 files. Verify correctness, completeness, and consistency.

## Verification Checklist

### V1: Automated Tests

- [ ] Run `tests/harness/run-tests.sh` — all tests must pass
- [ ] No new test failures compared to pre-edit baseline

### V2: UXP-1 (--infra Flag Format) — `commands/scaffold.md`

- [ ] Flag Parsing section: format description says `tracker:{ready|later},sc:{ready|later}`
- [ ] Flag Validation section: validation checks new format, not old positional format
- [ ] Error message references `--infra tracker:ready,sc:later` as example
- [ ] No occurrence of `--infra ready,later` as a valid example (old format)
- [ ] Step 0-INFRA: parsing description uses key:value format
- [ ] Cross-check with --issue: references "parsed tracker value", not "first value"

### V3: UXP-2 (Canary-Write Announcement) — `core/mcp-detection.md`

- [ ] Input Contract includes `interactive` parameter with description
- [ ] Process step 4: "Testing write access" announcement appears before canary creation
- [ ] Process step 4: interactive confirmation prompt exists
- [ ] Process step 4: decline path sets `write_available = null`

Verify in `commands/scaffold.md`:
- [ ] Step 0-MCP passes `interactive` parameter to mcp-detection

### V4: UXP-3 (No MCP Jargon) — Both files

Search `commands/scaffold.md` for:
- [ ] Zero occurrences of "MCP server for" in display/error messages
- [ ] Zero occurrences of "MCP for {type} not available"
- [ ] Note: "MCP" in HTML comments, section titles like "Step 0-MCP", and references to `core/mcp-detection.md` are acceptable

Search `core/mcp-detection.md` for:
- [ ] Zero occurrences of "No MCP tool matching prefix"
- [ ] Failure messages use "Cannot connect" language
- [ ] Note: "MCP" in the file title, Purpose section, and technical references is acceptable (it IS an MCP detection contract)

Search across ALL files for remaining jargon:
- [ ] `grep -r "MCP server for" commands/ core/` returns zero results in user-facing messages
- [ ] Technical/internal references to MCP are acceptable

### V5: UXP-4 (Resume --infra Override) — `commands/resume-ticket.md`

- [ ] Flag Parsing section exists with --infra description
- [ ] Format matches UXP-1: `tracker:{ready|later},sc:{ready|later}`
- [ ] Infrastructure Override section exists after State File Detection
- [ ] "Infrastructure changed since last run. Using new values." message present
- [ ] Non-scaffold pipeline warning present: "--infra flag is only applicable to scaffold pipeline resume"
- [ ] Logic prompts for details when changing from "later" to "ready"
- [ ] Re-runs Step 0-MCP for changed services

### V6: Cross-File Consistency

- [ ] `--infra` format description in `scaffold.md` matches `resume-ticket.md` exactly
- [ ] `interactive` parameter in `core/mcp-detection.md` Input Contract matches usage in `scaffold.md`
- [ ] No contradictions between the 3 modified files

### V7: Markdown Integrity

- [ ] All modified files parse as valid markdown (headings, code blocks, tables intact)
- [ ] No broken references to other files
- [ ] Line count changes are reasonable (expected: ~70 lines total across 3 files)

## Failure Handling

If any verification check fails:
1. Identify the specific failing check
2. Trace back to the execution step that should have addressed it
3. Apply the fix
4. Re-run verification from V1

## Expected Outcome

All 7 verification groups pass. The 3 modified files contain the v5.6.1 UX Polish changes with no regressions.
