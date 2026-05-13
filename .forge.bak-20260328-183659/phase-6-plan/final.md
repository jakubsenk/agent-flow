# Implementation Plan — version-check Fix (v5.5.1)

Single batch. One primary file, two secondary updates.

## Prerequisites

- Read all three input files (already done in spec phase):
  - `.forge/phase-3-brainstorm/final.md` — adopted design decisions
  - `.forge/phase-2-research-answers/final.md` — defect registry
  - `commands/version-check.md` — current file (to be replaced)
- Read the design spec: `.forge/phase-4-spec/final/design.md` — contains the verbatim new file content

## Steps

### Step 1: Rewrite `commands/version-check.md` (PRIMARY)

**Tool:** Write
**Action:** Replace the entire file with the content from `.forge/phase-4-spec/final/design.md` (the content between START and END markers, without the markdown code fence wrapper).
**File:** `commands/version-check.md`
**Verification after write:**
- `grep -c 'ceos-agents' commands/version-check.md` == 2 (AC1)
- `grep -c 'https\?://' commands/version-check.md` == 0 (AC2)
- `grep -c '\^{}' commands/version-check.md` >= 1 (AC7)
- `grep -c 'sort -V' commands/version-check.md` >= 1 (AC8)
- File contains "Plugin Identity" section
- File does NOT contain "Part C"

### Step 2: Update `docs/reference/commands.md` — /version-check section

**Tool:** Edit
**Action:** Replace lines 621-639 (the /version-check section) with updated description.
**Changes:**
- "What it does" text updated to describe 2-part structure (A: installed status from `installed_plugins.json`, B: repo comparison when in the plugin's own repo)
- Mention graceful degradation (remote unreachable, repository field absent)
- Remove any implicit mention of Part C or legacy cleanup
- Keep syntax and example unchanged (still zero arguments)
**Verification:** Read the updated section and confirm it matches the new behavior.

### Step 3: Update `CHANGELOG.md` — v5.5.1 entry

**Tool:** Edit
**Action:** Replace lines 10-17 (the [5.5.1] section content) with updated entry.
**Changes:**
- Summary line: "Fix version-check: generic plugin identity, removed hardcoded URL, full error handling, semver fix. No contract changes."
- Fixed bullets:
  1. Generic plugin identity via Plugin Identity table (no hardcoded `ceos-agents` outside the table)
  2. Removed hardcoded fallback URL — derives remote from `repository` field, skips gracefully if absent
  3. Reads `installed_plugins.json` as authoritative source, with guards for missing/corrupt/empty states
  4. Proper semver comparison using `sort -V` (fixes 5.10.0 vs 5.9.0)
  5. Annotated tag filtering (`grep -v '\^{}'`) and `timeout 10` on git ls-remote
  6. Removed Part C (legacy `CLAUDE-agents` cleanup — author-specific artifact)
  7. Part B name-match guard — only compares repo version when CWD is the correct plugin's repo
**Verification:** Read the entry and confirm AC10 sub-requirements.

### Step 4: Run test harness

**Tool:** Bash
**Action:** `./tests/harness/run-tests.sh`
**Expected:** All tests pass. The test harness validates markdown structure of commands, not runtime behavior.
**If failure:** Fix the structural issue in `commands/version-check.md` and re-run.

### Step 5: Verify from repo directory (simulate Part A + Part B)

**Tool:** Bash (from CWD = `C:\gitea_ceos-agents`)
**Action:** Manual verification steps:
1. Confirm `.claude-plugin/plugin.json` exists and `name` == `ceos-agents` (Part B would activate)
2. Confirm `~/.claude/plugins/installed_plugins.json` exists and has a `ceos-agents@ceos-agents` key
3. Walk through the steps mentally / spot-check that the command covers this scenario

### Step 6: Verify from /tmp (simulate Part A only)

**Tool:** Bash (from CWD = `/tmp`)
**Action:** Manual verification steps:
1. Confirm `/tmp/.claude-plugin/plugin.json` does NOT exist (Part B skipped)
2. Part A would still work (reads from `~/.claude/plugins/installed_plugins.json`)
3. Walk through the steps to confirm no CWD dependency in Part A

## Batch Summary

| # | File | Tool | Depends On |
|---|------|------|------------|
| 1 | `commands/version-check.md` | Write | None |
| 2 | `docs/reference/commands.md` | Edit | None |
| 3 | `CHANGELOG.md` | Edit | None |
| 4 | Test harness | Bash | Steps 1-3 |
| 5 | Repo directory check | Bash | Step 1 |
| 6 | /tmp directory check | Bash | Step 1 |

Steps 1-3 can run in parallel. Steps 4-6 run after 1-3 complete. Steps 5-6 can run in parallel.

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Test harness rejects new markdown structure | LOW | The new file follows the same frontmatter + heading + steps pattern as the current file |
| `sort -V` not available on target platform | LOW | Spec includes fallback note ("if `timeout` is not available, omit it"). `sort -V` is already used in the current file for tag sorting. |
| Other commands reference Part C behavior | NONE | Cross-reference surface confirmed: no other command references Part C or step 7 of version-check |
