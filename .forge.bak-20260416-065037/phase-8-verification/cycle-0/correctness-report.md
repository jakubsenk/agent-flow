# Correctness Report — ceos-agents v6.7.1
**Reviewer:** Correctness Agent (cycle-0)
**Date:** 2026-04-15
**Score:** 0.82 (36/44 AC pass)

---

## Test Suite

**Result:** 81/81 PASS, 0 FAIL, 0 SKIP

All existing tests pass. No regressions introduced.

---

## AC Verification Results

### Item 1 — config-reader Missing Key (AC-1 to AC-3)

| AC | Result | Notes |
|----|--------|-------|
| AC-1 | PASS | `decomposition.create_tracker_subtasks` present in `core/config-reader.md` |
| AC-2 | PASS | Default `enabled` correctly specified |
| AC-3 | PASS | Key is on the same line as other Decomposition entries |

**Item verdict: PASS (3/3)**

---

### Item 2 — Config Validity Gate in fix-bugs (AC-4 to AC-9)

| AC | Result | Notes |
|----|--------|-------|
| AC-4 | PASS | `### Step 0b: Config Validity Gate` heading present |
| AC-5 | **FAIL** | Missing phrase `implement-feature.md Step 0b`; step is fully inline without the cross-reference. The plan required `"Follow the same validation logic as implement-feature.md Step 0b:"` as the first line. |
| AC-6 | PASS | All 4 required sections checked (Issue Tracker, Source Control, PR Rules, Build & Test) |
| AC-7 | PASS | `[ceos-agents] 🔴 Pipeline Block` block comment present |
| AC-8 | PASS | Step 0b appears between MCP pre-flight (line 80) and `## Orchestration` (line 115) |
| AC-9 | PASS | `proceed to Step 1` present |

**Item verdict: PARTIAL (5/6)**

**Defect D-1 (low severity):** `skills/fix-bugs/SKILL.md` Step 0b is fully functional — it contains the correct 5-step gate logic and block template — but is missing the cross-reference phrase `"Follow the same validation logic as implement-feature.md Step 0b:"`. The AC verification command `grep -q 'implement-feature.md Step 0b'` fails. Behavioral correctness is not compromised; only the pointer to the canonical source is absent.

---

### Item 3 — State Schema Retry Limit Fields (AC-10 to AC-15)

| AC | Result | Notes |
|----|--------|-------|
| AC-10 | PASS | `config.retry_limits.spec_iterations` with default `5` in field table |
| AC-11 | PASS | `config.retry_limits.root_cause_iterations` with default `3` in field table |
| AC-12 | PASS | `spec_iterations` row at line 161, after `build_retries` (160), before `infrastructure` (163) |
| AC-13 | PASS | `"spec_iterations"` and `"root_cause_iterations"` present in JSON example |
| AC-14 | PASS | `"build_retries": 3,` has trailing comma in JSON block |
| AC-15 | PASS | `spec_iterations` description contains `↔` separator (`spec-writer↔spec-reviewer`) |

**Item verdict: PASS (6/6)**

---

### Item 4 — Code-analyst Before Architect in implement-feature (AC-16 to AC-25)

| AC | Result | Notes |
|----|--------|-------|
| AC-16 | PASS | `### 3a. Code-analyst` heading present |
| AC-17 | PASS | Step 3a dispatches `ceos-agents:code-analyst` via Task tool |
| AC-18 | PASS | Step 3a gated by `Skip stages` only, no keyword/heuristic gate |
| AC-19 | **FAIL** | Actual text: `"code-analyst blocked — proceeding to architect without impact analysis"`. AC expects regex `Code-analyst blocked.*continuing without impact analysis`. Two mismatches: (a) lowercase `c` in `code-analyst`, (b) `"proceeding"` vs `"continuing"`. |
| AC-20 | PASS | Stage map updated to `code-analyst = step 3a (Code-analyst)` |
| AC-21 | PASS | Old `N/A — feature pipeline does not have code-analyst` entry removed |
| AC-22 | **FAIL** | Architect context line reads `"code-analyst impact analysis (if available)"`. AC expects `"code-analyst impact report"`. The word `"report"` is not present — `"analysis"` is used instead. |
| AC-23 | PASS | Step 3a context includes `Mode: feature. Pipeline: implement-feature.` |
| AC-24 | PASS | `code_analysis.status` state.json update present in step 3a |
| AC-25 | PASS | Step 3a at line 191, between step 3 (line 177) and step 4 (line 204) |

**Item verdict: PARTIAL (8/10)**

**Defect D-2 (low severity):** `skills/implement-feature/SKILL.md` step 3a warning text uses lowercase `"code-analyst"` and the word `"proceeding"` instead of the plan's `"Code-analyst"` and `"continuing"`. The behavior (non-fatal warning, continue to architect) is correctly implemented; only the exact phrasing differs from the plan specification.

**Defect D-3 (negligible severity):** Architect step 4 uses `"code-analyst impact analysis"` where the AC verifier expects `"code-analyst impact report"`. Both terms unambiguously refer to the same artefact. Functional behavior is identical. This is a terminology inconsistency between the AC definition and the implementation text.

---

### Item 5 — Marker Nesting Attack Mitigation (AC-26 to AC-31)

| AC | Result | Notes |
|----|--------|-------|
| AC-26 | **FAIL** | No step labeled `1b.` in `core/external-input-sanitizer.md`. The escaping content was inserted as step `2.` (renumbering the original wrap step to `3.`). |
| AC-27 | PASS | `[ESCAPED: EXTERNAL INPUT START]` replacement string present |
| AC-28 | PASS | `[ESCAPED: EXTERNAL INPUT END]` replacement string present |
| AC-29 | **FAIL** | `idempotent` keyword present but inside step `2.`, not `1b.` — AC check via `grep -A 10 '1b\.' | grep -qi 'idempotent'` returns nothing |
| AC-30 | **FAIL** | No `1b.` label exists so position comparison fails (integer parse error on empty string) |
| AC-31 | **FAIL** | `"Before wrapping"` appears at line 24 as `"2. Before wrapping..."` — AC checks `grep '1b\.' | grep -qi 'before wrapping'` which yields nothing |

**Item verdict: PARTIAL (2/6)**

**Defect D-4 (medium severity):** The implementation inserted the marker-escape logic as step `2.` and renumbered the original wrap step to `3.`, producing this structure:
1. Identify content
2. Before wrapping, scan and escape markers (new)
3. Wrap each piece (was step 2)
3. Include wrapped content in context (duplicate step 3 — structural bug)
4. Multiple pieces wrapped individually

The security content is correct — the escape logic, replacement strings, and idempotency guarantee are all present. However:
- The step label is `2.` not `1b.`, causing AC-26/29/30/31 to fail
- There is a **duplicate step 3** in the file (lines 28 and 36 both labeled `3.`), which is a structural defect

The plan (T-002) explicitly required inserting the content as `1b.` between step 1 and the existing step 2, not renumbering steps. This deviation breaks 4 AC checks.

---

### Item 6 — State-Manager Graceful Degradation (AC-32 to AC-35)

| AC | Result | Notes |
|----|--------|-------|
| AC-32 | **FAIL** | Actual text: `"unreadable, contains malformed JSON, or lacks"`. AC expects `"unreadable, malformed, or lacks"`. The extra words `"contains malformed JSON"` instead of just `"malformed"` cause the exact match to fail. |
| AC-33 | PASS | `plugin_version` set to `null` |
| AC-34 | PASS | `no error, no warning` phrase present |
| AC-35 | PASS | Clause is inline on step 2a, contains `plugin.json` and `null` |

**Item verdict: PARTIAL (3/4)**

**Defect D-5 (negligible severity):** The plan required `"unreadable, malformed, or lacks"` (concise form). The actual wording is `"unreadable, contains malformed JSON, or lacks"` — semantically identical but more verbose. The intent and behavior are fully correct. Only the exact string match in the AC verifier fails.

---

### Item 7 — Extended NEVER Constraint (AC-36 to AC-42)

| AC | Result | Notes |
|----|--------|-------|
| AC-36 | PASS | All 10 agents have NEVER constraint with EXTERNAL INPUT START |
| AC-37 | PASS | All 10 agents have NEVER constraint with EXTERNAL INPUT END |
| AC-38 | PASS | All 5 new agents (acceptance-gate, architect, reproducer, priority-engine, browser-verifier) have byte-identical constraint text to triage-analyst |
| AC-39 | PASS | Constraint is last line in all 5 new agents |
| AC-40 | PASS | `AGENTS_TO_CHECK` array contains exactly 10 agents |
| AC-41 | PASS | All 5 new agents present in `AGENTS_TO_CHECK` |
| AC-42 | PASS | `"All 10 agents"` present, `"All 5 agents"` removed |

**Item verdict: PASS (7/7)**

---

### Cross-Cutting (AC-43 to AC-44)

| AC | Result | Notes |
|----|--------|-------|
| AC-43 | PASS | 21 agent files, 14 core files (counts unchanged) |
| AC-44 | PASS | `prompt-injection-protection.sh` exits 0 |

**Cross-cutting verdict: PASS (2/2)**

---

## Regression Check

**Step numbering in modified files:**
- `core/config-reader.md`: Line 33 inline append only — no step renumbering. Clean.
- `core/external-input-sanitizer.md`: Steps 1→1→2→3→3 (malformed — duplicate step 3 at lines 28 and 36). Regression introduced.
- `core/state-manager.md`: Step 2a inline modification only — sequential numbering preserved.
- `state/schema.md`: Two table rows inserted, JSON block extended — no step renumbering. Clean.
- `skills/fix-bugs/SKILL.md`: Step 0b inserted between MCP pre-flight and Orchestration — existing steps unaffected.
- `skills/implement-feature/SKILL.md`: Step 3a inserted between steps 3 and 4, stage map updated — existing step numbers intact.
- `agents/*.md` (5 files): Constraint appended to last line — no structural changes to any section.

**Broken cross-references:** None found.

---

## Summary of Defects

| ID | Severity | AC | File | Issue |
|----|----------|-----|------|-------|
| D-1 | Low | AC-5 | `skills/fix-bugs/SKILL.md` | Step 0b missing cross-ref `"implement-feature.md Step 0b"` |
| D-2 | Low | AC-19 | `skills/implement-feature/SKILL.md` | Warning uses `"code-analyst"` (lowercase) and `"proceeding"` instead of `"Code-analyst"` / `"continuing"` |
| D-3 | Negligible | AC-22 | `skills/implement-feature/SKILL.md` | Architect context uses `"impact analysis"` not `"impact report"` |
| D-4 | Medium | AC-26,29,30,31 | `core/external-input-sanitizer.md` | Escaping step labeled `2.` instead of `1b.`; duplicate step 3 in file |
| D-5 | Negligible | AC-32 | `core/state-manager.md` | Degradation clause uses `"contains malformed JSON"` vs `"malformed"` |

---

## Score

| Item | AC | Pass | Fail | Item Score |
|------|----|------|------|-----------|
| 1 — config-reader | 3 | 3 | 0 | 1.00 |
| 2 — fix-bugs gate | 6 | 5 | 1 | 0.83 |
| 3 — state schema | 6 | 6 | 0 | 1.00 |
| 4 — code-analyst step | 10 | 8 | 2 | 0.80 |
| 5 — sanitizer escape | 6 | 2 | 4 | 0.33 |
| 6 — state-manager degradation | 4 | 3 | 1 | 0.75 |
| 7 — NEVER constraints | 7 | 7 | 0 | 1.00 |
| Cross-cutting | 2 | 2 | 0 | 1.00 |
| **Total** | **44** | **36** | **8** | **0.82** |

**Correctness score: 0.82**

---

## Required Fixes Before Release

The following must be corrected to achieve full AC compliance:

1. **D-4 (highest priority):** Re-label the escaping step in `core/external-input-sanitizer.md` as `1b.` (not `2.`), keep original wrap step as `2.`, renumber subsequent steps to `3.` and `4.`. This fixes AC-26, AC-29, AC-30, AC-31, and eliminates the duplicate step-3 bug.

2. **D-1:** Add `"Follow the same validation logic as implement-feature.md Step 0b:"` as the first line of Step 0b in `skills/fix-bugs/SKILL.md`. Fixes AC-5.

3. **D-2:** In `skills/implement-feature/SKILL.md` step 3a, change warning text to `"Code-analyst blocked — continuing without impact analysis"`. Fixes AC-19.

4. **D-5:** In `core/state-manager.md` step 2a, change `"contains malformed JSON"` to `"malformed"`. Fixes AC-32.

5. **D-3 (optional):** In `skills/implement-feature/SKILL.md` step 4, change `"code-analyst impact analysis"` to `"code-analyst impact report"`. Fixes AC-22. Functionally equivalent — only required for AC compliance.
