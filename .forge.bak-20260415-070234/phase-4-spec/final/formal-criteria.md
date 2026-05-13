# Formal Acceptance Criteria — v6.5.1 PATCH: Format Evaluation Fixes

Each criterion is independently verifiable by reading the specified file(s) or running the test harness.

---

## AC-1: Scaffolder step numbering is sequential 1-6

**Verification:** Read `agents/scaffolder.md` Process section.

**Pass condition:**
- Steps are numbered 1, 2, 3, 4, 5, 6 with no substep labels (no `4b`).
- Step 5 is "Generate quality scorecard" (previously `4b`).
- Step 6 is "Output" (previously `5`).
- No other Process step numbers are affected (steps 1-4 remain unchanged).

**Fail condition:** Any step uses the `4b` label, or renumbering skipped one of the two affected steps, or steps 1-4 were inadvertently modified.

---

## AC-2: Contributor note exists in fix-bugs/SKILL.md before first atomic-write reference

**Verification:** Read `skills/fix-bugs/SKILL.md` and search for the HTML comment.

**Pass condition:**
- An HTML comment containing the text "intentional" and "Do not consolidate" (or semantically equivalent) appears before or immediately adjacent to the first occurrence of "Follow atomic write protocol from core/state-manager.md".
- The comment is a valid HTML comment (starts with `<!--`, ends with `-->`).
- All 16 existing occurrences of "Follow atomic write protocol from core/state-manager.md" remain intact and unmodified.

**Fail condition:** The comment is missing, or any occurrence of the atomic-write phrase was removed/consolidated, or the comment is placed after all occurrences rather than near the first.

---

## AC-3: triage-analyst has explicit token-spelling constraints

**Verification:** Read `agents/triage-analyst.md` Constraints section.

**Pass condition:**
- The Constraints section contains a rule specifying exact allowed values for the Quality gate token (at minimum: `PASS` and `UNCLEAR`).
- The Constraints section contains a rule specifying JSON array literal format for Reproduction steps.
- Both rules use imperative language (MUST) consistent with existing constraint style.

**Fail condition:** Either constraint is missing, or the constraint uses permissive language ("should", "prefer") instead of imperative ("MUST").

---

## AC-4: code-analyst has explicit token-spelling constraints

**Verification:** Read `agents/code-analyst.md` Constraints section.

**Pass condition:**
- The Constraints section contains a rule specifying exact allowed values for `root cause confirmed` (at minimum: `YES` and `NO`).
- The Constraints section contains a rule specifying exact allowed values for Risk level (at minimum: `LOW`, `MEDIUM`, `HIGH`).
- Both rules use imperative language (MUST).

**Fail condition:** Either constraint is missing or uses non-imperative language.

---

## AC-5: fixer and reviewer have explicit token-spelling constraints

**Verification:** Read `agents/fixer.md` and `agents/reviewer.md` Constraints sections.

**Pass condition — fixer:**
- The Constraints section contains a rule specifying the exact string `NEEDS_DECOMPOSITION` with no variations allowed.
- The rule uses imperative language (MUST).

**Pass condition — reviewer:**
- The Constraints section contains a rule specifying exact allowed Verdict values: `APPROVE`, `REQUEST_CHANGES`, `BLOCK` with no variations allowed.
- The Constraints section contains a rule specifying exact allowed AC fulfillment values: `FULFILLED`, `PARTIALLY`, `NOT ADDRESSED` with no variations allowed.
- Both rules use imperative language (MUST).

**Fail condition:** Any of the three constraints (fixer: 1, reviewer: 2) is missing, uses permissive language, or lists incorrect token values.

---

## AC-6: No existing functionality is broken (negative criterion)

**Verification:** Run `./tests/harness/run-tests.sh` from the repository root.

**Pass condition:**
- All existing test scenarios pass with the same results as before the changes.
- No test scenario that previously passed now fails.

**Fail condition:** Any test scenario fails that did not fail before the changes were applied. (Pre-existing failures, if any, are excluded from this criterion.)

---

## AC-7: Agent frontmatter and section structure is preserved (negative criterion)

**Verification:** Read the YAML frontmatter and section headings of all 6 modified files.

**Pass condition — agents (5 files):**
- Each agent file retains its original YAML frontmatter (`name`, `description`, `model`, `style`) with zero modifications.
- Each agent file retains the section order: Goal, Expertise, Process, Constraints (per CLAUDE.md convention).
- No section was removed, reordered, or renamed.

**Pass condition — skill (1 file):**
- `skills/fix-bugs/SKILL.md` retains its original YAML frontmatter (`name`, `description`, `allowed-tools`, `disable-model-invocation`, `argument-hint`) with zero modifications.
- No skill section was removed, reordered, or renamed.

**Fail condition:** Any frontmatter field was modified, any section was removed or reordered, or any content outside the specified change locations was altered.
