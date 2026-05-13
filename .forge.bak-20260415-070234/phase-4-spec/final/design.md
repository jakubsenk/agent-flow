# Design Specification — v6.5.1 PATCH: Format Evaluation Fixes

## Implementation Approach

All five changes are independent, single-file edits (C5 touches two files but the edits are independent of each other). No change has dependencies on another. The changes can be implemented in any order, but the recommended order below minimizes cognitive switching by grouping by file type.

---

## Change Order

| Order | Change | Rationale |
|-------|--------|-----------|
| 1 | C1 — scaffolder step renumber | Simplest change (2-line edit). Quick win to confirm editing workflow works. |
| 2 | C2 — fix-bugs contributor note | Single-line insertion. No judgment calls — exact text specified. |
| 3 | C3 — triage-analyst constraints | Additive constraint lines. Grouped with other agent constraint work. |
| 4 | C4 — code-analyst constraints | Same pattern as C3. |
| 5 | C5 — fixer + reviewer constraints | Two files, same pattern. Completes the constraint sweep. |

---

## File-by-File Change List

### 1. `agents/scaffolder.md`

**Change:** C1 — Fix duplicate step numbering

**Edits:**

| Line | Current | New |
|------|---------|-----|
| 149 | `4b. Generate quality scorecard:` | `5. Generate quality scorecard:` |
| 150 | `    Items 1 (Build) ...` (4-space indent) | `   Items 1 (Build) ...` (3-space indent, matching numbered-step convention) |
| 165 | `5. Output:` | `6. Output:` |

**Estimated LOC changed:** 3 lines modified (step labels and indentation alignment)

**Risk:** VERY LOW. No downstream code references scaffolder internal step numbers. The `description` frontmatter field and all external references (CLAUDE.md, docs, tests) reference the agent by name, not by internal step numbering.

---

### 2. `skills/fix-bugs/SKILL.md`

**Change:** C2 — Add contributor note

**Edit:** Insert one HTML comment line immediately before line 89 (first occurrence of "Follow atomic write protocol").

**Exact insertion:**
```
<!-- Contributor note: "Follow atomic write protocol from core/state-manager.md" appears at each state.json write step intentionally. This is LLM-directed repetition for reliable per-step compliance — not accidental duplication. Do not consolidate. -->
```

**Estimated LOC changed:** 1 line inserted

**Risk:** VERY LOW. HTML comments are invisible to the LLM runtime. The comment is placed inside the `### 0. MCP pre-flight check` section, before the first state-write instruction. No functional change to the skill.

---

### 3. `agents/triage-analyst.md`

**Change:** C3 — Add token-spelling constraints

**Edit:** Insert two new constraint lines in the `## Constraints` section. Place them after the "MUST store downloaded attachments" line (line 111) and before the "If issue tracker MCP server" line (line 112), maintaining the pattern of MUST rules grouped together.

**Lines to insert:**
```
- MUST use exactly `PASS` or `UNCLEAR` as the Quality gate value. No variations (not "incomplete", "insufficient", "fail", or other synonyms).
- MUST output Reproduction steps as a JSON array literal (e.g., `[{action: "navigate", target: "/"}]`), not as prose or numbered list. Omit the field entirely if not UI-related.
```

**Estimated LOC changed:** 2 lines inserted

**Risk:** LOW. The constraints are additive — they document existing implicit behavior. The triage-analyst already has inline documentation of `UNCLEAR` as the machine token (line 44), and the Reproduction steps format is already specified in step 8 (line 70). These constraints elevate the requirement from inline documentation to explicit constraint-section enforcement.

Note: The `UNCLEAR` token is already well-documented inline in step 4 (line 44: "The token `UNCLEAR` is the machine-readable signal..."). Adding the constraint in the Constraints section provides a second enforcement point, consistent with the pattern used for other agents.

---

### 4. `agents/code-analyst.md`

**Change:** C4 — Add token-spelling constraints

**Edit:** Insert two new constraint lines in the `## Constraints` section. Place them after the "Risk level criteria" line (line 106) and before the "If codebase is too large" line (line 107).

**Lines to insert:**
```
- MUST use exactly `YES` or `NO` as the `root cause confirmed` value. No variations (not "confirmed", "unconfirmed", "partial", or other synonyms).
- MUST use exactly one of `LOW`, `MEDIUM`, `HIGH` as the Risk level value. No variations.
```

**Estimated LOC changed:** 2 lines inserted

**Risk:** LOW. Additive constraints documenting existing implicit behavior. The risk level values are already defined on line 106 ("Risk level criteria: LOW = ..., MEDIUM = ..., HIGH = ...") and `root cause confirmed` values are already specified in the output template (line 92: `root cause confirmed: {YES / NO}`). These constraints make the spelling requirement explicit.

---

### 5a. `agents/fixer.md`

**Change:** C5a — Add NEEDS_DECOMPOSITION spelling constraint

**Edit:** Insert one new constraint line in the `## Constraints` section. Place it after the "NEVER signal NEEDS_DECOMPOSITION to avoid a hard problem" line (line 82) and before the "NEVER change more than necessary" line (line 83). This groups the two NEEDS_DECOMPOSITION-related constraints together.

**Line to insert:**
```
- MUST use the exact string `NEEDS_DECOMPOSITION` when signaling decomposition need. No variations (not "NEEDS DECOMPOSITION", "needs_decomposition", "decomposition needed", or other forms).
```

**Estimated LOC changed:** 1 line inserted

**Risk:** LOW. Additive constraint. The fixer already uses this token in its Process section (step 5, line 39-48), including the exact heading `## NEEDS_DECOMPOSITION`. The constraint makes the spelling requirement explicit in the Constraints section where behavioral rules are enforced.

---

### 5b. `agents/reviewer.md`

**Change:** C5b — Add Verdict and AC fulfillment spelling constraints

**Edit:** Insert two new constraint lines in the `## Constraints` section. Place them after the "Verdict = BLOCK only for" line (line 110) and before the "If acceptance criteria were provided" line (line 111).

**Lines to insert:**
```
- MUST use exactly one of: `APPROVE`, `REQUEST_CHANGES`, `BLOCK` as the Verdict value. No variations, no additional qualifiers (not "APPROVED", "CHANGES_REQUESTED", "BLOCKED", or other forms).
- MUST use exactly one of: `FULFILLED`, `PARTIALLY`, `NOT ADDRESSED` for each AC fulfillment verdict. No variations.
```

**Estimated LOC changed:** 2 lines inserted

**Risk:** LOW. Additive constraints. The verdict values are already specified in the output template (line 70: `{APPROVE | REQUEST_CHANGES | BLOCK}`) and AC values in step 4 (lines 41-43). The constraints elevate these to explicit Constraints-section rules.

---

## Total Estimated Impact

| Metric | Value |
|--------|-------|
| Files modified | 6 |
| Lines inserted | 10 |
| Lines modified | 3 |
| Lines deleted | 0 |
| Total LOC delta | +10, ~3 modified |

---

## Risk Assessment Summary

| Change | Risk | Blast Radius | Failure Mode |
|--------|------|-------------|--------------|
| C1 — scaffolder renumber | VERY LOW | 1 file | Step numbering mismatch in output template references (verified: none exist) |
| C2 — contributor note | VERY LOW | 1 file | HTML comment accidentally breaks markdown parsing (impossible — standard HTML comment syntax) |
| C3 — triage-analyst constraints | LOW | 1 file | Constraint wording conflicts with existing inline documentation (verified: consistent) |
| C4 — code-analyst constraints | LOW | 1 file | Same as C3 |
| C5 — fixer + reviewer constraints | LOW | 2 files | Constraint wording restricts valid behavior too aggressively (verified: constraints match existing output templates exactly) |

**Aggregate risk:** LOW. All changes are additive or corrective. No existing behavior is removed or altered. No downstream files need updating. The test suite (`tests/harness/run-tests.sh`) should pass unchanged since these are documentation/constraint additions that do not affect test-observable behavior.

---

## Items Explicitly Out of Scope

Per the judge verdict, the following are NOT implemented in this run:

1. **Remove `Issues found: {count}` from reviewer output** — Listed as item 5 in the verdict, but this is a format change to the reviewer output template, not a constraint addition. Deferred to avoid unnecessary churn. The field is harmless as-is.
2. **Machine Output sections** — Deferred to v7.0.0 (MAJOR version).
3. **Config template format migration** — Deferred to future MINOR release (v6.6.0).
4. **Skill file decomposition** — Blocked on runtime research.
5. **Any YAML/JSON format migration** — Permanently rejected.
