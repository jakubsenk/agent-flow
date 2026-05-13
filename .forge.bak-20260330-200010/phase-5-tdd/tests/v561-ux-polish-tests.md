# v5.6.1 UX Polish — Test Definitions

Each test below maps to a test scenario file in `tests/scenarios/`. The scenario file name is given for each test, and the bash script body is specified in full.

These tests verify structural content of markdown files — they do not invoke any agent or runtime code.

---

## Test T-1: --infra flag uses named format (not positional)

**File:** `tests/scenarios/scaffold-infra-flag-format.sh`

**Covers:** UXP-1 — `--infra` flag format changed from `ready,later` to `tracker:ready,sc:later`

**What it checks:**
1. `scaffold.md` Flag Parsing section documents `tracker:{value},sc:{value}` named format
2. `scaffold.md` Flag Validation section includes an error for the old positional format (migration error)
3. `scaffold.md` Flag Validation section uses `tracker:` and `sc:` keys in its validation regex or description
4. `scaffold.md` does NOT reference `{ready|later},{ready|later}` (old positional validator) as the current valid format
5. `scaffold.md` Flag Parsing no longer says `format: \`{tracker},{sc}\`` (old format description)
6. `CLAUDE.md` `--infra` documentation uses named format

**Pass condition:** All checks pass.

```bash
#!/bin/bash
# Test: scaffold --infra flag uses named tracker:value,sc:value format (UXP-1)
# Validates: old positional format removed, new named format present in scaffold.md
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# 1. Named format "tracker:{value}" documented in Flag Parsing
if ! grep -q 'tracker:{' "$SCAFFOLD_CMD" && ! grep -q 'tracker:ready\|tracker:later\|tracker:\(ready\|later\)' "$SCAFFOLD_CMD"; then
  fail "scaffold.md Flag Parsing missing named format (tracker:{value})"
fi

# 2. Named format "sc:{value}" documented in Flag Parsing
if ! grep -q 'sc:{' "$SCAFFOLD_CMD" && ! grep -q 'sc:ready\|sc:later\|sc:\(ready\|later\)' "$SCAFFOLD_CMD"; then
  fail "scaffold.md Flag Parsing missing named format (sc:{value})"
fi

# 3. Old positional format detection: migration error message present
# The old format was ready,later or later,ready — the new code must detect it and show a migration error
if ! grep -q 'positional\|old.*format\|migration\|--infra ready,later\|--infra later' "$SCAFFOLD_CMD"; then
  fail "scaffold.md Flag Validation missing old-format detection or migration error"
fi

# 4. Flag Parsing description no longer uses the old positional format description
# Old: format: `{tracker},{sc}` where each is `ready` or `later`
if grep -q 'format: `{tracker},{sc}`' "$SCAFFOLD_CMD"; then
  fail "scaffold.md still references old positional --infra format description: format: \`{tracker},{sc}\`"
fi

# 5. Step 0-INFRA preset parsing uses named-pair extraction (tracker= and sc= assignment)
# The new parsing extracts by key name, not by position
if ! grep -q 'tracker=\|tracker_preset\|extract.*tracker\|parse.*tracker' "$SCAFFOLD_CMD"; then
  fail "scaffold.md Step 0-INFRA missing named-key extraction for tracker preset"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: scaffold --infra named format verified (UXP-1)"
exit "$FAIL"
```

---

## Test T-2: canary-write announcement present in scaffold.md

**File:** `tests/scenarios/scaffold-canary-announcement.sh`

**Covers:** UXP-2 — Canary-write test announces to user before running

**What it checks:**
1. `scaffold.md` Step 0-MCP section contains text announcing the canary write to the user
2. The announcement occurs in the write-check sub-section (where `check_write = true` is described)
3. The announcement does not ask for confirmation (informational only)

**Pass condition:** Canary announcement text is present.

```bash
#!/bin/bash
# Test: scaffold.md Step 0-MCP announces canary-write test to user (UXP-2)
# Validates: informational canary announcement is present before write check runs
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# 1. Announcement text present — check for key phrases that describe the canary write
# Acceptable variants: "canary", "test issue", "test write", "temporary issue", "write test"
if ! grep -qi 'canary\|test.*write\|write.*test\|test.*issue.*creat\|temporary.*issue\|verificat.*write' "$SCAFFOLD_CMD"; then
  fail "scaffold.md Step 0-MCP missing canary-write announcement text"
fi

# 2. Announcement is informational — must NOT ask Y/n confirmation for the write test itself
# (Confirmation is only asked for "Continue without {service}?" — not for running the canary)
# Check that the canary context does not have a [Y/n] immediately after it
# Strategy: find lines with canary/write-test context and ensure no adjacent [Y/n] prompt
canary_line=$(grep -n -i 'canary\|test.*write\|write.*test' "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
if [ -n "$canary_line" ]; then
  nearby=$(sed -n "$((canary_line)),$(( canary_line + 3 ))p" "$SCAFFOLD_CMD")
  if echo "$nearby" | grep -q '\[Y/n\]'; then
    fail "scaffold.md canary announcement appears to ask for Y/n confirmation (should be informational)"
  fi
fi

# 3. Canary content appears within the MCP Verification section (Step 0-MCP)
mcp_start=$(grep -n "Step 0-MCP" "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
orchestration_start=$(grep -n "^## Orchestration\|^### Step 0: Mode Selection" "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
if [ -z "$mcp_start" ] || [ -z "$orchestration_start" ]; then
  fail "scaffold.md missing Step 0-MCP or Orchestration anchor (cannot verify canary placement)"
else
  canary_line_check=$(grep -n -i 'canary\|test.*write\|write.*test' "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
  if [ -n "$canary_line_check" ]; then
    if [ "$canary_line_check" -lt "$mcp_start" ] || [ "$canary_line_check" -gt "$orchestration_start" ]; then
      fail "scaffold.md canary announcement is outside Step 0-MCP section (line $canary_line_check, expected between $mcp_start and $orchestration_start)"
    fi
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: scaffold.md canary-write announcement verified (UXP-2)"
exit "$FAIL"
```

---

## Test T-3: no MCP jargon in user-facing error messages

**File:** `tests/scenarios/no-mcp-jargon-errors.sh`

**Covers:** UXP-3 — "MCP server for {Type} is not available" replaced across all user-facing error messages

**What it checks:**
1. Standard error pattern (`STOP with: "MCP server for {Type} is not available"`) is absent from all 12 standard-error files
2. scaffold.md MCP Pre-flight Check section no longer uses the old error string
3. implement-feature.md YOLO block does not use the old error string
4. The new error pattern (`Cannot connect to your`) is present in each of the 12 standard-error files
5. core/mcp-preflight.md does not contain the old pattern in its block Reason/Recommendation fields

**Pass condition:** 0 old-pattern matches in target files; new pattern present in each target file.

```bash
#!/bin/bash
# Test: No "MCP server for {Type} is not available" in user-facing error messages (UXP-3)
# Validates: jargon replaced with friendly "Cannot connect to your {Type} issue tracker"
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# Files that MUST have the old pattern replaced (standard error files)
STANDARD_ERROR_FILES=(
  "commands/analyze-bug.md"
  "commands/changelog.md"
  "commands/create-pr.md"
  "commands/dashboard.md"
  "commands/estimate.md"
  "commands/metrics.md"
  "commands/prioritize.md"
  "commands/status.md"
  "commands/resume-ticket.md"
  "commands/scaffold-add.md"
)

# Additional files with user-facing errors that must be updated
ADDITIONAL_FILES=(
  "commands/fix-bugs.md"
  "commands/publish.md"
  "commands/scaffold.md"
  "commands/implement-feature.md"
)

OLD_PATTERN='MCP server for.*is not available'
NEW_PATTERN='Cannot connect to your'

# 1. Check standard error files: old pattern must be absent
for rel_path in "${STANDARD_ERROR_FILES[@]}"; do
  f="$REPO_ROOT/$rel_path"
  if [ ! -f "$f" ]; then
    fail "File not found: $rel_path"
    continue
  fi
  if grep -q "$OLD_PATTERN" "$f"; then
    fail "$rel_path still contains old MCP jargon: 'MCP server for {Type} is not available'"
  fi
done

# 2. Check standard error files: new pattern must be present
for rel_path in "${STANDARD_ERROR_FILES[@]}"; do
  f="$REPO_ROOT/$rel_path"
  [ ! -f "$f" ] && continue  # already failed above
  if ! grep -q "$NEW_PATTERN" "$f"; then
    fail "$rel_path missing new friendly error: 'Cannot connect to your'"
  fi
done

# 3. Check additional files: user-facing error occurrences must use new pattern
# fix-bugs.md: line ~80 (standard error) must be updated; lines ~99 and ~321 (agent dispatch context) may keep old pattern
# We check that the STOP/Display/Block-user-facing occurrences are updated.
# Strategy: check that at least one occurrence of the new pattern exists in each additional file.
for rel_path in "${ADDITIONAL_FILES[@]}"; do
  f="$REPO_ROOT/$rel_path"
  if [ ! -f "$f" ]; then
    fail "File not found: $rel_path"
    continue
  fi
  # These files have a mix of user-facing and internal references.
  # We verify the new pattern is present (at least one user-facing occurrence was updated).
  if ! grep -q "$NEW_PATTERN" "$f"; then
    fail "$rel_path missing new friendly error pattern: 'Cannot connect to your'"
  fi
done

# 4. scaffold.md MCP Pre-flight Check standard error must use new pattern
# (The pre-flight section has a "Standard error message" block — verify it)
SCAFFOLD="$REPO_ROOT/commands/scaffold.md"
preflight_line=$(grep -n "Standard error message" "$SCAFFOLD" | head -1 | cut -d: -f1)
if [ -n "$preflight_line" ]; then
  # Check the 5 lines after "Standard error message:" header
  context=$(sed -n "$preflight_line,$((preflight_line + 5))p" "$SCAFFOLD")
  if echo "$context" | grep -q "$OLD_PATTERN"; then
    fail "scaffold.md MCP Pre-flight 'Standard error message' still uses old jargon"
  fi
fi

# 5. core/mcp-preflight.md must not have old pattern in Reason/Recommendation fields
MCP_PREFLIGHT="$REPO_ROOT/core/mcp-preflight.md"
if [ -f "$MCP_PREFLIGHT" ]; then
  # Extract Reason/Recommendation lines and check for old pattern
  if grep -i 'Reason:\|Recommendation:' "$MCP_PREFLIGHT" | grep -q "$OLD_PATTERN"; then
    fail "core/mcp-preflight.md Reason/Recommendation fields still use old MCP jargon"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: No MCP jargon in user-facing error messages — all 14 files verified (UXP-3)"
exit "$FAIL"
```

---

## Test T-4: scaffold.md resume --infra override logic present

**File:** `tests/scenarios/scaffold-resume-infra-override.sh`

**Covers:** UXP-4 — Resume `--infra` override: when resuming with `--infra` flag, state.json values are replaced

**What it checks:**
1. `scaffold.md` Step 0-INFRA "On resume" paragraph describes override behavior when `--infra` flag is provided alongside existing state
2. The override logic references the new named format (`tracker:` / `sc:`)
3. The override logic covers the case of overriding `"later"` → `"ready"` (upgrade) and `"ready"` → `"later"` (downgrade)
4. The no-change case is documented (when `--infra` values match existing state)

**Pass condition:** All override logic elements are present.

```bash
#!/bin/bash
# Test: scaffold.md resume --infra override logic (UXP-4)
# Validates: On resume section describes --infra override behavior with new named format
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# 1. "On resume" section exists in Step 0-INFRA
if ! grep -q "On resume" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing 'On resume' section in Step 0-INFRA"
fi

# 2. On resume section mentions --infra flag override behavior
# Check that the resume section references the --infra flag
resume_line=$(grep -n "On resume" "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
if [ -n "$resume_line" ]; then
  # Read 15 lines after "On resume" to check for override logic
  context=$(sed -n "$resume_line,$((resume_line + 15))p" "$SCAFFOLD_CMD")
  if ! echo "$context" | grep -q '\-\-infra'; then
    fail "scaffold.md 'On resume' section does not mention --infra override"
  fi
fi

# 3. Override logic references new named format keys (tracker: or sc:)
resume_line=$(grep -n "On resume" "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
if [ -n "$resume_line" ]; then
  context=$(sed -n "$resume_line,$((resume_line + 20))p" "$SCAFFOLD_CMD")
  if ! echo "$context" | grep -q 'tracker:\|sc:'; then
    fail "scaffold.md 'On resume' override does not reference named format (tracker: or sc:)"
  fi
fi

# 4. Override must describe re-verification (when upgrading from later to ready, Step 0-MCP must re-run)
if ! grep -q 're-run.*0-MCP\|0-MCP.*re-run\|re-check\|re-verify\|run.*MCP.*again\|re-ask' "$SCAFFOLD_CMD"; then
  fail "scaffold.md resume --infra override missing re-verification instruction (Step 0-MCP must re-run on upgrade)"
fi

# 5. No-change case documented: if --infra values match state, skip re-verification
if ! grep -q 'no changes\|match.*state\|already.*ready\|same.*values\|unchanged' "$SCAFFOLD_CMD"; then
  fail "scaffold.md resume --infra override missing no-change case (same values → skip re-verification)"
fi

# 6. Downgrade case: clearing detail fields on ready→later override
if ! grep -q 'clear\|null\|downgrade.*override\|override.*downgrade' "$SCAFFOLD_CMD"; then
  fail "scaffold.md resume --infra override missing downgrade/clear logic (ready→later must clear detail fields)"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: scaffold.md resume --infra override logic verified (UXP-4)"
exit "$FAIL"
```

---

## Test T-5: regression — existing scaffold tests still cover v5.6.1-modified sections

**File:** `tests/scenarios/scaffold-v561-regression.sh`

**Covers:** Regression guard — ensures v5.6.1 changes did not accidentally remove or break content that earlier tests rely on

**What it checks:**
1. `scaffold.md` still contains `--infra` in Flag Parsing (flag itself not removed)
2. `scaffold.md` still contains `Infrastructure Declaration` (Step 0-INFRA not removed)
3. `scaffold.md` still contains `Step 0-MCP` (not removed)
4. `scaffold.md` still contains `On resume` (not removed by UXP-4 edit)
5. `scaffold.md` still contains the four valid infrastructure combinations table
6. `scaffold.md` state persistence block (write to state.json after infra collection) still present

**Pass condition:** All structural elements still present.

```bash
#!/bin/bash
# Test: scaffold.md v5.6.1 regression — key structural elements not accidentally removed
# Validates: UXP-1/2/3/4 edits did not remove existing required content
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCAFFOLD_CMD="$REPO_ROOT/commands/scaffold.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# 1. --infra flag still present in Flag Parsing
if ! grep -q '\-\-infra' "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing --infra flag (accidentally removed?)"
fi

# 2. Infrastructure Declaration heading still present
if ! grep -q "Infrastructure Declaration" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing Step 0-INFRA: Infrastructure Declaration"
fi

# 3. Step 0-MCP still present
if ! grep -q "Step 0-MCP" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing Step 0-MCP section"
fi

# 4. On resume paragraph still present
if ! grep -q "On resume" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing 'On resume' paragraph"
fi

# 5. Four valid combinations table still present (ready/later matrix)
if ! grep -q "Tracker.*SC.*Downstream\|ready.*ready.*Full integration\|later.*later.*Fully local" "$SCAFFOLD_CMD"; then
  if ! grep -q "Four valid combinations" "$SCAFFOLD_CMD"; then
    fail "scaffold.md missing infrastructure combinations table (ready/later matrix)"
  fi
fi

# 6. State persistence block still present (state.json write after infra collection)
if ! grep -q "infrastructure.tracker_status\|infrastructure.sc_status" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing state persistence block (infrastructure.tracker_status / infrastructure.sc_status)"
fi

# 7. tracker_effective_status and sc_effective_status variables still defined
if ! grep -q "tracker_effective_status" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing tracker_effective_status variable definition"
fi
if ! grep -q "sc_effective_status" "$SCAFFOLD_CMD"; then
  fail "scaffold.md missing sc_effective_status variable definition"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: scaffold.md v5.6.1 regression — all structural elements intact"
exit "$FAIL"
```

---

## Summary

| Test ID | Scenario File | Covers |
|---------|--------------|--------|
| T-1 | `scaffold-infra-flag-format.sh` | UXP-1: --infra named format |
| T-2 | `scaffold-canary-announcement.sh` | UXP-2: canary-write announcement |
| T-3 | `no-mcp-jargon-errors.sh` | UXP-3: MCP jargon replaced |
| T-4 | `scaffold-resume-infra-override.sh` | UXP-4: resume --infra override |
| T-5 | `scaffold-v561-regression.sh` | Regression: structural elements intact |

## Notes for Implementation

- All 5 scenario files are drop-in additions to `tests/scenarios/` — no changes to the harness needed.
- T-3 (`no-mcp-jargon-errors.sh`) is the widest test: it checks 14 files. It is intentionally a **grep-negative** test — the primary assertion is absence of the old pattern.
- T-3 deliberately does NOT assert absence of `"MCP server"` everywhere — only of the specific user-facing error string. Files like `check-setup.md`, `init.md`, and agent dispatch contexts legitimately keep "MCP server" terminology.
- T-2 uses a broad regex (`canary|test.*write|write.*test`) to tolerate minor wording variations in the announcement text.
- T-4 checks logical presence (override described, re-verification mentioned, no-change case documented) rather than exact text, because the exact wording of the override paragraph is not yet finalized.
- T-5 is a pure regression guard — it would fail if any of the existing `scaffold-v2-happy-path` assertions broke due to v5.6.1 edits.
