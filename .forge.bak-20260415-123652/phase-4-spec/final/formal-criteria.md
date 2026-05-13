# Phase 4 Specification — Formal Acceptance Criteria

## v6.6.0: Status Verification Wiring + MCP Body Formatting Contract + fix-bugs On-Start-Set

Version: 1.0
Date: 2026-04-15

Each criterion has an ID, description, and a machine-checkable verification command.
All verification commands assume execution from the repository root.

---

### AC-1: Contract file exists

**Description:** `core/mcp-body-formatting.md` exists as a new core pipeline contract file.

**Verification:**
```bash
test -f core/mcp-body-formatting.md && echo "AC-1 PASS" || echo "AC-1 FAIL"
```

---

### AC-2: Contract file contains NEVER rule marker

**Description:** The contract file's Constraints section contains "NEVER use" for test compatibility with the T-013 scenario.

**Verification:**
```bash
grep -q "NEVER use" core/mcp-body-formatting.md && echo "AC-2 PASS" || echo "AC-2 FAIL"
```

---

### AC-3: All 4 status verification sites wired

**Description:** All 4 new status verification call sites contain the reference phrase pointing to `core/status-verification.md`. The 4 sites are: `skills/implement-feature/SKILL.md`, `core/fix-verification.md`, `skills/fix-bugs/SKILL.md` (block handler), and `skills/scaffold/SKILL.md`.

**Verification:**
```bash
FAIL=0
for f in \
  "skills/implement-feature/SKILL.md" \
  "core/fix-verification.md" \
  "skills/fix-bugs/SKILL.md" \
  "skills/scaffold/SKILL.md"; do
  if ! grep -q "core/status-verification.md" "$f"; then
    echo "AC-3 FAIL: $f missing status-verification reference"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "AC-3 PASS"
```

Note: `skills/scaffold/SKILL.md` must contain at least 2 occurrences (items 3a and 3b):
```bash
COUNT=$(grep -c "core/status-verification.md" skills/scaffold/SKILL.md)
[ "$COUNT" -ge 2 ] && echo "AC-3b PASS (scaffold has $COUNT refs)" || echo "AC-3b FAIL (scaffold has $COUNT refs, need >=2)"
```

---

### AC-4: All 5 MCP files contain contract reference

**Description:** All 5 files that previously contained inline NEVER instructions now reference `core/mcp-body-formatting.md`.

**Verification:**
```bash
FAIL=0
for f in \
  "agents/publisher.md" \
  "core/block-handler.md" \
  "skills/fix-ticket/SKILL.md" \
  "skills/implement-feature/SKILL.md" \
  "skills/fix-bugs/SKILL.md"; do
  if ! grep -q "core/mcp-body-formatting.md" "$f"; then
    echo "AC-4 FAIL: $f missing mcp-body-formatting reference"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "AC-4 PASS"
```

---

### AC-5: No remaining inline NEVER instructions (except publisher Constraints hybrid)

**Description:** The old marker phrase "NEVER use the literal characters" no longer appears in any agent, core, or skill file. The publisher.md Constraints section uses the condensed "NEVER use `\n` as a line separator" phrasing instead (which does NOT match the old marker).

**Verification:**
```bash
MATCHES=$(grep -r "NEVER use the literal characters" agents/ core/ skills/ 2>/dev/null | wc -l)
[ "$MATCHES" -eq 0 ] && echo "AC-5 PASS" || echo "AC-5 FAIL ($MATCHES files still contain old marker)"
```

---

### AC-6: CLAUDE.md contains updated core count

**Description:** The repository structure section in CLAUDE.md describes `core/` as having 13 (not 12) shared pipeline pattern contracts.

**Verification:**
```bash
grep -q "13 shared pipeline pattern contracts" CLAUDE.md && echo "AC-6 PASS" || echo "AC-6 FAIL"
```

---

### AC-7: fix-bugs contains "On start set" step with verification reference

**Description:** `skills/fix-bugs/SKILL.md` contains a Step 1a labeled "Set issue tracker" that includes the state-set instruction, the status verification reference, and the dry-run annotation.

**Verification:**
```bash
FAIL=0
grep -q "### 1a. Set issue tracker" skills/fix-bugs/SKILL.md || { echo "AC-7 FAIL: missing step 1a heading"; FAIL=1; }
grep -q "On start set" skills/fix-bugs/SKILL.md || { echo "AC-7 FAIL: missing On start set instruction"; FAIL=1; }
grep -q "core/status-verification.md" skills/fix-bugs/SKILL.md || { echo "AC-7 FAIL: missing status verification ref"; FAIL=1; }
grep -q "In dry-run: skip this step" skills/fix-bugs/SKILL.md || { echo "AC-7 FAIL: missing dry-run annotation"; FAIL=1; }
[ "$FAIL" -eq 0 ] && echo "AC-7 PASS"
```

---

### AC-8: fix-bugs worktree range updated

**Description:** The worktree parallel dispatch in fix-bugs references "steps 1a-8" (or "steps 1a--8") instead of the old "steps 2-8".

**Verification:**
```bash
FAIL=0
grep -q "steps 1a" skills/fix-bugs/SKILL.md || { echo "AC-8 FAIL: missing 'steps 1a' range"; FAIL=1; }
# Verify old range is gone
if grep -q "steps 2–8" skills/fix-bugs/SKILL.md; then
  echo "AC-8 FAIL: old 'steps 2–8' range still present"
  FAIL=1
fi
[ "$FAIL" -eq 0 ] && echo "AC-8 PASS"
```

---

### AC-9: Test scenario updated

**Description:** `tests/scenarios/mcp-newline-handling.sh` references `core/mcp-body-formatting.md` (Check B) and checks for "NEVER use" in the contract file (Check A).

**Verification:**
```bash
FAIL=0
grep -q "core/mcp-body-formatting.md" tests/scenarios/mcp-newline-handling.sh || { echo "AC-9 FAIL: test missing contract reference check"; FAIL=1; }
grep -q "NEVER use" tests/scenarios/mcp-newline-handling.sh || { echo "AC-9 FAIL: test missing NEVER use check"; FAIL=1; }
[ "$FAIL" -eq 0 ] && echo "AC-9 PASS"
```

---

### AC-10: All tests pass

**Description:** The full test suite passes after all changes are applied.

**Verification:**
```bash
./tests/harness/run-tests.sh && echo "AC-10 PASS" || echo "AC-10 FAIL"
```

---

### AC-11: Roadmap updated

**Description:** The v6.6.0 section in `docs/plans/roadmap.md` is marked as DONE (no longer PLANNED).

**Verification:**
```bash
FAIL=0
if grep -q "PLANNED.*v6\.6\.0\|v6\.6\.0.*PLANNED" docs/plans/roadmap.md; then
  echo "AC-11 FAIL: v6.6.0 still marked as PLANNED"
  FAIL=1
fi
if grep -q "DONE.*v6\.6\.0\|v6\.6\.0.*DONE" docs/plans/roadmap.md; then
  :
else
  echo "AC-11 FAIL: v6.6.0 not marked as DONE"
  FAIL=1
fi
[ "$FAIL" -eq 0 ] && echo "AC-11 PASS"
```

---

## Summary

| AC | Description | Type |
|----|-------------|------|
| AC-1 | Contract file exists | File existence |
| AC-2 | Contract contains NEVER rule | Grep marker |
| AC-3 | 4 status verification sites wired | Grep reference (4 files) |
| AC-4 | 5 MCP files contain contract reference | Grep reference (5 files) |
| AC-5 | No remaining old inline NEVER instructions | Grep absence |
| AC-6 | CLAUDE.md core count = 13 | Grep string |
| AC-7 | fix-bugs Step 1a with all 4 elements | Grep (4 checks) |
| AC-8 | fix-bugs worktree range = 1a-8 | Grep presence + absence |
| AC-9 | Test scenario updated with dual checks | Grep (2 checks) |
| AC-10 | All tests pass | Script exit code |
| AC-11 | Roadmap updated to DONE | Grep presence + absence |
