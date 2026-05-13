# Phase 4 Review 3 — Devil's Advocate (Tier 3 Only) — Round 2

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true,
    "note": "DA scope: T3 only"
  },
  "tier_2": {
    "fail_to_pass": null,
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true,
    "note": "DA scope: T3 only"
  },
  "tier_3": {
    "correctness": 2,
    "completeness": 3,
    "security": 4,
    "maintainability": 3,
    "robustness": 2,
    "weighted_aggregate": 2.75,
    "pass": false
  },
  "overall_verdict": "FAIL",
  "confidence": 0.91,
  "findings": [
    {
      "id": "f-r2-a1",
      "severity": "CRITICAL",
      "criterion": "correctness",
      "location": "design.md §3.1 Step 0d (lines 129-151) / requirements.md SC-11 step 5 / formal-criteria.md AC-PUBLISH-AUTO-DETECT-EXTRACTION-1",
      "description": "NEW BUG INTRODUCED BY REVISION: The bash idiom cited in design.md §3.1 Step 0d — `candidate=\"${residue%%${post_delim}*}\"` — is incorrect for the primary use case (YouTrack/Jira-style IDs), AND the algorithm in SC-11 is fundamentally incompatible with the worked example.\n\nSC-11 step 5 states: 'split residue at the FIRST occurrence of that delimiter and take the segment BEFORE it'. For `residue=\"PROJ-123-fix-crash\"` and `post_delim=\"-\"`, the FIRST occurrence of `-` is at position 4 (after `PROJ`). 'Split at first `-`' yields `candidate=\"PROJ\"`, NOT `candidate=\"PROJ-123\"`. The algorithm is correct as a string-split but wrong for YouTrack/Jira issue IDs which CONTAIN the delimiter character.\n\nFurther, the cited bash idiom `${residue%%${post_delim}*}` uses `%%` (LONGEST-match from right). On `\"PROJ-123-fix-crash\"` with pattern `-*`, `%%` removes the LONGEST trailing suffix matching `-*`. That suffix is `-123-fix-crash`, yielding `candidate=\"PROJ\"`. Runtime test confirms: `bash -c 'r=\"PROJ-123-fix-crash\"; echo \"${r%%-*}\"'` → `PROJ`.\n\nBoth paths — algorithmic 'first occurrence split' AND bash `%%` idiom — yield `PROJ`, not `PROJ-123`. The worked example in design.md is internally inconsistent with the algorithm it describes. This is a new regression introduced by the revision's attempt to fix the greedy-regex bug: the fix correctly identifies that a delimiter-aware approach is needed, but provides a broken implementation for the standard tracker ID format that CONTAINS the delimiter.\n\nVerification: run `bash -c 'r=\"PROJ-123-fix-crash\"; echo \"${r%%-*}\"'` → `PROJ`. Compare with design claim: → `PROJ-123`.",
      "recommendation": "The delimiter-aware extraction for template `fix/{issue-id}-{description}` with a `-` delimiter CANNOT use 'split at first -' when the issue-id itself contains hyphens. Two sound approaches: (A) Regex-based — extract issue_id by matching `^([A-Za-z][A-Za-z0-9]*-[0-9]+)` from the residue (this matches the standard PROJ-123 pattern and is tracker-agnostic for numeric IDs); (B) Greedy validation — take the whole residue and apply the full `^[A-Za-z0-9#._-]+$` regex on a GREEDY basis, BUT validate that the segment BEFORE the first lowercase word boundary is used (harder to express). Option A is simpler and covers YouTrack, Jira, Linear, GitLab, Gitea, GitHub. The spec must be explicit that 'split at first delimiter' does NOT work when the issue-id contains the delimiter; the algorithm needs to be redesigned. The design's own worked example already proves the algorithm needs to be something other than 'first occurrence split'."
    },
    {
      "id": "f-r2-b2",
      "severity": "HIGH",
      "criterion": "correctness",
      "location": "requirements.md SC-11 step 5 (regex `^[A-Za-z0-9#._]+$` NO hyphen)",
      "description": "The no-hyphen validation regex `^[A-Za-z0-9#._]+$` for the `description_present=true` case is wrong for standard tracker issue IDs. YouTrack IDs (`PROJ-123`), Jira IDs (`MYPROJECT-456`), Linear IDs (`ENG-789`), and GitHub-compatible IDs all contain hyphens. If the extraction algorithm produces `PROJ-123` as the candidate (by whatever correct method), the no-hyphen validation REJECTS it. The validator would set `issue_id = null` and mode = `pr-only-no-id` even for a valid YouTrack branch.\n\nThe spec's intent for no-hyphen validation is sound for ONE narrow case: if the delimiter between `{issue-id}` and `{description}` is a hyphen, AND the issue_id candidates ALSO use hyphens, then you CANNOT use a 'no hyphen after split' validation — because the pre-split extraction must already have handled the ambiguity.\n\nIf instead a regex-based extraction (Option A above) is used, the validation step becomes: confirm the match is `^[A-Za-z][A-Za-z0-9]*-[0-9]+$` or similar tracker-format-aware pattern. The current SC-11 step 5 no-hyphen regex only works if the extraction produces a hyphen-free segment (which requires a non-hyphen delimiter like `/`). The spec must be coherent: the algorithm design must work for real-world issue IDs.",
      "recommendation": "Revise SC-11 step 5 to clarify: when `post_delim == '-'` (hyphen), the 'first split' approach is inappropriate. Adopt a tracker-format regex for extraction (matches the convention used by all major trackers) and drop the no-hyphen restriction. When `post_delim != '-'` (e.g., `/`, `_`), the first-split-plus-no-hyphen approach is sound."
    },
    {
      "id": "f-r2-c3",
      "severity": "HIGH",
      "criterion": "correctness",
      "location": "formal-criteria.md AC-PUBLISH-AUTO-DETECT-EXTRACTION-1 (line 268)",
      "description": "AC-EXTRACTION-1 checks for `%%\\$\\{post_delim\\}\\*` in skills/publish/SKILL.md. If Phase 7 implements the CORRECT algorithm (which does NOT use `%%`) to fix the underlying extraction bug, this AC will FAIL even though the implementation is correct. The AC is pinned to the broken bash idiom from the design pseudocode. Because the design's bash idiom is wrong (as proven above), any correct implementation CANNOT use `%%${post_delim}*` to extract `PROJ-123` from `PROJ-123-fix-crash`. A Phase 7 author who implements the right algorithm (e.g., regex-based) will fail this AC. An author who follows the wrong AC will implement the wrong `%%` idiom and produce `PROJ` instead of `PROJ-123`.",
      "recommendation": "Remove the `%%\\$\\{post_delim\\}\\*` check from AC-EXTRACTION-1. Replace it with a check that verifies the correct semantics: grep for a pattern showing the algorithm handles the PROJ-123 case correctly (e.g., grep for the bash regex `[A-Za-z][A-Za-z0-9]*-[0-9]+` or equivalent). The AC must verify correctness, not a specific broken bash idiom."
    },
    {
      "id": "f-r2-d4",
      "severity": "MEDIUM",
      "criterion": "completeness",
      "location": "formal-criteria.md AC-PUBLISH-AUTO-DETECT-EXTRACTION-2 (line 276)",
      "description": "AC-EXTRACTION-2 uses OR: `grep -qE 'feature/PROJ-456|feature/\\{issue-id\\}'`. This passes if EITHER string appears. A Phase 7 author who documents only the template form `feature/{issue-id}` without the worked example input/output would satisfy this AC. Compare with AC-EXTRACTION-1 which (despite its bash idiom bug) requires BOTH the input string AND the output string. AC-EXTRACTION-2 does not verify that `PROJ-456` (the expected extracted value) appears near `feature/PROJ-456` in the skill prose.",
      "recommendation": "Strengthen to require BOTH the input example (`feature/PROJ-456`) AND an assertion that the extracted issue_id equals `PROJ-456`. Note: `feature/PROJ-456` with `post_delim=\"\"` (no description) takes the WHOLE residue as the candidate and validates `^[A-Za-z0-9#._-]+$`. `PROJ-456` contains a hyphen — this is valid under the no-post_delim path which allows hyphens. This sub-case is correct in the spec (unlike the SC-11 no-hyphen path above)."
    },
    {
      "id": "f-r2-e5",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "requirements.md SC-11 step 5 / design.md §3.1 Step 0d — regex `^[A-Za-z0-9#._]+$`",
      "description": "When `post_delim` is `/` (e.g., template `fix/{issue-id}/{description}`), `description_present=true` and the no-hyphen validation `^[A-Za-z0-9#._]+$` applies. But YouTrack/Jira IDs like `PROJ-123` still contain hyphens, and splitting at the first `/` correctly extracts `PROJ-123`. After splitting, the candidate is `PROJ-123` which contains a hyphen. The no-hyphen validation rejects it: `issue_id = null`. This edge case only matters for templates using `/` as the description separator (uncommon, but valid per the spec which says 'the delimiter character immediately following {issue-id}'). This is distinct from the `-` delimiter case in f-r2-a1 above, but stems from the same root cause: the no-hyphen restriction is too aggressive.",
      "recommendation": "The no-hyphen restriction should only apply when `post_delim == '-'` (because that is the only case where a hyphen in the candidate could be confused for the delimiter). For any other delimiter value, allow hyphens in the candidate with the full `^[A-Za-z0-9#._-]+$` charset."
    }
  ]
}
```

---

## Round 2 Detailed Analysis

### STOP-3 Check: No Stuck Loop

Round 1 finding IDs: `f-a1c2d3` (CRITICAL greedy regex), `f-b2d4e5` (CRITICAL workflow-router), `f-c3e5f6` (HIGH missing branch naming), `f-d4f6g7` (HIGH AC-TEST-INVENTORY-3), `f-e5g7h8` (HIGH CHANGELOG bullet 4), `f-f6h8i9` (MEDIUM email count), `f-g7i9j0` (MEDIUM SC-7/SC-8 single-line), `f-h8j0k1` (MEDIUM extraction correctness AC), `f-i9k1l2` (MINOR zero-commits), `f-j0l2m3` (MINOR FAIL-mode webhook), `f-k1m3n4` (MINOR CHANGELOG theme), `f-l2n4o5` (MINOR EARS rewrite-vs-remove).

None of these IDs appear in this round 2 report. STOP-3 does NOT trigger.

---

### CRITICAL-1 (f-a1c2d3): Greedy Regex — Resolution Status: RESOLUTION_FAILED (new form)

**Claim:** "FIXED at requirements.md REQ-PUBLISH-AUTO-DETECT EARS clause (b) + new SC-11 + design.md §3.1 Step 0d (delimiter-aware extraction with worked examples)"

**Verification:**

The revision correctly identifies that delimiter-aware extraction is needed and adds SC-11 as a 7-step algorithm. The SEMANTIC INTENT is correct: "split residue at FIRST occurrence of post_delim, take segment BEFORE it."

**The new bug (f-r2-a1):** The problem is that for the canonical use case — YouTrack/Jira branch naming like `fix/PROJ-123-fix-crash` with template `fix/{issue-id}-{description}` where `post_delim="-"` — the algorithm specification contains an internal contradiction:

1. SC-11 step 5 says: "split residue at the FIRST occurrence of that delimiter"
2. For residue `PROJ-123-fix-crash` and delimiter `-`, FIRST occurrence is at position 4 (after `PROJ`)
3. Segment BEFORE first `-` is `PROJ`
4. Validation: `PROJ` against `^[A-Za-z0-9#._]+$` — PASSES
5. Therefore `issue_id = "PROJ"` — NOT `"PROJ-123"`

But design.md §3.1 Step 0d worked example says:
> `candidate="PROJ-123" (split at first "-")`

This is arithmetically false: splitting `PROJ-123-fix-crash` at the first `-` yields `PROJ`, not `PROJ-123`.

Additionally, the cited bash implementation `${residue%%${post_delim}*}` was confirmed to produce `PROJ` (not `PROJ-123`) via runtime execution: `bash -c 'r="PROJ-123-fix-crash"; echo "${r%%-*}"'` → `PROJ`.

**Root cause:** The revision's algorithm design treats the delimiter as a simple single-character split boundary, but the primary real-world issue IDs (YouTrack, Jira, Linear) embed the same hyphen character in the tracker ID itself (`PROJ-123`). "Split at first hyphen" extracts only the project prefix, not the full ID.

**What would work:**
- Regex extraction: `[[ $residue =~ ^([A-Za-z][A-Za-z0-9]*-[0-9]+)(-|$) ]]` → `PROJ-123`
- The spec's own no-hyphen validation `^[A-Za-z0-9#._]+$` also fails for `PROJ-123` (contains hyphen)

**The original CRITICAL-1 bug** (greedy regex consuming description) is conceptually fixed — the revision correctly identifies that a delimiter is needed. But the replacement algorithm is broken for the same standard branch naming convention. The failure mode changed (was: too much in issue_id; now: too little in issue_id), but full-publish mode is still unreachable for `PROJ-123`-style branches with `-` as the template delimiter.

**AC-EXTRACTION-1 is compromised:** It verifies `%%\$\{post_delim\}\*` is present in the skill, but this is the wrong bash idiom. Any correct Phase 7 implementation that uses a regex-based approach would FAIL this AC.

---

### CRITICAL-2 (f-b2d4e5): Workflow-Router False Positives — RESOLVED

**Verification:**

1. **AC-RENAME-STATUS-4** (formal-criteria.md line 90): Now uses `--exclude=skills/workflow-router/SKILL.md`. FIXED.

2. **AC-RENAME-INIT-4** (line 140): Now uses `--exclude=skills/workflow-router/SKILL.md`. FIXED.

3. **AC-DEL-CREATE-PR-2** (line 310): Now uses `--exclude=skills/workflow-router/SKILL.md`. FIXED.

4. **AC-RENAME-STATUS-5** (lines 97-99): Tightened to check:
   - `grep -q '`ceos-agents:pipeline-status`' skills/workflow-router/SKILL.md` (positive)
   - `! grep -qE '^\| .*Show status.*\| `ceos-agents:status`' skills/workflow-router/SKILL.md` (intent table)
   - `! grep -qE 'NOT destructive.*\bstatus\b.*dashboard' skills/workflow-router/SKILL.md` (Step 3 prose)
   
   This correctly excludes the deprecated-names section while prohibiting the old form in the intent table and Step 3 prose. FIXED.

5. **AC-DEL-CREATE-PR-7** (lines 342-343):
   - `! grep -qE '^\| .*Create a pull request.*\| `ceos-agents:create-pr`' skills/workflow-router/SKILL.md`
   - `! grep -qE 'IS destructive.*create-pr,' skills/workflow-router/SKILL.md`
   
   Scoped to intent-table row format and destructive-list prose. FIXED.

6. **New AC-DOCS-COLLISION-WARN-WORKFLOW-1** (lines 398-399): Positively asserts `>= 3` hits of deprecated identifiers in workflow-router. FIXED.

7. **design.md §8.2** (lines 638-684): All three deprecated-identifier sanity greps now include `--exclude=skills/workflow-router/SKILL.md` + positive check. FIXED.

8. **REQ EARS texts** (requirements.md): REQ-RENAME-STATUS, REQ-RENAME-INIT, REQ-DEL-CREATE-PR all include the "EXCEPT in the workflow-router 'Did you mean...?' fallback prose" exception clause. FIXED.

**Design.md §5.3 resolution contract** (lines 522-524): The deferral is replaced with a binding "RESOLVED in Phase 4" statement cross-referencing formal-criteria.md. FIXED.

CRITICAL-2 is fully and correctly resolved. No residual false-positive risk.

---

### HIGH-1 (f-c3e5f6): Missing Branch naming Config Key — RESOLVED

**Verification:**

- **requirements.md SC-10** (lines 134-135): "When the `Source Control → Branch naming` config key is absent from Automation Config, the skill shall NOT FAIL; instead it shall log a single-line `[ceos-agents][INFO] No Branch naming pattern configured; PR-only mode.` line, set `issue_id = null` (and `tracker_needed = false`), and proceed to the pre-publish checks (Step 3)."

- **design.md §3.1 Step 0b** (lines 98-104): Explicit branch for ABSENT config key with INFO log + jump to Step 3.

- **design.md §3.2**: New "Missing Branch naming INFO tier" sample.

- **formal-criteria.md AC-PUBLISH-AUTO-DETECT-14** (lines 252-253): Verifies the INFO message text is present in the skill.

RESOLVED. The behavior is now fully specified.

---

### HIGH-2 (f-d4f6g7): AC-TEST-INVENTORY-3 Incomplete — RESOLVED

**Verification:**

AC-TEST-INVENTORY-3 (formal-criteria.md lines 590-591) now checks all 6 edits:
1. `grep -qF '18 optional config sections in total' tests/scenarios/v6.9.0-doc-count-drift.sh` ✓ (positive flip)
2. `grep -qF '19 optional config sections in total' tests/scenarios/v6.9.0-doc-count-drift.sh` ✓ (negative flip — the old string must now appear in the negative branch)
3. `grep -qE '\beq 28\b'` ✓
4. `grep -qE '\beq 18\b'` ✓
5. `grep -qE '18 optional, 28 skills'` ✓ (PASS message)
6. `! grep -qE '19 optional, 29 skills'` ✓ (old PASS message absent)

The revision also notes: "edit 5 (fallback prose 19 → 18): subsumed by edit 1 (same string updated)." This is correct — if the positive test for `'18 optional config sections in total'` passes, line 84 has been updated. RESOLVED.

---

### HIGH-3 (f-e5g7h8): CHANGELOG Bullet 4 Semantic Error — RESOLVED

**Verification:**

design.md §4.1 CHANGELOG migration item 4 (lines 373-382) is substantially rewritten:
- Sub-bullets now precisely describe the prefix-then-delimiter-aware-residue logic
- New "Branch parsing is delimiter-aware (NOT greedy)" sub-paragraph at line 379
- Lost-agency disclosure correctly explains that `chore/PROJ-123-foo` works because the `fix/` prefix no longer matches

The wording at line 374-376: "Branch starts with the configured `Branch naming` prefix AND the residue (delimiter-aware: split before first `{description}` delimiter) yields a valid issue-ID-shaped segment AND that issue exists in the tracker → full publish."

NOTE: This CHANGELOG wording is now ALSO inconsistent with finding f-r2-a1. If the algorithm cannot correctly extract `PROJ-123` from `PROJ-123-fix-crash` (as proven above), then the CHANGELOG's promised behavior (full-publish when issue exists) is still not actually achievable for standard branches. This is a downstream consequence of f-r2-a1 — when f-r2-a1 is fixed the CHANGELOG may need to be re-read, but the CHANGELOG wording itself is accurate assuming the algorithm works.

RESOLVED (subject to f-r2-a1 fix).

---

### MEDIUM (f-g7i9j0): SC-7/SC-8 Single-Line vs Multi-Line — RESOLVED

**Verification:**

- **requirements.md SC-7** (lines 128-129): "single-line (one logical line, one `echo` invocation, terminated by a single `\n`)"
- **requirements.md SC-8** (lines 130-131): Same single-line annotation.
- **design.md §3.2** (lines 300-303): 404 WARN tier shows the message as ONE visible line + "NOTE — this is ONE logical line; emit as a single `echo` call (single `\n` at end)."
- **design.md §3.2** (lines 308-311): No-issue-id INFO tier same treatment.
- **AC-PUBLISH-AUTO-DETECT-12** (line 238): Single-line grep with all 4 required token patterns.
- **AC-PUBLISH-AUTO-DETECT-13** (line 244): Same for INFO message.

RESOLVED. The NOTE annotation in design.md eliminates the spec ambiguity that would cause Phase 7 to implement 3 echo calls.

---

### MEDIUM (f-f6h8i9): CONTRIBUTING.md Email Count in §8.1 — RESOLVED

**Verification:**

design.md §8.1 (line 617): `# Expected: SECURITY.md: 1, CODE_OF_CONDUCT.md: 1, CONTRIBUTING.md: 1`

Previously said `CONTRIBUTING.md: 2`. Now corrected to 1. RESOLVED.

---

### MEDIUM (f-h8j0k1): No AC Tests Extraction Correctness — PARTIALLY RESOLVED

**Verification:**

New ACs AC-PUBLISH-AUTO-DETECT-EXTRACTION-1/-2/-3 test extraction correctness at the doc level. However, as noted in finding f-r2-c3/f-r2-a1, AC-EXTRACTION-1 is pinned to the wrong bash idiom `%%` which itself produces the wrong result. The AC will correctly FAIL a Phase 7 author who implements a correct algorithm (e.g., regex-based), and will PASS a Phase 7 author who implements the wrong `%%` idiom. This is a false-positive gate.

PARTIAL RESOLUTION (the intent is there but the AC itself is broken by f-r2-a1).

---

### MINOR (f-i9k1l2): No AC for Zero-Commits Early-Stop — RESOLVED

**AC-PUBLISH-AUTO-DETECT-ZERO-COMMITS** (lines 292-293): `grep -qE 'No changes to publish|zero commits|no commits above' skills/publish/SKILL.md`. RESOLVED.

---

### MINOR (f-j0l2m3): FAIL-Mode Webhook Unspecified — ADDRESSED

**requirements.md SC-9** (lines 132-133): "No `pr-created` event fires on FAIL. Whether `pipeline-completed` with `outcome: failed` fires on `/publish` FAIL is also deferred to v7.0.1+." ADDRESSED per spec — deferral is explicitly documented.

---

### MINOR (f-k1m3n4): CHANGELOG Theme Convention — ACCEPTED AS-IS

Per revision-1.md: "ACCEPTED AS-IS, rationale: cosmetic, fixed at /version-bump time." The design.md §4.1 template uses `## [7.0.0] — Unreleased` without a theme subtitle. This is cosmetic. Not re-raised.

---

### MINOR (f-l2n4o5): REQ-DEL-CREATE-PR EARS Rewrite-vs-Remove Ambiguity — RESOLVED

**requirements.md REQ-DEL-CREATE-PR EARS** (lines 151): "shall be either removed (if a self-contained row/example/array element, OR if it is a `/publish` skill's own 'Related skills' entry referring back to itself), or rewritten to reference `/ceos-agents:publish` (if a 'Related skills' or alternative-skill mention IN ANOTHER SKILL — not in `/publish` itself)." RESOLVED.

---

## New Bug Analysis: The Core Extraction Algorithm (f-r2-a1 / f-r2-b2)

This is the most important finding of this round. The revision's fix for CRITICAL-1 introduced a new form of the same fundamental problem.

**Root cause analysis:**

The revision's algorithm is based on "split at delimiter character." This works for delimiters that do NOT appear in the issue ID. But:
- YouTrack format: `PROJ-123` — contains `-`
- Jira format: `MYPROJECT-456` — contains `-`
- Linear format: `ENG-789` — contains `-`
- GitHub issue reference: `#123` — no hyphen (safe)

When `post_delim = "-"` (the most common template: `fix/{issue-id}-{description}`), splitting at the first `-` always yields the project prefix alone (`PROJ`, `MYPROJECT`, `ENG`), not the full ID.

**The design's worked example `PROJ-123` is therefore impossible to achieve with the stated algorithm**. This is not a subtle edge case — it is the CANONICAL example used throughout the spec and it is wrong.

**Proposed algorithm that actually works:**

Use a regex that matches the tracker ID format: `[A-Za-z][A-Za-z0-9]*-[0-9]+` (letter prefix, hyphen, digits). This is the universal convention for YouTrack/Jira/Linear. For issue trackers that use `#123` format (GitHub), the regex also handles `#[0-9]+`.

Alternative: instruct users to use a non-hyphen delimiter for descriptions, e.g., `fix/{issue-id}_{description}` with `post_delim="_"`. This would make "split at first `_`" work correctly. But this changes the project convention and breaks existing branches.

The spec must be explicit about which tracker ID formats are supported and design the algorithm around them, rather than using a generic "split at delimiter" that fails for the dominant formats.

---

## Summary of Round 1 Resolution Status

| Round 1 Finding | Severity | Resolution Status |
|---|---|---|
| f-a1c2d3 (greedy regex) | CRITICAL | RESOLUTION_FAILED — new form of same bug introduced |
| f-b2d4e5 (workflow-router false positives) | CRITICAL | RESOLVED |
| f-c3e5f6 (missing Branch naming) | HIGH | RESOLVED |
| f-d4f6g7 (AC-TEST-INVENTORY-3) | HIGH | RESOLVED |
| f-e5g7h8 (CHANGELOG bullet 4) | HIGH | RESOLVED (subject to f-r2-a1 fix) |
| f-f6h8i9 (email count) | MEDIUM | RESOLVED |
| f-g7i9j0 (single-line SC-7/SC-8) | MEDIUM | RESOLVED |
| f-h8j0k1 (extraction correctness AC) | MEDIUM | PARTIALLY RESOLVED (AC pinned to broken idiom) |
| f-i9k1l2 (zero-commits AC) | MINOR | RESOLVED |
| f-j0l2m3 (FAIL webhook) | MINOR | ADDRESSED (deferred to v7.0.1) |
| f-k1m3n4 (CHANGELOG theme) | MINOR | ACCEPTED AS-IS |
| f-l2n4o5 (EARS rewrite/remove) | MINOR | RESOLVED |

**r1_critical_resolved: 1/2** — f-b2d4e5 resolved; f-a1c2d3 has a new equivalent.

**r1_high_resolved: 3/3** — All HIGH findings resolved.

**new_findings: 5** — f-r2-a1 (CRITICAL), f-r2-b2 (HIGH), f-r2-c3 (HIGH), f-r2-d4 (MEDIUM), f-r2-e5 (MINOR).

---

## Blocker Before Phase 7

**Finding f-r2-a1 (CRITICAL)** must be resolved before Phase 7. The extraction algorithm in SC-11 and design.md §3.1 Step 0d is broken for the canonical case: `fix/PROJ-123-fix-crash` with `post_delim="-"`. The bash idiom `%%` produces `PROJ`; the "split at first occurrence" algorithm also produces `PROJ`. Neither produces `PROJ-123`. The full-publish mode is unreachable for any branch with a YouTrack/Jira/Linear-style issue ID when the template delimiter is `-`.

**Finding f-r2-b2 (HIGH)** is a secondary consequence: the no-hyphen validation `^[A-Za-z0-9#._]+$` for `description_present=true` would also reject `PROJ-123` if it were somehow extracted correctly.

**Finding f-r2-c3 (HIGH)** renders AC-EXTRACTION-1 actively harmful: it will reject correct implementations and accept the broken `%%` idiom.

DONE — verdict=FAIL, r1_critical_resolved=1/2, r1_high_resolved=3/3, new_findings=5
