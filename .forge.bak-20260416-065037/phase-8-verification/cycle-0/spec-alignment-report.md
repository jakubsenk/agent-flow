# Spec Alignment Report — ceos-agents v6.7.1

**Reviewer:** Spec Alignment Reviewer (Opus 4.6)
**Date:** 2026-04-15
**Spec files:** `.forge/phase-4-spec/final/requirements.md`, `.forge/phase-4-spec/final/formal-criteria.md`

## Summary

**Score: spec_alignment = 0.88**

- **44 formal acceptance criteria** evaluated
- **37 PASS** (84.1%)
- **4 FAIL** (9.1%) — 3 from Item 5 numbering deviation, 1 from Item 2 reference text
- **3 SOFT FAIL** (6.8%) — semantically correct but formal grep pattern does not match

All 7 specification items have implementations present. No missing features. All deviations are cosmetic or structural (numbering style, text phrasing) rather than functional.

---

## Per-Item Verification

### Item 1: config-reader Missing Key (REQ-001)

| AC | Result | Notes |
|----|--------|-------|
| AC-1 | PASS | `decomposition.create_tracker_subtasks` present in `core/config-reader.md` line 33 |
| AC-2 | PASS | Default value `enabled` documented |
| AC-3 | PASS | All 4 Decomposition keys on same line |

**Verdict: FULLY ALIGNED.** REQ-001 satisfied exactly as specified.

---

### Item 2: Config Validity Gate in fix-bugs (REQ-002 to REQ-005)

| AC | Result | Notes |
|----|--------|-------|
| AC-4 | PASS | `### Step 0b: Config Validity Gate` heading present |
| AC-5 | **FAIL** | fix-bugs does NOT reference `implement-feature.md Step 0b`. Instead, it inlines the full gate text (byte-identical to implement-feature Step 0b). fix-ticket references it; fix-bugs does not. |
| AC-6 | PASS | All 4 required sections listed on one line |
| AC-7 | PASS | `[ceos-agents]` block comment template with `🔴` present |
| AC-8 | PASS | Step 0b between MCP pre-flight check and `## Orchestration` |
| AC-9 | PASS | Terminal instruction says "proceed to Step 1" |

**REQ-005 analysis (byte-identical):** The fix-bugs Step 0b text is byte-identical to the **implement-feature** Step 0b (the canonical source), not to the fix-ticket Step 0b. The fix-ticket version has a different intro line ("Follow the same validation logic as implement-feature.md Step 0b:") and slightly compressed step 2-3 formatting. Since the spec says "byte-identical to the Step 0b text in fix-ticket", this is technically a deviation, but the implementation is arguably more correct (it copies the canonical source rather than the reference).

**Verdict: NEARLY ALIGNED.** 5/6 AC pass. The missing reference text (AC-5) is a documentation style choice, not a functional gap.

---

### Item 3: State Schema Retry Limit Fields (REQ-006, REQ-007)

| AC | Result | Notes |
|----|--------|-------|
| AC-10 | PASS | `config.retry_limits.spec_iterations` with default `5` in field table |
| AC-11 | PASS | `config.retry_limits.root_cause_iterations` with default `3` in field table |
| AC-12 | PASS | `spec_iterations` row after `build_retries`, before `infrastructure` |
| AC-13 | PASS | JSON example contains both fields |
| AC-14 | PASS | `build_retries` line has trailing comma |
| AC-15 | PASS | Description uses `↔` separator |

**Verdict: FULLY ALIGNED.** All 6 AC pass. Both REQ-006 and REQ-007 satisfied exactly.

---

### Item 4: Code-analyst Before Architect in implement-feature (REQ-008 to REQ-012)

**Key question: Was the step made UNCONDITIONAL (as decided in Gate 1)?**

**Answer: YES.** Step 3a dispatches `ceos-agents:code-analyst` unconditionally. There is no keyword heuristic, no `if.*modification` or `if.*refactor` gate. The only skip mechanism is Pipeline Profiles (`Skip stages` list), which is the standard opt-out mechanism per REQ-009.

| AC | Result | Notes |
|----|--------|-------|
| AC-16 | PASS | `### 3a. Code-analyst` heading present |
| AC-17 | PASS | Dispatches `ceos-agents:code-analyst` via Task |
| AC-18 | PASS | Unconditional — `Skip stages` reference present, no keyword heuristic |
| AC-19 | **SOFT FAIL** | Text says "proceeding to architect without impact analysis" instead of "continuing without impact analysis". Behavior is correct (log warning, proceed to step 4), but exact grep pattern `'Code-analyst blocked.*continuing without impact analysis'` fails due to different verb. |
| AC-20 | PASS | Stage map: `code-analyst = step 3a (Code-analyst)` |
| AC-21 | PASS | Old N/A entry removed |
| AC-22 | PASS | Architect context mentions "code-analyst impact analysis (if available)" |
| AC-23 | PASS | Context includes `Mode: feature. Pipeline: implement-feature.` |
| AC-24 | PASS | State update with `code_analysis.status` present |
| AC-25 | PASS | Step 3a between Step 3 (Spec-analyst) and Step 4 (Architect) |

**Verdict: FULLY ALIGNED (with minor text variant).** 9/10 AC pass. The AC-19 soft fail is a synonym substitution ("proceeding to architect" vs "continuing") — functionally identical, non-fatal blocking behavior implemented correctly per REQ-010.

---

### Item 5: Marker Nesting Attack Mitigation (REQ-013 to REQ-016)

| AC | Result | Notes |
|----|--------|-------|
| AC-26 | **FAIL** | No `1b.` step exists. Escaping was implemented as step `2.` (renumbering original steps). REQ-014 explicitly says "step 1b". |
| AC-27 | PASS | `[ESCAPED: EXTERNAL INPUT START]` format present |
| AC-28 | PASS | `[ESCAPED: EXTERNAL INPUT END]` format present |
| AC-29 | PASS | Idempotency mentioned in the escaping step text |
| AC-30 | **FAIL** | Cannot verify ordering since step 1b does not exist. However, step 2 (escaping) is before step 3 (wrapping) — ordering is functionally correct. |
| AC-31 | **FAIL** | Pattern `grep '1b\.'` finds nothing. The step 2 text does say "Before wrapping" but under `2.` not `1b.`. |

**Additional issue found:** There is a numbering bug — two steps are numbered `3.` (lines 28 and 36). The original step 2 (wrapping) became step 3, but the original step 3 was not renumbered to 4. This creates ambiguity.

**Escaping format check:** Uses `[ESCAPED: ...]` format as specified in REQ-013. PASS.

**Idempotency (REQ-015):** Explicitly mentioned: "The transform is idempotent -- applying it to already-escaped content produces no additional changes." PASS.

**Literal-only matching (REQ-016):** The implementation says "literal occurrences of the boundary marker strings". Only full marker strings are matched. PASS.

**Verdict: FUNCTIONALLY ALIGNED, STRUCTURALLY DEVIANT.** The escaping logic is correct (right format, idempotent, before wrapping, literal-only). But the step numbering deviates from spec (step 2 instead of 1b) and introduces a duplicate step 3 bug. 3/6 AC formally fail.

---

### Item 6: State-Manager Graceful Degradation (REQ-017, REQ-018)

| AC | Result | Notes |
|----|--------|-------|
| AC-32 | **SOFT FAIL** | Grep pattern expects `"unreadable, malformed, or lacks"` but text says `"unreadable, contains malformed JSON, or lacks"`. Extra "contains" and "JSON" words break the exact pattern, but meaning is identical. |
| AC-33 | PASS | `plugin_version` to `null` documented |
| AC-34 | PASS | "no error, no warning" present |
| AC-35 | PASS | Inline on Step 2a with `plugin.json` and `null` |

**Verdict: FULLY ALIGNED (with minor text expansion).** The implementation adds specificity ("contains malformed JSON" instead of just "malformed") which is an improvement, not a defect.

---

### Item 7: Extended NEVER Constraint to 5 Additional Agents (REQ-019 to REQ-022)

**Key question: Were ALL 5 agents updated (not just the original 3)?**

**Answer: YES.** All 5 new agents have the constraint: acceptance-gate, architect, reproducer, priority-engine, browser-verifier. Combined with the existing 5 (triage-analyst, code-analyst, fixer, spec-analyst, reviewer), all 10 agents carry the NEVER constraint.

| AC | Result | Notes |
|----|--------|-------|
| AC-36 | PASS | All 10 agents have EXTERNAL INPUT START + NEVER |
| AC-37 | PASS | All 10 agents have EXTERNAL INPUT END + NEVER |
| AC-38 | PASS | Constraint text byte-identical across all 10 agents |
| AC-39 | PASS | Constraint is last line in all 5 new agents |
| AC-40 | PASS | AGENTS_TO_CHECK array has exactly 10 agents |
| AC-41 | PASS | All 5 new agents in the array |
| AC-42 | PASS | AC-3 comment updated to "All 10 agents" |

**Verdict: FULLY ALIGNED.** All 7 AC pass. All 10 agents covered. Test file updated.

---

### Cross-Cutting Criteria

| AC | Result | Notes |
|----|--------|-------|
| AC-43 | PASS | 21 agent files, 14 core files — counts unchanged |
| AC-44 | PASS | `prompt-injection-protection.sh` exits 0 |

---

## Roadmap Verification

The roadmap at `docs/plans/roadmap.md` has the v6.7.1 section marked as `## DONE -- v6.7.1` with all 7 items listed. Status: **ALIGNED.**

## CLAUDE.md Counts

CLAUDE.md declares "28 skills" and "14 shared pipeline pattern contracts" and "21 agents". No new files were created. Counts: **UNCHANGED.**

## Test Array Verification

`tests/scenarios/prompt-injection-protection.sh` AGENTS_TO_CHECK array contains exactly 10 agents:
triage-analyst, code-analyst, fixer, spec-analyst, reviewer, acceptance-gate, architect, reproducer, priority-engine, browser-verifier. **PASS.**

---

## Deviations Summary

| # | Item | AC | Severity | Description |
|---|------|----|----------|-------------|
| D1 | 5 — Sanitizer | AC-26, AC-30, AC-31 | Medium | Escaping step numbered as `2.` instead of spec's `1b.`. Functionally correct but violates explicit numbering requirement. |
| D2 | 5 — Sanitizer | N/A | Low | Duplicate step `3.` numbering (lines 28 and 36). Bug introduced during renumbering. |
| D3 | 2 — fix-bugs | AC-5 | Low | fix-bugs inlines Step 0b instead of referencing `implement-feature.md Step 0b`. Functionally identical. |
| D4 | 4 — implement-feature | AC-19 | Low | "proceeding to architect without" vs spec's "continuing without". Synonym, not a semantic difference. |
| D5 | 6 — state-manager | AC-32 | Low | "contains malformed JSON" vs spec's "malformed". Adds specificity, not a defect. |
| D6 | 2 — fix-bugs | REQ-005 | Low | Step 0b byte-identical to implement-feature (correct canonical source) rather than fix-ticket (spec's stated reference). |

---

## Scoring Rationale

- **7 items specified, 7 items implemented** — no missing work
- **44 AC total: 37 PASS, 4 FAIL, 3 SOFT FAIL**
- All FAILs are in Item 5 (step numbering deviation) — the escaping logic itself is correct
- All SOFT FAILs are minor text variations that preserve meaning
- No functional or security regressions detected
- The unconditional code-analyst decision (Gate 1 override) is correctly implemented
- All 10 agents have byte-identical NEVER constraints
- Test coverage is complete (10 agents in test array)

**Score: 0.88** — High alignment. All functionality present and correct. Deductions for:
- Item 5 numbering deviation (step 2 vs 1b) + duplicate step 3 bug (-0.07)
- Item 2 missing cross-reference (-0.02)
- Item 4 + Item 6 minor text variants (-0.03)
