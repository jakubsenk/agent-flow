# Formal Acceptance Criteria — v6.7.0: Pipeline Hardening

Each criterion is independently verifiable by reading the specified file(s), running grep commands, or executing the test harness.

---

## AC-1: Core contract `core/external-input-sanitizer.md` exists with complete contract

**Verification:** File existence check + section grep.

**Machine-checkable commands:**

```bash
# File exists
test -f core/external-input-sanitizer.md

# Required sections present
grep -q "## Purpose" core/external-input-sanitizer.md
grep -q "## Applies To" core/external-input-sanitizer.md
grep -q "## Process" core/external-input-sanitizer.md
grep -q "## Constraints" core/external-input-sanitizer.md
grep -q "## Failure Mode" core/external-input-sanitizer.md

# Marker format documented
grep -q "EXTERNAL INPUT START" core/external-input-sanitizer.md
grep -q "EXTERNAL INPUT END" core/external-input-sanitizer.md

# NEVER constraints present (defense-in-depth rules)
grep -c "NEVER" core/external-input-sanitizer.md  # expect >= 3
```

**Pass condition:**
- File exists at `core/external-input-sanitizer.md`.
- All 5 sections (`## Purpose`, `## Applies To`, `## Process`, `## Constraints`, `## Failure Mode`) are present.
- Both marker strings (`EXTERNAL INPUT START`, `EXTERNAL INPUT END`) appear in the file.
- At least 3 NEVER constraints exist in the Constraints section.

**Fail condition:** File missing, any section absent, or marker format not documented.

---

## AC-2: All 5 pipeline skills reference the sanitizer

**Verification:** Grep each skill file for the core contract reference.

**Machine-checkable commands:**

```bash
grep -q "core/external-input-sanitizer" skills/fix-ticket/SKILL.md
grep -q "core/external-input-sanitizer" skills/fix-bugs/SKILL.md
grep -q "core/external-input-sanitizer" skills/implement-feature/SKILL.md
grep -q "core/external-input-sanitizer" skills/scaffold/SKILL.md
grep -q "core/external-input-sanitizer" skills/analyze-bug/SKILL.md
```

**Pass condition:** All 5 grep commands exit 0 (match found in each file).

**Fail condition:** Any of the 5 skills does not contain a reference to `core/external-input-sanitizer`.

---

## AC-3: All 5 agents have the NEVER constraint with marker text

**Verification:** Grep each agent file for the marker text within a NEVER constraint.

**Machine-checkable commands:**

```bash
# Each agent contains EXTERNAL INPUT START marker reference
grep -q "EXTERNAL INPUT START" agents/triage-analyst.md
grep -q "EXTERNAL INPUT START" agents/code-analyst.md
grep -q "EXTERNAL INPUT START" agents/fixer.md
grep -q "EXTERNAL INPUT START" agents/spec-analyst.md
grep -q "EXTERNAL INPUT START" agents/reviewer.md

# Each agent contains EXTERNAL INPUT END marker reference
grep -q "EXTERNAL INPUT END" agents/triage-analyst.md
grep -q "EXTERNAL INPUT END" agents/code-analyst.md
grep -q "EXTERNAL INPUT END" agents/fixer.md
grep -q "EXTERNAL INPUT END" agents/spec-analyst.md
grep -q "EXTERNAL INPUT END" agents/reviewer.md

# Each constraint uses NEVER (imperative language)
grep "EXTERNAL INPUT START" agents/triage-analyst.md | grep -q "NEVER"
grep "EXTERNAL INPUT START" agents/code-analyst.md | grep -q "NEVER"
grep "EXTERNAL INPUT START" agents/fixer.md | grep -q "NEVER"
grep "EXTERNAL INPUT START" agents/spec-analyst.md | grep -q "NEVER"
grep "EXTERNAL INPUT START" agents/reviewer.md | grep -q "NEVER"
```

**Pass condition:** All 15 grep commands exit 0. Each agent has both markers referenced in a line containing NEVER.

**Fail condition:** Any agent is missing the constraint, or the constraint does not use NEVER, or either marker string is absent.

---

## AC-4: CLAUDE.md core count = 14

**Verification:** Grep CLAUDE.md for the core count declaration.

**Machine-checkable commands:**

```bash
# Extract the claimed count from the core/ line in Repository Structure
CLAIMED=$(grep '`core/`' CLAUDE.md | grep 'shared' | grep -oE '[0-9]+' | head -1)
test "$CLAIMED" = "14"

# Cross-check: actual file count in core/ matches
ACTUAL=$(ls core/*.md 2>/dev/null | wc -l)
test "$ACTUAL" = "14"
```

**Pass condition:** CLAUDE.md declares 14 core contracts AND `core/` directory contains exactly 14 `.md` files.

**Fail condition:** CLAUDE.md claims a different number, or the actual file count does not match 14.

---

## AC-5: Test scenario passes

**Verification:** Run the test scenario.

**Machine-checkable commands:**

```bash
# Test file exists
test -f tests/scenarios/external-input-sanitizer.sh

# Test is executable
test -x tests/scenarios/external-input-sanitizer.sh

# Test passes
bash tests/scenarios/external-input-sanitizer.sh
```

**Pass condition:** Test file exists, is executable, and exits with code 0 printing "PASS:".

**Fail condition:** Test file missing, not executable, or exits non-zero.

---

## AC-6: `state/schema.md` documents `plugin_version` field

**Verification:** Grep state/schema.md for the field documentation.

**Machine-checkable commands:**

```bash
# Field appears in Top-Level Field Definitions table
grep -q "plugin_version" state/schema.md

# Field type is documented as string or null
grep "plugin_version" state/schema.md | grep -q "string"

# Field appears in the Full Schema Example
grep -q '"plugin_version"' state/schema.md
```

**Pass condition:** `plugin_version` appears in the Top-Level Field Definitions table with type `string or null`, and appears in the Full Schema Example JSON block.

**Fail condition:** Field not documented in the table, or missing from the schema example.

---

## AC-7: `core/state-manager.md` includes version read and write

**Verification:** Grep core/state-manager.md for plugin version initialization logic.

**Machine-checkable commands:**

```bash
# Write Process references plugin_version
grep -q "plugin_version" core/state-manager.md

# References plugin.json as the source
grep -q "plugin.json" core/state-manager.md
```

**Pass condition:** The Write Process section in `core/state-manager.md` contains both `plugin_version` and `plugin.json` references, indicating that state initialization reads the version from the plugin metadata file.

**Fail condition:** Either reference is missing from the state-manager contract.

---

## AC-8: `resume-ticket` includes version comparison

**Verification:** Grep resume-ticket for version comparison logic.

**Machine-checkable commands:**

```bash
# References plugin_version field
grep -q "plugin_version" skills/resume-ticket/SKILL.md

# Contains WARN log message for mismatch
grep -q "major version mismatch" skills/resume-ticket/SKILL.md

# References plugin.json for current version
grep -q "plugin.json" skills/resume-ticket/SKILL.md

# Comparison is advisory (no block)
grep "major version mismatch" skills/resume-ticket/SKILL.md | grep -qi "warn"
```

**Pass condition:** `skills/resume-ticket/SKILL.md` contains: (a) `plugin_version` reference, (b) `major version mismatch` warning text, (c) `plugin.json` reference for reading current version, (d) the mismatch message is a WARN (not a block).

**Fail condition:** Any of the 4 checks fails.

---

## AC-9: No WARN when `plugin_version` field is missing

**Verification:** Read the resume-ticket logic for the backwards compatibility guard.

**Machine-checkable commands:**

```bash
# The skill explicitly handles the absent/null case
grep -q "absent\|null" skills/resume-ticket/SKILL.md | head -5

# More precise: look for skip/silent behavior when field is missing
grep -A2 "plugin_version.*absent\|plugin_version.*null\|field is absent\|field.*missing" skills/resume-ticket/SKILL.md | grep -qi "skip\|silent\|no WARN"
```

**Pass condition:** The resume-ticket skill contains explicit language indicating that when `plugin_version` is absent or null, the version check is skipped silently (no WARN emitted). This ensures backwards compatibility with state files created by plugin versions before v6.7.0.

**Fail condition:** The skill does not have an explicit guard for the missing field case, or the guard emits a WARN instead of skipping silently.

**Manual verification (fallback):** Read `skills/resume-ticket/SKILL.md` and confirm the version check sub-step contains a conditional: "If `plugin_version` field is absent or null: skip version check silently (no WARN)".

---

## AC-10: Existing test suite passes (regression check)

**Verification:** Run the full test harness.

**Machine-checkable commands:**

```bash
./tests/harness/run-tests.sh
```

**Pass condition:** All existing tests pass (exit 0). The `xref-core-registry.sh` test must pass with the updated count of 14.

**Fail condition:** Any existing test fails, indicating a regression introduced by v6.7.0 changes.

---

## Summary Matrix

| AC | Requirement(s) | Verification Method | Automated |
|----|---------------|-------------------|-----------|
| AC-1 | R-001, R-002 | File existence + grep | Yes |
| AC-2 | R-003 | Grep 5 skill files | Yes |
| AC-3 | R-004 | Grep 5 agent files | Yes |
| AC-4 | R-005 | Grep CLAUDE.md + ls count | Yes |
| AC-5 | R-006 | Run test script | Yes |
| AC-6 | R-007 | Grep state/schema.md | Yes |
| AC-7 | R-008 | Grep core/state-manager.md | Yes |
| AC-8 | R-009 | Grep resume-ticket/SKILL.md | Yes |
| AC-9 | R-010 | Grep + manual read | Partial |
| AC-10 | All | Run test harness | Yes |
