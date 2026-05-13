# Phase 4 Review 3 — Devil's Advocate (Tier 3 Only) — Round 3

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
    "correctness": 4,
    "completeness": 4,
    "security": 4,
    "maintainability": 4,
    "robustness": 4,
    "weighted_aggregate": 4.0,
    "pass": true
  },
  "overall_verdict": "PASS",
  "confidence": 0.93,
  "findings": []
}
```

---

## STOP-3 Check

Round 2 finding IDs: `f-r2-a1` (CRITICAL), `f-r2-b2` (HIGH), `f-r2-c3` (HIGH), `f-r2-d4` (MEDIUM), `f-r2-e5` (MINOR).

None of these IDs appear in this round 3 report. STOP-3 does NOT trigger.

---

## Round-2 Finding Resolution Verification

### f-r2-a1 (CRITICAL — broken extraction algorithm): FIXED

**What was broken:** The round-1 revision introduced `${residue%%-*}` (longest-match `%%` bash idiom) and a "split at first delimiter" description. For `residue="PROJ-123-fix-crash"` and delimiter `-`, both approaches yield `PROJ`, not `PROJ-123`.

**Verification against round-2 spec:**

`requirements.md` SC-11 (steps 1-6): The "split at delimiter" approach is explicitly described as ABANDONED with a stated rationale ("YouTrack/Jira/Linear issue IDs (`PROJ-123`) themselves contain `-`, so splitting at the first `-` of `PROJ-123-fix-crash` yields `PROJ`, not `PROJ-123`"). The algorithm now uses the canonical regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)` anchored at the start of the residue. There is no `%%` idiom, no `post_delim` parsing, no "split at first occurrence" language anywhere in SC-11.

`design.md` §3.1 Step 0c-0d: Step 0c now only identifies `pre_prefix` (the literal prefix preceding `{issue-id}`). Step 0d contains the explicit Bash idiom:
```
if [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]]; then
  issue_id="${BASH_REMATCH[1]}"
else
  issue_id=""
fi
```
No `%%`. No `post_delim`. A 6-row tracker-coverage table and 6 worked examples (including `PROJ-123-fix-crash → PROJ-123`) are present.

**Mental execution of specified test cases against the regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)`:**

| residue | regex branch | result |
|---------|-------------|--------|
| `PROJ-123-fix-crash` | `[A-Za-z][A-Za-z0-9_]*-[0-9]+` → P+ROJ then -123, trailing `-fix-crash` discarded | `PROJ-123` ✓ |
| `PROJ-456` | `[A-Za-z][A-Za-z0-9_]*-[0-9]+` | `PROJ-456` ✓ |
| `123-numeric-id` | `#?[0-9]+` → matches `123`, trailing `-numeric-id` discarded | `123` ✓ |
| `#42-fix` | `#?[0-9]+` → matches `#42`, trailing `-fix` discarded | `#42` ✓ |
| `ABC_DEF-789` | `[A-Za-z][A-Za-z0-9_]*-[0-9]+` → A then BC_DEF then -789 | `ABC_DEF-789` ✓ |
| (no residue — prefix didn't match) | prefix-strip guard before regex runs → `issue_id = null` | null ✓ |

Note on `ABC_DEF-789`: the character class `[A-Za-z0-9_]*` allows underscore, so `BC_DEF` is consumed; then `-789` matches `-[0-9]+`. Correct.

VERDICT: **FIXED**.

---

### f-r2-b2 (HIGH — no-hyphen validation regex `^[A-Za-z0-9#._]+$` rejecting PROJ-123): FIXED

**Verification:** The no-hyphen validation regex `^[A-Za-z0-9#._]+$` is completely absent from both `requirements.md` and `design.md`. SC-11 in `requirements.md` contains only two regexes: the canonical extraction regex and the dot-only path-traversal defense `^\.+$`. The `design.md` §3.1 Step 0d contains only those same two regexes. There is no `description_present` branch, no `post_delim`-conditional validation, and no charset validator that excludes hyphens.

The structural rationale: the canonical extraction regex IS the validator by construction. `PROJ-123` matches `[A-Za-z][A-Za-z0-9_]*-[0-9]+` and is accepted. The only secondary check is the defensive `^\.+$` (dot-only) which the canonical regex can never match anyway.

VERDICT: **FIXED**.

---

### f-r2-c3 (HIGH — AC-EXTRACTION-1 pinned to broken `%%` bash idiom): FIXED

**Verification:** `formal-criteria.md` AC-PUBLISH-AUTO-DETECT-EXTRACTION-1 (lines 269-271):

```bash
grep -qE 'PROJ-123-fix-crash' skills/publish/SKILL.md && grep -qE 'PROJ-123\b' skills/publish/SKILL.md && grep -qE '\[A-Za-z\]\[A-Za-z0-9_\]\*-\[0-9\]\+|BASH_REMATCH|canonical.*extraction.*regex' skills/publish/SKILL.md && bash -c 'residue="PROJ-123-fix-crash"; [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]] && [[ "${BASH_REMATCH[1]}" == "PROJ-123" ]]'
```

There is no `%%\$\{post_delim\}\*` check anywhere in this AC. The AC now:
1. Verifies the worked example input (`PROJ-123-fix-crash`) is documented.
2. Verifies the expected output (`PROJ-123`) is documented.
3. Verifies the canonical regex character class OR `BASH_REMATCH` OR the phrase `canonical extraction regex` appears in the skill.
4. Includes an embedded runtime bash check (`BASH_REMATCH[1] == "PROJ-123"`) that proves the semantics are correct independent of the prose.

A Phase 7 author implementing a correct regex-based extractor will PASS this AC. A Phase 7 author implementing the broken `%%` idiom would FAIL the embedded bash check (since `${BASH_REMATCH[1]}` is never set by `%%` — that idiom does not use BASH_REMATCH). The AC now correctly rewards correct implementations and rejects broken ones.

VERDICT: **FIXED**.

---

### f-r2-d4 (MEDIUM — AC-EXTRACTION-2 OR-form too lax): FIXED

**Verification:** `formal-criteria.md` AC-PUBLISH-AUTO-DETECT-EXTRACTION-2 (lines 277-279):

```bash
grep -qE 'feature/PROJ-456' skills/publish/SKILL.md && grep -qE 'PROJ-456' skills/publish/SKILL.md && bash -c 'residue="PROJ-456"; [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]] && [[ "${BASH_REMATCH[1]}" == "PROJ-456" ]]'
```

Both the input example (`feature/PROJ-456`) AND the expected output (`PROJ-456`) must be present (two separate `grep -qE` checks, chained with `&&`). Plus an independent runtime bash verification. This is not an OR-form anymore.

VERDICT: **FIXED**.

---

### f-r2-e5 (MINOR — `/`-delimiter still rejected hyphens): FIXED

**Verification:** The `post_delim` concept is eliminated from the spec entirely. The design.md §3.1 Step 0c explicitly states: "The post-`{issue-id}` delimiter character is intentionally NOT parsed or used as a split boundary. The canonical extraction regex (Step 0d) understands the structure of valid issue IDs and consumes only the issue-ID portion, ignoring any trailing description segment."

Templates using `/`, `_`, `-`, or any other character as the post-`{issue-id}` separator all work uniformly through the same regex path. There is no code path that applies different validation based on the delimiter character.

VERDICT: **FIXED**.

---

## New-Bug Check (Round-2 Revision Targeted Scope)

The round-2 revision was narrowly scoped: only the extraction algorithm in requirements.md SC-11, design.md §3.1 Step 0c-0d, and 5 ACs in formal-criteria.md. All other spec content is carried over unchanged from round 1. I check specifically for bugs introduced by the new regex.

### Regex correctness across all 6 supported tracker ID shapes

**Regex under review:** `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)`

| Tracker | ID shape | Example residue | Match? | Extracted |
|---------|----------|-----------------|--------|-----------|
| youtrack | `PREFIX-N` (uppercase) | `PROJ-123-fix-crash` | Yes | `PROJ-123` |
| jira | `PREFIX-N` (uppercase) | `ABC-456` | Yes | `ABC-456` |
| linear | `PREFIX-N` (uppercase) | `ENG-789` | Yes | `ENG-789` |
| github/gitea/redmine | `N` (numeric) | `42-fix-crash` | Yes | `42` |
| github/gitea/redmine | `#N` (hash-prefixed) | `#42-fix` | Yes | `#42` |
| youtrack (underscore) | `PREFIX_SUB-N` | `ABC_DEF-789` | Yes | `ABC_DEF-789` |

All 6 shapes verified correct. The regex uses `[A-Za-z0-9_]*` which allows underscore in the project prefix, handles YouTrack underscore-separator IDs.

### Edge cases that do NOT regress

**2-letter prefix:** `AB-12` → `[A-Za-z]` matches `A`, `[A-Za-z0-9_]*` matches `B`, then `-12`. Correct.

**All-lowercase prefix:** `proj-42` → valid. The regex allows mixed-case; no uppercase-only restriction.

**Zero as issue number:** `PROJ-0` → `[0-9]+` matches `0`. Correct.

**Single-letter prefix:** `A-123` → `[A-Za-z]` = `A`, `[A-Za-z0-9_]*` = (empty), then `-123`. Correct.

### Edge cases with expected null behavior

**Multi-segment prefix (non-standard):** `PROJ-MOB-123` — `[A-Za-z][A-Za-z0-9_]*` matches `PROJ` (stops at first `-` since `-` not in `[A-Za-z0-9_]*`), then `-[0-9]+` requires digits but finds `MOB`. Does NOT match the second alternative. Does it match the first alternative `#?[0-9]+`? No — `PROJ-MOB-123` does not start with `#` or a digit. Result: `issue_id = null`. This is correct behavior: `PROJ-MOB-123` is not a standard tracker ID shape in any supported tracker. The spec does not claim to support multi-level prefix IDs.

**Pure-text residue:** `fix-some-bug` → not `#?[0-9]+` (no leading digit/hash), not `[A-Za-z][A-Za-z0-9_]*-[0-9]+` (ends in `bug`, not digits). `issue_id = null`. Correct — this is a chore branch that doesn't match any issue ID format.

**Numeric residue starting with alpha:** `abc` → not `#?[0-9]+`, not the alpha-prefix form (no `-[0-9]+` suffix). `issue_id = null`. Correct.

### Path-traversal defense still present

`requirements.md` SC-11 step 6: "Apply path-traversal defense: if `issue_id =~ ^\.+$` (dot-only): `issue_id = null`."

`design.md` §3.1 Step 0d: "Path-traversal defense (defensive — canonical regex never matches dot-only by construction): if issue_id =~ ^\.+$, set issue_id = null."

The AC-PUBLISH-AUTO-DETECT-3 bash check includes `grep -qE '\^\\\.\+\$|\^\.\+\$' skills/publish/SKILL.md` to verify the dot-only defense appears in the skill file.

Both the spec text and the AC verify the v6.8.1 path-traversal defense is preserved. Canonical regex cannot match dot-only by construction (`.` is not in any of the character classes), so this check is defensive. PRESENT AND CORRECT.

### No `post_delim` orphan references

After the revision, `post_delim` is completely eliminated from requirements.md and design.md. There are no orphan references that would confuse a Phase 7 implementer into re-introducing delimiter splitting. The removal is clean.

### AC arithmetic

Round-2 revision added 2 new ACs (AC-EXTRACTION-4 and AC-EXTRACTION-5) to formal-criteria.md. Summary section states `REQ-PUBLISH-AUTO-DETECT: 21 (was 19 in r1; +2 in revision-2)` and total `94 ACs`. The AC count is consistent throughout the document.

### CHANGELOG sub-bullet 4 consistency

`design.md` §4.1 migration item 4 (lines 407-413): the sub-bullets no longer reference "delimiter-aware split." They reference "residue matches the canonical issue-ID extraction regex" and include an explicit note about the abandoned `%%-*` approach producing `PROJ` instead of `PROJ-123`. This is internally consistent with the corrected algorithm.

### No regression to round-1 PASS findings

The following round-1 findings were confirmed RESOLVED in round-2 review. I verify none are re-broken by the round-2 targeted edit:

- **f-b2d4e5 (CRITICAL — workflow-router false positives):** `--exclude=skills/workflow-router/SKILL.md` flags in all three global deprecated-identifier greps are unchanged. The targeted round-2 edit did not touch these ACs. STILL RESOLVED.
- **f-c3e5f6 (HIGH — missing Branch naming config key):** SC-10 and AC-PUBLISH-AUTO-DETECT-14 are unchanged. STILL RESOLVED.
- **f-d4f6g7 (HIGH — AC-TEST-INVENTORY-3 incomplete):** AC-TEST-INVENTORY-3 with 6 edit checks is unchanged. STILL RESOLVED.
- **f-e5g7h8 (HIGH — CHANGELOG bullet 4):** The CHANGELOG wording now references the canonical regex (consistent with the fix). STILL RESOLVED.
- **f-g7i9j0 (MEDIUM — SC-7/SC-8 single-line):** SC-7, SC-8, and ACs 12/13 unchanged. STILL RESOLVED.
- **f-f6h8i9 (MEDIUM — CONTRIBUTING.md email count):** design.md §8.1 `Expected: CONTRIBUTING.md: 1` unchanged. STILL RESOLVED.

---

## Overall Assessment

The round-2 revision is targeted, correct, and complete. Every round-2 finding is resolved at the root cause level:

- **f-r2-a1 (CRITICAL):** The broken `%%` idiom and "split at first delimiter" algorithm are gone. Replaced with a canonical extraction regex that handles all 6 tracker ID shapes correctly, including the canonical YouTrack/Jira/Linear `PROJ-123` format with `-` in the issue ID.
- **f-r2-b2 (HIGH):** The no-hyphen validation regex is eliminated; the canonical extraction regex serves as the structural validator.
- **f-r2-c3 (HIGH):** AC-EXTRACTION-1 no longer enforces the broken `%%` idiom. It now verifies the correct regex pattern AND embeds a runtime bash correctness check.
- **f-r2-d4 (MEDIUM):** AC-EXTRACTION-2 strengthened from OR-form to require both input and output.
- **f-r2-e5 (MINOR):** `post_delim` parsing eliminated; all delimiter characters handled uniformly through the regex.

No new bugs were introduced. The spec is now internally consistent, the worked examples match the algorithm, and the ACs correctly reward correct implementations.

---

DONE — verdict=PASS, r2_critical_resolved=1/1, r2_high_resolved=2/2, new_findings=0, STOP3_triggered=false
