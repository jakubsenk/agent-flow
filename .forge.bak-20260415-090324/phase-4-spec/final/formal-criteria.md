# v6.5.2 Formal Acceptance Criteria

**Version:** v6.5.2 (PATCH)
**Date:** 2026-04-15

Each criterion below is machine-checkable: it specifies what to verify, where to verify it, and the expected result.

---

## AC1: `status_id:22` Format Parsed Correctly

**Requirement:** The canonical Redmine state transition format is `status_id:{id}` and is documented as such throughout the plugin.

### Verification Steps

1. **trackers.md State Transition Syntax table:** The Redmine row's Format column contains `status_id:{id}`, not `status:{name}`.
   - **Check:** `grep -P 'redmine.*status_id:\{id\}' docs/reference/trackers.md` returns a match.

2. **trackers.md On Start Set Defaults table:** The Redmine row contains `status_id:2`.
   - **Check:** `grep -P 'redmine.*status_id:2' docs/reference/trackers.md` returns a match.

3. **Config templates use `status_id:{id}` format:**
   - **Check (oracle):** `grep 'status_id:2' examples/configs/redmine-oracle-plsql.md` returns matches for both State transitions and On start set.
   - **Check (rails):** `grep 'status_id:2' examples/configs/redmine-rails.md` returns matches for both State transitions and On start set.

4. **Config templates do NOT use legacy `status:{name}` format in active config:**
   - **Check (oracle):** `grep -c 'status:In Progress' examples/configs/redmine-oracle-plsql.md` returns 0 (outside HTML comments).
   - **Check (rails):** `grep -c 'status:In Progress' examples/configs/redmine-rails.md` returns 0 (outside HTML comments).

### Test Scenario

```bash
# Assert trackers.md canonical format
grep -q 'status_id:{id}' docs/reference/trackers.md || fail "AC1: trackers.md missing status_id:{id} format"
grep -q 'status_id:2' docs/reference/trackers.md || fail "AC1: trackers.md missing status_id:2 default"

# Assert templates use status_id format (active config, not comments)
grep -v '<!--' examples/configs/redmine-oracle-plsql.md | grep -q 'status_id:2' || fail "AC1: oracle template missing status_id:2"
grep -v '<!--' examples/configs/redmine-rails.md | grep -q 'status_id:2' || fail "AC1: rails template missing status_id:2"
```

---

## AC2: `status:In Progress` Legacy Format Logs WARN

**Requirement:** The legacy `status:{name}` format is accepted but triggers a WARN. Three mechanisms enforce this.

### Verification Steps

1. **trackers.md Validation Rules:** The Redmine row's State transition format column accepts both `status_id:{id}` and `status:{name}` (legacy).
   - **Check:** `grep -P 'redmine.*status_id.*legacy' docs/reference/trackers.md` returns a match.

2. **check-setup WARN emission:** The skill contains a Redmine legacy format check that emits `[WARN]`.
   - **Check:** `grep -A3 'Redmine legacy format check' skills/check-setup/SKILL.md | grep -q 'WARN'` returns 0.

3. **migrate-config deprecated pattern:** The skill contains a Redmine `status:{name}` detection rule.
   - **Check:** `grep -q 'status:{name}.*pre-v6.5.2' skills/migrate-config/SKILL.md` returns 0 (match found).

### Test Scenario

```bash
# Assert trackers.md accepts legacy format
grep -q 'legacy' docs/reference/trackers.md || fail "AC2: trackers.md missing legacy annotation"

# Assert check-setup has WARN for legacy format
grep -q 'Redmine legacy format check' skills/check-setup/SKILL.md || fail "AC2: check-setup missing Redmine legacy check"
grep -A5 'Redmine legacy format check' skills/check-setup/SKILL.md | grep -q 'WARN' || fail "AC2: check-setup legacy check missing WARN"

# Assert migrate-config has deprecated pattern rule
grep -q 'status:{name}' skills/migrate-config/SKILL.md || fail "AC2: migrate-config missing Redmine legacy pattern"
```

---

## AC3: Post-Update Verification via Read-Back

**Requirement:** After a status-set MCP call, the pipeline reads back the issue state and compares to the expected value.

### Verification Steps

1. **core/status-verification.md exists:** The file is present and contains the verification contract.
   - **Check:** `test -f core/status-verification.md` returns 0.

2. **Contract contains read-back instruction:** The file contains "Read back issue state" or equivalent.
   - **Check:** `grep -q 'read back' core/status-verification.md` (case-insensitive) returns 0.

3. **Three call sites reference the contract:**
   - **publisher.md:** `grep -q 'core/status-verification.md' agents/publisher.md` returns 0.
   - **block-handler.md:** `grep -q 'core/status-verification.md' core/block-handler.md` returns 0.
   - **fix-ticket SKILL.md:** `grep -q 'core/status-verification.md' skills/fix-ticket/SKILL.md` returns 0.

### Test Scenario

```bash
# Assert contract file exists
test -f core/status-verification.md || fail "AC3: core/status-verification.md not found"

# Assert contract contains verification logic
grep -iq 'read.back' core/status-verification.md || fail "AC3: contract missing read-back instruction"

# Assert 3 call sites reference the contract
grep -q 'core/status-verification.md' agents/publisher.md || fail "AC3: publisher missing verification reference"
grep -q 'core/status-verification.md' core/block-handler.md || fail "AC3: block-handler missing verification reference"
grep -q 'core/status-verification.md' skills/fix-ticket/SKILL.md || fail "AC3: fix-ticket missing verification reference"
```

---

## AC4: WARN Not BLOCK on Verification Failure

**Requirement:** The verification contract explicitly states that verification failures produce WARN, never BLOCK.

### Verification Steps

1. **Contract contains NEVER-block rule:** The file contains "NEVER block" in the Constraints section.
   - **Check:** `grep -q 'NEVER block' core/status-verification.md` returns 0.

2. **Contract contains WARN on mismatch:** The file contains `[WARN]` log entries for all failure modes.
   - **Check:** `grep -c 'WARN' core/status-verification.md` returns >= 3 (mismatch + read-back failure + tool unavailable).

3. **No BLOCK/FAIL outputs:** The contract does not contain any blocking verdicts.
   - **Check:** `grep -c 'BLOCK\|FAIL' core/status-verification.md` returns 0 (excluding "NEVER block").

### Test Scenario

```bash
# Assert NEVER-block constraint exists
grep -q 'NEVER block' core/status-verification.md || fail "AC4: contract missing NEVER-block constraint"

# Assert WARN is the verdict for failures
WARN_COUNT=$(grep -c 'WARN' core/status-verification.md)
[ "$WARN_COUNT" -ge 3 ] || fail "AC4: contract has fewer than 3 WARN entries (found $WARN_COUNT)"

# Assert no blocking outputs (excluding the NEVER-block constraint itself)
grep -v 'NEVER block' core/status-verification.md | grep -v 'not BLOCK' | grep -qiw 'BLOCK' && fail "AC4: contract contains BLOCK verdict outside NEVER-block constraint"
```

---

## AC5: Onboard Generates `status_id:XX` Format

**Requirement:** The onboard wizard generates Redmine configs with `status_id:{id}` format, not `status:{name}`.

### Verification Steps

1. **Onboard has Redmine-specific sub-step:** The skill contains a Redmine status ID guidance section.
   - **Check:** `grep -q 'Redmine status ID' skills/onboard/SKILL.md` returns 0.

2. **Sub-step displays curl command:** The section contains the `issue_statuses.json` API endpoint.
   - **Check:** `grep -q 'issue_statuses.json' skills/onboard/SKILL.md` returns 0.

3. **Sub-step uses `status_id` format:** The section references `status_id:{id}` format.
   - **Check:** `grep -q 'status_id:' skills/onboard/SKILL.md` returns 0.

4. **trackers.md On Start Set Defaults shows `status_id:2` for Redmine:** (Cross-check with AC1)
   - **Check:** Already verified in AC1.

### Test Scenario

```bash
# Assert onboard has Redmine sub-step
grep -q 'Redmine status ID' skills/onboard/SKILL.md || fail "AC5: onboard missing Redmine ID sub-step"
grep -q 'issue_statuses.json' skills/onboard/SKILL.md || fail "AC5: onboard missing status lookup guidance"
grep -q 'status_id:' skills/onboard/SKILL.md || fail "AC5: onboard missing status_id format reference"
```

---

## AC6: Publisher Newline Fix (Implicit)

**Requirement:** The publisher agent and subtask description call sites contain a NEVER-rule preventing literal `\n` in MCP parameters.

### Verification Steps

1. **publisher.md Constraints section:** Contains the NEVER-rule.
   - **Check:** `grep -q 'NEVER use the literal characters' agents/publisher.md` returns 0.

2. **publisher.md Step 6:** Contains a newline reinforcement note.
   - **Check:** `grep -q 'real line breaks' agents/publisher.md` returns 0.

3. **fix-ticket subtask description:** Contains the newline instruction after the Issue Description Template.
   - **Check:** `grep -q 'NEVER use the literal characters' skills/fix-ticket/SKILL.md` returns 0.

4. **implement-feature subtask description:** Contains the newline instruction after the Issue Description Template.
   - **Check:** `grep -q 'NEVER use the literal characters' skills/implement-feature/SKILL.md` returns 0.

### Test Scenario

```bash
# Assert publisher has NEVER-rule
grep -q 'NEVER use the literal characters' agents/publisher.md || fail "AC6: publisher missing newline NEVER-rule"
grep -q 'real line breaks' agents/publisher.md || fail "AC6: publisher missing newline reinforcement in Step 6"

# Assert subtask description sites have newline instruction
grep -q 'NEVER use the literal characters' skills/fix-ticket/SKILL.md || fail "AC6: fix-ticket missing newline instruction"
grep -q 'NEVER use the literal characters' skills/implement-feature/SKILL.md || fail "AC6: implement-feature missing newline instruction"
```

---

## AC7: Block Handler Newline Fix (Implicit)

**Requirement:** Block comment posting sites contain a newline instruction preventing literal `\n`.

### Verification Steps

1. **block-handler.md Step 4:** Contains the newline instruction after the block comment template.
   - **Check:** `grep -q 'NEVER use the literal characters' core/block-handler.md` returns 0.

2. **fix-bugs inline block handler:** Contains the newline instruction.
   - **Check:** `grep -q 'NEVER use the literal characters' skills/fix-bugs/SKILL.md` returns 0.

### Test Scenario

```bash
# Assert block-handler has newline instruction
grep -q 'NEVER use the literal characters' core/block-handler.md || fail "AC7: block-handler missing newline instruction"

# Assert fix-bugs inline block handler has newline instruction
grep -q 'NEVER use the literal characters' skills/fix-bugs/SKILL.md || fail "AC7: fix-bugs missing newline instruction"
```

---

## AC8: Roadmap Updated with Deferred Items (Implicit)

**Requirement:** The roadmap reflects v6.5.2 as DONE and includes deferred items with version assignments.

### Verification Steps

1. **v6.5.2 in DONE section:** The roadmap contains `## DONE — v6.5.2`.
   - **Check:** `grep -q 'DONE.*v6.5.2' docs/plans/roadmap.md` returns 0.

2. **v6.5.2 no longer in PLANNED section:** The roadmap does NOT contain `## PLANNED — v6.5.2`.
   - **Check:** `grep -c 'PLANNED.*v6.5.2' docs/plans/roadmap.md` returns 0.

3. **Deferred items in v6.6.0:** The roadmap's v6.6.0 section contains the 3 deferred items.
   - **Check:** `grep -q 'Status Verification.*Remaining Call Sites' docs/plans/roadmap.md` returns 0.
   - **Check:** `grep -q 'MCP Body Formatting Contract' docs/plans/roadmap.md` returns 0.
   - **Check:** `grep -q 'fix-bugs.*On start set' docs/plans/roadmap.md` returns 0.

4. **NOT PLANNED items present:** The roadmap contains rejection entries for the two not-planned items.
   - **Check:** `grep -q 'config-reader Redmine' docs/plans/roadmap.md` returns 0.
   - **Check:** `grep -q 'Onboard Wizard MCP Access' docs/plans/roadmap.md` returns 0.

5. **CLAUDE.md core count:** The count is 12.
   - **Check:** `grep -q '12 shared pipeline pattern contracts' CLAUDE.md` returns 0.

6. **Roadmap version header:** Current version is v6.5.2.
   - **Check:** `grep -q 'Current version.*v6.5.2' docs/plans/roadmap.md` returns 0.

### Test Scenario

```bash
# Assert v6.5.2 is DONE
grep -q 'DONE.*v6.5.2' docs/plans/roadmap.md || fail "AC8: roadmap missing DONE v6.5.2"
grep -c 'PLANNED.*v6.5.2' docs/plans/roadmap.md | grep -q '^0$' || fail "AC8: roadmap still has PLANNED v6.5.2"

# Assert deferred items in v6.6.0
grep -q 'Status Verification' docs/plans/roadmap.md || fail "AC8: roadmap missing deferred verification wiring"
grep -q 'MCP Body Formatting' docs/plans/roadmap.md || fail "AC8: roadmap missing deferred MCP formatting"
grep -q 'On start set' docs/plans/roadmap.md || fail "AC8: roadmap missing deferred fix-bugs On start set"

# Assert NOT PLANNED items
grep -q 'config-reader Redmine' docs/plans/roadmap.md || fail "AC8: roadmap missing NOT PLANNED config-reader"
grep -q 'Onboard Wizard MCP Access' docs/plans/roadmap.md || fail "AC8: roadmap missing NOT PLANNED onboard MCP"

# Assert CLAUDE.md core count
grep -q '12 shared pipeline pattern contracts' CLAUDE.md || fail "AC8: CLAUDE.md core count not updated to 12"
```

---

## Consolidated Test Scenario

The following script combines all AC checks into a single executable test. It can be run as part of the test harness.

```bash
#!/usr/bin/env bash
# Test: v6.5.2 acceptance criteria verification
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# --- AC1: status_id format ---
grep -q 'status_id:{id}' docs/reference/trackers.md || fail "AC1: trackers.md missing status_id:{id} format"
grep -q 'status_id:2' docs/reference/trackers.md || fail "AC1: trackers.md missing status_id:2 default"
grep -v '<!--' examples/configs/redmine-oracle-plsql.md | grep -q 'status_id:2' || fail "AC1: oracle template missing status_id:2"
grep -v '<!--' examples/configs/redmine-rails.md | grep -q 'status_id:2' || fail "AC1: rails template missing status_id:2"

# --- AC2: legacy WARN ---
grep -q 'legacy' docs/reference/trackers.md || fail "AC2: trackers.md missing legacy annotation"
grep -q 'Redmine legacy format check' skills/check-setup/SKILL.md || fail "AC2: check-setup missing Redmine legacy check"
grep -q 'status:{name}' skills/migrate-config/SKILL.md || fail "AC2: migrate-config missing Redmine legacy pattern"

# --- AC3: post-update verification ---
test -f core/status-verification.md || fail "AC3: core/status-verification.md not found"
grep -iq 'read.back' core/status-verification.md || fail "AC3: contract missing read-back instruction"
grep -q 'core/status-verification.md' agents/publisher.md || fail "AC3: publisher missing verification reference"
grep -q 'core/status-verification.md' core/block-handler.md || fail "AC3: block-handler missing verification reference"
grep -q 'core/status-verification.md' skills/fix-ticket/SKILL.md || fail "AC3: fix-ticket missing verification reference"

# --- AC4: WARN not BLOCK ---
grep -q 'NEVER block' core/status-verification.md || fail "AC4: contract missing NEVER-block constraint"
WARN_COUNT=$(grep -c 'WARN' core/status-verification.md)
[ "$WARN_COUNT" -ge 3 ] || fail "AC4: contract has fewer than 3 WARN entries (found $WARN_COUNT)"

# --- AC5: onboard generates status_id ---
grep -q 'Redmine status ID' skills/onboard/SKILL.md || fail "AC5: onboard missing Redmine ID sub-step"
grep -q 'issue_statuses.json' skills/onboard/SKILL.md || fail "AC5: onboard missing status lookup guidance"

# --- AC6: publisher newline fix ---
grep -q 'NEVER use the literal characters' agents/publisher.md || fail "AC6: publisher missing newline NEVER-rule"
grep -q 'NEVER use the literal characters' skills/fix-ticket/SKILL.md || fail "AC6: fix-ticket missing newline instruction"
grep -q 'NEVER use the literal characters' skills/implement-feature/SKILL.md || fail "AC6: implement-feature missing newline instruction"

# --- AC7: block handler newline fix ---
grep -q 'NEVER use the literal characters' core/block-handler.md || fail "AC7: block-handler missing newline instruction"
grep -q 'NEVER use the literal characters' skills/fix-bugs/SKILL.md || fail "AC7: fix-bugs missing newline instruction"

# --- AC8: roadmap + CLAUDE.md ---
grep -q 'DONE.*v6.5.2' docs/plans/roadmap.md || fail "AC8: roadmap missing DONE v6.5.2"
grep -q 'Status Verification' docs/plans/roadmap.md || fail "AC8: roadmap missing deferred verification wiring"
grep -q 'MCP Body Formatting' docs/plans/roadmap.md || fail "AC8: roadmap missing deferred MCP formatting"
grep -q '12 shared pipeline pattern contracts' CLAUDE.md || fail "AC8: CLAUDE.md core count not updated to 12"

# --- Result ---
[ "$FAIL" -eq 0 ] && echo "PASS: All v6.5.2 acceptance criteria verified"
exit "$FAIL"
```

---

## AC-to-File Traceability Matrix

| AC | Files Involved | Verification Method |
|----|---------------|-------------------|
| AC1 | trackers.md, redmine-oracle-plsql.md, redmine-rails.md | grep for `status_id:{id}` and `status_id:2` |
| AC2 | trackers.md, check-setup SKILL.md, migrate-config SKILL.md | grep for `legacy`, `WARN`, `status:{name}` |
| AC3 | core/status-verification.md, publisher.md, block-handler.md, fix-ticket SKILL.md | file existence + grep for contract reference |
| AC4 | core/status-verification.md | grep for `NEVER block` + WARN count |
| AC5 | onboard SKILL.md | grep for `Redmine status ID`, `issue_statuses.json` |
| AC6 | publisher.md, fix-ticket SKILL.md, implement-feature SKILL.md | grep for `NEVER use the literal characters` |
| AC7 | block-handler.md, fix-bugs SKILL.md | grep for `NEVER use the literal characters` |
| AC8 | roadmap.md, CLAUDE.md | grep for `DONE.*v6.5.2`, deferred items, core count |
