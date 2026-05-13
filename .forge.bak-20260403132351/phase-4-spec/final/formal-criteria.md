# Formal Verification Criteria — Scaffold Pipeline Bugfixes

**Version:** 6.1.6 (PATCH)
**Date:** 2026-04-02

Each criterion below is a testable assertion. A criterion PASSES if the stated condition holds after implementation. A criterion FAILS otherwise.

---

## FC-1: Story Sub-Issue Linking (REQ-1)

### FC-1.1: Inline parameter table present

**Assertion:** `skills/scaffold/SKILL.md` Step 4e contains a markdown table with exactly 4 rows (YouTrack, Jira, Linear, Redmine) mapping tracker type to parent parameter name(s).

**Verification method:** Grep for `| YouTrack |` and `| Jira |` and `| Linear |` and `| Redmine |` within the Step 4e section of `skills/scaffold/SKILL.md`. All four must be present within the same table structure. The table must appear between `### Step 4e:` and `### Step 5:`.

### FC-1.2: Cross-file reference removed from inline instruction

**Assertion:** The Step 4e bullet about native sub-issue creation does NOT contain the text `see Sub-Issue Capabilities in \`docs/reference/trackers.md\``.

**Verification method:** Grep for `docs/reference/trackers.md` within lines bounded by `### Step 4e:` and `### Step 5:`. Must return zero matches.

### FC-1.3: Verification sub-step present

**Assertion:** Step 4e contains an instruction to read back the created story issue and confirm the parent field is set.

**Verification method:** Grep for `read the created issue back` or `Verification` within Step 4e. Must return at least one match. The text must reference confirming the parent field.

### FC-1.4: Verification failure is WARN, not BLOCK

**Assertion:** The verification failure handler logs a WARN and continues, not a block.

**Verification method:** The verification sub-step text contains `WARN:` and `continue`. It does NOT contain `Block` or `BLOCK` or `Pipeline Block`.

### FC-1.5: Reference doc unchanged

**Assertion:** `docs/reference/trackers.md` Sub-Issue Capabilities table (lines 86-97) is identical before and after the change.

**Verification method:** `git diff docs/reference/trackers.md` returns empty (no changes to this file).

---

## FC-2: Explicit Story Closing (REQ-2)

### FC-2.1: Cascade assumption removed

**Assertion:** `skills/scaffold/SKILL.md` does NOT contain the phrase "typically cascades to children" anywhere in the file.

**Verification method:** Grep for `cascades to children` in `skills/scaffold/SKILL.md`. Must return zero matches.

### FC-2.2: "Do NOT explicitly close" removed

**Assertion:** `skills/scaffold/SKILL.md` does NOT contain the phrase "Do NOT explicitly close story sub-issues" anywhere in the file.

**Verification method:** Grep for `Do NOT explicitly close` in `skills/scaffold/SKILL.md`. Must return zero matches.

### FC-2.3: Unified close logic for all trackers

**Assertion:** Step 8b contains an instruction to close story sub-issues for ALL tracker types, without branching by tracker type.

**Verification method:** The Step 8b text between items 3.a and 3.d contains a single instruction to close stories that applies to all trackers. It does NOT contain `For GitHub/Gitea` as a separate branch from `For trackers with native sub-issues`.

### FC-2.4: Already-Done idempotency

**Assertion:** Step 8b contains an instruction that if a story issue is already in Done state, it is treated as success.

**Verification method:** Grep for `already in` and `Done` and `success` within Step 8b (between `### Step 8b:` and `### Step 9:`). At least one match combining these concepts must be present.

### FC-2.5: Updated display line includes story count

**Assertion:** The display line in Step 8b item 5 includes story issue count (not just epic count).

**Verification method:** The display template in Step 8b item 5 contains `story issues` in addition to the existing epic count. The format includes both `{N}/{M} epic issues` and `{S} story issues`.

---

## FC-3: Implementation Comments (REQ-3)

### FC-3.1: Step 8a section exists

**Assertion:** `skills/scaffold/SKILL.md` contains a section heading `### Step 8a:` that appears after `### Step 8:` and before `### Step 8b:`.

**Verification method:** Grep for `### Step 8a:` in `skills/scaffold/SKILL.md`. Must return exactly one match. Its line number must be greater than the line number of `### Step 8:` and less than the line number of `### Step 8b:`.

### FC-3.2: Comment uses [ceos-agents] prefix

**Assertion:** The Step 8a comment template starts with `[ceos-agents]`.

**Verification method:** Grep for `\[ceos-agents\] Scaffold implementation completed` within Step 8a. Must return at least one match.

### FC-3.3: Comment is per-epic only

**Assertion:** Step 8a explicitly states comments are posted to epic-level issues, not story issues.

**Verification method:** The Step 8a text contains "epic" in the context of posting comments. It does NOT contain instructions to post comments to story/sub-issue level.

### FC-3.4: Failure is WARN, not BLOCK

**Assertion:** Step 8a comment failure handler uses WARN and continues, never blocks.

**Verification method:** Grep for `WARN:` within Step 8a section. Must return at least one match. Grep for `Block` or `BLOCK` or `Pipeline Block` within Step 8a section (excluding the guard clause reference). Must return zero matches related to blocking the pipeline.

### FC-3.5: Guard clause matches Step 8b guards

**Assertion:** Step 8a has a guard clause that checks `tracker_effective_status`, `tracker_write_available`, and back-reference comment existence.

**Verification method:** Step 8a text contains all three guard conditions: `tracker_effective_status`, `tracker_write_available`, and `back-reference comments`.

### FC-3.6: Step 9 reflects comment count

**Assertion:** Step 9 Final Report tracker display line includes a conditional for implementation comments posted.

**Verification method:** Grep for `comments posted` within the Step 9 section. Must return at least one match.

---

## FC-4: Language Fidelity (REQ-4)

### FC-4.1: spec-writer NEVER constraint present

**Assertion:** `agents/spec-writer.md` Constraints section contains a NEVER rule about diacritics/non-ASCII character preservation.

**Verification method:** Grep for `NEVER.*diacrit` (case-insensitive) in `agents/spec-writer.md`. Must return at least one match. The match must be within the `## Constraints` section.

### FC-4.2: spec-writer constraint uses NEVER prefix

**Assertion:** The new constraint follows the existing convention of starting with "NEVER".

**Verification method:** The line containing the diacritics constraint starts with `- NEVER` (matching the format of all other constraints in the section).

### FC-4.3: Step 4e language fidelity instruction present

**Assertion:** Step 4e in `skills/scaffold/SKILL.md` contains an explicit instruction about preserving diacritics/non-ASCII characters in tracker issue titles and descriptions.

**Verification method:** Grep for `diacrit` or `non-ASCII` or `Language fidelity` within Step 4e (between `### Step 4e:` and `### Step 5:`). At least one match must be present.

### FC-4.4: No other agent files modified

**Assertion:** Only `agents/spec-writer.md` is modified in the `agents/` directory. No other agent files are changed.

**Verification method:** `git diff --name-only agents/` returns only `agents/spec-writer.md` (or empty if checking before commit, the diff of the implementation touches only this one agent file).

---

## Cross-Cutting Criteria

### FC-X.1: No breaking changes

**Assertion:** No new required keys are added to the Automation Config contract. No existing section formats are changed. No agent output format contracts are modified.

**Verification method:** Grep for changes to the `## Config Contract` section in `CLAUDE.md`. Must return zero changes. No new rows in the "required sections" table.

### FC-X.2: Only two files modified

**Assertion:** The implementation touches exactly two files: `skills/scaffold/SKILL.md` and `agents/spec-writer.md`.

**Verification method:** `git diff --name-only` returns exactly these two files (excluding `.forge/` spec artifacts).

### FC-X.3: Existing test suite passes

**Assertion:** All existing tests in `tests/` continue to pass after the changes.

**Verification method:** Run `./tests/harness/run-tests.sh` and confirm exit code 0 with no new failures.

### FC-X.4: Section ordering preserved

**Assertion:** The step numbering in `skills/scaffold/SKILL.md` follows the existing convention: Step 4e, Step 5, Step 6, Step 7, Step 7b, Step 8, Step 8a (new), Step 8b, Step 9.

**Verification method:** Grep for `### Step` in `skills/scaffold/SKILL.md` and verify the headings appear in monotonically increasing order with no gaps or duplicates.

### FC-X.5: Agent definition format preserved

**Assertion:** `agents/spec-writer.md` retains its exact frontmatter structure (name, description, model, style) and section order (Goal, Expertise, Process, Constraints).

**Verification method:** The frontmatter and section headings in `agents/spec-writer.md` are unchanged. Only the Constraints section content has an additional bullet.

---

## Verification Summary

| ID | Requirement | Criteria Count | Critical |
|----|-------------|---------------|----------|
| FC-1 | Story Sub-Issue Linking | 5 | FC-1.1, FC-1.2 |
| FC-2 | Explicit Story Closing | 5 | FC-2.1, FC-2.2, FC-2.3 |
| FC-3 | Implementation Comments | 6 | FC-3.1, FC-3.2, FC-3.5 |
| FC-4 | Language Fidelity | 4 | FC-4.1, FC-4.3 |
| FC-X | Cross-Cutting | 5 | FC-X.2, FC-X.3 |
| **Total** | | **25** | |

All 25 criteria must PASS for the implementation to be accepted.
